local g = Rogue -- alias

g.ObjBase = {}
function g.ObjBase.new()
	local obj       = {}
	obj.o_row       = 0 -- o is how many times stuck at o_row, o_col
	obj.o_col       = 0
	obj.o           = 0
	obj.row         = 0 -- current row, col
	obj.col         = 0
	obj.trow        = 0 -- target row, col
	obj.tcol        = 0
	obj.what_is     = 0
	obj.next_object = nil
	return obj
end

local Object = {}
function Object.new()
	local obj        = g.ObjBase.new()
	obj.damage       = 0
	obj.quantity     = 0
	obj.ichar        = ' '
	obj.is_protected = false
	obj.is_cursed    = false
	obj.class        = 0
	obj.identified   = false
	obj.which_kind   = 0
	obj.d_enchant    = 0
	obj.quiver       = 0
	obj.hit_enchant  = 0
	obj.picked_up    = false
	obj.in_use_flags = g.NOT_USED
	return obj
end

local Fighter = {}
function Fighter.new()
	local fighter = {}
	fighter.armor = nil
	fighter.weapon = nil
	fighter.left_ring = nil
	fighter.right_ring = nil
	fighter.hp_current = g.INIT_HP
	fighter.hp_max = g.INIT_HP
	fighter.str_current = 16
	fighter.str_max = 16
	fighter.pack = {}
	fighter.gold = 0
	fighter.exp = 1
	fighter.exp_points = 0
	fighter.row = 0
	fighter.col = 0
	fighter.fchar = '@'
	fighter.moves_left = 1250
	return fighter
end

g.level_objects = {}
g.rogue = {}
g.foods = 0
g.party_counter = 0
g.fruit = ''

g.po_color = {}
g.id_potions = {}
g.id_scrolls = {}
g.id_weapons = {}
g.id_armors = {}
g.id_wands = {}
g.id_rings = {}

function g.init_object()
	g.rogue = Fighter.new()
	g.fruit = g.mesg[333]
	g.po_color = { [0] =
		g.mesg[334], g.mesg[335], g.mesg[336], g.mesg[337], g.mesg[338],
		g.mesg[339], g.mesg[340], g.mesg[341], g.mesg[342], g.mesg[343],
		g.mesg[344], g.mesg[345], g.mesg[346], g.mesg[347]
	}
	g.id_potions = { [0] =
		{value=100, title='', real=g.mesg[348], id_status=0},
		{value=250, title='', real=g.mesg[349], id_status=0},
		{value=100, title='', real=g.mesg[350], id_status=0},
		{value=200, title='', real=g.mesg[351], id_status=0},
		{value= 10, title='', real=g.mesg[352], id_status=0},
		{value=300, title='', real=g.mesg[353], id_status=0},
		{value= 10, title='', real=g.mesg[354], id_status=0},
		{value= 25, title='', real=g.mesg[355], id_status=0},
		{value=100, title='', real=g.mesg[356], id_status=0},
		{value=100, title='', real=g.mesg[357], id_status=0},
		{value= 10, title='', real=g.mesg[358], id_status=0},
		{value= 80, title='', real=g.mesg[359], id_status=0},
		{value=150, title='', real=g.mesg[360], id_status=0},
		{value=145, title='', real=g.mesg[361], id_status=0}
	}
	g.id_scrolls = { [0] =
		{value=505, title='', real=g.mesg[362], id_status=0},
		{value=200, title='', real=g.mesg[363], id_status=0},
		{value=235, title='', real=g.mesg[364], id_status=0},
		{value=235, title='', real=g.mesg[365], id_status=0},
		{value=175, title='', real=g.mesg[366], id_status=0},
		{value=190, title='', real=g.mesg[367], id_status=0},
		{value= 25, title='', real=g.mesg[368], id_status=0},
		{value=610, title='', real=g.mesg[369], id_status=0},
		{value=210, title='', real=g.mesg[370], id_status=0},
		{value=100, title='', real=g.mesg[371], id_status=0},
		{value= 25, title='', real=g.mesg[372], id_status=0},
		{value=180, title='', real=g.mesg[373], id_status=0}
	}
	g.id_weapons = { [0] =
		{value=150, title=g.mesg[374], real='', id_status=0},
		{value=  8, title=g.mesg[375], real='', id_status=0},
		{value= 15, title=g.mesg[376], real='', id_status=0},
		{value= 27, title=g.mesg[377], real='', id_status=0},
		{value= 35, title=g.mesg[378], real='', id_status=0},
		{value=360, title=g.mesg[379], real='', id_status=0},
		{value=470, title=g.mesg[380], real='', id_status=0},
		{value=580, title=g.mesg[381], real='', id_status=0}
	}
	g.id_armors = { [0] =
		{value=300, title=g.mesg[382], real='', id_status=(g.UNIDENTIFIED)},
		{value=300, title=g.mesg[383], real='', id_status=(g.UNIDENTIFIED)},
		{value=400, title=g.mesg[384], real='', id_status=(g.UNIDENTIFIED)},
		{value=500, title=g.mesg[385], real='', id_status=(g.UNIDENTIFIED)},
		{value=600, title=g.mesg[386], real='', id_status=(g.UNIDENTIFIED)},
		{value=600, title=g.mesg[387], real='', id_status=(g.UNIDENTIFIED)},
		{value=700, title=g.mesg[388], real='', id_status=(g.UNIDENTIFIED)}
	}
	g.id_wands = { [0] =
		{value= 25, title='', real=g.mesg[389], id_status=0},
		{value= 50, title='', real=g.mesg[390], id_status=0},
		{value= 45, title='', real=g.mesg[391], id_status=0},
		{value=  8, title='', real=g.mesg[392], id_status=0},
		{value= 55, title='', real=g.mesg[393], id_status=0},
		{value=  2, title='', real=g.mesg[394], id_status=0},
		{value= 25, title='', real=g.mesg[395], id_status=0},
		{value= 20, title='', real=g.mesg[396], id_status=0},
		{value= 20, title='', real=g.mesg[397], id_status=0},
		{value=  0, title='', real=g.mesg[398], id_status=0}
	}
	g.id_rings = { [0] =
		{value=250, title='', real=g.mesg[399], id_status=0},
		{value=100, title='', real=g.mesg[400], id_status=0},
		{value=255, title='', real=g.mesg[401], id_status=0},
		{value=295, title='', real=g.mesg[402], id_status=0},
		{value=200, title='', real=g.mesg[403], id_status=0},
		{value=250, title='', real=g.mesg[404], id_status=0},
		{value=250, title='', real=g.mesg[405], id_status=0},
		{value= 25, title='', real=g.mesg[406], id_status=0},
		{value=300, title='', real=g.mesg[407], id_status=0},
		{value=290, title='', real=g.mesg[408], id_status=0},
		{value=270, title='', real=g.mesg[409], id_status=0}
	}
