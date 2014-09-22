local g = Rogue -- alias

local Door = {}
function Door.new()
	local dr = {}
	dr.oth_room = g.NO_ROOM
	dr.oth_row  = 0
	dr.oth_col  = 0
	dr.door_row = 0
	dr.door_col = 0
	return dr
end

local Room = {}
function Room.new()
	local rm = {}
	rm.left_col   = 0
	rm.top_row    = 0
	rm.right_col  = 0
	rm.bottom_row = 0
	rm.doors = {}
	for i = 0, 3 do
		rm.doors[i] = Door.new()
	end
	rm.is_room = g.R_NOTHING
	rm.rooms_visited = false
	return rm
end

g.rooms = {}

function g.init_room()
	for i = 0, g.MAXROOMS-1 do
		g.rooms[i] = Room.new()
	end
end

function g.light_up_room(rn)
	if g.blind == 0 then
		for i = g.rooms[rn].top_row, g.rooms[rn].bottom_row do
			for j = g.rooms[rn].left_col, g.rooms[rn].right_col do
				if g.dungeon[i][j][g.MONSTER] then
					local monster = g.object_at(g.level_monsters, i, j)
					if monster then
						g.dungeon[monster.row][monster.col][g.MONSTER] = nil
						monster.trail_char = 
							g.get_dungeon_char(monster.row, monster.col)
						g.dungeon[monster.row][monster.col][g.MONSTER] = g.dungeon_desc[g.MONSTER]
					end
				end
				g.mvaddch(i, j, g.get_dungeon_char(i, j))
			end
		end
		g.mvaddch(g.rogue.row, g.rogue.col, g.rogue.fchar)
	end
end

function g.light_passage(row, col)
	if g.blind > 0 then
		return
	end
	local i_end = (row < (g.DROWS-2)) and 1 or 0
	local j_end = (col < (g.DCOLS-1)) and 1 or 0

	for i = ((row > g.MIN_ROW) and -1 or 0), i_end do
		for j = ((col > 0) and -1 or 0), j_end do
			if g.can_move(row, col, row+i, col+j) then
				g.mvaddch(row+i, col+j, g.get_dungeon_char(row+i, col+j))
			end
		end
	end
end

function g.darken_room(rn)
	for i = g.rooms[rn].top_row + 1, g.rooms[rn].bottom_row-1 do
		for j = g.rooms[rn].left_col + 1, g.rooms[rn].right_col-1 do
			if g.blind > 0 then
				g.mvaddch(i, j, ' ')
			else
				if not (g.dungeon[i][j][g.OBJECT] or g.dungeon[i][j][g.STAIRS]) and
					not (g.detect_monster and g.dungeon[i][j][g.MONSTER]) then
					if not g.imitating(i, j) then
						g.mvaddch(i, j, ' ')
					end
					if g.dungeon[i][j][g.TRAP] and not g.dungeon[i][j][g.HIDDEN] then
						g.mvaddch(i, j, '^')
					end
				end
			end
		end
	end
end

function g.get_dungeon_char(row, col)
	local mask = g.dungeon[row][col]

	--[[
	if g.DEBUG then
		if mask[g.HIDDEN] then
			return 'h'
		end
	end
	--]]
	if mask[g.MONSTER] then
		return g.gmc_row_col(row, col)
	end
	if mask[g.OBJECT] then
		local obj = g.object_at(g.level_objects, row, col)
		return g.get_mask_char(obj.what_is)
	end
	if mask[g.TUNNEL] or mask[g.STAIRS] or mask[g.HORWALL] or mask[g.VERTWALL] or
			mask[g.FLOOR] or mask[g.DOOR] then
		if (mask[g.TUNNEL] or mask[g.STAIRS]) and (not (mask[g.HIDDEN])) then
			return mask[g.STAIRS] and '%' or '#'
		end
		if mask[g.HORWALL] then
			return '-'
		end
		if mask[g.VERTWALL] then
			return '|'
		end
		if mask[g.FLOOR] then
			if mask[g.TRAP] then
				if not g.dungeon[row][col][g.HIDDEN] then
					return '^'
				end
			end
			return '.'
		end
		if mask[g.DOOR] then
			if mask[g.HIDDEN] then
				if ((col > 0) and g.dungeon[row][col-1][g.HORWALL]) or
					((col < g.DCOLS-1) and g.dungeon[row][col+1][g.HORWALL]) then
					return '-'
				else
					return '|'
				end
			else
				return '+'
			end
		end
	end
	return ' '
