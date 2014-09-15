local g = Rogue -- alias

g.curse_message = ''

function g.init_pack()
	g.curse_message = g.mesg[85]
end

local function check_duplicate(obj, pack)
	if not (obj.what_is == g.WEAPON or
			obj.what_is == g.FOOD or
			obj.what_is == g.SCROL or
			obj.what_is == g.POTION) then
		return nil
	end
	if (obj.what_is == g.FOOD) and (obj.which_kind == g.FRUIT) then
		return nil
	end
	local op = pack.next_object

	while op do
		if (op.what_is == obj.what_is) and (op.which_kind == obj.which_kind) then
			if ((obj.what_is ~= g.WEAPON) or
				((obj.what_is == g.WEAPON) and
					((obj.which_kind == g.ARROW) or
					 (obj.which_kind == g.DAGGER) or
					 (obj.which_kind == g.DART) or
					 (obj.which_kind == g.SHURIKEN)) and
					 (obj.quiver == op.quiver))) then
				op.quantity = op.quantity + obj.quantity
				return op
			end
		end
		op = op.next_object
	end
	return nil
end

local function next_avail_ichar()
	local ichars = {}
	local obj = g.rogue.pack.next_object
	while obj do
		ichars[obj.ichar] = true
		obj = obj.next_object
	end
	for s in string.gmatch("abcdefghijklmnopqrstuvwxyz", "%a") do
		if not ichars[s] then
			return s
		end
	end
	return '?'
end

function g.wait_for_ack()
	while g.rgetchar() ~= ' ' do
	end
end

local function mask_pack(pack, mask)
	if type(mask) == 'number' then
		mask = { [mask] = true }
	end
	while pack.next_object do
		pack = pack.next_object
		if mask[pack.what_is] then
			return true
		end
	end
	return false
end

local function is_pack_letter(c, mask)
	if c == '?' then
		return true, g.LIST, g.SCROL
	elseif c == '!' then
		return true, g.LIST, g.POTION
	elseif c == ':' then
		return true, g.LIST, g.FOOD
	elseif c == ')' then
		return true, g.LIST, g.WEAPON
	elseif c == ']' then
		return true, g.LIST, g.ARMOR
	elseif c == '/' then
		return true, g.LIST, g.WAND
	elseif c == '=' then
		return true, g.LIST, g.RING
	elseif c == ',' then
		return true, g.LIST, g.AMULET
	else
		return (c:match('^[a-z]$') ~= nil or c == g.CANCEL or c == g.LIST), c, mask
	end
end

function g.pack_letter(prompt, mask)
	if type(mask) == 'number' then
		mask = { [mask] = true }
	end
	local tmask = mask

	if not mask_pack(g.rogue.pack, mask) then
		g.message(g.mesg[93])
		return g.CANCEL
	end
	local ch
	while true do
		g.message(prompt)

		while true do
			ch = g.rgetchar()
			local ret
			ret, ch, mask = is_pack_letter(ch, mask)
			if not ret then
				g.sound_bell()
			else
				break
			end
		end

		if ch == g.LIST then
			g.check_message()
			g.inventory(g.rogue.pack, mask)
		else
			break
		end
		mask = tmask
	end
	g.check_message()
	return ch
end

function g.add_to_pack(obj, pack, condense)
	local op
	if condense then
		op = check_duplicate(obj, pack)
		if op then
			g.free_object(obj)
			return op
		else
			obj.ichar = next_avail_ichar()
		end
	end
	op = pack
	while op.next_object do
		if op.next_object.what_is > obj.what_is then
			local p = op.next_object
			op.next_object = obj
			obj.next_object = p
			return obj
		end
		op = op.next_object
	end
	op.next_object = obj
	obj.next_object = nil
	return obj
end

function g.take_from_pack(obj, pack)
	local p = pack
	while p.next_object ~= obj do
		p = p.next_object
	end
	p.next_object = p.next_object.next_object
end

