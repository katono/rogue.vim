local g = Rogue -- alias

g.halluc = 0
g.blind = 0
g.confused = 0
g.levitate = 0
g.haste_self = 0
g.see_invisible = false
g.extra_hp = 0
g.detect_monster = false
local strange_feeling = ''

function g.init_use()
	strange_feeling = g.mesg[230]
end

-- vanish() does NOT handle a quiver of weapons with more than one
-- arrow (or whatever) in the quiver.  It will only decrement the count.
function g.vanish(obj, rm, pack)
	if obj.quantity > 1 then
		obj.quantity = obj.quantity - 1
	else
		if obj.in_use_flags == g.BEING_WIELDED then
			g.unwield(obj)
		elseif obj.in_use_flags == g.BEING_WORN then
			g.unwear(obj)
		elseif g.ON_EITHER_HAND(obj.in_use_flags) then
			g.un_put_on(obj)
		end
		g.take_from_pack(obj, pack)
		g.free_object(obj)
	end
	if rm then
		g.reg_move()
	end
end

local function potion_heal(extra)
	g.rogue.hp_current = g.rogue.hp_current + g.rogue.exp

	local ratio = g.int_div(g.rogue.hp_current * 100, g.rogue.hp_max)

	if ratio >= 100 then
		g.rogue.hp_max = g.rogue.hp_max + (extra and 2 or 1)
		g.extra_hp = g.extra_hp + (extra and 2 or 1)
		g.rogue.hp_current = g.rogue.hp_max
	elseif ratio >= 90 then
		g.rogue.hp_max = g.rogue.hp_max + (extra and 1 or 0)
		g.extra_hp = g.extra_hp + (extra and 1 or 0)
		g.rogue.hp_current = g.rogue.hp_max
	else
		if ratio < 33 then
			ratio = 33
		end
		if extra then
			ratio = ratio + ratio
		end
		local add = g.int_div((ratio * (g.rogue.hp_max - g.rogue.hp_current)), 100)
		g.rogue.hp_current = g.rogue.hp_current + add
		if g.rogue.hp_current > g.rogue.hp_max then
			g.rogue.hp_current = g.rogue.hp_max
		end
	end
	if g.blind > 0 then
		g.unblind()
	end
	if g.confused > 0 and extra then
		g.unconfuse()
	elseif g.confused > 0 then
		g.confused = g.int_div(g.confused, 2) + 1
	end
	if g.halluc > 0 and extra then
		g.unhallucinate()
	elseif g.halluc > 0 then
		g.halluc = g.int_div(g.halluc, 2) + 1
	end
end

local function idntfy()
	local ch
	local obj
	repeat
		ch = g.pack_letter(g.mesg[260], g.ALL_OBJECTS)
		if ch == g.CANCEL then
			return
		end
		obj = g.get_letter_object(ch)
		if not obj then
			g.message(g.mesg[261])
			g.message("")
			g.check_message()
		end
	until obj
	obj.identified = true
	if obj.what_is == g.SCROL or
		obj.what_is == g.POTION or
		obj.what_is == g.WEAPON or
		obj.what_is == g.ARMOR or
		obj.what_is == g.WAND or
		obj.what_is == g.RING then
		local id_table = g.get_id_table(obj)
		id_table[obj.which_kind].id_status = g.IDENTIFIED
	end
	g.message(g.get_desc(obj, true))
end

function g.eat()
	local ch = g.pack_letter(g.mesg[262], g.FOOD)
	if ch == g.CANCEL then
		return
	end
	local obj = g.get_letter_object(ch)
	if not obj then
		g.message(g.mesg[263])
		return
	end
	if obj.what_is ~= g.FOOD then
		g.message(g.mesg[264])
		return
	end
	local moves
	if obj.which_kind == g.FRUIT or g.rand_percent(60) then
		moves = g.get_rand(900, 1100)
		if obj.which_kind == g.RATION then
			if g.get_rand(1, 10) == 1 then
				g.message(g.mesg[265])
			else
				g.message(g.mesg[266])
			end
		else
			g.message(string.format(g.mesg[267], g.fruit))
		end
	else
		moves = g.get_rand(700, 900)
		g.message(g.mesg[268])
		g.add_exp(2, true)
	end
	g.rogue.moves_left = g.int_div(g.rogue.moves_left, 3)
	g.rogue.moves_left = g.rogue.moves_left + moves
	g.hunger_str = ''
	g.print_stats()

	g.vanish(obj, true, g.rogue.pack)
end

local function hold_monster()
	local mcount = 0

	for i = -2, 2 do
		for j = -2, 2 do
			local row = g.rogue.row + i
			local col = g.rogue.col + j
			if not ((row < g.MIN_ROW) or (row > (g.DROWS-2)) or (col < 0) or (col > (g.DCOLS-1))) then
				if g.dungeon[row][col][g.MONSTER] then
					local monster = g.object_at(g.level_monsters, row, col)
					monster.m_flags[g.ASLEEP] = g.m_flags_desc[g.ASLEEP]
					monster.m_flags[g.WAKENS] = nil
					mcount = mcount + 1
				end
			end
		end
	end
	if mcount == 0 then
		g.message(g.mesg[269])
	elseif mcount == 1 then
		g.message(g.mesg[270])
	else
		g.message(g.mesg[271])
	end