end

function g.get_mask_char(mask)
	if mask == g.SCROL then
		return '?'
	elseif mask == g.POTION then
		return '!'
	elseif mask == g.GOLD then
		return '*'
	elseif mask == g.FOOD then
		return ':'
	elseif mask == g.WAND then
		return '/'
	elseif mask == g.ARMOR then
		return ']'
	elseif mask == g.WEAPON then
		return ')'
	elseif mask == g.RING then
		return '='
	elseif mask == g.AMULET then
		return ','
	else
		return '~' -- unknown, something is wrong
	end
end

local function check_mask(t, m, reverse_flag)
	for k, v in pairs(t) do
		if reverse_flag then
			if not m[k] then
				return true
			end
		else
			if m[k] then
				return true
			end
		end
	end
	return false
end

function g.gr_row_col(mask)
	local rn
	local r
	local c

	repeat
		r = g.get_rand(g.MIN_ROW, g.DROWS-2)
		c = g.get_rand(0, g.DCOLS-1)
		rn = g.get_room_number(r, c)
	until not (
		(rn == g.NO_ROOM) or
		(not check_mask(g.dungeon[r][c], mask)) or
		(check_mask(g.dungeon[r][c], mask, true)) or
		(not (g.rooms[rn].is_room == g.R_ROOM or g.rooms[rn].is_room == g.R_MAZE)) or
		(r == g.rogue.row and c == g.rogue.col)
	)

	return r, c
end

function g.dungeon_equals(dun, t)
	local found = false
	for k, v in pairs(dun) do
		if k == t then
			found = true
		else
			return false
		end
	end
	return found
end

function g.gr_room()
	local i
	repeat
		i = g.get_rand(0, g.MAXROOMS-1)
	until (g.rooms[i].is_room == g.R_ROOM or g.rooms[i].is_room == g.R_MAZE)
	return i
end

function g.party_objects(rn)
	local nf = 0
	local N = ((g.rooms[rn].bottom_row - g.rooms[rn].top_row) - 1) *
				((g.rooms[rn].right_col - g.rooms[rn].left_col) - 1)
	local n =  g.get_rand(5, 10)
	if n > N then
		n = N - 2
	end
	for i = 0, n-1 do
		local row
		local col
		local found = false
		local j = 0
		while (not found) and (j < 250) do
			row = g.get_rand(g.rooms[rn].top_row+1, g.rooms[rn].bottom_row-1)
			col = g.get_rand(g.rooms[rn].left_col+1, g.rooms[rn].right_col-1)
			if g.dungeon_equals(g.dungeon[row][col], g.FLOOR) or
					g.dungeon_equals(g.dungeon[row][col], g.TUNNEL) then
				found = true
			end

			j = j + 1
		end
		if found then
			local obj = g.gr_object()
			g.place_at(obj, row, col)
			nf = nf + 1
		end
	end
	return nf
end

function g.get_room_number(row, col)
	for i = 0, g.MAXROOMS-1 do
		if (row >= g.rooms[i].top_row and row <= g.rooms[i].bottom_row) and
			(col >= g.rooms[i].left_col and col <= g.rooms[i].right_col) then
			return i
		end
	end
	return g.NO_ROOM
end

local function visit_rooms(rn)
	g.rooms[rn].rooms_visited = true

	for i = 0, 3 do
		local oth_rn = g.rooms[rn].doors[i].oth_room
		if (oth_rn >= 0) and (not g.rooms[oth_rn].rooms_visited) then
			visit_rooms(oth_rn)
		end
	end
end

function g.is_all_connected()
	local starting_room = 0
	
	for i = 0, g.MAXROOMS-1 do
		g.rooms[i].rooms_visited = false
		if g.rooms[i].is_room == g.R_ROOM or g.rooms[i].is_room == g.R_MAZE then
			starting_room = i
		end
	end

	visit_rooms(starting_room)

	for i = 0, g.MAXROOMS-1 do
		if (g.rooms[i].is_room == g.R_ROOM or g.rooms[i].is_room == g.R_MAZE) and
				(not g.rooms[i].rooms_visited) then
			return false
		end
	end
	return true
