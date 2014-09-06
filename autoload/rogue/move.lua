local g = Rogue -- alias

g.m_moves = 0
g.you_can_move_again = ''
g.jump = false
local bent_passage
local move_left_cou = 0

local heal_exp = -1
local heal_n = 0
local heal_c = 0
local heal_alt = false

function g.init_move()
	g.you_can_move_again = g.mesg[66]
end

function g.gr_dir()
	local idx = g.get_rand(1, 8)
	return string.sub("jklhyubn", idx, idx)
end

function g.one_move_rogue(dirch, pickup)
	local r = g.rogue.row
	local c = g.rogue.col
	bent_passage = false

	if g.confused > 0 then
		dirch = g.gr_dir()
	end
	r, c = g.get_dir_rc(dirch, r, c, true)
	local row = r
	local col = c

	if not g.can_move(g.rogue.row, g.rogue.col, row, col) then
		if (g.cur_room == g.PASSAGE) and (g.blind == 0) and (g.confused == 0) and 
				(not string.match("yubn", dirch)) then
			bent_passage = true
		end
		return g.MOVE_FAILED
	end
	if g.being_held or g.bear_trap > 0 then
		if not g.dungeon[row][col][g.MONSTER] then
			if g.being_held then
				g.message(g.mesg[67], true)
			else
				g.message(g.mesg[68])
				g.reg_move()
			end
			return g.MOVE_FAILED
		end
	end
	if g.r_teleport then
		if g.rand_percent(g.R_TELE_PERCENT) then
	 		g.tele()
			return g.STOPPED_ON_SOMETHING
		end
	end
	if g.dungeon[row][col][g.MONSTER] then
		g.rogue_hit(g.object_at(g.level_monsters, row, col), false)
		g.reg_move()
		return g.MOVE_FAILED
	end
	if g.dungeon[row][col][g.DOOR] then
		if g.cur_room == g.PASSAGE then
			g.cur_room = g.get_room_number(row, col)
			g.light_up_room(g.cur_room)
			g.wake_room(g.cur_room, true, row, col)
		else
			g.light_passage(row, col)
		end
	elseif g.dungeon[g.rogue.row][g.rogue.col][g.DOOR] and g.dungeon[row][col][g.TUNNEL]then
		g.light_passage(row, col)
		g.wake_room(g.cur_room, false, g.rogue.row, g.rogue.col)
		g.darken_room(g.cur_room)
		g.cur_room = g.PASSAGE
	elseif g.dungeon[row][col][g.TUNNEL]then
		g.light_passage(row, col)
	end

	g.mvaddch(g.rogue.row, g.rogue.col, g.get_dungeon_char(g.rogue.row, g.rogue.col))
	g.mvaddch(row, col, g.rogue.fchar)

	if not g.jump then
		g.refresh()
	end
	g.rogue.row = row
	g.rogue.col = col

	if g.dungeon[row][col][g.OBJECT] then
		if g.levitate > 0 and pickup then
			return g.STOPPED_ON_SOMETHING
		end
		local obj
		local desc
		if pickup and g.levitate == 0 then
			local status
			obj, status = g.pick_up(row, col)
			if obj then
				desc = g.get_desc(obj, true)
				if obj.what_is == g.GOLD then
					g.free_object(obj)
					if g.JAPAN then
						desc = desc .. g.mesg[69]
					end
					-- goto NOT_IN_PACK
					g.message(desc, true)
					g.reg_move()
					return g.STOPPED_ON_SOMETHING
				end
			elseif not status then
				-- goto MVED
				if g.reg_move() then
					return g.STOPPED_ON_SOMETHING
				end
				return g.confused > 0 and g.STOPPED_ON_SOMETHING or g.MOVED
			else
				-- goto MOVE_ON
				obj = g.object_at(g.level_objects, row, col)
				if g.JAPAN then
					desc = g.get_desc(obj, false)
					desc = desc .. g.mesg[70]
				else
					desc = g.mesg[70]
					desc = desc .. g.get_desc(obj, false)
				end
				-- goto NOT_IN_PACK
				g.message(desc, true)
				g.reg_move()
				return g.STOPPED_ON_SOMETHING
			end
		else
			-- ::MOVE_ON::
			obj = g.object_at(g.level_objects, row, col)
			if g.JAPAN then
				desc = g.get_desc(obj, false)
				desc = desc .. g.mesg[70]
			else
				desc = g.mesg[70]
				desc = desc .. g.get_desc(obj, false)
			end
			-- goto NOT_IN_PACK
			g.message(desc, true)
			g.reg_move()
			return g.STOPPED_ON_SOMETHING
		end
		if g.JAPAN then
			desc = desc .. g.mesg[69]
		end
		desc = desc .. '(' .. obj.ichar .. ')'
		-- ::NOT_IN_PACK::
		g.message(desc, true)
		g.reg_move()
		return g.STOPPED_ON_SOMETHING
	end
	if g.dungeon[row][col][g.DOOR] or g.dungeon[row][col][g.STAIRS] or g.dungeon[row][col][g.TRAP] then
		if g.levitate == 0 and g.dungeon[row][col][g.TRAP] then
			g.trap_player(row, col)
		end
		g.reg_move()
		return g.STOPPED_ON_SOMETHING
	end
	-- ::MVED::
	if g.reg_move() then -- fainted from hunger
		return g.STOPPED_ON_SOMETHING
	end
	return g.confused > 0 and g.STOPPED_ON_SOMETHING or g.MOVED