end

function g.tele()
	g.mvaddch(g.rogue.row, g.rogue.col, g.get_dungeon_char(g.rogue.row, g.rogue.col))

	if g.cur_room >= 0 then
		g.darken_room(g.cur_room)
	end
	g.put_player(g.get_room_number(g.rogue.row, g.rogue.col))
	g.being_held = false
	g.bear_trap = 0
end

function g.hallucinate()
	if g.blind > 0 then
		return
	end
	local obj = g.level_objects.next_object
	while obj do
		local ch = g.mvinch(obj.row, obj.col)
		if not ch:find('^[A-Z]$') and (obj.row ~= g.rogue.row or obj.col ~= g.rogue.col) then
			if not string.find(" .#+", ch, 1, true) then
				g.mvaddch(obj.row, obj.col, ch)
			end
		end
		obj = obj.next_object
	end

	local monster = g.level_monsters.next_object
	while monster do
		local ch = g.mvinch(monster.row, monster.col)
		if ch:find('^[A-Z]$') then
			g.mvaddch(monster.row, monster.col, g.mon_tab[g.get_rand(0, 25)].m_char)
		end
		monster = monster.next_object
	end
end

function g.unhallucinate()
	g.halluc = 0
	g.relight()
	g.message(g.mesg[272], true)
end

function g.unblind()
	g.blind = 0
	g.message(g.mesg[273], true)
	g.relight()
	if g.halluc > 0 then
		g.hallucinate()
	end
	if g.detect_monster then
		g.show_monsters()
	end
end

function g.relight()
	if g.cur_room == g.PASSAGE then
		g.light_passage(g.rogue.row, g.rogue.col)
	else
		g.light_up_room(g.cur_room)
	end
	g.mvaddch(g.rogue.row, g.rogue.col, g.rogue.fchar)
end

function g.take_a_nap()
	local i = g.get_rand(2, 5)
	g.msleep(1000)
	while i > 0 do
		g.mv_mons()
		i = i - 1
	end
	g.msleep(1000)
	g.message(g.you_can_move_again)
end

local function go_blind()
	if g.blind == 0 then
		g.message(g.mesg[274])
	end
	g.blind = g.blind + g.get_rand(500, 800)

	if g.detect_monster then
		local monster = g.level_monsters.next_object
		while monster do
			g.mvaddch(monster.row, monster.col, monster.trail_char)
			monster = monster.next_object
		end
	end
	if g.cur_room >= 0 then
		for i = g.rooms[g.cur_room].top_row + 1, g.rooms[g.cur_room].bottom_row - 1 do
			for j = g.rooms[g.cur_room].left_col + 1, g.rooms[g.cur_room].right_col - 1 do
				g.mvaddch(i, j, ' ')
			end
		end
	end
	g.mvaddch(g.rogue.row, g.rogue.col, g.rogue.fchar)
end

local function get_ench_color()
	if g.halluc > 0 then
		return g.id_potions[g.get_rand(0, g.POTIONS-1)].title
	end
	return g.mesg[275]
end

function g.confuse()
	g.confused = g.confused + g.get_rand(12, 22)
end

function g.unconfuse()
	g.confused = 0
	if g.halluc > 0 then
		g.message(g.mesg[276], true)
	else
		g.message(g.mesg[277], true)
	end
end

local function uncurse_all()
	local obj = g.rogue.pack.next_object

	while obj do
		obj.is_cursed = false
		obj = obj.next_object
	end
end