end

function g.draw_magic_map()
	for i = 0, g.DROWS-1 do
		for j = 0, g.DCOLS-1 do
			local s = g.dungeon[i][j]
			if s[g.HORWALL] or s[g.VERTWALL] or s[g.DOOR] or s[g.TUNNEL] or s[g.TRAP] or
					s[g.STAIRS] or s[g.MONSTER] then
				local ch = g.mvinch(i, j)
				if ch == ' ' or ch:find('^[A-Z]$') or s[g.TRAP] or s[g.HIDDEN] then
					local skip = false
					local och = ch
					g.dungeon[i][j][g.HIDDEN] = nil
					if s[g.HORWALL] then
						ch = '-'
					elseif s[g.VERTWALL] then
						ch = '|'
					elseif s[g.DOOR] then
						ch = '+'
					elseif s[g.TRAP] then
						ch = '^'
					elseif s[g.STAIRS] then
						ch = '%'
					elseif s[g.TUNNEL] then
						ch = '#'
					else
						skip = true
					end
					if not skip then
						if (not s[g.MONSTER]) or (och == ' ') then
							g.mvaddch(i, j, ch)
						end
						if s[g.MONSTER] then
							local monster = g.object_at(g.level_monsters, i, j)
							if monster then
								monster.trail_char = ch
							end
						end
					end
				end
			end
		end
	end
end

local function get_oth_room(rn, row, col)
	local d = -1
	if row == g.rooms[rn].top_row then
		d = g.int_div(g.UPWARD, 2)
	elseif row == g.rooms[rn].bottom_row then
		d = g.int_div(g.DOWN, 2)
	elseif col == g.rooms[rn].left_col then
		d = g.int_div(g.LEFT, 2)
	elseif col == g.rooms[rn].right_col then
		d = g.int_div(g.RIGHT, 2)
	end
	if d ~= -1 and g.rooms[rn].doors[d].oth_room >= 0 then
		row = g.rooms[rn].doors[d].oth_row
		col = g.rooms[rn].doors[d].oth_col
		return true, row, col
	end
	return false, row, col
end

function g.dr_course(monster, entering, row, col)
	monster.row = row
	monster.col = col

	if g.mon_sees(monster, g.rogue.row, g.rogue.col) then
		monster.trow = g.NO_ROOM
		return
	end
	local rn = g.get_room_number(row, col)

	if entering then -- entering room
		-- look for door to some other room
		local r = g.get_rand(0, g.MAXROOMS-1)
		for i = 0, g.MAXROOMS-1 do
			local rr = (r + i) % g.MAXROOMS
			if not (g.rooms[i].is_room == g.R_ROOM or g.rooms[i].is_room == g.R_MAZE) or
				(rr == rn) then
			else
				for k = 0, 3 do
					if g.rooms[rr].doors[k].oth_room == rn then
						local continue_flag = false
						monster.trow = g.rooms[rr].doors[k].oth_row
						monster.tcol = g.rooms[rr].doors[k].oth_col
						if monster.trow == row and monster.tcol == col then
							continue_flag = true
						end
						if not continue_flag then
							return
						end
					end
				end
			end
		end
		-- look for door to dead end
		for i = g.rooms[rn].top_row, g.rooms[rn].bottom_row do
			for j = g.rooms[rn].left_col, g.rooms[rn].right_col do
				if i ~= monster.row and j ~= monster.col and
					g.dungeon[i][j][g.DOOR] then
					monster.trow = i
					monster.tcol = j
					return
				end
			end
		end
		-- return monster to room that he came from
		for i = 0, g.MAXROOMS-1 do
			for j = 0, 3 do
				if g.rooms[i].doors[j].oth_room == rn then
					for k = 0, 3 do
						if g.rooms[rn].doors[k].oth_room == i then
							monster.trow = g.rooms[rn].doors[k].oth_row
							monster.tcol = g.rooms[rn].doors[k].oth_col
							return
						end
					end
				end
			end
		end
		-- no place to send monster
		monster.trow = -1
	else -- exiting room
		local ret, row, col = get_oth_room(rn, row, col)
		if not ret then
			monster.trow = g.NO_ROOM
		else
			monster.trow = row
			monster.tcol = col
		end
	end
end