end

local function make_party()
	g.party_room = g.gr_room()

	local n = g.rand_percent(99) and g.party_objects(g.party_room) or 11
	if g.rand_percent(99) then
		g.party_monsters(g.party_room, n)
	end
end

local function next_party()
	local n = g.cur_level
	while (n % g.PARTY_TIME) ~= 0 do
		n = n + 1
	end
	return g.get_rand((n + 1), (n + g.PARTY_TIME))
end

local function plant_gold(row, col, is_maze)
	local obj = g.alloc_object()
	obj.row = row
	obj.col = col
	obj.what_is = g.GOLD
	obj.quantity = g.get_rand((2 * g.cur_level), (16 * g.cur_level))
	if is_maze then
		obj.quantity = obj.quantity + g.int_div(obj.quantity, 2)
	end
	obj.desc = g.get_desc(obj)
	g.dungeon[row][col][g.OBJECT] = g.dungeon_desc[g.OBJECT]
	g.add_to_pack(obj, g.level_objects, false)
end

function g.place_at(obj, row, col)
	obj.row = row
	obj.col = col
	g.dungeon[row][col][g.OBJECT] = g.dungeon_desc[g.OBJECT]
	g.add_to_pack(obj, g.level_objects, false)
end

function g.object_at(pack, row, col)
	local obj = pack.next_object
	while obj and (obj.row ~= row or obj.col ~= col) do
		obj = obj.next_object
	end
	return obj
end

function g.get_letter_object(ch)
	local obj = g.rogue.pack.next_object

	while obj and obj.ichar ~= ch do
		obj = obj.next_object
	end
	return obj
end

function g.free_stuff(objlist)
	g.free_object(objlist)
end

