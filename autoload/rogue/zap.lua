local g = Rogue -- alias

g.wizard = false

local wiz_passwd = '\171\068\076\182\092\165\000\219\237\052'

local function get_zapped_monster(dir, row, col)
	while true do
		local orow, ocol = row, col
		row, col = g.get_dir_rc(dir, row, col, false)
		if (row == orow and col == ocol) or
			(g.dungeon[row][col][g.HORWALL] or g.dungeon[row][col][g.VERTWALL]) or
			g.table_is_empty(g.dungeon[row][col]) then
			return nil, row, col
		end
		if g.dungeon[row][col][g.MONSTER] then
			if not g.imitating(row, col) then
				return g.object_at(g.level_monsters, row, col), row, col
			end
		end
	end
end

local function get_missiled_monster(dir, row, col)
	local orow, ocol = row, col
	local first = true
	while true do
		row, col = g.get_dir_rc(dir, row, col, false)
		if (row == orow and col == ocol) or
			(g.dungeon[row][col][g.HORWALL] or g.dungeon[row][col][g.VERTWALL]) or
			g.table_is_empty(g.dungeon[row][col]) then
			row, col = orow, ocol
			return nil, row, col
		end
		if not first and g.rogue_can_see(orow, ocol) then
			g.mvaddch(orow, ocol, g.get_dungeon_char(orow, ocol))
		end
		if g.rogue_can_see(row, col) then
			-- if not g.dungeon[row][col][g.MONSTER] then
				g.mvaddch(row, col, '(r(*(r(')
				g.msleep(50)
			-- end
			g.refresh()
		end
		if g.dungeon[row][col][g.MONSTER] then
			if not g.imitating(row, col) then
				return g.object_at(g.level_monsters, row, col), row, col
			end
		end
		first = false
		orow, ocol = row, col
	end
end

function g.zapp()
	local dir = g.get_direction()
	if dir == g.CANCEL then
		return
	end
	local wch = g.pack_letter(g.mesg[278], g.WAND)
	if wch == g.CANCEL then
		return
	end
	g.check_message()

	local wand = g.get_letter_object(wch)
	if not wand then
		g.message(g.mesg[279])
		return
	end
	if wand.what_is ~= g.WAND then
		g.message(g.mesg[280])
		return
	end
	if wand.class <= 0 then
		g.message(g.mesg[281])
	else
		wand.class = wand.class - 1
		local row = g.rogue.row
		local col = g.rogue.col
		local monster
		if wand.which_kind == g.MAGIC_MISSILE then
			monster, row, col = get_missiled_monster(dir, row, col)
			g.mvaddch(g.rogue.row, g.rogue.col, g.rogue.fchar)
			g.refresh()
			if (row ~= g.rogue.row or col ~= g.rogue.col) and g.rogue_can_see(row, col) then
				g.mvaddch(row, col, g.get_dungeon_char(row, col))
			end
		else
			monster, row, col = get_zapped_monster(dir, row, col)
		end
		if monster then
			g.wake_up(monster)
			g.zap_monster(monster, wand.which_kind)
			g.relight()
		end
	end
	g.reg_move()
end

local function tele_away(monster)
	if monster.m_flags[g.HOLDS] then
		g.being_held = false
	end
	local row, col = g.gr_row_col({ [g.FLOOR]=true, [g.TUNNEL]=true, [g.STAIRS]=true, [g.OBJECT]=true })
	g.mvaddch(monster.row, monster.col, monster.trail_char)
	g.dungeon[monster.row][monster.col][g.MONSTER] = nil
	monster.row = row
	monster.col = col
	g.dungeon[row][col][g.MONSTER] = g.m_flags_desc[g.MONSTER]
	monster.trail_char = g.mvinch(row, col)
	if g.detect_monster or g.rogue_can_see(row, col) then
		g.mvaddch(row, col, g.gmc(monster))
	end
end

function g.zap_monster(monster, kind)
	local row = monster.row
	local col = monster.col

	if kind == g.SLOW_MONSTER then
		if monster.m_flags[g.HASTED] then
			monster.m_flags[g.HASTED] = nil
		else
			monster.slowed_toggle = false
			monster.m_flags[g.SLOWED] = g.m_flags_desc[g.SLOWED]
		end
	elseif kind == g.HASTE_MONSTER then
		if monster.m_flags[g.SLOWED] then
			monster.m_flags[g.SLOWED] = nil
		else
			monster.m_flags[g.HASTED] = g.m_flags_desc[g.HASTED]
		end
	elseif kind == g.TELE_AWAY then
		tele_away(monster)
	elseif kind == g.CONFUSE_MONSTER then
		monster.m_flags[g.CONFUSED] = g.m_flags_desc[g.CONFUSED]
		monster.moves_confused = monster.moves_confused + g.get_rand(12, 22)
	elseif kind == g.INVISIBILITY then
		monster.m_flags[g.INVISIBLE] = g.m_flags_desc[g.INVISIBLE]
	elseif kind == g.POLYMORPH then
		if monster.m_flags[g.HOLDS] then
			g.being_held = false
		end
		local nm = monster.next_object
		local tc = monster.trail_char
		g.gr_monster(monster, g.get_rand(0, g.MONSTER-1))
		monster.row = row
		monster.col = col
		monster.next_object = nm
		monster.trail_char = tc
		if not monster.m_flags[g.IMITATES] then
			g.wake_up(monster)
		end
	elseif kind == g.PUT_TO_SLEEP then
		monster.m_flags[g.ASLEEP] = g.m_flags_desc[g.ASLEEP]
		monster.m_flags[g.NAPPING] = g.m_flags_desc[g.NAPPING]
		monster.nap_length = g.get_rand(3, 6)
	elseif kind == g.MAGIC_MISSILE then
		g.rogue_hit(monster, true)
	elseif kind == g.CANCELLATION then
		if monster.m_flags[g.HOLDS] then
			g.being_held = false
		end
		if monster.m_flags[g.STEALS_ITEM] then
			monster.drop_percent = 0
		end
		monster.m_flags[g.FLIES] = nil
		monster.m_flags[g.FLITS] = nil
		monster.m_flags[g.INVISIBLE] = nil
		monster.m_flags[g.FLAMES] = nil
		monster.m_flags[g.IMITATES] = nil
		monster.m_flags[g.CONFUSES] = nil
		monster.m_flags[g.SEEKS_GOLD] = nil
		monster.m_flags[g.RUSTS] = nil
		monster.m_flags[g.HOLDS] = nil
		monster.m_flags[g.FREEZES] = nil
		monster.m_flags[g.STEALS_GOLD] = nil
		monster.m_flags[g.STEALS_ITEM] = nil
		monster.m_flags[g.STINGS] = nil
		monster.m_flags[g.DRAINS_LIFE] = nil
		monster.m_flags[g.DROPS_LEVEL] = nil
	elseif kind == g.DO_NOTHING then
		g.message(g.mesg[282])
	end
end

function g.wizardize()
	if g.wizard then
		g.wizard = false
		g.message(g.mesg[497])
		return
	end
	local buf = g.get_input_line(g.mesg[498], "", "", false, false)
	if buf == '' then
		return
	end
	g.xxx(true)
	buf = g.xxxx(buf)
	if buf == wiz_passwd then
		g.message(g.mesg[499])
		g.wizard = true
		g.score_only = true
	else
		g.message(g.mesg[500])
	end
end
