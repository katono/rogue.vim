local g = Rogue -- alias

g.less_hp = 0
local flame_name
g.being_held = false

function g.init_spechit()
	flame_name = g.mesg[200]
end

local function freeze(monster)
	local freeze_percent = 99
	if g.rand_percent(12) then
		return
	end
	freeze_percent = freeze_percent - (g.rogue.str_current + g.int_div(g.rogue.str_current, 2))
	freeze_percent = freeze_percent - ((g.rogue.exp + g.ring_exp) * 4)
	freeze_percent = freeze_percent - (g.get_armor_class(g.rogue.armor) * 5)
	freeze_percent = freeze_percent - g.int_div(g.rogue.hp_max, 3)

	if freeze_percent > 10 then
		monster.m_flags[g.FREEZING_ROGUE] = g.m_flags_desc[g.FREEZING_ROGUE]
		g.message(g.mesg[203], true)
		local n = g.get_rand(4, 8)
		for i = 1, n do
			g.mv_mons()
		end
		if g.rand_percent(freeze_percent) then
			for i = 1, 50 do
				g.mv_mons()
			end
			g.killed_by(nil, g.HYPOTHERMIA)
			-- NOTREACHED
		end
		g.message(g.you_can_move_again, true)
		monster.m_flags[g.FREEZING_ROGUE] = nil
	end
end

local function disappear(monster)
	local row = monster.row
	local col = monster.col

	g.dungeon[row][col][g.MONSTER] = nil
	if g.rogue_can_see(row, col) then
		g.mvaddch(row, col, g.get_dungeon_char(row, col))
	end
	g.take_from_pack(monster, g.level_monsters)
	g.free_object(monster)
	g.mon_disappeared = true
end

local function steal_gold(monster)
	if g.rogue.gold <= 0 or g.rand_percent(10) then
		return
	end
	local amount = g.get_rand((g.cur_level * 10), (g.cur_level * 30))
	if amount > g.rogue.gold then
		amount = g.rogue.gold
	end
	g.rogue.gold = g.rogue.gold - amount
	g.message(g.mesg[204])
	g.print_stats()
	disappear(monster)
end

local function steal_item(monster)
	if g.rand_percent(15) then
		return
	end
	local obj = g.rogue.pack.next_object
	if not obj then
		-- goto DSPR
		disappear(monster)
		return
	end
	local goto_adornment_flag = false
	while obj do
		if obj.what_is == g.RING and
			obj.which_kind == g.ADORNMENT and
			g.ON_EITHER_HAND(obj.in_use_flags) and
			not obj.is_cursed then
			g.un_put_on(obj)
			-- goto adornment
			goto_adornment_flag = true
			break
		end
		obj = obj.next_object
	end
	if not goto_adornment_flag then
		local has_something = false
		obj = g.rogue.pack.next_object
		while obj do
			if not g.BEING_USED(obj.in_use_flags) then
				has_something = true
				break
			end
			obj = obj.next_object
		end
		if not has_something then
			-- goto DSPR
			disappear(monster)
			return
		end

		local n = g.get_rand(0, g.MAX_PACK_COUNT)
		obj = g.rogue.pack.next_object
		for i = 0, n do
			obj = obj.next_object
			while not obj or g.BEING_USED(obj.in_use_flags) do
				if not obj then
					obj = g.rogue.pack.next_object
				else
					obj = obj.next_object
				end
			end
		end
	end
	-- ::adornment::
	local desc = ''
	if not g.JAPAN then
		desc = g.mesg[205]
	end
	local t = 0
	if obj.what_is ~= g.WEAPON then
		t = obj.quantity
		obj.quantity = 1
	end
	if g.JAPAN then
		desc = g.get_desc(obj, false) .. g.mesg[205]
	else
		desc = desc .. g.get_desc(obj, false)
	end
	g.message(desc)
	obj.quantity = (obj.what_is ~= g.WEAPON and t or 1)
	g.vanish(obj, false, g.rogue.pack)
	-- ::DSPR::
	disappear(monster)
end

local function sting(monster)
	if g.rogue.str_current <= 3 or g.sustain_strength then
		return
	end
	local sting_chance = 35
	sting_chance = sting_chance + (6 * (6 - g.get_armor_class(g.rogue.armor)))
	if g.rogue.exp + g.ring_exp > 8 then
		sting_chance = sting_chance - (6 * ((g.rogue.exp + g.ring_exp) - 8))
	end
	if g.rand_percent(sting_chance) then
		g.message(string.format(g.mesg[207], g.mon_name(monster)))
		g.rogue.str_current = g.rogue.str_current - 1
		g.print_stats()
	end