local function put_gold()
	for i = 0, g.MAXROOMS-1 do
		local is_maze = (g.rooms[i].is_room == g.R_MAZE) and true or false
		local is_room = (g.rooms[i].is_room == g.R_ROOM) and true or false

		if not (is_room or is_maze) then
			-- continue
		else
			if is_maze or g.rand_percent(g.GOLD_PERCENT) then
				for j = 0, 49 do
					local row = g.get_rand(g.rooms[i].top_row+1, g.rooms[i].bottom_row-1)
					local col = g.get_rand(g.rooms[i].left_col+1, g.rooms[i].right_col-1)
					if g.dungeon[row][col][g.FLOOR] or
							g.dungeon[row][col][g.TUNNEL] then
						plant_gold(row, col, is_maze)
						break
					end
				end
			end
		end
	end
end

local function rand_place(obj)
	local row
	local col
	row, col = g.gr_row_col({[g.FLOOR]=true, [g.TUNNEL]=true})
	g.place_at(obj, row, col)
end

function g.put_objects()
	if g.cur_level < g.max_level then
		return
	end
	local n = g.coin_toss() and g.get_rand(2, 4) or g.get_rand(3, 5)
	while g.rand_percent(33) do
		n = n + 1
	end
	if g.cur_level == g.party_counter then
		make_party()
		g.party_counter = next_party()
	end
	for i = 0, n-1 do
		local obj = g.gr_object()
		rand_place(obj)
	end
	put_gold()
end

function g.name_of(obj)
	local wa = {
		g.SCROL, g.POTION, g.WAND, g.ARMOR, g.RING, g.AMULET
	}
	local na = {
		g.mesg[3], g.mesg[4], g.mesg[5], g.mesg[7], g.mesg[8], g.mesg[9]
	}
	if not g.JAPAN then
		if obj.what_is == g.WAND then
			return g.is_wood[obj.which_kind] and g.mesg[6] or g.mesg[5]
		end
	end
	if obj.what_is == g.WEAPON then
		if not g.English then
			return g.id_weapons[obj.which_kind].title
		else
			local bf = g.id_weapons[obj.which_kind].title
			if obj.which_kind == g.DART or
				obj.which_kind == g.ARROW or
				obj.which_kind == g.DAGGER or
				obj.which_kind == g.SHURIKEN then
				if obj.quantity == 1 then
					-- remove "s" of the plural
					bf = bf:gsub("s ", " ")
				end
			end
			return bf
		end
	end
	if obj.what_is == g.FOOD then
		return (obj.which_kind == g.RATION) and g.mesg[2] or g.fruit
	end
	for i = 1, #wa do
		if obj.what_is == wa[i] then
			if not g.English then
				return na[i]
			else
				if obj.quantity > 1 then
					-- add "s" of the plural
					return na[i]:gsub(" ", "s ")
				else
					return na[i]
				end
			end
		end
	end
	return g.mesg[80]
end

local function gr_what_is()
	local per = { 30, 60, 64, 74, 83, 88, 91 }
	local ret = {
		g.SCROL, g.POTION, g.WAND, g.WEAPON, g.ARMOR, g.FOOD, g.RING
	}

	local percent = g.get_rand(1, 91)
	for i = 1, #per do
		if percent <= per[i] then
			return ret[i]
		end
	end
end

local function gr_scroll(obj)
	local per = {
		5, 11, 16, 21, 36, 44, 51, 56, 65, 74, 80, 85
	}
	local percent = g.get_rand(0, 85)
	obj.what_is = g.SCROL
	for i = 1, #per do
		if percent <= per[i] then
			obj.which_kind = i - 1
			obj.which_kind_scroll = obj.which_kind
			return
		end
	end
end

local function gr_potion(obj)
	local per = {
		10, 20, 30, 40, 50, 55, 65, 75, 85, 95, 105, 110, 114, 118
	}
	local percent = g.get_rand(1, 118)
	obj.what_is = g.POTION
	for i = 1, #per do
		if percent <= per[i] then
			obj.which_kind = i - 1
			obj.which_kind_potion = obj.which_kind
			return
		end
	end
end

local function gr_weapon(obj, assign_wk)
	local da = { [0] =
		"1d1", "1d1", "1d2", "1d3", "1d4", "2d3", "3d4", "4d5"
	}

	obj.what_is = g.WEAPON
	if assign_wk then
		obj.which_kind = g.get_rand(0, g.WEAPONS - 1)
		obj.which_kind_weapon = obj.which_kind
	end
	local i = obj.which_kind
	if i == g.ARROW or i == g.DAGGER or i == g.SHURIKEN or i == g.DART then
		obj.quantity = g.get_rand(3, 15)
		obj.quiver = g.get_rand(0, 126)
	else
		obj.quantity = 1
	end
	obj.hit_enchant = 0
	obj.d_enchant = 0

	local percent = g.get_rand(1, 96)
	local blessing = g.get_rand(1, 3)

	local increment
	if percent <= 16 then
		increment = 1
	elseif percent <= 32 then
		increment = -1
		obj.is_cursed = true
	end
	if percent <= 32 then
		for i = 0, blessing-1 do
			if g.coin_toss() then
				obj.hit_enchant = obj.hit_enchant + increment
			else
				obj.d_enchant = obj.d_enchant + increment
			end
		end
	end
	obj.damage = da[obj.which_kind]
