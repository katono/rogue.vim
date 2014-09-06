local g = Rogue -- alias

g.hit_message = ''
local fight_monster = nil

local function rogue_damage(d, monster)
	if d >= g.rogue.hp_current then
		g.rogue.hp_current = 0
		g.print_stats()
		g.killed_by(monster, 0)
		-- NOTREACHED
	end
	g.rogue.hp_current = g.rogue.hp_current - d
	g.print_stats()
end

function g.mon_hit(monster, other, flame)
	local damage, hit_chance
	if fight_monster and monster ~= fight_monster then
		fight_monster = nil
	end
	monster.trow = g.NO_ROOM
	if g.cur_level >= (g.AMULET_LEVEL * 2) then
		hit_chance = 100
	else
		hit_chance = monster.m_hit_chance
		hit_chance = hit_chance - (((2 * g.rogue.exp) + (2 * g.ring_exp)) - g.r_rings)
	end
	if g.wizard then
		hit_chance = g.int_div(hit_chance, 2)
	end
	if not fight_monster then
		g.interrupted = true
	end
	local mn = g.mon_name(monster)

	if other then
		hit_chance = hit_chance - ((g.rogue.exp + g.ring_exp) - g.r_rings)
	end

	if not g.rand_percent(hit_chance) then
		if not fight_monster then
			g.hit_message = g.hit_message .. string.format(g.mesg[18], (other and other or mn))
			g.message(g.hit_message, true)
			g.hit_message = ''
		end
		return
	end
	if not fight_monster then
		if other then
			g.hit_message = g.hit_message ..
				string.format(g.mesg[19], other, g.mesg[20])
		else
			g.hit_message = g.hit_message ..
				string.format(g.mesg[19], mn, g.mesg[21])
		end
		g.message(g.hit_message, true)
		g.hit_message = ''
	end
	if not monster.m_flags[g.STATIONARY] then
		damage = g.get_damage(monster.m_damage, true)
		if other then
			if flame then
				damage = damage - g.get_armor_class(g.rogue.armor)
				if damage < 0 then
					damage = 1
				end
			end
		end
		local minus
		if g.cur_level >= (g.AMULET_LEVEL * 2) then
			minus = (g.AMULET_LEVEL * 2) - g.cur_level
		else
			minus = g.get_armor_class(g.rogue.armor) * 3
			minus = g.int_div(minus * damage, 100)
		end
		damage = damage - minus
	else
		damage = monster.stationary_damage
		monster.stationary_damage = monster.stationary_damage + 1
	end
	if g.wizard then
		damage = g.int_div(damage, 3)
	end
	if damage > 0 then
		rogue_damage(damage, monster)
	end
	if g.SPECIAL_HIT(monster.m_flags) then
		g.special_hit(monster)
	end
end

function g.rogue_hit(monster, force_hit)
	if not monster then
		return
	end
	if g.check_imitator(monster) then
		return
	end
	local hit_chance = force_hit and 100 or g.get_hit_chance(g.rogue.weapon)

	if g.wizard then
		hit_chance = hit_chance * 2
	end
	if not g.rand_percent(hit_chance) then
		if not fight_monster then
			g.hit_message = string.format(g.mesg[22], g.nick_name)
		end
		-- goto RET
		g.check_gold_seeker(monster)
		g.wake_up(monster)
		return
	end
	local damage = g.get_weapon_damage(g.rogue.weapon)
	if g.wizard then
		damage = damage * 3
	end
	if g.mon_damage(monster, damage) then -- still alive?
		if not fight_monster then
			g.hit_message = string.format(g.mesg[23], g.nick_name)
		end
	end
	-- ::RET::
	g.check_gold_seeker(monster)
	g.wake_up(monster)
end

function g.get_damage(ds, r)
	local t = g.get_number(ds)
	local total = 0
	for i, v in ipairs(t) do
		local n = v[1]
		local d = v[2]
		for j = 1, n do
			if r then
				total = total + g.get_rand(1, d)
			else
				total = total + d
			end
		end
	end
	return total
end

local function get_w_damage(obj)
	if not obj or obj.what_is ~= g.WEAPON then
		return -1
	end
	local t = g.get_number(obj.damage)
	local to_hit = t[1][1] + obj.hit_enchant
	local damage = t[1][2] + obj.d_enchant

	local new_damage = string.format("%dd%d", to_hit, damage)

	return g.get_damage(new_damage, true)
end

