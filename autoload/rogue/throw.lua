local g = Rogue -- alias

local rand_around_pos = {[0] = 8, 7, 1, 3, 4, 5, 2, 6, 0}
local rand_around_row = 0
local rand_around_col = 0

local function potion_monster(monster, kind)
	local maxhp = g.mon_tab[string.byte(monster.m_char) - string.byte('A')].hp_to_kill
	if kind == g.RESTORE_STRENGTH or
		kind == g.LEVITATION or
		kind == g.HALLUCINATION or
		kind == g.DETECT_MONSTER or
		kind == g.DETECT_OBJECTS or
		kind == g.SEE_INVISIBLE then
	elseif kind == g.EXTRA_HEALING then
		monster.hp_to_kill = monster.hp_to_kill + g.int_div(((maxhp - monster.hp_to_kill) * 2), 3)
	elseif kind == g.INCREASE_STRENGTH or
		kind == g.HEALING or
		kind == g.RAISE_LEVEL then
		monster.hp_to_kill = monster.hp_to_kill + g.int_div((maxhp - monster.hp_to_kill), 5)
	elseif kind == g.POISON then
		g.mon_damage(monster, (g.int_div(monster.hp_to_kill, 4) + 1))
	elseif kind == g.BLINDNESS then
		monster.m_flags[g.ASLEEP] = g.m_flags_desc[g.ASLEEP]
		monster.m_flags[g.WAKENS] = g.m_flags_desc[g.WAKENS]
	elseif kind == g.CONFUSION then
		monster.m_flags[g.CONFUSED] = g.m_flags_desc[g.CONFUSED]
		monster.moves_confused = monster.moves_confused + g.get_rand(12, 22)
	elseif kind == g.HASTE_SELF then
		if monster.m_flags[g.SLOWED] then
			monster.m_flags[g.SLOWED] = nil
		else
			monster.m_flags[g.HASTED] = g.m_flags_desc[g.HASTED]
		end
	end
end

local function throw_at_monster(monster, weapon)
	local hit_chance = g.get_hit_chance(weapon)
	local damage = g.get_weapon_damage(weapon)
	if weapon.which_kind == g.ARROW and 
		(g.rogue.weapon and g.rogue.weapon.which_kind == g.BOW) then
		damage = damage + g.get_weapon_damage(g.rogue.weapon)
		damage = g.int_div((damage * 2), 3)
		hit_chance = hit_chance + g.int_div(hit_chance, 3)
	elseif weapon.in_use_flags == g.BEING_WIELDED and
		(weapon.which_kind == g.DAGGER or
		 weapon.which_kind == g.SHURIKEN or
		 weapon.which_kind == g.DART) then
		damage = g.int_div((damage * 3), 2)
		hit_chance = hit_chance + g.int_div(hit_chance, 3)
	end
	local t = weapon.quantity
	weapon.quantity = 1
	g.hit_message = string.format(g.mesg[212], g.name_of(weapon))
	weapon.quantity = t

	if not g.rand_percent(hit_chance) then
		g.hit_message = g.hit_message .. g.mesg[213]
		return false
	end
	g.hit_message = g.hit_message .. g.mesg[214]
	if weapon.what_is == g.WAND and g.rand_percent(75) then
		g.zap_monster(monster, weapon.which_kind)
	elseif weapon.what_is == g.POTION then
		potion_monster(monster, weapon.which_kind)
	else
		g.mon_damage(monster, damage)
	end
	return true
end

local function get_thrown_at_monster(obj, dir, row, col)
	local orow, ocol = row, col

	local ch = g.get_mask_char(obj.what_is)
	local i = 0
	while i < 24 do
		row, col = g.get_dir_rc(dir, row, col, false)
		if g.table_is_empty(g.dungeon[row][col]) or
			((g.dungeon[row][col][g.HORWALL] or
			  g.dungeon[row][col][g.VERTWALL] or
			  g.dungeon[row][col][g.HIDDEN]) and
			not g.dungeon[row][col][g.TRAP]) then
			row, col = orow, ocol
			return nil, row, col
		end
		if i ~= 0 and g.rogue_can_see(orow, ocol) then
			g.mvaddch(orow, ocol, g.get_dungeon_char(orow, ocol))
		end
		if g.rogue_can_see(row, col) then
			if not g.dungeon[row][col][g.MONSTER] then
				g.mvaddch(row, col, ch)
			end
			g.refresh()
		end
		orow, ocol = row, col
		if g.dungeon[row][col][g.MONSTER] then
			if not g.imitating(row, col) then
				return g.object_at(g.level_monsters, row, col), row, col
			end
		end
		if g.dungeon[row][col][g.TUNNEL] then
			i = i + 2
		end

		i = i + 1
	end
	return nil, row, col
end