end

local function gr_armor(obj, assign_wk)
	obj.what_is = g.ARMOR
	if assign_wk then
		obj.which_kind = g.get_rand(0, g.ARMORS - 1)
		obj.which_kind_armor = obj.which_kind
	end
	obj.class = obj.which_kind + 2
	if obj.which_kind == g.PLATE or obj.which_kind == g.SPLINT then
		obj.class = obj.class - 1
	end
	obj.is_protected = false
	obj.d_enchant = 0

	local percent = g.get_rand(1, 100)
	local blessing = g.get_rand(1, 3)

	if percent <= 16 then
		obj.is_cursed = true
		obj.d_enchant = obj.d_enchant - blessing
	elseif percent <= 32 then
		obj.d_enchant = obj.d_enchant + blessing
	end
end

local function gr_wand(obj)
	obj.what_is = g.WAND
	obj.which_kind = g.get_rand(0, g.WANDS - 1)
	obj.which_kind_wand = obj.which_kind
	if obj.which_kind == g.MAGIC_MISSILE then
		obj.class = g.get_rand(6, 12)
	elseif obj.which_kind == g.CANCELLATION then
		obj.class = g.get_rand(5, 9)
	else
		obj.class = g.get_rand(3, 6)
	end
end

function g.get_food(obj, force_ration)
	obj.what_is = g.FOOD

	if force_ration or g.rand_percent(80) then
		obj.which_kind = g.RATION
	else
		obj.which_kind = g.FRUIT
	end
	obj.which_kind_food = obj.which_kind
end

function g.gr_object()
	local obj = g.alloc_object()
	if g.foods < g.int_div(g.cur_level, 3) then
		obj.what_is = g.FOOD
		g.foods = g.foods + 1
	else
		obj.what_is = gr_what_is()
	end
	if obj.what_is == g.SCROL then
		gr_scroll(obj)
	elseif obj.what_is == g.POTION then
		gr_potion(obj)
	elseif obj.what_is == g.WEAPON then
		gr_weapon(obj, true)
	elseif obj.what_is == g.ARMOR then
		gr_armor(obj, true)
	elseif obj.what_is == g.WAND then
		gr_wand(obj)
	elseif obj.what_is == g.FOOD then
		g.get_food(obj, false)
	elseif obj.what_is == g.RING then
		g.gr_ring(obj, true)
	end
	obj.desc = g.get_desc(obj)
	return obj
end

function g.put_stairs()
	local row
	local col
	row, col = g.gr_row_col({ [g.FLOOR]=true, [g.TUNNEL]=true })
	g.dungeon[row][col][g.STAIRS] = g.dungeon_desc[g.STAIRS]
end

function g.get_armor_class(obj)
	if obj then
		return obj.class + obj.d_enchant
	end
	return 0
end

function g.alloc_object()
	local obj = Object.new()
	obj.quantity = 1
	obj.ichar = 'L'
	obj.picked_up = false
	obj.is_cursed = false
	obj.identified = false
	obj.damage = "1d1"
	return obj
end

function g.free_object(obj)
	obj.next_object = nil
end

function g.copy_object(dst, src)
	for k, v in pairs(src) do
		dst[k] = v
	end
	if src.m_flags then
		dst.m_flags = {}
		for k, v in pairs(src.m_flags) do
			dst.m_flags[k] = v
		end
	end
end

function g.show_objects()
	local obj = g.level_objects.next_object
	local monster

	while obj do
		local row = obj.row
		local col = obj.col
		local rc = g.get_mask_char(obj.what_is)

		if g.dungeon[row][col][g.MONSTER] then
			monster = g.object_at(g.level_monsters, row, col)
			if monster then
				monster.trail_char = rc
			end
		end
		local mc = g.mvinch(row, col)
		if (not mc:find('^[A-Z]$')) and
			(row ~= g.rogue.row or col ~= g.rogue.col) then
			g.mvaddch(row, col, rc)
		end
		obj = obj.next_object
	end

	monster = g.level_monsters.next_object
	while monster do
		if monster.m_flags[g.IMITATES] then
			g.mvaddch(monster.row, monster.col, monster.disguise)
		end
		monster = monster.next_object
	end