function g.get_number(s)
	local ret = {}
	local t = g.split(s, '/')
	for i, v in ipairs(t) do
		local t1 = g.split(v, 'd')
		local t2 = {}
		for j, x in ipairs(t1) do
			table.insert(t2, tonumber(x))
		end
		table.insert(ret, t2)
	end
	return ret
end

local function to_hit(obj)
	if not obj then
		return 1
	end
	return g.get_number(obj.damage)[1][1] + obj.hit_enchant
end

local function damage_for_strength()
	local sa = { 14, 17, 18, 20, 21, 30, 9999 }
	local ra = {  1,  3,  4,  5,  6,  7,    8 }
	local strength = g.rogue.str_current + g.add_strength
	if strength <= 6 then
		return strength - 5
	end
	for i = 1, #sa do
		if strength <= sa[i] then
			return ra[i]
		end
	end
	return ra[#ra]
end

function g.mon_damage(monster, damage)
	monster.hp_to_kill = monster.hp_to_kill - damage
	if monster.hp_to_kill > 0 then
		return true
	end
	local row = monster.row
	local col = monster.col
	g.dungeon[row][col][g.MONSTER] = nil
	g.mvaddch(row, col, g.get_dungeon_char(row, col))

	fight_monster = nil
	g.cough_up(monster)
	local mn = g.mon_name(monster)
	g.hit_message = g.hit_message .. string.format(g.mesg[24], mn)
	g.message(g.hit_message, true)
	g.hit_message = ''
	g.add_exp(monster.kill_exp, true)
	g.take_from_pack(monster, g.level_monsters)

	if monster.m_flags[g.HOLDS] then
		g.being_held = false
	end
	g.free_object(monster)
	return false
end

function g.fight(to_the_death)
	local ch = g.get_direction()
	if ch == g.CANCEL then
		return
	end
	local row = g.rogue.row
	local col = g.rogue.col
	row, col = g.get_dir_rc(ch, row, col, false)

	local c = g.mvinch(row, col)
	if not c:find('^[A-Z]$') or 
		not g.can_move(g.rogue.row, g.rogue.col, row, col) then
		g.message(g.mesg[25])
		return
	end
	fight_monster = g.object_at(g.level_monsters, row, col)
	if not fight_monster then
		return
	end
	local possible_damage
	if not fight_monster.m_flags[g.STATIONARY] then
		possible_damage = g.int_div((g.get_damage(fight_monster.m_damage, false) * 2), 3)
	else
		possible_damage = fight_monster.stationary_damage - 1
	end
	while fight_monster do
		g.one_move_rogue(ch, false)
		if (not to_the_death and (g.rogue.hp_current <= possible_damage)) or
			g.interrupted or not g.dungeon[row][col][g.MONSTER] then
			fight_monster = nil
		else
			local monster = g.object_at(g.level_monsters, row, col)
			if monster ~= fight_monster then
				fight_monster = nil
			end
		end
	end
end

function g.get_dir_rc(dir, row, col, allow_off_screen)
	if dir == 'h' then
		if allow_off_screen or (col > 0) then
			col = col - 1
		end
	elseif dir == 'j' then
		if allow_off_screen or (row < g.DROWS-2) then
			row = row + 1
		end
	elseif dir == 'k' then
		if allow_off_screen or (row > g.MIN_ROW) then
			row = row - 1
		end
	elseif dir == 'l' then
		if allow_off_screen or (col < g.DCOLS-1) then
			col = col + 1
		end
	elseif dir == 'y' then
		if allow_off_screen or (row > g.MIN_ROW and col > 0) then
			row = row - 1
			col = col - 1
		end
	elseif dir == 'u' then
		if allow_off_screen or (row > g.MIN_ROW and col < g.DCOLS-1) then
			row = row - 1
			col = col + 1
		end
	elseif dir == 'n' then
		if allow_off_screen or (row < g.DROWS-2 and col < g.DCOLS-1) then
			row = row + 1
			col = col + 1
		end
	elseif dir == 'b' then
		if allow_off_screen or (row < g.DROWS-2 and col > 0) then
			row = row + 1
			col = col - 1
		end
	end

	return row, col
end

function g.get_hit_chance(weapon)
	local hit_chance = 40 + 3 * to_hit(weapon)
	hit_chance = hit_chance + (((2 * g.rogue.exp) + (2 * g.ring_exp)) - g.r_rings)
	return hit_chance
end

function g.get_weapon_damage(weapon)
	local damage = get_w_damage(weapon) + damage_for_strength()
	damage = damage + g.int_div((((g.rogue.exp + g.ring_exp) - g.r_rings) + 1), 2)
	return damage
end