end

local function next_to_something(drow, dcol)
	local row
	local col
	local pass_count = 0
	local s

	if g.confused > 0 then
		return true
	end
	if g.blind > 0 then
		return false
	end
	local i_end = (g.rogue.row < (g.DROWS-2)) and 1 or 0
	local j_end = (g.rogue.col < (g.DCOLS-1)) and 1 or 0

	for i = ((g.rogue.row > g.MIN_ROW) and -1 or 0), i_end do
		for j = ((g.rogue.col > 0) and -1 or 0), j_end do
			local continue_flag = false
			if (i == 0 and j == 0) or
				(g.rogue.row+i == drow and g.rogue.col+j == dcol) then
				-- continue
				continue_flag = true
			else
				row = g.rogue.row + i
				col = g.rogue.col + j
				s = g.dungeon[row][col]
				if s[g.HIDDEN] then
					-- continue
					continue_flag = true
				end
			end
			if not continue_flag then
				-- If the rogue used to be right, up, left, down,
				-- or right of row, col, and now isn't,
				-- then don't stop
				if s[g.MONSTER] or s[g.OBJECT] or s[g.STAIRS] then
					if (row == drow or col == dcol) and
						(not(row == g.rogue.row or col == g.rogue.col)) then
						-- continue
						continue_flag = true
					else
						return true
					end
				end
			end
			if not continue_flag then
				if s[g.TRAP] then
					if not s[g.HIDDEN] then
						if (row == drow or col == dcol) and
							(not(row == g.rogue.row or col == g.rogue.col)) then
							-- continue
							continue_flag = true
						else
							return true
						end
					end
				end
			end
			if not continue_flag then
				if ((i - j == 1) or (i - j == -1)) and s[g.TUNNEL] then
					pass_count = pass_count + 1
					if pass_count > 1 then
						return true
					end
				end
				if s[g.DOOR] and ((i == 0) or (j == 0)) then
					return true
				end
			end
		end
	end
	return false
end