end

local function drop_level()
	if g.rand_percent(80) or g.rogue.exp <= 5 then
		return
	end
	g.rogue.exp_points = g.level_points[g.rogue.exp-2] - g.get_rand(9, 29)
	g.rogue.exp = g.rogue.exp - 2
	local hp = g.hp_raise()
	g.rogue.hp_current = g.rogue.hp_current - hp
	if g.rogue.hp_current <= 0 then
		g.rogue.hp_current = 1
	end
	g.rogue.hp_max = g.rogue.hp_max - hp
	if g.rogue.hp_max <= 0 then
		g.rogue.hp_max = 1
	end
	g.add_exp(1, false)
end

local function drain_life()
	if g.rand_percent(60) or g.rogue.hp_max <= 30 or g.rogue.hp_current < 10 then
		return
	end
	local n = g.get_rand(1, 3)		-- 1 Hp, 2 Str, 3 both
	if n ~= 2 or not g.sustain_strength then
		g.message(g.mesg[208])
	end
	if n ~= 2 then
		g.rogue.hp_max = g.rogue.hp_max - 1
		g.rogue.hp_current = g.rogue.hp_current - 1
		g.less_hp = g.less_hp + 1
	end
	if n ~= 1 then
		if g.rogue.str_current > 3 and not g.sustain_strength then
			g.rogue.str_current = g.rogue.str_current - 1
			if g.coin_toss() then
				g.rogue.str_max = g.rogue.str_max - 1
			end
		end
	end
	g.print_stats()
end

function g.special_hit(monster)
	if monster.m_flags[g.CONFUSED] and g.rand_percent(66) then
		return
	end
	if monster.m_flags[g.RUSTS] then
		g.rust(monster)
	end
	if monster.m_flags[g.HOLDS] and g.levitate == 0 then
		g.being_held = true
	end
	if monster.m_flags[g.FREEZES] then
		freeze(monster)
	end
	if monster.m_flags[g.STINGS] then
		sting(monster)
	end
	if monster.m_flags[g.DRAINS_LIFE] then
		drain_life()
	end
	if monster.m_flags[g.DROPS_LEVEL] then
		drop_level()
	end
	if monster.m_flags[g.STEALS_GOLD] then
		steal_gold(monster)
	elseif monster.m_flags[g.STEALS_ITEM] then
		steal_item(monster)
	end
end

function g.rust(monster)
	if not g.rogue.armor or (g.get_armor_class(g.rogue.armor) <= 1) or
		g.rogue.armor.which_kind == g.LEATHER then
		return
	end
	if g.rogue.armor.is_protected or g.maintain_armor then
		if monster and not monster.m_flags[g.RUST_VANISHED] then
			g.message(g.mesg[201])
			monster.m_flags[g.RUST_VANISHED] = g.m_flags_desc[g.RUST_VANISHED]
		end
	else
		g.rogue.armor.d_enchant = g.rogue.armor.d_enchant - 1
		g.message(g.mesg[202])
		g.print_stats()
	end
end

local function try_to_cough(row, col, obj)
	if (row < g.MIN_ROW) or (row > (g.DROWS-2)) or (col < 0) or (col>(g.DCOLS-1)) then
		return false
	end
	local d = g.dungeon[row][col]
	if not (d[g.OBJECT] or d[g.STAIRS] or d[g.TRAP]) and
			(d[g.TUNNEL] or d[g.FLOOR] or d[g.DOOR]) then
		g.place_at(obj, row, col)
		if ((row ~= g.rogue.row) or (col ~= g.rogue.col)) and
				(not d[g.MONSTER]) then
			g.mvaddch(row, col, g.get_dungeon_char(row, col))
		end
		return true
	end
	return false
end

function g.cough_up(monster)
	local obj
	if g.cur_level < g.max_level then
		return
	end
	if monster.m_flags[g.STEALS_GOLD] then
		obj = g.alloc_object()
		obj.what_is = g.GOLD
		obj.quantity = g.get_rand((g.cur_level * 15), (g.cur_level * 30))
	else
		if not g.rand_percent(monster.drop_percent) then
			return
		end
		obj = g.gr_object()
	end
	local row = monster.row
	local col = monster.col

	for n = 0, 5 do
		local i
		i = -n
		while i <= n do
			if try_to_cough(row+n, col+i, obj) then
				return
			end
			if try_to_cough(row-n, col+i, obj) then
				return
			end
			i = i + 1
		end
		i = -n
		while i <= n do
			if try_to_cough(row+i, col-n, obj) then
				return
			end
			if try_to_cough(row+i, col+n, obj) then
				return
			end
			i = i + 1
		end
	end
	g.free_object(obj)
