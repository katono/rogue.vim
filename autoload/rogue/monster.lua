local g = Rogue -- alias

g.level_monsters = {}
g.mon_disappeared = false
g.m_names = {}
g.mon_tab = {}

local Monster = {}
function Monster.new(m_damage, hp_to_kill, m_char, kill_exp,
		first_level, last_level, m_hit_chance, stationary_damage, drop_percent, m_name)
	local mon = g.ObjBase.new()
	mon.m_flags           = {}                -- monster flags
	mon.m_damage          = m_damage          -- damage it does
	mon.hp_to_kill        = hp_to_kill        -- hit points to kill
	mon.m_char            = m_char            -- 'A' is for aquatar
	mon.kill_exp          = kill_exp          -- exp for killing it
	mon.first_level       = first_level       -- level starts
	mon.last_level        = last_level        -- level ends
	mon.m_hit_chance      = m_hit_chance      -- chance of hitting you
	mon.stationary_damage = stationary_damage -- 'F' damage, 1,2,3...
	mon.drop_percent      = drop_percent      -- item carry/drop %
	mon.trail_char        = 0 -- room char when g.detect_monster
	mon.slowed_toggle     = false -- monster slowed toggle
	mon.moves_confused    = 0 -- how many moves is g.confused
	mon.disguise          = 0 -- imitator's charactor (?!%:
	mon.nap_length        = 0 -- sleep from wand of sleep
	mon.m_name            = m_name -- monster name
	return mon
end

