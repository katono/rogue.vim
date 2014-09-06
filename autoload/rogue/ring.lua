local g = Rogue -- alias

local left_or_right
local no_ring

g.stealthy = 0
g.r_rings = 0
g.add_strength = 0
g.e_rings = 0
g.regeneration = 0
g.ring_exp = 0
g.auto_search = 0

g.r_teleport = false
g.r_see_invisible = false
g.sustain_strength = false
g.maintain_armor = false

function g.init_ring()
	left_or_right = g.mesg[158]
	no_ring = g.mesg[159]
end

function g.put_on_ring()
	if g.r_rings == 2 then
		g.message(g.mesg[160])
		return
	end
	local ch = g.pack_letter(g.mesg[161], g.RING)
	if ch == g.CANCEL then
		return
	end
	local ring = g.get_letter_object(ch)
	if not ring then
		g.message(g.mesg[162])
		return
	end
	if ring.what_is ~= g.RING then
		g.message(g.mesg[163])
		return
	end
	if g.ON_EITHER_HAND(ring.in_use_flags) then
		g.message(g.mesg[164])
		return
	end
	if g.r_rings == 1 then
		ch = g.rogue.left_ring and 'r' or 'l'
	else
		g.message(left_or_right)
		repeat
			ch = g.rgetchar()
			if ch == 'L' then
				ch = 'l'
			elseif ch == 'R' then
				ch = 'r'
			end
		until ch == g.CANCEL or ch == 'l' or ch == 'r' or ch == 'ENTER'
	end
	if ch ~= 'l' and ch ~= 'r' then
		g.check_message()
		return
	end
	if ((ch == 'l') and g.rogue.left_ring) or ((ch == 'r') and g.rogue.right_ring) then
		g.check_message()
		g.message(g.mesg[165])
		return
	end
	g.do_put_on(ring, (ch == 'l' and true or false))
	g.ring_stats(true)
	g.check_message()
	g.message(g.get_desc(ring, true))
	g.reg_move()
end

-- Do not call ring_stats() from within do_put_on().  It will cause
-- serious problems when do_put_on() is called from read_pack() in restore().
function g.do_put_on(ring, on_left)
	if on_left then
		ring.in_use_flags = g.ON_LEFT_HAND
		g.rogue.left_ring = ring
	else
		ring.in_use_flags = g.ON_RIGHT_HAND
		g.rogue.right_ring = ring
	end
end

function g.remove_ring()
	local left = false
	local right = false

	if g.r_rings == 0 then
		g.inv_rings()
	elseif g.rogue.left_ring and not g.rogue.right_ring then
		left = true
	elseif not g.rogue.left_ring and g.rogue.right_ring then
		right = true
	else
		local ch
		g.message(left_or_right)
		repeat
			ch = g.rgetchar()
			if ch == 'L' then
				ch = 'l'
			elseif ch == 'R' then
				ch = 'r'
			end
		until ch == g.CANCEL or ch == 'l' or ch == 'r' or ch == 'ENTER'
		left = (ch == 'l')
		right = (ch == 'r')
		g.check_message()
	end
	if left or right then
		local ring
		if left and g.rogue.left_ring then
			ring = g.rogue.left_ring
		elseif right and g.rogue.right_ring then
			ring = g.rogue.right_ring
		else
			g.message(no_ring)
		end
		if ring.is_cursed then
			g.message(g.curse_message)
		else
			g.un_put_on(ring)
			local buf
			if g.JAPAN then
				buf = g.get_desc(ring, false) .. g.mesg[166]
			else
				buf = g.mesg[166] .. g.get_desc(ring, false)
			end
			g.message(buf)
			g.reg_move()
		end
	end
end

function g.un_put_on(ring)
	if ring then
		if ring.in_use_flags == g.ON_LEFT_HAND then
			ring.in_use_flags = g.NOT_USED
			g.rogue.left_ring = nil
		elseif ring.in_use_flags == g.ON_RIGHT_HAND then
			ring.in_use_flags = g.NOT_USED
			g.rogue.right_ring = nil
		end
	end
	g.ring_stats(true)
end

function g.gr_ring(ring, assign_wk)
	ring.what_is = g.RING
	if assign_wk then
		ring.which_kind = g.get_rand(0, g.RINGS - 1)
		ring.which_kind_ring = ring.which_kind
	end
	ring.class = 0

	if ring.which_kind == g.R_TELEPORT then
		ring.is_cursed = true
	elseif ring.which_kind == g.ADD_STRENGTH or ring.which_kind == g.DEXTERITY then
		repeat
			ring.class = g.get_rand(0, 4) - 2
		until ring.class ~= 0
		ring.is_cursed = (ring.class < 0)
	elseif ring.which_kind == g.ADORNMENT then
		ring.is_cursed = g.coin_toss()
	end
end

function g.inv_rings()
	if g.r_rings == 0 then
		g.message(g.mesg[167])
	else
		if g.rogue.left_ring then
			g.message(g.get_desc(g.rogue.left_ring, true))
		end
		if g.rogue.right_ring then
			g.message(g.get_desc(g.rogue.right_ring, true))
		end
	end
	--[[ DEBUG
	if g.wizard then
		g.message(string.format(
			"ste %d, r_r %d, e_r %d, r_t %d, s_s %d, a_s %d, reg %d, r_e %d, s_i %d, m_a %d, aus %d",
			g.stealthy, g.r_rings, g.e_rings, g.r_teleport and 1 or 0, g.sustain_strength and 1 or 0,
			g.add_strength, g.regeneration, g.ring_exp, g.r_see_invisible and 1 or 0,
			g.maintain_armor and 1 or 0, g.auto_search))
	end
	--]]
end

function g.ring_stats(pr)
	g.stealthy = 0
	g.r_rings = 0
	g.e_rings = 0
	g.r_teleport = false
	g.sustain_strength = false
	g.add_strength = 0
	g.regeneration = 0
	g.ring_exp = 0
	g.r_see_invisible = false
	g.maintain_armor = false
	g.auto_search = 0

	for i = 0, 1 do
		local ring
		if i == 0 then
			ring = g.rogue.left_ring
		else
			ring = g.rogue.right_ring
		end
		if ring then
			g.r_rings = g.r_rings + 1
			g.e_rings = g.e_rings + 1
			if ring.which_kind == g.STEALTH then
				g.stealthy = g.stealthy + 1
			elseif ring.which_kind == g.R_TELEPORT then
				g.r_teleport = true
			elseif ring.which_kind == g.REGENERATION then
				g.regeneration = g.regeneration + 1
			elseif ring.which_kind == g.SLOW_DIGEST then
				g.e_rings = g.e_rings - 2
			elseif ring.which_kind == g.ADD_STRENGTH then
				g.add_strength = g.add_strength + ring.class
			elseif ring.which_kind == g.SUSTAIN_STRENGTH then
				g.sustain_strength = true
			elseif ring.which_kind == g.DEXTERITY then
				g.ring_exp = g.ring_exp + ring.class
			elseif ring.which_kind == g.ADORNMENT then
			elseif ring.which_kind == g.R_SEE_INVISIBLE then
				g.r_see_invisible = true
			elseif ring.which_kind == g.MAINTAIN_ARMOR then
				g.maintain_armor = true
			elseif ring.which_kind == g.SEARCHING then
				g.auto_search = g.auto_search + 2
			end
		end
	end
	if pr then
		g.print_stats()
		g.relight()
	end
end