end

local function gold_at(row, col)
	if g.dungeon[row][col][g.OBJECT] then
		local obj = g.object_at(g.level_objects, row, col)
		if obj and obj.what_is == g.GOLD then
			return true
		end
	end
	return false
end

function g.seek_gold(monster)
	local rn = g.get_room_number(monster.row, monster.col)
	if rn < 0 then
		return false
	end
	for i = g.rooms[rn].top_row+1, g.rooms[rn].bottom_row-1 do
		for j = g.rooms[rn].left_col+1, g.rooms[rn].right_col-1 do
			if gold_at(i, j) and not g.dungeon[i][j][g.MONSTER] then
				monster.m_flags[g.CAN_FLIT] = g.m_flags_desc[g.CAN_FLIT]
				local s = g.mon_can_go(monster, i, j)
				monster.m_flags[g.CAN_FLIT] = nil
				if s then
					g.move_mon_to(monster, i, j)
					monster.m_flags[g.ASLEEP] = g.m_flags_desc[g.ASLEEP]
					monster.m_flags[g.WAKENS] = nil
					monster.m_flags[g.SEEKS_GOLD] = nil
					return true
				end
				monster.m_flags[g.SEEKS_GOLD] = nil
				monster.m_flags[g.CAN_FLIT] = g.m_flags_desc[g.CAN_FLIT]
				g.mv_monster(monster, i, j)
				monster.m_flags[g.CAN_FLIT] = nil
				monster.m_flags[g.SEEKS_GOLD] = g.m_flags_desc[g.SEEKS_GOLD]
				return true
			end
		end
	end
	return false
end

function g.check_gold_seeker(monster)
	monster.m_flags[g.SEEKS_GOLD] = nil
end

function g.check_imitator(monster)
	if monster.m_flags[g.IMITATES] then
		g.wake_up(monster)
		if g.blind > 0 then
			g.mvaddch(monster.row, monster.col,
					g.get_dungeon_char(monster.row, monster.col))
			g.check_message()
			g.message(string.format(g.mesg[206], g.mon_name(monster)))
		end
		return true
	end
	return false
end

function g.imitating(row, col)
	if g.dungeon[row][col][g.MONSTER] then
		local monster = g.object_at(g.level_monsters, row, col)
		if monster then
			if monster.m_flags[g.IMITATES] then
				return true
			end
		end
	end
	return false
end

function g.m_confuse(monster)
	if not g.rogue_can_see(monster.row, monster.col) then
		return false
	end
	if g.rand_percent(45) then
		monster.m_flags[g.CONFUSES] = nil	-- will not confuse the rogue
		return false
	end
	if g.rand_percent(55) then
		monster.m_flags[g.CONFUSES] = nil
		g.message(string.format(g.mesg[209], g.mon_name(monster)))
		g.confuse()
		return true
	end
	return false
end

local function get_closer(row, col, trow, tcol)
	if row < trow then
		row = row + 1
	elseif row > trow then
		row = row - 1
	end
	if col < tcol then
		col = col + 1
	elseif col > tcol then
		col = col - 1
	end
	return row, col
end

function g.flame_broil(monster)
	if not g.mon_sees(monster, g.rogue.row, g.rogue.col) or g.coin_toss() then
		return false
	end
	local row = g.rogue.row - monster.row
	local col = g.rogue.col - monster.col
	if row < 0 then
		row = -row
	end
	if col < 0 then
		col = -col
	end
	if ((row ~= 0) and (col ~= 0) and (row ~= col)) or ((row > 7) or (col > 7)) then
		return false
	end
	if g.blind == 0 and not g.rogue_is_around(monster.row, monster.col) then
		row = monster.row
		col = monster.col
		row, col = get_closer(row, col, g.rogue.row, g.rogue.col)
		repeat
			g.mvaddch(row, col, '(R(~(R(')
			g.refresh()
			row, col = get_closer(row, col, g.rogue.row, g.rogue.col)
			g.msleep(50)
		until (row == g.rogue.row and col == g.rogue.col)
		g.msleep(50)
		row = monster.row
		col = monster.col
		row, col = get_closer(row, col, g.rogue.row, g.rogue.col)
		repeat
			g.mvaddch(row, col, g.get_dungeon_char(row, col))
			g.refresh()
			row, col = get_closer(row, col, g.rogue.row, g.rogue.col)
		until (row == g.rogue.row and col == g.rogue.col)
	end
	g.mon_hit(monster, flame_name, true)
	return true
end