function g.init_monster()
	g.m_names = { [0] =
		g.mesg[307], g.mesg[308], g.mesg[309], g.mesg[310], g.mesg[311], g.mesg[312],
		g.mesg[313], g.mesg[314], g.mesg[315], g.mesg[316], g.mesg[317], g.mesg[318],
		g.mesg[319], g.mesg[320], g.mesg[321], g.mesg[322], g.mesg[323], g.mesg[324],
		g.mesg[325], g.mesg[326], g.mesg[327], g.mesg[328], g.mesg[329], g.mesg[330],
		g.mesg[331], g.mesg[332]
	}
	g.mon_tab[ 0] = Monster.new("0d0"      , 25  , 'A' , 20   , 9  , 18  , 100 , 0 , 0   , g.m_names[ 0])
	g.mon_tab[ 1] = Monster.new("1d3"      , 10  , 'B' , 2    , 1  , 8   , 60  , 0 , 0   , g.m_names[ 1])
	g.mon_tab[ 2] = Monster.new("3d3/2d5"  , 32  , 'C' , 15   , 7  , 16  , 85  , 0 , 10  , g.m_names[ 2])
	g.mon_tab[ 3] = Monster.new("4d6/4d9"  , 145 , 'D' , 5000 , 21 , 126 , 100 , 0 , 90  , g.m_names[ 3])
	g.mon_tab[ 4] = Monster.new("1d3"      , 11  , 'E' , 2    , 1  , 7   , 65  , 0 , 0   , g.m_names[ 4])
	g.mon_tab[ 5] = Monster.new("5d5"      , 73  , 'F' , 91   , 12 , 126 , 80  , 0 , 0   , g.m_names[ 5])
	g.mon_tab[ 6] = Monster.new("5d5/5d5"  , 115 , 'G' , 2000 , 20 , 126 , 85  , 0 , 10  , g.m_names[ 6])
	g.mon_tab[ 7] = Monster.new("1d3/1d2"  , 15  , 'H' , 3    , 1  , 10  , 67  , 0 , 0   , g.m_names[ 7])
	g.mon_tab[ 8] = Monster.new("0d0"      , 15  , 'I' , 5    , 2  , 11  , 68  , 0 , 0   , g.m_names[ 8])
	g.mon_tab[ 9] = Monster.new("3d10/4d5" , 132 , 'J' , 3000 , 21 , 126 , 100 , 0 , 0   , g.m_names[ 9])
	g.mon_tab[10] = Monster.new("1d4"      , 10  , 'K' , 2    , 1  , 6   , 60  , 0 , 0   , g.m_names[10])
	g.mon_tab[11] = Monster.new("0d0"      , 25  , 'L' , 21   , 6  , 16  , 75  , 0 , 0   , g.m_names[11])
	g.mon_tab[12] = Monster.new("4d4/3d7"  , 97  , 'M' , 250  , 18 , 126 , 85  , 0 , 25  , g.m_names[12])
	g.mon_tab[13] = Monster.new("0d0"      , 25  , 'N' , 39   , 10 , 19  , 75  , 0 , 100 , g.m_names[13])
	g.mon_tab[14] = Monster.new("1d6"      , 25  , 'O' , 5    , 4  , 13  , 70  , 0 , 10  , g.m_names[14])
	g.mon_tab[15] = Monster.new("5d4"      , 76  , 'P' , 120  , 15 , 24  , 80  , 0 , 50  , g.m_names[15])
	g.mon_tab[16] = Monster.new("3d5"      , 30  , 'Q' , 20   , 8  , 17  , 78  , 0 , 20  , g.m_names[16])
	g.mon_tab[17] = Monster.new("2d5"      , 19  , 'R' , 10   , 3  , 12  , 70  , 0 , 0   , g.m_names[17])
	g.mon_tab[18] = Monster.new("1d3"      , 8   , 'S' , 2    , 1  , 9   , 50  , 0 , 0   , g.m_names[18])
	g.mon_tab[19] = Monster.new("4d6/1d4"  , 75  , 'T' , 125  , 13 , 22  , 75  , 0 , 33  , g.m_names[19])
	g.mon_tab[20] = Monster.new("4d10"     , 90  , 'U' , 200  , 17 , 26  , 85  , 0 , 33  , g.m_names[20])
	g.mon_tab[21] = Monster.new("1d14/1d4" , 55  , 'V' , 350  , 19 , 126 , 85  , 0 , 18  , g.m_names[21])
	g.mon_tab[22] = Monster.new("2d8"      , 45  , 'W' , 55   , 14 , 23  , 75  , 0 , 0   , g.m_names[22])
	g.mon_tab[23] = Monster.new("4d6"      , 42  , 'X' , 110  , 16 , 25  , 75  , 0 , 0   , g.m_names[23])
	g.mon_tab[24] = Monster.new("3d6"      , 35  , 'Y' , 50   , 11 , 20  , 80  , 0 , 20  , g.m_names[24])
	g.mon_tab[25] = Monster.new("1d7"      , 21  , 'Z' , 8    , 5  , 14  , 69  , 0 , 0   , g.m_names[25])

	g.mon_tab[0].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.RUSTS] = g.m_flags_desc[g.RUSTS],
	}
	g.mon_tab[1].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.FLITS] = g.m_flags_desc[g.FLITS],
	}
	g.mon_tab[2].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[3].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.FLAMES] = g.m_flags_desc[g.FLAMES],
	}
	g.mon_tab[4].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
	}
	g.mon_tab[5].m_flags = {
		[g.HOLDS] = g.m_flags_desc[g.HOLDS],
		[g.STATIONARY] = g.m_flags_desc[g.STATIONARY],
	}
	g.mon_tab[6].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.FLIES] = g.m_flags_desc[g.FLIES],
	}
	g.mon_tab[7].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[8].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.FREEZES] = g.m_flags_desc[g.FREEZES],
	}
	g.mon_tab[9].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[10].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.FLIES] = g.m_flags_desc[g.FLIES],
	}
	g.mon_tab[11].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.STEALS_GOLD] = g.m_flags_desc[g.STEALS_GOLD],
	}
	g.mon_tab[12].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.CONFUSES] = g.m_flags_desc[g.CONFUSES],
	}
	g.mon_tab[13].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.STEALS_ITEM] = g.m_flags_desc[g.STEALS_ITEM],
	}
	g.mon_tab[14].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.SEEKS_GOLD] = g.m_flags_desc[g.SEEKS_GOLD],
	}
	g.mon_tab[15].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.INVISIBLE] = g.m_flags_desc[g.INVISIBLE],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.FLITS] = g.m_flags_desc[g.FLITS],
	}
	g.mon_tab[16].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[17].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.STINGS] = g.m_flags_desc[g.STINGS],
	}
	g.mon_tab[18].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[19].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[20].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[21].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.DRAINS_LIFE] = g.m_flags_desc[g.DRAINS_LIFE],
	}
	g.mon_tab[22].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
		[g.DROPS_LEVEL] = g.m_flags_desc[g.DROPS_LEVEL],
	}
	g.mon_tab[23].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.IMITATES] = g.m_flags_desc[g.IMITATES],
	}
	g.mon_tab[24].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
	g.mon_tab[25].m_flags = {
		[g.ASLEEP] = g.m_flags_desc[g.ASLEEP],
		[g.WAKENS] = g.m_flags_desc[g.WAKENS],
		[g.WANDERS] = g.m_flags_desc[g.WANDERS],
	}
