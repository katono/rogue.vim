local g = Rogue -- alias

g.msg_cleared = true
g.hunger_str = ""

local msg_line = ""

local function save_screen()
	local file, err = io.open(g.game_dir .. "rogue_vim.screen", "w")
	if not file then
		g.sound_bell()
		return
	end
	for i = 0, g.DROWS-1 do
		file:write(g.iconv_to_utf8(g.screen[i]) .. "\n")
	end
	file:close()
end

function g.rgetchar()
	local n
	if vim then
		n = vim.eval("getchar()")
	else
		os.execute("stty -echo cbreak")
		n = string.byte(io.stdin:read(1))
		os.execute("stty echo -cbreak")
	end
	local c = ''
	if type(n) == 'string' then
		if vim then
			if n == vim.eval('"\\<BS>"') then
				c = 'BS'
			end
		end
	elseif type(n) == 'number' then
		if n == 0x1B then
			c = 'ESC'
		elseif 0x01 <= n and n <= 0x1F then
			-- CTRL
			c = 'CTRL_' .. string.char(n + 0x40)
			if c == 'CTRL_M' then
				c = 'ENTER'
			end
		else
			if vim then
				c = vim.eval("nr2char("..tostring(n)..")")
			elseif n <= 0x7E then
				c = string.char(n)
			end
		end
		if c == 'CTRL_D' then
			save_screen()
			c = g.rgetchar()
		end
	end
	return c
end

function g.message(msg, intrpt)
	if not g.save_is_interactive then
		return
	end
	if intrpt then
		g.interrupted = true
	end

	if not g.msg_cleared then
		g.mvaddstr(g.MIN_ROW-1, 0, msg_line .. g.mesg[11])
		g.refresh()
		g.wait_for_ack()
		g.check_message()
	end
	msg_line = msg
	g.mvaddstr(g.MIN_ROW-1, 0, msg)
	g.refresh()
	g.msg_cleared = false
end

function g.remessage()
	if msg_line ~= "" then
		g.message(msg_line, false)
	end
end

function g.check_message()
	if g.msg_cleared then
		return
	end
	g.mvaddstr(g.MIN_ROW-1, 0, ' ')
	g.refresh()
	g.msg_cleared = true
end

function g.get_direction()
	g.message(g.mesg[55])
	while true do
		local dir = g.rgetchar()
		if g.is_direction(dir) then
			g.check_message()
			return dir
		end
		g.sound_bell()
	end
end

function g.get_input_line(prompt, insert, if_cancelled, add_blank, do_echo)
	local buf = ''
	local input_list = {}

	for i = 1, #insert do
		table.insert(input_list, string.char(insert:byte(i)))
	end

	while true do
		buf = table.concat(input_list)
		if do_echo then
			g.mvaddstr(g.MIN_ROW-1, 0, prompt .. ' ' .. buf)
		else
			g.mvaddstr(g.MIN_ROW-1, 0, prompt)
		end
		g.refresh()
		local ch = g.rgetchar()
		if ch == 'ENTER' then
			break
		elseif ch == g.CANCEL then
			buf = ''
			break
		elseif ch == 'BS' or ch == 'CTRL_H' then
			if #input_list > 0 then
				table.remove(input_list)
			end
		elseif ch == 'CTRL_W' then
			input_list = {}
		elseif ch == '' or ch:find('CTRL_') then
		else
			table.insert(input_list, ch)
		end
	end
	g.mvaddstr(g.MIN_ROW-1, 0, '')
	buf = buf:gsub("^%s*(.-)%s*$", "%1")

	if buf == '' then
		g.message(if_cancelled)
	elseif add_blank then
		buf = buf .. ' '
	end

	return buf
end

--[[
Level: 99 Gold: 999999 Hp: 999(999) Str: 99(99) Arm: 99 Exp: 21/9999999 Hungry
階: 99 金塊: 999999 体力: 999(999) 強さ: 99(99) 守備: 99 経験: 21/9999999 空腹
0    5    1    5    2    5    3    5    4    5    5    5    6    5    7    5
--]]

function g.print_stats(update_flag)
	local row = g.DROWS - 1

	if g.rogue.gold > g.MAX_GOLD then
		g.rogue.gold = g.MAX_GOLD
	end

	if g.rogue.hp_max > g.MAX_HP then
		g.rogue.hp_current = g.rogue.hp_current - (g.rogue.hp_max - g.MAX_HP)
		g.rogue.hp_max = g.MAX_HP
	end

	if g.rogue.str_max > g.MAX_STRENGTH then
		g.rogue.str_current = g.rogue.str_current - (g.rogue.str_max - g.MAX_STRENGTH)
		g.rogue.str_max = g.MAX_STRENGTH
	end

	if g.rogue.armor and (g.rogue.armor.d_enchant > g.MAX_ARMOR) then
		g.rogue.armor.d_enchant = g.MAX_ARMOR
	end

	local line = ''
	local tmp
	tmp = string.format("%d", g.cur_level)
	line = line .. g.mesg[56] .. tmp .. string.rep(' ', 3 - #tmp)
	tmp = string.format("%d", g.rogue.gold)
	line = line .. g.mesg[57] .. tmp .. string.rep(' ', 7 - #tmp)
	tmp = string.format("%d(%d)", g.rogue.hp_current, g.rogue.hp_max)
	line = line .. g.mesg[58] .. tmp .. string.rep(' ', 9 - #tmp)
	tmp = string.format("%d(%d)", g.rogue.str_current + g.add_strength, g.rogue.str_max)
	line = line .. g.mesg[59] .. tmp .. string.rep(' ', 7 - #tmp)
	tmp = string.format("%d", g.get_armor_class(g.rogue.armor))
	line = line .. g.mesg[60] .. tmp .. string.rep(' ', 3 - #tmp)
	tmp = string.format("%d/%d", g.rogue.exp, g.rogue.exp_points)
	line = line .. g.mesg[61] .. tmp .. string.rep(' ', 11 - #tmp)
	line = line .. g.hunger_str

	g.mvaddstr(row, 0, line)
	if update_flag then
		g.update_flag = true
	end
	g.refresh()
end

function g.clear_stats()
	g.mvaddstr(g.DROWS-1, 0, '')
	g.refresh()
end

function g.sound_bell()
	if vim then
		vim.beep()
	end
end