end

function g.put_amulet()
	local obj = g.alloc_object()
	obj.what_is = g.AMULET
	obj.desc = g.get_desc(obj)
	rand_place(obj)
end

local function list_object(obj, max)
	local row
	local col
	local msg = ' ' .. g.mesg[494]
	if g.JAPAN then
		msg = ' ' .. msg
	end
	local len = g.strwidth(msg)
	local weapon_or_armor = false
	local id
	if obj.what_is == g.ARMOR then
		id = g.id_armors
		weapon_or_armor = true
	elseif obj.what_is == g.WEAPON then
		id = g.id_weapons
		weapon_or_armor = true
	elseif obj.what_is == g.SCROL then
		id = g.id_scrolls
	elseif obj.what_is == g.POTION then
		id = g.id_potions
	elseif obj.what_is == g.WAND then
		id = g.id_wands
	elseif obj.what_is == g.RING then
		id = g.id_rings
	else
		return
	end

	local descs = {}
	local maxlen = len
	for i = 0, max do
		if g.JAPAN then
			descs[i] = string.format(" %c) %s%s", i + string.byte('a'),
				(weapon_or_armor and id[i].title or id[i].real),
				(weapon_or_armor and "" or g.name_of(obj)))
		else
			descs[i] = string.format(" %c) %s%s", i + string.byte('a'),
				(weapon_or_armor and "" or g.name_of(obj)),
				(weapon_or_armor and id[i].title or id[i].real))
		end
		local n = g.strwidth(g.descs[i])
		if n > maxlen then
			maxlen = n
		end
	end
	local m = max + 1
	descs[m] = msg

	col = g.DCOLS - (maxlen + 2 + 1)
	for row = 0, m do
		g.mvaddstr(row, col, descs[row])
	end
	g.refresh()
	g.wait_for_ack()
	for row = 0, g.DROWS-2 do
		g.mvaddstr(row, 0, '')
	end
end

function g.new_object_for_wizard()
	if g.pack_count(nil) >= g.MAX_PACK_COUNT then
		g.message(g.mesg[81])
		return
	end
	g.message(g.mesg[82])
	local ch
	while true do
		ch = g.rgetchar()
		if ch == g.CANCEL then
			g.check_message()
			return
		elseif string.find('!?:)]=/,', ch, 1, true) then
			g.check_message()
			break
		else
			g.sound_bell()
		end
	end

	local max = 0
	local obj = g.alloc_object()
	if ch == '!' then
		obj.what_is = g.POTION
		max = g.POTIONS - 1
	elseif ch == '?' then
		obj.what_is = g.SCROL
		max = g.SCROLS - 1
	elseif ch == ',' then
		obj.what_is = g.AMULET
	elseif ch == ':' then
		g.get_food(obj, false)
	elseif ch == ')' then
		obj.what_is = g.WEAPON
		max = g.WEAPONS - 1
	elseif ch == ']' then
		obj.what_is = g.ARMOR
		max = g.ARMORS - 1
	elseif ch == '/' then
		gr_wand(obj)
		max = g.WANDS - 1
	elseif ch == '=' then
		obj.what_is = g.RING
		max = g.RINGS - 1
	end

	if ch ~= ',' and ch ~= ':' then
		local buf = string.format(g.mesg[83], (obj.what_is == g.WEAPON)
			and g.mesg[84] or g.name_of(obj))
		while true do
			g.message(buf)
			while true do
				ch = g.rgetchar()
				if ch ~= g.LIST and ch ~= g.CANCEL and
					string.byte(ch) < string.byte('a') or string.byte(ch) > string.byte('a')+max then
					g.sound_bell()
				else
					break
				end
			end
			if ch == g.LIST then
				g.check_message()
				list_object(obj, max)
			else
				break
			end
		end
		g.check_message()
		if ch == g.CANCEL then
			g.free_object(obj)
			return
		end
		obj.which_kind = string.byte(ch) - string.byte('a')
		if obj.what_is == g.RING then
			g.gr_ring(obj, false)
		end
		if obj.what_is == g.ARMOR then
			gr_armor(obj, false)
		elseif obj.what_is == g.WEAPON then
			gr_weapon(obj, false)
		end
	end
	obj.desc = g.get_desc(obj)
	g.message(g.get_desc(obj, true))
	g.add_to_pack(obj, g.rogue.pack, true)
end