end

local function aim_monster(monster)
	local rn = g.get_room_number(monster.row, monster.col)
	if rn == g.NO_ROOM then
		-- fixed original bug: access rooms[-1]
		return
	end
	local r = g.get_rand(0, 12)

	for i = 0, 3 do
		local d = (r + i) % 4
		if g.rooms[rn].doors[d].oth_room ~= g.NO_ROOM then
			monster.trow = g.rooms[rn].doors[d].door_row
			monster.tcol = g.rooms[rn].doors[d].door_col
			break
		end
	end
end

local function put_m_at(row, col, monster)
	monster.row = row
	monster.col = col
	g.dungeon[row][col][g.MONSTER] = g.dungeon_desc[g.MONSTER]
	monster.trail_char = g.mvinch(row, col)
	g.add_to_pack(monster, g.level_monsters, false)
	aim_monster(monster)
end

function g.put_mons()
	local n = g.get_rand(4, 6)
	for i = 1, n do
		local monster = g.gr_monster(nil, 0)
		if monster.m_flags[g.WANDERS] and g.coin_toss() then
			g.wake_up(monster)
		end
		local row, col = g.gr_row_col({[g.FLOOR]=true, [g.TUNNEL]=true, [g.STAIRS]=true, [g.OBJECT]=true})
		put_m_at(row, col, monster)
	end
end

function g.gr_monster(monster, mn)
	if not monster then
		monster = {}
		while true do
			mn = g.get_rand(0, g.MONSTERS-1)
			if (g.cur_level >= g.mon_tab[mn].first_level) and
				(g.cur_level <= g.mon_tab[mn].last_level) then
				break
			end
		end
	end
	g.copy_object(monster, g.mon_tab[mn])
	if monster.m_flags[g.IMITATES] then
		monster.disguise = g.gr_obj_char()
	end
	if g.cur_level > (g.AMULET_LEVEL + 2) then
		monster.m_flags[g.HASTED] = g.m_flags_desc[g.HASTED]
	end
	monster.trow = g.NO_ROOM
	return monster
end

local function mtry(monster, row, col)
	if g.mon_can_go(monster, row, col) then
		g.move_mon_to(monster, row, col)
		return true
	end
	return false
end

local function move_confused(monster)
	if not monster.m_flags[g.ASLEEP] then
		monster.moves_confused = monster.moves_confused - 1
		if monster.moves_confused <= 0 then
			monster.m_flags[g.CONFUSED] = nil
		end
		if monster.m_flags[g.STATIONARY] then
			return g.coin_toss()
		elseif g.rand_percent(15) then
			return true
		end
		local row = monster.row
		local col = monster.col

		for i = 0, 8 do
			row, col = g.rand_around(i, row, col)
			if row == g.rogue.row and col == g.rogue.col then
				return false
			end
			if mtry(monster, row, col) then
				return true
			end
		end
	end
	return false
end

