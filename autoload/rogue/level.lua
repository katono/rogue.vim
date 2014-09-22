local g = Rogue -- alias

g.cur_level = 0
g.max_level = 1
g.cur_room = 0
g.new_level_message = nil
g.party_room = 0
g.level_points = {}

local r_de = 0
local random_rooms = { [0] = 3, 7, 5, 2, 0, 6, 1, 4, 8 }

function g.init_level()
	g.cur_room = g.NO_ROOM
	g.party_room = g.NO_ROOM
	g.level_points = {
			[0] = 10,
				  20,
				  40,
				  80,
				 160,
				 320,
				 640,
				1300,
				2600,
				5200,
			   10000,
			   20000,
			   40000,
			   80000,
			  160000,
			  320000,
			 1000000,
			 3333333,
			 6666666,
			g.MAX_EXP,
			99900000
	}
end

local function make_room(rn, r1, r2, r3)
	local left_col = 0
	local right_col = 0
	local top_row = 0
	local bottom_row = 0
	local width = 0
	local height = 0
	local row_offset = 0
	local col_offset = 0
	local ch = 0
	local goto_B = false
	local goto_END = false
	if rn == g.BIG_ROOM then
		top_row = g.get_rand(g.MIN_ROW, g.MIN_ROW+5)
		bottom_row = g.get_rand(g.DROWS-7, g.DROWS-2)
		left_col = g.get_rand(0, 10)
		right_col = g.get_rand(g.DCOLS-11, g.DCOLS-2)
		rn = 0
		goto_B = true
		-- goto B
	end
	if not goto_B then
		local mod_rn = rn % 3
		if mod_rn == 0 then
			left_col = 0
			right_col = g.COL1-1
		elseif mod_rn == 1 then
			left_col = g.COL1+1
			right_col = g.COL2-1
		elseif mod_rn == 2 then
			left_col = g.COL2+1
			right_col = g.DCOLS-2
		end
		local div_rn = g.int_div(rn, 3)
		if div_rn == 0 then
			top_row = g.MIN_ROW
			bottom_row = g.ROW1-1
		elseif div_rn == 1 then
			top_row = g.ROW1+1
			bottom_row = g.ROW2-1
		elseif div_rn == 2 then
			top_row = g.ROW2+1
			bottom_row = g.DROWS - 2
		end
		height = g.get_rand(4, (bottom_row-top_row+1))
		width = g.get_rand(7, (right_col-left_col-2))

		row_offset = g.get_rand(0, ((bottom_row-top_row)-height+1))
		col_offset = g.get_rand(0, ((right_col-left_col)-width+1))

		top_row = top_row + row_offset
		bottom_row = top_row + height - 1

		left_col = left_col + col_offset
		right_col = left_col + width - 1

		if (rn ~= r1) and (rn ~= r2) and (rn ~= r3) and g.rand_percent(40) then
			goto_END = true
			-- goto END
		end
	end
	-- ::B::
	if not goto_END then
		g.rooms[rn].is_room = g.R_ROOM
		for i = top_row, bottom_row do
			for j = left_col, right_col do
				if i == top_row or i == bottom_row then
					ch = g.HORWALL
				elseif j == left_col or j == right_col then
					ch = g.VERTWALL
				else
					ch = g.FLOOR
				end
				g.dungeon[i][j] = {}
				g.dungeon[i][j][ch] = g.dungeon_desc[ch]
			end
		end
	end
	-- ::END::
	g.rooms[rn].top_row = top_row
	g.rooms[rn].bottom_row = bottom_row
	g.rooms[rn].left_col = left_col
	g.rooms[rn].right_col = right_col
end


local function same_row(room1, room2)
	return g.int_div(room1, 3) == g.int_div(room2, 3)
end

local function same_col(room1, room2)
	return (room1 % 3) == (room2 % 3)
end