function g.quaff()
	local ch = g.pack_letter(g.mesg[231], g.POTION)

	if ch == g.CANCEL then
		return
	end
	local obj = g.get_letter_object(ch)
	if not obj then
		g.message(g.mesg[232])
		return
	end
	if obj.what_is ~= g.POTION then
		g.message(g.mesg[233])
		return
	end
	if obj.which_kind == g.INCREASE_STRENGTH then
		g.message(g.mesg[234])
		g.rogue.str_current = g.rogue.str_current + 1
		if g.rogue.str_current > g.rogue.str_max then
			g.rogue.str_max = g.rogue.str_current
		end
	elseif obj.which_kind == g.RESTORE_STRENGTH then
		g.rogue.str_current = g.rogue.str_max
		g.message(g.mesg[235])
	elseif obj.which_kind == g.HEALING then
		g.message(g.mesg[236])
		potion_heal(false)
	elseif obj.which_kind == g.EXTRA_HEALING then
		g.message(g.mesg[237])
		potion_heal(true)
	elseif obj.which_kind == g.POISON then
		if not g.sustain_strength then
			g.rogue.str_current = g.rogue.str_current - g.get_rand(1, 3)
			if g.rogue.str_current < 1 then
				g.rogue.str_current = 1
			end
		end
		g.message(g.mesg[238])
		if g.halluc > 0 then
			g.unhallucinate()
		end
	elseif obj.which_kind == g.RAISE_LEVEL then
		g.rogue.exp_points = g.level_points[g.rogue.exp - 1]
		g.add_exp(1, true)
	elseif obj.which_kind == g.BLINDNESS then
		go_blind()
	elseif obj.which_kind == g.HALLUCINATION then
		g.message(g.mesg[239])
		g.halluc = g.halluc + g.get_rand(500, 800)
	elseif obj.which_kind == g.DETECT_MONSTER then
		g.show_monsters()
		if not g.level_monsters.next_object then
			g.message(strange_feeling)
		end
	elseif obj.which_kind == g.DETECT_OBJECTS then
		if g.level_objects.next_object then
			if g.blind == 0 then
				g.show_objects()
			end
		else
			g.message(strange_feeling)
		end
	elseif obj.which_kind == g.CONFUSION then
		g.message((g.halluc > 0) and g.mesg[240] or g.mesg[241])
		g.confuse()
	elseif obj.which_kind == g.LEVITATION then
		g.message(g.mesg[242])
		g.levitate = g.levitate + g.get_rand(15, 30)
		g.bear_trap = 0
		g.being_held = false
	elseif obj.which_kind == g.HASTE_SELF then
		g.message(g.mesg[243])
		g.haste_self = g.haste_self + g.get_rand(11, 21)
		if (g.haste_self % 2) == 0 then
			g.haste_self = g.haste_self + 1
		end
	elseif obj.which_kind == g.SEE_INVISIBLE then
		g.message(string.format(g.mesg[244], g.fruit))
		if g.blind > 0 then
			g.unblind()
		end
		g.see_invisible = true
		g.relight()
	end
	g.print_stats()
	g.id_potions[obj.which_kind].id_status = g.IDENTIFIED
	g.vanish(obj, true, g.rogue.pack)
end

function g.read_scroll()
	local ch = g.pack_letter(g.mesg[245], g.SCROL)

	if ch == g.CANCEL then
		return
	end
	local obj = g.get_letter_object(ch)
	if not obj then
		g.message(g.mesg[246])
		return
	end
	if obj.what_is ~= g.SCROL then
		g.message(g.mesg[247])
		return
	end
	if obj.which_kind == g.SCARE_MONSTER then
		g.message(g.mesg[248])
	elseif obj.which_kind == g.HOLD_MONSTER then
		hold_monster()
	elseif obj.which_kind == g.ENCH_WEAPON then
		if g.rogue.weapon then
			if g.rogue.weapon.what_is == g.WEAPON then
				local msg
				if not g.English then
					msg = string.format(g.mesg[249],
						g.name_of(g.rogue.weapon),
						get_ench_color())
				else
					-- add "s" of the third person singular
					msg = string.format(g.mesg[249],
						g.name_of(g.rogue.weapon),
						((g.rogue.weapon.quantity <= 1) and "s" or ""),
						get_ench_color())
				end
				g.message(msg)
				if g.coin_toss() then
					g.rogue.weapon.hit_enchant = g.rogue.weapon.hit_enchant + 1
				else
					g.rogue.weapon.d_enchant = g.rogue.weapon.d_enchant + 1
				end
			end
			g.rogue.weapon.is_cursed = false
		else
			g.message(g.mesg[250])
		end
	elseif obj.which_kind == g.ENCH_ARMOR then
		if g.rogue.armor then
			g.message(string.format(g.mesg[251], get_ench_color()))
			g.rogue.armor.d_enchant = g.rogue.armor.d_enchant + 1
			g.rogue.armor.is_cursed = false
			g.print_stats()
		else
			g.message(g.mesg[252])
		end
	elseif obj.which_kind == g.IDENTIFY then
		g.message(g.mesg[253])
		obj.identified = true
		g.id_scrolls[obj.which_kind].id_status = g.IDENTIFIED
		idntfy()
	elseif obj.which_kind == g.TELEPORT then
		g.tele()
	elseif obj.which_kind == g.SLEEP then
		g.message(g.mesg[254])
		g.take_a_nap()
	elseif obj.which_kind == g.PROTECT_ARMOR then
		if g.rogue.armor then
			g.message(g.mesg[255])
			g.rogue.armor.is_protected = true
			g.rogue.armor.is_cursed = false
		else
			g.message(g.mesg[256])
		end
	elseif obj.which_kind == g.REMOVE_CURSE then
		g.message((g.halluc == 0) and g.mesg[257] or g.mesg[258])
		uncurse_all()
	elseif obj.which_kind == g.CREATE_MONSTER then
		g.create_monster()
	elseif obj.which_kind == g.AGGRAVATE_MONSTER then
		g.aggravate()
	elseif obj.which_kind == g.MAGIC_MAPPING then
		g.message(g.mesg[259])
		g.draw_magic_map()
	end
	g.id_scrolls[obj.which_kind].id_status = g.IDENTIFIED
	g.vanish(obj, (obj.which_kind ~= g.SLEEP), g.rogue.pack)
end