function g.mv_mons()
	if (g.haste_self % 2) ~= 0 then
		return
	end
	local monster = g.level_monsters.next_object
	while monster do
		local goto_NM_flag = false
		local next_monster = monster.next_object
		if monster.m_flags[g.HASTED] then
			g.mon_disappeared = false
			g.mv_monster(monster, g.rogue.row, g.rogue.col)
			if g.mon_disappeared then
				-- goto NM
				goto_NM_flag = true
			end
		elseif monster.m_flags[g.SLOWED] then
			monster.slowed_toggle = not monster.slowed_toggle
			if monster.slowed_toggle then
				-- goto NM
				goto_NM_flag = true
			end
		end
		if not goto_NM_flag and monster.m_flags[g.CONFUSED] and move_confused(monster) then
			-- goto NM
			goto_NM_flag = true
		end
		if not goto_NM_flag then
			local flew = false
			if monster.m_flags[g.FLIES] and not monster.m_flags[g.NAPPING]
				and not g.mon_can_go(monster, g.rogue.row, g.rogue.col) then
				flew = true
				g.mv_monster(monster, g.rogue.row, g.rogue.col)
			end
			if not (flew and g.mon_can_go(monster, g.rogue.row, g.rogue.col)) then
				g.mv_monster(monster, g.rogue.row, g.rogue.col)
			end
		end
		-- ::NM::
		monster = next_monster
	end
end

local function no_room_for_monster(rn)
	for i = g.rooms[rn].top_row+1, g.rooms[rn].bottom_row-1 do
		for j = g.rooms[rn].left_col+1, g.rooms[rn].right_col-1 do
			if not g.dungeon[i][j][g.MONSTER] then
				return false
			end
		end
	end
	return true
end

function g.party_monsters(rn, n)
	n = n + n
	for i = 0, g.MONSTERS-1 do
		g.mon_tab[i].first_level = g.mon_tab[i].first_level - (g.cur_level % 3)
	end
	for i = 0, n-1 do
		if no_room_for_monster(rn) then
			break
		end
		local row, col
		local found = false
		for j = 0, 249 do
			row = g.get_rand(g.rooms[rn].top_row+1, g.rooms[rn].bottom_row-1)
			col = g.get_rand(g.rooms[rn].left_col+1, g.rooms[rn].right_col-1)
			if not g.dungeon[row][col][g.MONSTER] and
				(g.dungeon[row][col][g.FLOOR] or
				 g.dungeon[row][col][g.TUNNEL])then
				found = true
				break
			end
		end
		if found then
			local monster = g.gr_monster(nil, 0)
			if not monster.m_flags[g.IMITATES] then
				monster.m_flags[g.WAKENS] = g.m_flags_desc[g.WAKENS]
			end
			put_m_at(row, col, monster)
		end
	end
	for i = 0, g.MONSTERS-1 do
		g.mon_tab[i].first_level = g.mon_tab[i].first_level + (g.cur_level % 3)
	end
end

function g.gmc_row_col(row, col)
	local monster = g.object_at(g.level_monsters, row, col)
	if monster then
		return g.gmc(monster)
	end
	return '&' -- BUG if this ever happens
end

function g.gmc(monster)
	if (not (g.detect_monster or g.see_invisible or g.r_see_invisible) and
			monster.m_flags[g.INVISIBLE]) or g.blind > 0 then
		return monster.trail_char
	end
	if monster.m_flags[g.IMITATES] then
		return monster.disguise
	end
	return monster.m_char
end

local function flit(monster)
	if not g.rand_percent(g.FLIT_PERCENT) then
		return false
	end
	if g.rand_percent(10) then
		return false
	end
	local row = monster.row
	local col = monster.col

	for i = 0, 8 do
		row, col = g.rand_around(i, row, col)
		if row == g.rogue.row and col == g.rogue.col then
			-- continue
		else
			if mtry(monster, row, col) then
				return true
			end
		end
	end
	return true
end

