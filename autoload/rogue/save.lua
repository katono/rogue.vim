local g = Rogue -- alias

g.save_file = 'rogue_vim.save'

local function save_into_file(fname)
	fname = g.expand_fname(fname, g.game_dir)
	local fp = io.open(fname, "wb")
	if not fp then
		g.message(g.mesg[503])
		return
	end

	local Rogue_copy = {}

	Rogue_copy.cur_level = g.cur_level
	Rogue_copy.max_level = g.max_level
	Rogue_copy.hunger_str = g.hunger_str
	Rogue_copy.nick_name = g.nick_name
	Rogue_copy.home_dir = g.home_dir
	Rogue_copy.party_room = g.party_room
	Rogue_copy.party_counter = g.party_counter
	Rogue_copy.level_monsters = g.level_monsters
	Rogue_copy.level_objects = g.level_objects
	Rogue_copy.dungeon = g.dungeon
	Rogue_copy.foods = g.foods
	Rogue_copy.id_potions = g.id_potions
	Rogue_copy.id_scrolls = g.id_scrolls
	Rogue_copy.id_wands = g.id_wands
	Rogue_copy.id_rings = g.id_rings
	Rogue_copy.traps = g.traps
	Rogue_copy.is_wood = g.is_wood
	Rogue_copy.cur_room = g.cur_room
	Rogue_copy.rooms = g.rooms
	Rogue_copy.being_held = g.being_held
	Rogue_copy.bear_trap = g.bear_trap
	Rogue_copy.halluc = g.halluc
	Rogue_copy.blind = g.blind
	Rogue_copy.confused = g.confused
	Rogue_copy.levitate = g.levitate
	Rogue_copy.haste_self = g.haste_self
	Rogue_copy.see_invisible = g.see_invisible
	Rogue_copy.detect_monster = g.detect_monster
	Rogue_copy.wizard = g.wizard
	Rogue_copy.score_only = g.score_only
	Rogue_copy.m_moves = g.m_moves

	Rogue_copy.saved_time = os.time() + 10
	Rogue_copy.dungeon_concat = g.dungeon_buffer_concat()

	Rogue_copy.rogue = {}
	for k, v in pairs(g.rogue) do
		Rogue_copy.rogue[k] = v
	end
	Rogue_copy.rogue.armor = nil
	Rogue_copy.rogue.weapon = nil
	Rogue_copy.rogue.left_ring = nil
	Rogue_copy.rogue.right_ring = nil

	local buf = g.dump(Rogue_copy)
	-- easy compression
	buf = buf:gsub('\n *', '')
	         :gsub(' = ({)', '=%1')
	         :gsub(' = (")', '=%1')
	         :gsub(' = (%-?%d)', '=%1')
	         :gsub(' = (true)', '=%1')
	         :gsub(' = (false)', '=%1')
	         :gsub('"OBJECT"', '1')
	         :gsub('"MONSTER"', '1')
	         :gsub('"STAIRS"', '1')
	         :gsub('"HORWALL"', '1')
	         :gsub('"VERTWALL"', '1')
	         :gsub('"DOOR"', '1')
	         :gsub('"FLOOR"', '1')
	         :gsub('"TUNNEL"', '1')
	         :gsub('"TRAP"', '1')
	         :gsub('"HIDDEN"', '1')
	buf = g.iconv_to_utf8(buf)

	g.xxx(true)
	buf = g.xxxx(buf)
	local ret = fp:write(buf)
	fp:close()
	if not ret then
		g.message(g.mesg[512])
		return
	end

	g.exit()
end

function g.save_game()
	local fname = g.get_input_line(g.mesg[501], g.save_file, g.mesg[502], false, true)
	if fname == '' then
		return
	end
	g.check_message()
	g.message(fname)
	save_into_file(fname)
end

function g.restore(fname)
	fname = g.expand_fname(fname, g.game_dir)
	local fp = io.open(fname, "rb")
	if not fp then
		g.message(g.mesg[504])
		return false
	end

	local buf = fp:read("*a")
	fp:close()
	if not buf then
		g.message(g.mesg[511])
		return false
	end
	g.xxx(true)
	buf = g.xxxx(buf)
	vim.command('let &encoding = "utf-8"')
	buf = g.iconv_from_utf8(buf)
	vim.command('let &encoding = s:save_encoding')
	local Rogue_copy = assert(g.loadstring('return ' .. buf), g.mesg[508])()

	if g.home_dir ~= Rogue_copy.home_dir then
		g.message(g.mesg[506])
		return false
	end

	local saved_time = Rogue_copy.saved_time
	Rogue_copy.saved_time = nil
	if saved_time < g.getftime(fname) then
		g.message(g.mesg[509])
		return false
	end

	if not Rogue_copy.wizard then
		local ret = os.remove(fname)
		if not ret then
			g.message(g.mesg[510])
			return false
		end
	end

	-- restore Rogue
	g.dungeon_buffer_restore(Rogue_copy.dungeon_concat)
	Rogue_copy.dungeon_concat = nil
	for k, v in pairs(Rogue_copy) do
		g[k] = v
	end

	local obj = g.rogue.pack.next_object
	while obj do
		if obj.in_use_flags == g.BEING_WORN then
			g.do_wear(obj)
		elseif obj.in_use_flags == g.BEING_WIELDED then
			g.do_wield(obj)
		elseif obj.in_use_flags == g.ON_LEFT_HAND then
			g.do_put_on(obj, true)
		elseif obj.in_use_flags == g.ON_RIGHT_HAND then
			g.do_put_on(obj, false)
		end
		obj = obj.next_object
	end
	g.msg_cleared = false
	g.ring_stats(false)
	g.print_stats(true)
	return true
end