local function flop_weapon(weapon, row, col)
	local i = 0
	local found = false

	while i < 9 do
		if not(g.dungeon[row][col][g.OBJECT] or
			g.dungeon[row][col][g.STAIRS] or
			g.dungeon[row][col][g.HORWALL] or
			g.dungeon[row][col][g.VERTWALL] or
			g.dungeon[row][col][g.TRAP] or
			g.dungeon[row][col][g.HIDDEN]) then
			break
		end
		row, col = g.rand_around(i, row, col)
		i = i + 1
		if (row > (g.DROWS-2)) or (row < g.MIN_ROW) or
			(col > (g.DCOLS-1)) or (col < 0) or
			g.table_is_empty(g.dungeon[row][col]) or
			(g.dungeon[row][col][g.OBJECT] or
			 g.dungeon[row][col][g.STAIRS] or
			 g.dungeon[row][col][g.HORWALL] or
			 g.dungeon[row][col][g.VERTWALL] or
			 g.dungeon[row][col][g.TRAP] or
			 g.dungeon[row][col][g.HIDDEN]) then
		 else
			 found = true
			 break
		 end
	end
	if found or i == 0 then
		local new_weapon = g.alloc_object()
		g.copy_object(new_weapon, weapon)
		new_weapon.in_use_flags = g.NOT_USED
		new_weapon.quantity = 1
		new_weapon.ichar = 'L'
		g.place_at(new_weapon, row, col)
		if g.rogue_can_see(row, col) and (row ~= g.rogue.row or col ~= g.rogue.col) then
			local mon = g.dungeon[row][col][g.MONSTER]
			g.dungeon[row][col][g.MONSTER] = nil
			local dch = g.get_dungeon_char(row, col)
			if mon then
				local mch = g.mvinch(row, col)
				local monster = g.object_at(g.level_monsters, row, col)
				if monster then
					monster.trail_char = dch
				end
				if not mch:find('^[A-Z]$') then
					g.mvaddch(row, col, dch)
				end
			else
				g.mvaddch(row, col, dch)
			end
			g.dungeon[row][col][g.MONSTER] = mon
		end
	else
		local t = weapon.quantity
		weapon.quantity = 1
		local msg = string.format(g.mesg[215], g.name_of(weapon))
		weapon.quantity = t
		g.message(msg)
	end
end

function g.throw()
	local dir = g.get_direction()
	if dir == g.CANCEL then
		return
	end
	local wch = g.pack_letter(g.mesg[210], g.WEAPON)
	if wch == g.CANCEL then
		return
	end
	g.check_message()

	local weapon = g.get_letter_object(wch)
	if not weapon then
		g.message(g.mesg[211])
		return
	end
	if g.BEING_USED(weapon.in_use_flags) and weapon.is_cursed then
		g.message(g.curse_message)
		return
	end
	local row = g.rogue.row
	local col = g.rogue.col

	if weapon.in_use_flags == g.BEING_WIELDED and weapon.quantity <= 1 then
		g.unwield(g.rogue.weapon)
	elseif weapon.in_use_flags == g.BEING_WORN then
		g.mv_aquatars()
		g.unwear(g.rogue.armor)
		g.print_stats()
	elseif g.ON_EITHER_HAND(weapon.in_use_flags) then
		g.un_put_on(weapon)
	end
	local monster
	monster, row, col = get_thrown_at_monster(weapon, dir, row, col)
	g.mvaddch(g.rogue.row, g.rogue.col, g.rogue.fchar)
	g.refresh()
	if g.rogue_can_see(row, col) and (row ~= g.rogue.row or col ~= g.rogue.col) then
		g.mvaddch(row, col, g.get_dungeon_char(row, col))
	end
	if monster then
		g.wake_up(monster)
		g.check_gold_seeker(monster)

		if not throw_at_monster(monster, weapon) then
			flop_weapon(weapon, row, col)
		end
	else
		flop_weapon(weapon, row, col)
	end
	g.vanish(weapon, true, g.rogue.pack)
end

function g.rand_around(i, r, c)
	local ra = { [0] = 1,  1, -1, -1,  0,  1,  0, -1,  0 }
	local ca = { [0] = 1, -1,  1, -1,  1,  0,  0,  0, -1 }
	if i == 0 then
		rand_around_row = r
		rand_around_col = c
		local o = g.get_rand(1, 8)
		for j = 0, 4 do
			local x = g.get_rand(0, 8) % 9
			local y = (x + o) % 9
			local t = rand_around_pos[x]
			rand_around_pos[x] = rand_around_pos[y]
			rand_around_pos[y] = t
		end
	end
	local j = rand_around_pos[i] % 9
	r = rand_around_row + ra[j]
	c = rand_around_col + ca[j]
	return r, c
end