function g.mv_monster(monster, row, col)
	if monster.m_flags[g.ASLEEP] then
		if monster.m_flags[g.NAPPING] then
			monster.nap_length = monster.nap_length - 1
			if monster.nap_length <= 0 then
				monster.m_flags[g.NAPPING] = nil
				monster.m_flags[g.ASLEEP] = nil
			end
			return
		end
		if monster.m_flags[g.WAKENS] and
			 g.rogue_is_around(monster.row, monster.col) and
			 g.rand_percent(((g.stealthy > 0) and
			 	g.int_div(g.WAKE_PERCENT, (g.STEALTH_FACTOR + g.stealthy)) or
				g.WAKE_PERCENT)) then
			g.wake_up(monster)
		end
		return
	elseif monster.m_flags[g.ALREADY_MOVED] then
		monster.m_flags[g.ALREADY_MOVED] = nil
		return
	end
	if monster.m_flags[g.FLITS] and flit(monster) then
		return
	end
	if monster.m_flags[g.STATIONARY] and
		not g.mon_can_go(monster, g.rogue.row, g.rogue.col) then
		return
	end
	if monster.m_flags[g.FREEZING_ROGUE] then
		return
	end
	if monster.m_flags[g.CONFUSES] and g.m_confuse(monster) then
		return
	end
	if g.mon_can_go(monster, g.rogue.row, g.rogue.col) then
		g.mon_hit(monster, nil, false)
		return
	end
	if monster.m_flags[g.FLAMES] and g.flame_broil(monster) then
		return
	end
	if monster.m_flags[g.SEEKS_GOLD] and g.seek_gold(monster) then
		return
	end
	if (monster.trow == monster.row) and (monster.tcol == monster.col) then
		monster.trow = g.NO_ROOM
	elseif monster.trow ~= g.NO_ROOM then
		row = monster.trow
		col = monster.tcol
	end
	if monster.row > row then
		row = monster.row - 1
	elseif monster.row < row then
		row = monster.row + 1
	end
	if g.dungeon[row][monster.col][g.DOOR] and
		mtry(monster, row, monster.col) then
		return
	end
	if monster.col > col then
		col = monster.col - 1
	elseif monster.col < col then
		col = monster.col + 1
	end
	if g.dungeon[monster.row][col][g.DOOR] and
		mtry(monster, monster.row, col) then
		return
	end
	if mtry(monster, row, col) then
		return
	end

	local tried = {}
	for i = 0, 5 do
		local n
		repeat
			n = g.get_rand(0, 5)
		until not tried[n]
		if n == 0 then
			if mtry(monster, row, monster.col - 1) then
				break
			end
		elseif n == 1 then
			if mtry(monster, row, monster.col) then
				break
			end
		elseif n == 2 then
			if mtry(monster, row, monster.col + 1) then
				break
			end
		elseif n == 3 then
			if mtry(monster, monster.row - 1, col) then
				break
			end
		elseif n == 4 then
			if mtry(monster, monster.row, col) then
				break
			end
		elseif n == 5 then
			if mtry(monster, monster.row + 1, col) then
				break
			end
		end
		tried[n] = true
	end

	if monster.row == monster.o_row and
		monster.col == monster.o_col then
		monster.o = monster.o + 1
		if monster.o > 4 then
			if monster.trow == g.NO_ROOM and
				not g.mon_sees(monster, g.rogue.row, g.rogue.col) then
				monster.trow = g.get_rand(1, (g.DROWS - 2))
				monster.tcol = g.get_rand(0, (g.DCOLS - 1))
			else
				monster.trow = g.NO_ROOM
				monster.o = 0
			end
		end
	else
		monster.o_row = monster.row
		monster.o_col = monster.col
		monster.o = 0
	end
end

