local g = Rogue -- alias

g.interrupted = false
g.suspended = false

local function help()
	local help_message = {
		g.mesg[116], g.mesg[117], g.mesg[118], g.mesg[119], g.mesg[120], g.mesg[121],
		g.mesg[122], g.mesg[123], g.mesg[124], g.mesg[125], g.mesg[126], g.mesg[127],
		g.mesg[128], g.mesg[129], g.mesg[130], g.mesg[131], g.mesg[132], g.mesg[133],
		g.mesg[134], g.mesg[135], g.mesg[136], g.mesg[137],
		" ",
		g.mesg[494]
	}

	for n = 1, #help_message do
		g.mvaddstr(n-1, 0, help_message[n])
	end
	g.refresh()
	g.wait_for_ack()

	for row = 0, g.DROWS-1 do
		g.mvaddstr(row, 0, '')
	end
	g.print_stats()
	g.refresh()
end

local function identify()
	local o_names = { [0] =
		g.mesg[138], g.mesg[139], g.mesg[140], g.mesg[141], g.mesg[142], g.mesg[143],
		g.mesg[144], g.mesg[145], g.mesg[146], g.mesg[147], g.mesg[148], g.mesg[149],
		g.mesg[150], g.mesg[151], g.mesg[152], g.mesg[153], g.mesg[154]
	}

	g.message(g.mesg[155])
	local p
	local ch
	while true do
		ch = g.rgetchar()
		if ch == g.CANCEL then
			g.check_message()
			return
		elseif ch:find('^[A-Z]$') then
			g.check_message()
			p = g.m_names[string.byte(ch) - string.byte('A')]
			break
		elseif ch:find('^[a-z]$') then
			g.check_message()
			p = g.m_names[string.byte(ch) - string.byte('a')]
			break
		else
			local n = string.find("@.|-+#%^*:])?!/=,", ch, 1, true)
			if n then
				g.check_message()
				p = o_names[n - 1]
				break
			end
		end
		g.sound_bell()
	end
	g.message(string.format("'%s': %s", string.upper(ch), p))
end

local function doshell()
	if vim then
		vim.command("sh")
	end
end