function g.pick_up(row, col)
	local obj = g.object_at(g.level_objects, row, col)
	local status = true

	if obj.what_is == g.SCROL and obj.which_kind == g.SCARE_MONSTER and obj.picked_up then
		g.message(g.mesg[86])
		g.dungeon[row][col][g.OBJECT] = nil
		g.vanish(obj, false, g.level_objects)
		status = false
		if g.id_scrolls[g.SCARE_MONSTER].id_status == g.UNIDENTIFIED then
			g.id_scrolls[g.SCARE_MONSTER].id_status = g.IDENTIFIED
		end
		return nil, status
	end
	if obj.what_is == g.GOLD then
		g.rogue.gold = g.rogue.gold + obj.quantity
		g.dungeon[row][col][g.OBJECT] = nil
		g.take_from_pack(obj, g.level_objects)
		g.print_stats()
		return obj, status -- obj will be free_object()ed in one_move_rogue()
	end
	if g.pack_count(obj) >= g.MAX_PACK_COUNT then
		g.message(g.mesg[87], true)
		return nil, status
	end
	g.dungeon[row][col][g.OBJECT] = nil
	g.take_from_pack(obj, g.level_objects)
	obj = g.add_to_pack(obj, g.rogue.pack, true)
	obj.picked_up = true
	return obj, status
end

function g.drop()
	if g.dungeon[g.rogue.row][g.rogue.col][g.OBJECT] or
			g.dungeon[g.rogue.row][g.rogue.col][g.STAIRS] or
			g.dungeon[g.rogue.row][g.rogue.col][g.TRAP] then
		g.message(g.mesg[88])
		return
	end
	if not g.rogue.pack.next_object then
		g.message(g.mesg[89])
		return
	end
	local ch = g.pack_letter(g.mesg[90], g.ALL_OBJECTS)
	if ch == g.CANCEL then
		return
	end
	local obj = g.get_letter_object(ch)
	if not obj then
		g.message(g.mesg[91])
		return
	end
	if obj.in_use_flags == g.BEING_WIELDED then
		if obj.is_cursed then
			g.message(g.curse_message)
			return
		end
		g.unwield(g.rogue.weapon)
	elseif obj.in_use_flags == g.BEING_WORN then
		if obj.is_cursed then
			g.message(g.curse_message)
			return
		end
		g.mv_aquatars()
		g.unwear(g.rogue.armor)
		g.print_stats()
	elseif g.ON_EITHER_HAND(obj.in_use_flags) then
		if obj.is_cursed then
			g.message(g.curse_message)
			return
		end
		g.un_put_on(obj)
	end
	obj.row = g.rogue.row
	obj.col = g.rogue.col

	if obj.quantity > 1 and obj.what_is ~= g.WEAPON then
		obj.quantity = obj.quantity - 1
		local new = g.alloc_object()
		g.copy_object(new, obj)
		new.quantity = 1
		obj = new
	else
		obj.ichar = 'L'
		g.take_from_pack(obj, g.rogue.pack)
	end
	g.place_at(obj, g.rogue.row, g.rogue.col)
	if g.JAPAN then
		g.message(g.get_desc(obj) .. g.mesg[92])
	else
		g.message(g.mesg[92] .. g.get_desc(obj))
	end
	g.reg_move()
end

function g.take_off()
	if g.rogue.armor then
		if g.rogue.armor.is_cursed then
			g.message(g.curse_message)
		else
			g.mv_aquatars()
			local obj = g.rogue.armor
			g.unwear(obj)
			if g.JAPAN then
				g.message(g.get_desc(obj) .. g.mesg[94])
			else
				g.message(g.mesg[94] .. g.get_desc(obj))
			end
			g.print_stats()
			g.reg_move()
		end
	else
		g.message(g.mesg[95])
	end
end

function g.wear()
	if g.rogue.armor then
		g.message(g.mesg[96])
		return
	end
	local ch = g.pack_letter(g.mesg[97], g.ARMOR)

	if ch == g.CANCEL then
		return
	end
	local obj = g.get_letter_object(ch)
	if not obj then
		g.message(g.mesg[98])
		return
	end
	if obj.what_is ~= g.ARMOR then
		g.message(g.mesg[99])
		return
	end
	obj.identified = true
	if g.JAPAN then
		g.message(g.get_desc(obj) .. g.mesg[100])
	else
		g.message(g.mesg[100] .. g.get_desc(obj))
	end
	g.do_wear(obj)
	g.print_stats()
	g.reg_move()
end