function g.move_mon_to(monster, row, col)
	local mrow = monster.row
	local mcol = monster.col

	g.dungeon[mrow][mcol][g.MONSTER] = nil
	g.dungeon[row][col][g.MONSTER] = g.dungeon_desc[g.MONSTER]

	local c = g.mvinch(mrow, mcol)
	if c:find('^[A-Z]$') then
		if not g.detect_monster then
			g.mvaddch(mrow, mcol, monster.trail_char)
		else
			if g.rogue_can_see(mrow, mcol) then
				g.mvaddch(mrow, mcol, monster.trail_char)
			else
				if monster.trail_char == '.' then
					monster.trail_char = ' '
				end
				g.mvaddch(mrow, mcol, monster.trail_char)
			end
		end
	end
	monster.trail_char = g.mvinch(row, col)
	if g.blind == 0 and (g.detect_monster or g.rogue_can_see(row, col)) then
		if not monster.m_flags[g.INVISIBLE] or
			(g.detect_monster or g.see_invisible or g.r_see_invisible) then
			g.mvaddch(row, col, g.gmc(monster))
		end
	end
	if g.dungeon[row][col][g.DOOR] and
		g.get_room_number(row, col) ~= g.cur_room and
		g.dungeon_equals(g.dungeon[mrow][mcol], g.FLOOR) and g.blind == 0 then
		g.mvaddch(mrow, mcol, ' ')
	end
	if g.dungeon[row][col][g.DOOR] then
		g.dr_course(monster, g.dungeon[mrow][mcol][g.TUNNEL] and true or false,
			row, col)
	else
		monster.row = row
		monster.col = col
	end
end

function g.mon_can_go(monster, row, col)
	local dr = monster.row - row
	local dc = monster.col - col
	if dr >= 2 or dr <= -2 or dc >= 2 or dc <= -2 then
		return false
	end
	if g.table_is_empty(g.dungeon[monster.row][col]) or
		g.table_is_empty(g.dungeon[row][monster.col]) or
		not g.is_passable(row, col) or
		g.dungeon[row][col][g.MONSTER] then
		return false
	end
	if monster.row ~= row and monster.col ~= col and
		(g.dungeon[row][col][g.DOOR] or
		 g.dungeon[monster.row][monster.col][g.DOOR]) then
		return false
	end
	if not (monster.m_flags[g.FLITS] or
		monster.m_flags[g.CONFUSED] or
		monster.m_flags[g.CAN_FLIT]) and
		monster.trow == g.NO_ROOM then
		if (monster.row < g.rogue.row and row < monster.row) or
		   (monster.row > g.rogue.row and row > monster.row) or
		   (monster.col < g.rogue.col and col < monster.col) or
		   (monster.col > g.rogue.col and col > monster.col) then
			return false
		end
	end
	if g.dungeon[row][col][g.OBJECT] then
		local obj = g.object_at(g.level_objects, row, col)
		if obj.what_is == g.SCROL and obj.which_kind == g.SCARE_MONSTER then
			return false
		end
	end
	return true
end

function g.wake_up(monster)
	if not monster.m_flags[g.NAPPING] then
		monster.m_flags[g.ASLEEP] = nil
		monster.m_flags[g.IMITATES] = nil
		monster.m_flags[g.WAKENS] = nil
	end
end

function g.wake_room(rn, entering, row, col)
	local wake_percent = (rn == g.party_room) and g.PARTY_WAKE_PERCENT or g.WAKE_PERCENT
	if g.stealthy > 0 then
		wake_percent = g.int_div(wake_percent, (g.STEALTH_FACTOR + g.stealthy))
	end

	local monster = g.level_monsters.next_object

	while monster do
		local in_room = (rn == g.get_room_number(monster.row, monster.col))
		if in_room then
			if entering then
				monster.trow = g.NO_ROOM
			else
				monster.trow = row
				monster.tcol = col
			end
		end
		if monster.m_flags[g.WAKENS] and 
				(rn == g.get_room_number(monster.row, monster.col)) then
			if g.rand_percent(wake_percent) then
				g.wake_up(monster)
			end
		end
		monster = monster.next_object
	end
end

function g.mon_name(monster)
	if g.blind > 0 or
			(monster.m_flags[g.INVISIBLE] and
			not (g.detect_monster or g.see_invisible or g.r_see_invisible)) then
		return g.mesg[63]
	end
	if g.halluc > 0 then
		return g.m_names[g.get_rand(0, 25)]
	end
	return monster.m_name
end

function g.rogue_is_around(row, col)
	local rdif = row - g.rogue.row
	local cdif = col - g.rogue.col

	return ((rdif >= -1) and (rdif <= 1) and (cdif >= -1) and (cdif <= 1))