local function put_door(rm, dir)
	local row = 0
	local col = 0

	local wall_width = (rm.is_room == g.R_MAZE) and 0 or 1

	if dir == g.UPWARD or dir == g.DOWN then
		row = (dir == g.UPWARD) and rm.top_row or rm.bottom_row
		repeat
			col = g.get_rand(rm.left_col+wall_width, rm.right_col-wall_width)
		until (g.dungeon[row][col][g.HORWALL] or g.dungeon[row][col][g.TUNNEL])
	elseif dir == g.RIGHT or dir == g.LEFT then
		col = (dir == g.LEFT) and rm.left_col or rm.right_col
		repeat
			row = g.get_rand(rm.top_row+wall_width, rm.bottom_row-wall_width)
		until (g.dungeon[row][col][g.VERTWALL] or g.dungeon[row][col][g.TUNNEL])
	end
	if rm.is_room == g.R_ROOM then
		g.dungeon[row][col] = {}
		g.dungeon[row][col][g.DOOR] = g.dungeon_desc[g.DOOR]
	end
	if (g.cur_level > 2) and g.rand_percent(g.HIDE_PERCENT) then
		g.dungeon[row][col][g.HIDDEN] = g.dungeon_desc[g.HIDDEN]
	end
	rm.doors[g.int_div(dir, 2)].door_row = row
	rm.doors[g.int_div(dir, 2)].door_col = col

	return row, col
end

local function hide_boxed_passage(row1, col1, row2, col2, n)
	local row = 0
	local col = 0
	local row_cut = 0
	local col_cut = 0
	local h = 0
	local w = 0

	if g.cur_level > 2 then
		if row1 > row2 then
			row1, row2 = row2, row1
		end
		if col1 > col2 then
			col1, col2 = col2, col1
		end
		h = row2 - row1
		w = col2 - col1

		if (w >= 5) or (h >= 5) then
			row_cut = (h >= 2) and 1 or 0
			col_cut = (w >= 2) and 1 or 0

			for i = 0, n-1 do
				for j = 0, 9 do
					row = g.get_rand(row1 + row_cut, row2 - row_cut)
					col = g.get_rand(col1 + col_cut, col2 - col_cut)
					if g.dungeon_equals(g.dungeon[row][col], g.TUNNEL) then
						g.dungeon[row][col][g.HIDDEN] = g.dungeon_desc[g.HIDDEN]
						break
					end
				end
			end
		end
	end
end