function g.unwear(obj)
	if obj then
		obj.in_use_flags = g.NOT_USED
	end
	g.rogue.armor = nil
end

function g.do_wear(obj)
	g.rogue.armor = obj
	obj.in_use_flags = g.BEING_WORN
	obj.identified = true
end

function g.wield()
	if g.rogue.weapon and g.rogue.weapon.is_cursed then
		g.message(g.curse_message)
		return
	end
	local ch = g.pack_letter(g.mesg[101], g.WEAPON)

	if ch == g.CANCEL then
		return
	end
	local obj = g.get_letter_object(ch)
	if not obj then
		g.message(g.mesg[102])
		return
	end
	if obj.what_is == g.ARMOR then
		g.message(string.format(g.mesg[103], g.mesg[104]))
		return
	elseif obj.what_is == g.RING then
		g.message(string.format(g.mesg[103], g.mesg[105]))
		return
	end

	if obj.in_use_flags == g.BEING_WIELDED then
		g.message(g.mesg[106])
	else
		g.unwield(g.rogue.weapon)
		if g.JAPAN then
			g.message(g.get_desc(obj) .. g.mesg[107])
		else
			g.message(g.mesg[107] .. g.get_desc(obj))
		end
		g.do_wield(obj)
		g.reg_move()
	end
end

function g.do_wield(obj)
	g.rogue.weapon = obj
	obj.in_use_flags = g.BEING_WIELDED
end

function g.unwield(obj)
	if obj then
		obj.in_use_flags = g.NOT_USED
	end
	g.rogue.weapon = nil
end

function g.call_it()
	local ch = g.pack_letter(g.mesg[108],
		{[g.SCROL] = true, [g.POTION] = true, [g.WAND] = true, [g.RING] = true})
	if ch == g.CANCEL then
		return
	end
	local obj = g.get_letter_object(ch)
	if not obj then
		g.message(g.mesg[109])
		return
	end
	if not (obj.what_is == g.SCROL or obj.what_is == g.POTION or
			obj.what_is == g.WAND or obj.what_is == g.RING) then
		g.message(g.mesg[110])
		return
	end
	local id_table = g.get_id_table(obj)
	local buf
	if g.JAPAN then
		buf = g.get_input_line(g.mesg[111], "", id_table[obj.which_kind].title, false, true)
		if buf ~= '' and string.byte(' ') <= buf:byte(1) and buf:byte(1) <= string.byte('~') then
			buf = buf .. ' '
		end
	else
		buf = g.get_input_line(g.mesg[111], "", id_table[obj.which_kind].title, true, true)
	end
	if buf ~= '' then
		id_table[obj.which_kind].id_status = g.CALLED
		id_table[obj.which_kind].title = buf
	end
end

function g.pack_count(new_obj)
	local count = 0
	local obj = g.rogue.pack.next_object

	while obj do
		if obj.what_is ~= g.WEAPON then
			count = count + obj.quantity
		elseif not new_obj then
			count = count + 1
		elseif ((new_obj.what_is ~= g.WEAPON) or
			((obj.which_kind ~= g.ARROW) and
			 (obj.which_kind ~= g.DAGGER) and
			 (obj.which_kind ~= g.DART) and
			 (obj.which_kind ~= g.SHURIKEN)) or
			(new_obj.which_kind ~= obj.which_kind) or
			(obj.quiver ~= new_obj.quiver)) then
			count = count + 1
		end
		obj = obj.next_object
	end
	return count
end

function g.has_amulet()
	return mask_pack(g.rogue.pack, g.AMULET)
end

function g.kick_into_pack()
	if not g.dungeon[g.rogue.row][g.rogue.col][g.OBJECT] then
		g.message(g.mesg[112])
	else
		if g.levitate > 0 then
			g.message(g.mesg[113])
			return
		end
		local obj, stat = g.pick_up(g.rogue.row, g.rogue.col)
		if obj then
			local desc = g.get_desc(obj, true)
			if g.JAPAN then
				desc = desc .. g.mesg[114]
			end
			if obj.what_is == g.GOLD then
				g.message(desc)
				g.free_object(obj)
			else
				desc = desc .. '(' .. obj.ichar .. ')'
				g.message(desc)
			end
		end
		if obj or (not stat) then
			g.reg_move()
		end
	end
end

