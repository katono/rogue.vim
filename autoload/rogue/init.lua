local g = Rogue -- alias

g.nick_name = ''
g.score_only = false
g.save_is_interactive = true
g.show_skull = true
g.ask_quit = true
g.pass_go = true
g.do_restore = false

local rest_file = nil

local function set_nick_name()
	g.nick_name = g.get_vim_variable("g:rogue#name")
	if type(g.nick_name) == 'string' and g.nick_name ~= '' then
		return
	end
	g.nick_name = os.getenv('FIGHTER')
	if g.nick_name then
		return
	end
	g.nick_name = os.getenv('USER')
	if g.nick_name then
		return
	end
	g.nick_name = os.getenv('USERNAME')
	if g.nick_name then
		return
	end
	local default_name = g.mesg[542]
	if vim then
		g.nick_name = vim.eval('inputdialog("'..g.mesg[13]..' ", "'..default_name..'")')
		if g.nick_name == '' then
			g.nick_name = default_name
		end
	else
		g.nick_name = default_name
	end
end

local function do_args(args)
	for i = 1, #args do
		if args[i] == '' then
			break
		elseif args[i] == '-s' then
			g.score_only = true
			break
		elseif args[i] == '-r' then
			g.do_restore = true
		elseif args[i] == '--resume' then
			-- failed to resume
			g.message(g.mesg[543])
			break
		else
			rest_file = args[i]
			break
		end
	end
end

local function do_opts()
	local save_file = g.get_vim_variable("g:rogue#file")
	if type(save_file) == 'string' and save_file ~= '' then
		g.save_file = save_file
	end
	local color = g.get_vim_variable("g:rogue#color")
	if type(color) == 'number' then
		if color ~= 0 then
			g.COLOR = true
		else
			g.COLOR = false
		end
	end
	local jump = g.get_vim_variable("g:rogue#jump")
	if type(jump) == 'number' then
		if jump ~= 0 then
			g.jump = true
		else
			g.jump = false
		end
	end
	local passgo = g.get_vim_variable("g:rogue#passgo")
	if type(passgo) == 'number' then
		if passgo ~= 0 then
			g.pass_go = true
		else
			g.pass_go = false
		end
	end
	local tombstone = g.get_vim_variable("g:rogue#tombstone")
	if type(tombstone) == 'number' then
		if tombstone ~= 0 then
			g.show_skull = true
		else
			g.show_skull = false
		end
	end
	local fruit = g.get_vim_variable("g:rogue#fruit")
	if type(fruit) == 'string' and fruit ~= '' then
		g.fruit = fruit
	end
end

local function player_init()
	g.rogue.pack.next_object = nil

	local obj
	obj = g.alloc_object()
	g.get_food(obj, true)
	g.add_to_pack(obj, g.rogue.pack, true)
	obj.desc = g.get_desc(obj)

	-- initial armor
	obj = g.alloc_object()
	obj.what_is = g.ARMOR
	obj.which_kind = g.RINGMAIL
	obj.which_kind_armor = obj.which_kind
	obj.class = g.RINGMAIL+2
	obj.is_protected = false
	obj.d_enchant = 1
	g.add_to_pack(obj, g.rogue.pack, true)
	g.do_wear(obj)
	obj.desc = g.get_desc(obj)

	-- initial weapons
	obj = g.alloc_object()
	obj.what_is = g.WEAPON
	obj.which_kind = g.MACE
	obj.which_kind_weapon = obj.which_kind
	obj.damage = "2d3"
	obj.hit_enchant = 1
	obj.d_enchant = 1
	obj.identified = true
	g.add_to_pack(obj, g.rogue.pack, true)
	g.do_wield(obj)
	obj.desc = g.get_desc(obj)

	obj = g.alloc_object()
	obj.what_is = g.WEAPON
	obj.which_kind = g.BOW
	obj.which_kind_weapon = obj.which_kind
	obj.damage = "1d2"
	obj.hit_enchant = 1
	obj.d_enchant = 0
	obj.identified = true
	g.add_to_pack(obj, g.rogue.pack, true)
	obj.desc = g.get_desc(obj)

	obj = g.alloc_object()
	obj.what_is = g.WEAPON
	obj.which_kind = g.ARROW
	obj.which_kind_weapon = obj.which_kind
	obj.quantity = g.get_rand(25, 35)
	obj.damage = "1d2"
	obj.hit_enchant = 0
	obj.d_enchant = 0
	obj.identified = true
	g.add_to_pack(obj, g.rogue.pack, true)
	obj.desc = g.get_desc(obj)
end

function g.init(args)
	do_opts()

	if g.suspended then
		-- resume
		g.suspended = false
		g.print_stats(true)
		return true
	end

	g.init_curses()

	do_args(args)
	if g.score_only then
		g.message('')
		print('')
		g.put_scores(nil, 0)
		-- NOTREACHED
	end

	g.srrandom(os.time())

	g.init_invent()
	g.init_level()
	g.init_monster()
	g.init_move()
	g.init_object()
	g.init_pack()
	g.init_ring()
	g.init_room()
	g.init_spechit()
	g.init_trap()
	g.init_use()

	if g.do_restore and g.save_file ~= '' then
		rest_file = g.save_file
	end
	if rest_file then
		if g.restore(rest_file) then
			return true
		end
	end
	set_nick_name()
	g.mix_colors()
	g.get_wand_and_ring_materials()
	g.make_scroll_titles()
	g.level_objects.next_object = nil
	g.level_monsters.next_object = nil
	player_init()
	g.party_counter = g.get_rand(1, g.PARTY_TIME)
	g.ring_stats(false)
	g.print_stats(true)
	return false
end