local function draw_simple_passage(row1, col1, row2, col2, dir)
	local middle = 0

	if dir == g.LEFT or dir == g.RIGHT then
		if col1 > col2 then
			row1, row2 = row2, row1
			col1, col2 = col2, col1
		end
		middle = g.get_rand(col1+1, col2-1)
		for i = col1+1, middle-1 do
			g.dungeon[row1][i] = {}
			g.dungeon[row1][i][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
		end
		if row1 > row2 then
			for i = row1, row2+1, -1 do
				g.dungeon[i][middle] = {}
				g.dungeon[i][middle][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
			end
		else
			for i = row1, row2-1 do
				g.dungeon[i][middle] = {}
				g.dungeon[i][middle][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
			end
		end
		for i = middle, col2-1 do
			g.dungeon[row2][i] = {}
			g.dungeon[row2][i][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
		end
	else
		if row1 > row2 then
			row1, row2 = row2, row1
			col1, col2 = col2, col1
		end
		middle = g.get_rand(row1+1, row2-1)
		for i = row1+1, middle-1 do
			g.dungeon[i][col1] = {}
			g.dungeon[i][col1][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
		end
		if col1 > col2 then
			for i = col1, col2+1, -1 do
				g.dungeon[middle][i] = {}
				g.dungeon[middle][i][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
			end
		else
			for i = col1, col2-1 do
				g.dungeon[middle][i] = {}
				g.dungeon[middle][i][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
			end
		end
		for i = middle, row2-1 do
			g.dungeon[i][col2] = {}
			g.dungeon[i][col2][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]
		end
	end
	if g.rand_percent(g.HIDE_PERCENT) then
		hide_boxed_passage(row1, col1, row2, col2, 1)
	end
end

local function connect_rooms(room1, room2)
	local row1 = 0
	local col1 = 0
	local row2 = 0
	local col2 = 0
	local dir = 0
	local rev = 0

	if (not (g.rooms[room1].is_room == g.R_ROOM or g.rooms[room1].is_room == g.R_MAZE)) or
			(not (g.rooms[room2].is_room == g.R_ROOM or g.rooms[room2].is_room == g.R_MAZE)) then
		return false
	end
	if same_row(room1, room2) then
		if g.rooms[room1].left_col > g.rooms[room2].right_col then
			dir = g.LEFT
			rev = g.RIGHT
		else
			dir = g.RIGHT
			rev = g.LEFT
		end
	elseif same_col(room1, room2) then
		if g.rooms[room1].top_row > g.rooms[room2].bottom_row then
			dir = g.UPWARD
			rev = g.DOWN
		else
			dir = g.DOWN
			rev = g.UPWARD
		end
	else
		return false
	end
	row1, col1 = put_door(g.rooms[room1], dir)
	row2, col2 = put_door(g.rooms[room2], rev)

	repeat
		draw_simple_passage(row1, col1, row2, col2, dir)
	until not g.rand_percent(4)

	local dp = g.rooms[room1].doors[g.int_div(dir, 2)]
	dp.oth_room = room2
	dp.oth_row = row2
	dp.oth_col = col2

	dp = g.rooms[room2].doors[g.int_div(((dir+4)%g.DIRS), 2)]
	dp.oth_room = room1
	dp.oth_row = row1
	dp.oth_col = col1
	return true
end

function g.clear_level()
	for i = 0, g.MAXROOMS-1 do
		g.rooms[i].is_room = g.R_NOTHING
		for j = 0, 3 do
			g.rooms[i].doors[j].oth_room = g.NO_ROOM
		end
	end
	for i = 0, g.MAX_TRAPS-1 do
		g.traps[i].trap_type = g.NO_TRAP
	end
	for i = 0, g.DROWS-1 do
		for j = 0, g.DCOLS-1 do
			g.dungeon[i][j] = {}
		end
	end
	g.detect_monster = false
	g.see_invisible = false
	g.being_held = false
	g.bear_trap = 0
	g.party_room = g.NO_ROOM
	g.rogue.row = -1
	g.rogue.col = -1
	g.clear()
end

local function make_maze(r, c, tr, br, lc, rc)
	local dirs = {}
	dirs[0] = g.UPWARD
	dirs[1] = g.DOWN
	dirs[2] = g.LEFT
	dirs[3] = g.RIGHT

	g.dungeon[r][c] = {}
	g.dungeon[r][c][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]

	if g.rand_percent(33) then
		for i = 0, 9 do
			local t1 = g.get_rand(0, 3)
			local t2 = g.get_rand(0, 3)

			dirs[t1], dirs[t2] = dirs[t2], dirs[t1]
		end
	end
	for i = 0, 3 do
		if dirs[i] == g.UPWARD then
			if ((r-1) >= tr) and
				(not g.dungeon[r-1][c][g.TUNNEL]) and
				(not g.dungeon[r-1][c-1][g.TUNNEL]) and
				(not g.dungeon[r-1][c+1][g.TUNNEL]) and
				(not g.dungeon[r-2][c][g.TUNNEL]) then
				make_maze((r-1), c, tr, br, lc, rc)
			end
		elseif dirs[i] == g.DOWN then
			if ((r+1) <= br) and
				(not g.dungeon[r+1][c][g.TUNNEL]) and
				(not g.dungeon[r+1][c-1][g.TUNNEL]) and
				(not g.dungeon[r+1][c+1][g.TUNNEL]) and
				(not g.dungeon[r+2][c][g.TUNNEL]) then
				make_maze((r+1), c, tr, br, lc, rc)
			end
		elseif dirs[i] == g.LEFT then
			if ((c-1) >= lc) and
				(c-2 >= 0) and -- fixed original bug: access dungeon[r][-1]
				(not g.dungeon[r][c-1][g.TUNNEL]) and
				(not g.dungeon[r-1][c-1][g.TUNNEL]) and
				(not g.dungeon[r+1][c-1][g.TUNNEL]) and
				(not g.dungeon[r][c-2][g.TUNNEL]) then
				make_maze(r, (c-1), tr, br, lc, rc)
			end
		elseif dirs[i] == g.RIGHT then
			if ((c+1) <= rc) and
				(not g.dungeon[r][c+1][g.TUNNEL]) and
				(not g.dungeon[r-1][c+1][g.TUNNEL]) and
				(not g.dungeon[r+1][c+1][g.TUNNEL]) and
				(not g.dungeon[r][c+2][g.TUNNEL]) then
				make_maze(r, (c+1), tr, br, lc, rc)
			end
		end
	end
end

local function add_mazes()
	if g.cur_level > 1 then
		local start = g.get_rand(0, g.MAXROOMS-1)
		local maze_percent = g.int_div((g.cur_level * 5), 4)

		if g.cur_level > 15 then
			maze_percent = maze_percent + g.cur_level
		end
		for i = 0, g.MAXROOMS-1 do
			local j = ((start + i) % g.MAXROOMS)
			if g.rooms[j].is_room == g.R_NOTHING then
				if g.rand_percent(maze_percent) then
					g.rooms[j].is_room = g.R_MAZE
					make_maze(g.get_rand(g.rooms[j].top_row+1, g.rooms[j].bottom_row-1),
						g.get_rand(g.rooms[j].left_col+1, g.rooms[j].right_col-1),
						g.rooms[j].top_row, g.rooms[j].bottom_row,
						g.rooms[j].left_col, g.rooms[j].right_col)
					hide_boxed_passage(g.rooms[j].top_row, g.rooms[j].left_col,
						g.rooms[j].bottom_row, g.rooms[j].right_col,
						g.get_rand(0, 2))
				end
			end
		end
	end
end

local function mix_random_rooms()
	for i = 0, g.MAXROOMS-1 do
		local j = g.get_rand(i, g.MAXROOMS - 1)
		random_rooms[i], random_rooms[j] = random_rooms[j], random_rooms[i]
	end
end

local function mask_room(rn, mask)
	local row = 0
	local col = 0

	for i = g.rooms[rn].top_row, g.rooms[rn].bottom_row do
		for j = g.rooms[rn].left_col, g.rooms[rn].right_col do
			if g.dungeon[i][j][mask] then
				row = i
				col = j
				return true, row, col
			end
		end
	end
	return false, row, col
end

local function recursive_deadend(rn, offsets, srow, scol)
	local de = 0
	local drow = 0
	local dcol = 0
	local tunnel_dir = 0

	g.rooms[rn].is_room = g.R_DEADEND
	g.dungeon[srow][scol] = {}
	g.dungeon[srow][scol][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]

	for i = 0, 3 do
		de = rn + offsets[i]
		if ((de < 0) or (de >= g.MAXROOMS)) or
			(not (same_row(rn, de) or same_col(rn, de))) then
			-- continue
		else
			if not (g.rooms[de].is_room == g.R_NOTHING) then
				-- continue
			else
				drow = g.int_div(g.rooms[de].top_row + g.rooms[de].bottom_row, 2)
				dcol = g.int_div(g.rooms[de].left_col + g.rooms[de].right_col, 2)
				if same_row( rn, de) then
					tunnel_dir = (g.rooms[rn].left_col < g.rooms[de].left_col) and g.RIGHT or g.LEFT
				else
					tunnel_dir = (g.rooms[rn].top_row < g.rooms[de].top_row) and g.DOWN or g.UPWARD
				end
				draw_simple_passage(srow, scol, drow, dcol, tunnel_dir)
				r_de = de
				recursive_deadend(de, offsets, drow, dcol)
			end
		end
	end
end

local function fill_it(rn, do_rec_de)
	local tunnel_dir = 0
	local door_dir = 0
	local drow = 0
	local dcol = 0
	local target_room = 0
	local rooms_found = 0
	local srow = 0
	local scol = 0
	local did_this = false
	local offsets = {}
	offsets[0] = -1
	offsets[1] = 1
	offsets[2] = 3
	offsets[3] = -3

	for i = 0, 9 do
		srow = g.get_rand(0, 3)
		scol = g.get_rand(0, 3)
		local t = offsets[srow]
		offsets[srow] = offsets[scol]
		offsets[scol] = t
	end
	for i = 0, 3 do
		target_room = rn + offsets[i]
		if (target_room < 0 or target_room >= g.MAXROOMS) or
			(not (same_row(rn, target_room) or same_col(rn, target_room))) or
			(not (g.rooms[target_room].is_room == g.R_ROOM or g.rooms[target_room].is_room == g.R_MAZE)) then
			-- continue
		else
			if same_row(rn, target_room) then
				tunnel_dir = (g.rooms[rn].left_col < g.rooms[target_room].left_col) and g.RIGHT or g.LEFT
			else
				tunnel_dir = (g.rooms[rn].top_row < g.rooms[target_room].top_row) and g.DOWN or g.UPWARD
			end
			door_dir = ((tunnel_dir + 4) % g.DIRS)
			if g.rooms[target_room].doors[g.int_div(door_dir, 2)].oth_room ~= g.NO_ROOM then
				-- continue
			else
				local mask_room_ret = false
				local tmp_srow = 0
				local tmp_scol = 0
				mask_room_ret, tmp_srow, tmp_scol = mask_room(rn, g.TUNNEL)
				if mask_room_ret then
					srow = tmp_srow
					scol = tmp_scol
				end
				if ((not do_rec_de) or did_this) or (not mask_room_ret) then
					srow = g.int_div(g.rooms[rn].top_row + g.rooms[rn].bottom_row, 2)
					scol = g.int_div(g.rooms[rn].left_col + g.rooms[rn].right_col, 2)
				end
				drow, dcol = put_door(g.rooms[target_room], door_dir)
				rooms_found = rooms_found + 1
				draw_simple_passage(srow, scol, drow, dcol, tunnel_dir)
				g.rooms[rn].is_room = g.R_DEADEND
				g.dungeon[srow][scol] = {}
				g.dungeon[srow][scol][g.TUNNEL] = g.dungeon_desc[g.TUNNEL]

				local continue_flag = false
				if (i < 3) and (not did_this) then
					did_this = true
					if g.coin_toss() then
						continue_flag = true
					end
				end
				if (rooms_found < 2) and do_rec_de then
					recursive_deadend(rn, offsets, srow, scol)
				end
				if not continue_flag then
					break
				end
			end
		end
	end
end

local function fill_out_level()
	mix_random_rooms()

	r_de = g.NO_ROOM

	for i = 0, g.MAXROOMS-1 do
		local rn = random_rooms[i]
		if g.rooms[rn].is_room == g.R_NOTHING or 
				(g.rooms[rn].is_room == g.R_CROSS and g.coin_toss()) then
			fill_it(rn, 1)
		end
	end
	if r_de ~= g.NO_ROOM then
		fill_it(r_de, 0)
	end
end

function g.make_level()
	if g.cur_level < g.LAST_DUNGEON then
		g.cur_level = g.cur_level + 1
	end
	if g.cur_level > g.max_level then
		g.max_level = g.cur_level
	end
	local must_exist1 = g.get_rand(0, 2)
	local must_exist2 = 0
	local must_exist3 = 0
	local vertical = g.coin_toss()
	if vertical then
		must_exist2 = must_exist1 + 3
		must_exist3 = must_exist2 + 3
	else
		must_exist1 = must_exist1 * 3
		must_exist2 = must_exist1 + 1
		must_exist3 = must_exist2 + 1
	end
	local big_room = ((g.cur_level == g.party_counter) and g.rand_percent(1))
	if big_room then
		make_room(g.BIG_ROOM, 0, 0, 0)
	else
		for i = 0, g.MAXROOMS-1 do
			make_room(i, must_exist1, must_exist2, must_exist3)
		end
	end
	if not big_room then
		add_mazes()

		mix_random_rooms()

		for j = 0, g.MAXROOMS-1 do
			local i = random_rooms[j]

			if i < g.MAXROOMS - 1 then
				connect_rooms(i, i + 1)
			end
			if i < g.MAXROOMS - 3 then
				connect_rooms(i, i + 3)
			end
			if i < g.MAXROOMS - 2 then
				if g.rooms[i + 1].is_room == g.R_NOTHING and 
						(i + 1 ~= 4 or vertical) then
					if connect_rooms(i, i + 2) then
						g.rooms[i + 1].is_room = g.R_CROSS
					end
				end
			end
			if i < g.MAXROOMS - 6 then
				if g.rooms[i + 3].is_room == g.R_NOTHING and 
						(i + 3 ~= 4 or vertical) then
					if connect_rooms(i, i + 6) then
						g.rooms[i + 3].is_room = g.R_CROSS
					end
				end
			end
			if g.is_all_connected() then
				break
			end
		end
		fill_out_level()
	end
	if (not g.has_amulet()) and (g.cur_level >= g.AMULET_LEVEL) then
		g.put_amulet()
	end
end

function g.put_player(nr)
	local rn = nr
	local misses = 0
	local row
	local col

	while (misses < 2) and (rn == nr) do
		row, col = g.gr_row_col({[g.FLOOR]=true, [g.TUNNEL]=true, [g.OBJECT]=true, [g.STAIRS]=true})
		rn = g.get_room_number(row, col)

		misses = misses + 1
	end
	g.rogue.row = row
	g.rogue.col = col

	if g.dungeon[g.rogue.row][g.rogue.col][g.TUNNEL] then
		g.cur_room = g.PASSAGE
	else
		g.cur_room = rn
	end
	if g.cur_room ~= g.PASSAGE then
		g.light_up_room(g.cur_room)
	else
		g.light_passage(g.rogue.row, g.rogue.col)
	end
	g.wake_room(g.get_room_number(g.rogue.row, g.rogue.col), true, g.rogue.row, g.rogue.col)

	if g.new_level_message then
		g.message(g.new_level_message)
		g.new_level_message = nil
	end
	g.mvaddch(g.rogue.row, g.rogue.col, g.rogue.fchar)
end

function g.drop_check()
	if g.wizard then
		return true
	end
	if g.dungeon[g.rogue.row][g.rogue.col][g.STAIRS] then
		if g.levitate > 0 then
			g.message(g.mesg[48])
			return false
		end
		return true
	end
	g.message(g.mesg[49])
	return false
end

function g.check_up()
	if not g.wizard then
		if not g.dungeon[g.rogue.row][g.rogue.col][g.STAIRS] then
			g.message(g.mesg[50])
			return false
		end
		if not g.has_amulet() then
			g.message(g.mesg[51])
			return false
		end
	end
	g.new_level_message = g.mesg[52]
	if g.cur_level == 1 then
		g.win()
		-- NOTREACHED
	else
		g.cur_level = g.cur_level - 2
		return true
	end
	return false
end

local function get_exp_level(e)
	local i = 0
	while i < g.MAX_EXP_LEVEL - 1 do
		if g.level_points[i] > e then
			break
		end
		i = i + 1
	end
	return i + 1
end

function g.add_exp(e, promotion)
	g.rogue.exp_points = g.rogue.exp_points + e
	if g.rogue.exp_points < g.level_points[g.rogue.exp-1] then
		g.print_stats()
		return
	end
	local new_exp = get_exp_level(g.rogue.exp_points)
	if g.rogue.exp_points > g.MAX_EXP then
		g.rogue.exp_points = g.MAX_EXP + 1
	end
	for i = g.rogue.exp + 1, new_exp do
		if g.JAPAN then
			g.message(string.format(g.mesg[53], g.znum(i)))
		else
			g.message(string.format(g.mesg[53], i))
		end
		if promotion then
			local hp = g.hp_raise()
			g.rogue.hp_current = g.rogue.hp_current + hp
			g.rogue.hp_max = g.rogue.hp_max + hp
		end
		g.rogue.exp = i
		g.print_stats()
	end
end

function g.hp_raise()
	if g.wizard then
		return 10
	else
		return g.get_rand(3, 10)
	end
end

function g.show_average_hp()
	local real_average = 0
	local effective_average = 0

	if g.rogue.exp ~= 1 then
		real_average = g.int_div(((g.rogue.hp_max - g.extra_hp - g.INIT_HP) + g.less_hp)
			* 100, (g.rogue.exp - 1))
		effective_average = g.int_div((g.rogue.hp_max - g.INIT_HP)
			* 100, (g.rogue.exp - 1))
	end
	g.message(string.format(g.mesg[54], 
		g.int_div(real_average, 100), (real_average % 100),
		g.int_div(effective_average, 100), (effective_average % 100),
		g.extra_hp, g.less_hp))
end
