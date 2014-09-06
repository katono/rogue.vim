local g = Rogue -- alias

local Trap = {}
function Trap.new()
	local tr = {}
	tr.trap_type = g.NO_TRAP
	tr.trap_row  = 0
	tr.trap_col  = 0
	return tr
end

g.traps = {}

g.trap_door = false
g.bear_trap = 0

local trap_strings = {}

local reg_search = false

function g.init_trap()
	for i = 0, g.MAX_TRAPS-1 do
		g.traps[i] = Trap.new()
	end
	trap_strings = { [0] =
		g.mesg[216], g.mesg[217], g.mesg[218], g.mesg[219], g.mesg[220], g.mesg[221],
		g.mesg[222], g.mesg[223], g.mesg[224], g.mesg[225], g.mesg[226], g.mesg[227]
	}
end

local function trap_at(row, col)
	for i = 0, g.MAX_TRAPS-1 do
		if g.traps[i].trap_type == g.NO_TRAP then
			break
		end
		if g.traps[i].trap_row == row and g.traps[i].trap_col == col then
			return g.traps[i].trap_type
		end
	end
	return g.NO_TRAP
end

function g.trap_player(row, col)
	local t = trap_at(row, col)
	if t == g.NO_TRAP then
		return
	end
	g.dungeon[row][col][g.HIDDEN] = nil
	if g.rand_percent(g.rogue.exp + g.ring_exp) then
		g.message(g.mesg[228], true)
		return
	end
	local str = trap_strings[(t*2)+1]
	if t == g.TRAP_DOOR then
		g.trap_door = true
		g.new_level_message = str
	elseif t == g.BEAR_TRAP then
		g.message(str, true)
		g.bear_trap = g.get_rand(4, 7)
	elseif t == g.TELE_TRAP then
		g.mvaddch(g.rogue.row, g.rogue.col, '^')
		g.tele()
	elseif t == g.DART_TRAP then
		g.message(str, true)
		g.rogue.hp_current = g.rogue.hp_current - g.get_damage("1d6", true)
		if g.rogue.hp_current <= 0 then
			g.rogue.hp_current = 0
		end
		if not g.sustain_strength and g.rand_percent(40) and g.rogue.str_current >= 3 then
			g.rogue.str_current = g.rogue.str_current - 1
		end
		g.print_stats()
		if g.rogue.hp_current <= 0 then
			g.killed_by(nil, g.POISON_DART)
			-- NOTREACHED
		end
	elseif t == g.SLEEPING_GAS_TRAP then
		g.message(str, true)
		g.take_a_nap()
	elseif t == g.RUST_TRAP then
		g.message(str, true)
		g.rust(nil)
	end
end

function g.add_traps()
	local n
	local tries = 0
	local row, col

	if g.cur_level <= 2 then
		n = 0
	elseif g.cur_level <= 7 then
		n = g.get_rand(0, 2)
	elseif g.cur_level <= 11 then
		n = g.get_rand(1, 2)
	elseif g.cur_level <= 16 then
		n = g.get_rand(2, 3)
	elseif g.cur_level <= 21 then
		n = g.get_rand(2, 4)
	elseif g.cur_level <= (g.AMULET_LEVEL + 2) then
		n = g.get_rand(3, 5)
	else
		n = g.get_rand(5, g.MAX_TRAPS)
	end
	for i = 0, n-1 do
		g.traps[i].trap_type = g.get_rand(0, (g.TRAPS - 1))

		if i == 0 and g.party_room ~= g.NO_ROOM then
			repeat
				row = g.get_rand((g.rooms[g.party_room].top_row+1), (g.rooms[g.party_room].bottom_row-1))
				col = g.get_rand((g.rooms[g.party_room].left_col+1), (g.rooms[g.party_room].right_col-1))
				tries = tries + 1
			until not (
				((g.dungeon[row][col][g.OBJECT] or
				  g.dungeon[row][col][g.STAIRS] or
				  g.dungeon[row][col][g.TRAP] or
				  g.dungeon[row][col][g.TUNNEL]) or
				 g.table_is_empty(g.dungeon[row][col])) and
				(tries < 15))
			if tries >= 15 then
				row, col = g.gr_row_col({[g.FLOOR]=true, [g.MONSTER]=true})
			end
		else
			row, col = g.gr_row_col({[g.FLOOR]=true, [g.MONSTER]=true})
		end
		g.traps[i].trap_row = row
		g.traps[i].trap_col = col
		g.dungeon[row][col][g.TRAP] = g.dungeon_desc[g.TRAP]
		g.dungeon[row][col][g.HIDDEN] = g.dungeon_desc[g.HIDDEN]
	end
end

function g.id_trap()
	local dir = g.get_direction()
	if dir == g.CANCEL then
		return
	end
	local row = g.rogue.row
	local col = g.rogue.col

	row, col = g.get_dir_rc(dir, row, col, false)
	if g.dungeon[row][col][g.TRAP] and not g.dungeon[row][col][g.HIDDEN] then
		local t = trap_at(row, col)
		g.message(trap_strings[t*2])
	else
		g.message(g.mesg[229])
	end
end

function g.show_traps()
	for i = 0, g.DROWS-1 do
		for j = 0, g.DCOLS-1 do
			if g.dungeon[i][j][g.TRAP] then
				g.mvaddch(i, j, '^')
			end
		end
	end
end

function g.search(n, is_auto)
	local row
	local col
	local shown = 0
	local found = 0

	for i = -1, 1 do
		for j = -1, 1 do
			row = g.rogue.row + i
			col = g.rogue.col + j
			if (row < g.MIN_ROW) or (row >= g.DROWS-1) or
				(col < 0) or (col >= g.DCOLS) then
				-- continue
			else
				if g.dungeon[row][col][g.HIDDEN] then
					found = found + 1
				end
			end
		end
	end
	for s = 0, n-1 do
		for i = -1, 1 do
			for j = -1, 1 do
				row = g.rogue.row + i
				col = g.rogue.col + j
				if (row < g.MIN_ROW) or (row >= g.DROWS-1) or
					(col < 0) or (col >= g.DCOLS) then
					-- continue
				else
					if g.dungeon[row][col][g.HIDDEN] then
						if g.rand_percent(17 + (g.rogue.exp + g.ring_exp)) then
							g.dungeon[row][col][g.HIDDEN] = nil
							if g.blind == 0 and (row ~= g.rogue.row or
								col ~= g.rogue.col) then
								g.mvaddch(row, col, g.get_dungeon_char(row, col))
							end
							shown = shown + 1
							if g.dungeon[row][col][g.TRAP] then
								local t = trap_at(row, col)
								g.message(trap_strings[t*2], true)
							end
						end
					end
					if (shown == found and found > 0) or g.interrupted then
						return
					end
				end
			end
		end
		if not is_auto then
			reg_search = not reg_search
			if reg_search then
				g.reg_move()
			end
		end
	end
end