function g.play_level()
	local unknown_command = g.mesg[115]
	local ch
	local cmd = '.'
	local oldcmd
	local count = 0
	local goto_CH_flag = false

	while true do
		if not goto_CH_flag then
			g.interrupted = false
			if g.hit_message ~= "" then
				g.message(g.hit_message, true)
				g.hit_message = ""
			end
			if g.trap_door then
				g.trap_door = false
				return
			end
			g.refresh()

			oldcmd = cmd
			cmd = g.rgetchar()
			ch = cmd
			g.check_message()
			count = 0
		end

		-- ::CH::
		goto_CH_flag = false
		if ch == '.' then
			g.rest((count > 0) and count or 1)
		elseif ch == 's' then
			g.search(((count > 0) and count or 1), false)
		elseif ch == 'i' then
			g.inventory(g.rogue.pack, g.ALL_OBJECTS)
		elseif ch == 'f' then
			g.fight(false)
		elseif ch == 'F' then
			g.fight(true)
		elseif ch == 'h' or
				ch == 'j' or
				ch == 'k' or
				ch == 'l' or
				ch == 'y' or
				ch == 'u' or
				ch == 'n' or
				ch == 'b' then
			g.one_move_rogue(ch, true)
		elseif ch == 'H' or
				ch == 'J' or
				ch == 'K' or
				ch == 'L' or
				ch == 'Y' or
				ch == 'U' or
				ch == 'N' or
				ch == 'B' or
				ch == 'CTRL_H' or ch == 'BS' or
				ch == 'CTRL_J' or
				ch == 'CTRL_K' or
				ch == 'CTRL_L' or
				ch == 'CTRL_Y' or
				ch == 'CTRL_U' or
				ch == 'CTRL_N' or
				ch == 'CTRL_B' then
			if ch == 'BS' then
				ch = 'CTRL_H'
			end
			g.multiple_move_rogue(ch)
		elseif ch == 'e' then
			g.eat()
		elseif ch == 'q' then
			g.quaff()
		elseif ch == 'r' then
			g.read_scroll()
		elseif ch == 'm' then
			g.move_onto()
		elseif ch == 'd' then
			g.drop()
		elseif ch == 'P' then
			g.put_on_ring()
		elseif ch == 'R' then
			g.remove_ring()
		elseif ch == 'CTRL_P' then
			g.remessage()
		elseif ch == 'CTRL_W' then
			g.wizardize()
		elseif ch == '>' then
			if g.drop_check() then
				return
			end
		elseif ch == '<' then
			if g.check_up() then
				return
			end
		elseif ch == ')' then
			g.inv_weapon()
		elseif ch == ']' then
			g.inv_armor()
		elseif ch == '=' then
			g.inv_rings()
		elseif ch == '^' then
			g.id_trap()
		elseif ch == 'I' then
			g.single_inv(false)
		elseif ch == 'T' then
			g.take_off()
		elseif ch == 'W' then
			g.wear()
		elseif ch == 'w' then
			g.wield()
		elseif ch == 'c' then
			g.call_it()
		elseif ch == 'z' then
			g.zapp()
		elseif ch == 't' then
			g.throw()
		elseif ch == 'v' then
			g.message("Rogue-clone: Version II. (Tim Stoehr was here), tektronix!zeus!tims ")
			g.message("Japanese edition: Ver.1.3a (enhanced by ohta@src.ricoh.co.jp)")
			g.message("Ver.1.3aS program bug fix/separate (by brx@kmc.kyoto-u.ac.jp)")
			g.message("Porting to Vim plugin: Ver." .. g.version .. " (by katono)")
			g.message(g.mesg[1]) -- for message version
		elseif ch == 'Q' then
			g.quit(false)
		elseif ch == '0' or
				ch == '1' or
				ch == '2' or
				ch == '3' or
				ch == '4' or
				ch == '5' or
				ch == '6' or
				ch == '7' or
				ch == '8' or
				ch == '9' then
			g.refresh()
			repeat
				if count < 100 then
					count = (10 * count) + tonumber(ch)
				end
				ch = g.rgetchar()
			until not tonumber(ch)
			if ch ~= g.CANCEL then
				-- goto CH
				goto_CH_flag = true
			end
		elseif ch == ' ' then
		elseif ch == 'CTRL_I' then
			if g.wizard then
				g.inventory(g.level_objects, g.ALL_OBJECTS)
			else
				g.message(unknown_command)
			end
		elseif ch == 'CTRL_S' then
			if g.wizard then
				g.draw_magic_map()
			else
				g.message(unknown_command)
			end
		elseif ch == 'CTRL_T' then
			if g.wizard then
				g.show_traps()
			else
				g.message(unknown_command)
			end
		elseif ch == 'CTRL_O' then
			if g.wizard then
				g.show_objects()
			else
				g.message(unknown_command)
			end
		elseif ch == 'CTRL_A' then
			g.show_average_hp()
		elseif ch == 'CTRL_G' then
			if g.wizard then
				g.new_object_for_wizard()
			else
				g.message(unknown_command)
			end
		elseif ch == 'ENTER' then -- CTRL_M
			if g.wizard then
				g.show_monsters()
			else
				g.message(unknown_command)
			end
		elseif ch == 'S' then
			g.save_game()
		elseif ch == ',' then
			g.kick_into_pack()
		elseif ch == 'CTRL_X' then
			if g.wizard then
				g.draw_magic_map()
				g.show_monsters()
				g.show_objects()
				g.show_traps()
			else
				g.message(unknown_command)
			end
		elseif ch == '?' then
			help()
		elseif ch == '@' or ch == 'CTRL_R' then
			g.print_stats(true)
		elseif ch == 'D' then
			g.discovered()
		elseif ch == '/' then
			identify()
		elseif ch == '!' then
			doshell()
		elseif ch == 'a' then
			cmd = oldcmd
			ch = cmd
			-- goto CH
			goto_CH_flag = true
		elseif ch == 'CTRL_Z' then
			g.suspended = true
			g.exit()
			-- NOTREACHED
		--[[
		elseif ch == 'CTRL_Q' then
			g.breakpoint(true)
		--]]
		else
			g.message(unknown_command)
		end
	end
end