function g.multiple_move_rogue(dirch)
	local row
	local col
	local m
	local n
	local ch
	local dir
	if dirch == 'CTRL_H' or
			 dirch == 'CTRL_J' or
			 dirch == 'CTRL_K' or
			 dirch == 'CTRL_L' or
			 dirch == 'CTRL_Y' or
			 dirch == 'CTRL_U' or
			 dirch == 'CTRL_N' or
			 dirch == 'CTRL_B' then
		dirch = dirch:gsub('CTRL_', ''):lower()
		local retry_flag
		repeat
			-- ::retry::
			retry_flag = false
			row = g.rogue.row
			col = g.rogue.col
			m = g.one_move_rogue(dirch, true)
			if m == g.STOPPED_ON_SOMETHING or g.interrupted then
				break
			end
			if m ~= g.MOVE_FAILED then
				-- continue
			else
				if (not g.pass_go) or (not bent_passage) then
					break
				end
				n = 0
				dir = {[0] = 'h', 'j', 'k', 'l'}
				for i = 0, 3 do
					row = g.rogue.row
					col = g.rogue.col
					row, col = g.get_dir_rc(dir[i], row, col, true)
					if g.is_passable(row, col) and dirch ~= dir[3-i] then
						n = n + 1
						ch = dir[i]
					end
				end
				if n == 1 then
					dirch = ch
					-- goto retry
					retry_flag = true
				else
					break
				end
			end
		until (not retry_flag) and next_to_something(row, col)
	 elseif dirch == 'H' or
			 dirch == 'J' or
			 dirch == 'K' or
			 dirch == 'L' or
			 dirch == 'Y' or
			 dirch == 'U' or
			 dirch == 'N' or
			 dirch == 'B' then
		dirch = dirch:lower()
		while true do
			-- ::retry2::
			m = g.one_move_rogue(dirch, true)
			if g.interrupted then
				break
			end
			if m == g.MOVED then
				-- continue
			else
				if m ~= g.MOVE_FAILED or (not g.pass_go) or (not bent_passage) then
					break
				end
				n = 0
				dir = {[0] = 'h', 'j', 'k', 'l'}
				for i = 0, 3 do
					row = g.rogue.row
					col = g.rogue.col
					row, col = g.get_dir_rc(dir[i], row, col, true)
					if g.is_passable(row, col) and dirch ~= dir[3-i] then
						n = n + 1
						ch = dir[i]
					end
				end
				if n == 1 then
					dirch = ch
					-- goto retry2
				else
					break
				end
			end
		end
	 end
end

function g.can_move(row1, col1, row2, col2) 
	if not g.is_passable(row2, col2) then
		return false
	end
	if (row1 ~= row2) and (col1 ~= col2) then
		if g.dungeon[row1][col1][g.DOOR] or g.dungeon[row2][col2][g.DOOR]
				or g.table_is_empty(g.dungeon[row1][col2]) or g.table_is_empty(g.dungeon[row2][col1]) then
			return false
		end
	end
	return true
end

function g.move_onto()
	local ch = g.get_direction()
	if ch ~= g.CANCEL then
		g.one_move_rogue(ch, false)
	end
end

function g.is_direction(c)
	if c == g.CANCEL then
		return true
	end
	if string.find('hjklbyun', c) then
		return true
	end
	return false
end

local function check_hunger(messages_only)
	local fainted = false

	if g.rogue.moves_left == g.HUNGRY then
		g.hunger_str = g.mesg[71]
		g.message(g.mesg[72])
		g.print_stats()
	end
	if g.rogue.moves_left == g.WEAK then
		g.hunger_str = g.mesg[73]
		g.message(g.mesg[74], true)
		g.print_stats()
	end
	if g.rogue.moves_left <= g.FAINT then
		if g.rogue.moves_left == g.FAINT then
			g.hunger_str = g.mesg[75]
			g.message(g.mesg[76], true)
			g.print_stats()
		end
		local n = g.get_rand(0, (g.FAINT - g.rogue.moves_left))
		if n > 0 then
			fainted = true
			if g.rand_percent(40) then
				g.rogue.moves_left = g.rogue.moves_left + 1
			end
			g.message(g.mesg[77], true)
			for i = 1, n do
				if g.coin_toss() then
					g.mv_mons()
				end
			end
			g.message(g.you_can_move_again, true)
		end
	end
	if messages_only then
		return fainted
	end
	if g.rogue.moves_left <= g.STARVE then
		g.killed_by(nil, g.STARVATION)
		-- NOTREACHED
	end
	if g.e_rings == -1 then
		g.rogue.moves_left = g.rogue.moves_left - move_left_cou
	elseif g.e_rings == 0 then
		g.rogue.moves_left = g.rogue.moves_left - 1
	elseif g.e_rings == 1 then
		g.rogue.moves_left = g.rogue.moves_left - 1
		check_hunger(true)
		g.rogue.moves_left = g.rogue.moves_left - move_left_cou
	elseif g.e_rings == 2 then
		g.rogue.moves_left = g.rogue.moves_left - 1
		check_hunger(true)
		g.rogue.moves_left = g.rogue.moves_left - 1
	end
	move_left_cou = 1
	return fainted