end

function g.wanderer()
	local monster
	local found = false
	for i = 0, 14 do
		monster = g.gr_monster(nil, 0)
		if not (monster.m_flags[g.WAKENS] or monster.m_flags[g.WANDERS]) then
			g.free_object(monster)
		else
			found = true
			break
		end
	end
	if found then
		found = false
		g.wake_up(monster)
		for i = 0, 24 do
			local row, col = g.gr_row_col({[g.FLOOR]=true, [g.TUNNEL]=true, [g.STAIRS]=true, [g.OBJECT]=true})
			if not g.rogue_can_see(row, col) then
				put_m_at(row, col, monster)
				found = true
				break
			end
		end
		if not found then
			g.free_object(monster)
		end
	end
end

function g.show_monsters()
	g.detect_monster = true

	if g.blind > 0 then
		return
	end
	local monster = g.level_monsters.next_object
	while monster do
		g.mvaddch(monster.row, monster.col, monster.m_char)
		if monster.m_flags[g.IMITATES] then
			monster.m_flags[g.IMITATES] = nil
			monster.m_flags[g.WAKENS] = g.m_flags_desc[g.WAKENS]
		end
		monster = monster.next_object
	end
end

function g.create_monster()
	local row, col
	local found = false
	local r = g.rogue.row
	local c = g.rogue.col

	for i = 0, 8 do
		r, c = g.rand_around(i, r, c)
		row = r
		col = c
		if (row == g.rogue.row and col == g.rogue.col) or
				(row < g.MIN_ROW) or (row > (g.DROWS-2)) or
				(col < 0) or (col > (g.DCOLS-1)) then
			-- continue
		else
			if not g.dungeon[row][col][g.MONSTER] and
					(g.dungeon[row][col][g.FLOOR] or g.dungeon[row][col][g.TUNNEL] or
					 g.dungeon[row][col][g.STAIRS] or g.dungeon[row][col][g.DOOR]) then
				found = true
				break
			end
		end
	end
	if found then
		local monster = g.gr_monster(nil, 0)
		put_m_at(row, col, monster)
		g.mvaddch(row, col, g.gmc(monster))
		if monster.m_flags[g.WANDERS] or monster.m_flags[g.WAKENS] then
			g.wake_up(monster)
		end
	else
		g.message(g.mesg[64])
	end
end

function g.rogue_can_see(row, col)
	return (g.blind == 0 and
			((g.get_room_number(row, col) == g.cur_room and
			g.rooms[g.cur_room].is_room ~= g.R_MAZE) or
			g.rogue_is_around(row, col)))
end

function g.gr_obj_char()
	local rs = {'%', '!', '?', ']', '=', '/', ')', ':', '*'}
	local r = g.get_rand(1, 9)
	return rs[r]
end

function g.aggravate()
	g.message(g.mesg[65])
	local monster = g.level_monsters.next_object

	while monster do
		g.wake_up(monster)
		monster.m_flags[g.IMITATES] = nil
		if g.rogue_can_see(monster.row, monster.col) then
			g.mvaddch(monster.row, monster.col, monster.m_char)
		end
		monster = monster.next_object
	end
end

function g.mon_sees(monster, row, col)
	local rn = g.get_room_number(row, col)
	if rn ~= g.NO_ROOM and
		rn == g.get_room_number(monster.row, monster.col) and
		g.rooms[rn].is_room ~= g.R_MAZE then
		return true
	end
	local rdif = row - monster.row
	local cdif = col - monster.col

	return ((rdif >= -1) and (rdif <= 1) and (cdif >= -1) and (cdif <= 1))
end

function g.mv_aquatars()
	local monster = g.level_monsters.next_object

	while monster do
		if monster.m_char == 'A' and g.mon_can_go(monster, g.rogue.row, g.rogue.col) then
			g.mv_monster(monster, g.rogue.row, g.rogue.col)
			monster.m_flags[g.ALREADY_MOVED] = g.m_flags_desc[g.ALREADY_MOVED]
		end
		monster = monster.next_object
	end
end
