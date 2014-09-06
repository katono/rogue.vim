local g = Rogue -- alias

g.COLOR = true

g.update_flag = false

g.dungeon = {}
local dungeon_buffer = {}
local dungeon_str_buffer = {}
local last_row_str = {}
local last_print_area = ''
g.descs = {}
g.screen = {}

function g.init_curses()
	for i = 0, g.DROWS-1 do
		g.dungeon[i] = {}
		dungeon_buffer[i] = {}
		dungeon_str_buffer[i] = {}
		dungeon_str_buffer[i].col = 0
		dungeon_str_buffer[i].str = ''
		last_row_str[i] = ''
		g.descs[i] = ''
		g.screen[i] = ''
		for j = 0, g.DCOLS-1 do
			g.dungeon[i][j] = {}
			dungeon_buffer[i][j] = ' '
		end
	end
end

local function dungeon_row(row)
	return table.concat(dungeon_buffer[row], '', 0, g.DCOLS-1)
end

function g.dungeon_buffer_concat()
	local t = {}
	for i = 0, g.DROWS-1 do
		table.insert(t, dungeon_row(i) .. ';')
	end
	return table.concat(t)
end

function g.dungeon_buffer_restore(str)
	local t = g.split(str, ';')
	for i, v in ipairs(t) do
		for j = 1, #v do
			dungeon_buffer[i-1][j-1] = string.char(v:byte(j))
		end
	end
end

function g.clear()
	for i = 0, g.DROWS-1 do
		for j = 0, g.DCOLS-1 do
			dungeon_buffer[i][j] = ' '
		end
		g.mvaddstr(i, 0, '')
	end
	g.refresh()
end

function g.mvinch(row, col)
	return dungeon_buffer[row][col]
end

function g.mvaddch(row, col, ch)
	dungeon_buffer[row][col] = ch
end

function g.mvaddstr(row, col, str)
	dungeon_str_buffer[row].col = col
	dungeon_str_buffer[row].str = str
end

function g.refresh()
	if vim then
		vim.command("normal gg")
	end
	local update = false
	local done_redraw = false
	for i = 0, g.DROWS-1 do
		local row_str
		if dungeon_str_buffer[i].str == '' then
			row_str = dungeon_row(i)
		else
			row_str = dungeon_row(i):sub(1, dungeon_str_buffer[i].col)
		end
		if vim then
			if i == g.DROWS-1 and vim.eval("&lines") == g.DROWS then
				row_str = row_str .. dungeon_str_buffer[i].str
				if g.update_flag or row_str ~= last_print_area then
					vim.command("redraw")
					print((vim.eval("has('gui_running')") ~= 0 and '' or ' ') .. row_str)
					vim.command("redrawstatus")
					last_print_area = row_str
					done_redraw = true
				end
			else
				if g.update_flag and i == 0 and vim.eval("&lines") > g.DROWS then
					print(' ')
				end
				if dungeon_str_buffer[i].str ~= '' then
					if g.COLOR then
						row_str = row_str .. '$$' .. dungeon_str_buffer[i].str
					else
						row_str = row_str .. dungeon_str_buffer[i].str
						row_str = row_str:gsub('%(%w%(', '')
					end
				end
				if g.update_flag or row_str ~= last_row_str[i] then
					local cmd_str
					cmd_str = 'call setline(' .. tostring(i + 1) .. ', "' .. row_str .. '")'
					vim.command(cmd_str)
					last_row_str[i] = row_str
					update = true
				end
			end
		else
			row_str = row_str .. dungeon_str_buffer[i].str
			print(row_str)
		end
		g.screen[i] = row_str:gsub("%$%$", ""):gsub("%(%w%(", ""):gsub('\\\\', '\\')
	end
	g.update_flag = false
	if update and not done_redraw then
		vim.command("redraw")
	end
end