end

function g.is_passable(row, col)
	if (row < g.MIN_ROW) or (row > (g.DROWS - 2)) or (col < 0) or (col > (g.DCOLS-1)) then
		return false
	end
	if g.dungeon[row][col][g.HIDDEN] then
		return g.dungeon[row][col][g.TRAP] and true or false
	end
	if g.dungeon[row][col][g.FLOOR] or 
			g.dungeon[row][col][g.TUNNEL] or 
			g.dungeon[row][col][g.DOOR] or 
			g.dungeon[row][col][g.STAIRS] or 
			g.dungeon[row][col][g.TRAP] then
		return true
	else
		return false
	end
end

local function heal()
	local na = { [0] = 0, 20, 18, 17, 14, 13, 10, 9, 8, 7, 4, 3 }

	if g.rogue.hp_current == g.rogue.hp_max then
		heal_c = 0
		return
	end
	if g.rogue.exp ~= heal_exp then
		heal_exp = g.rogue.exp
		heal_n = (heal_exp < 1 or heal_exp > 11) and 2 or na[heal_exp]
	end
	heal_c = heal_c + 1
	if heal_c >= heal_n then
		heal_c = 0
		g.rogue.hp_current = g.rogue.hp_current + 1
		heal_alt = not heal_alt
		if heal_alt then
			g.rogue.hp_current = g.rogue.hp_current + 1
		end
		g.rogue.hp_current = g.rogue.hp_current + g.regeneration
		if g.rogue.hp_current > g.rogue.hp_max then
			g.rogue.hp_current = g.rogue.hp_max
		end
		g.print_stats()
	end
end

function g.reg_move()
	local fainted = false

	if (g.rogue.moves_left <= g.HUNGRY) or (g.cur_level >= g.max_level) then
		fainted = check_hunger(false)
	else
		fainted = false
	end

	g.mv_mons()

	g.m_moves = g.m_moves + 1
	if g.m_moves >= 120 then
		g.m_moves = 0
		g.wanderer()
	end
	if g.halluc > 0 then
		g.halluc = g.halluc - 1
		if g.halluc == 0 then
			g.unhallucinate()
		else
			g.hallucinate()
		end
	end
	if g.blind > 0 then
		g.blind = g.blind - 1
		if g.blind == 0 then
			g.unblind()
		end
	end
	if g.confused > 0 then
		g.confused = g.confused - 1
		if g.confused == 0 then
			g.unconfuse()
		end
	end
	if g.bear_trap > 0 then
		g.bear_trap = g.bear_trap - 1
	end
	if g.levitate > 0 then
		g.levitate = g.levitate - 1
		if g.levitate == 0 then
			g.message(g.mesg[78], true)
			if g.dungeon[g.rogue.row][g.rogue.col][g.TRAP] then
				g.trap_player(g.rogue.row, g.rogue.col)
			end
		end
	end
	if g.haste_self > 0 then
		g.haste_self = g.haste_self - 1
		if g.haste_self == 0 then
			g.message(g.mesg[79])
		end
	end
	heal()
	if g.auto_search > 0 then
		g.search(g.auto_search, g.auto_search)
	end
	return fainted
end

function g.rest(count)
	g.interrupted = false

	for i = 1, count do
		if g.interrupted then
			break
		end
		g.reg_move()
	end
end
