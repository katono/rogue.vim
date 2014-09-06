local g = Rogue -- alias

g.DEBUG = true
-- g.COVERAGE = true

local debug_log_file = nil
local debug_log_file_name = 'rogue_vim.log'

local cov_data

function g.printf(fmt, ...)
	if not g.DEBUG then
		return
	end
	if vim then
		print(string.format(fmt, ...))
	else
		io.write(string.format(fmt, ...))
	end
end

function g.msgbox(fmt, ...)
	if not g.DEBUG or not vim then
		return
	end
	vim.eval("confirm('" .. string.format(fmt, ...) .. "')")
end

function g.log(fmt, ...)
	if not g.DEBUG then
		return false
	end
	if not debug_log_file then
		if not g.log_open() then
			return false
		end
	end
	debug_log_file:write(string.format(fmt, ...))
	debug_log_file:flush()
	return true
end

function g.log_open()
	if not g.DEBUG then
		return false
	end
	if not debug_log_file then
		local err
		debug_log_file, err = io.open(g.game_dir .. debug_log_file_name, "a")
		if debug_log_file then
			g.log("\n[%s]\n", os.date())
			return true
		else
			g.printf("%s\n", err)
			return false
		end
	end
	return true
end

function g.log_close()
	if not g.DEBUG then
		return
	end
	if debug_log_file then
		debug_log_file:close()
		debug_log_file = nil
	end
end

function g.log_remove()
	g.log_close()
	local ret, err = os.remove(g.game_dir .. debug_log_file_name)
	if not ret then
		return false
	end
	return true
end

local function get_local_var(level, name)
	local i = 1
	local lname, lval
	repeat
		lname, lval = debug.getlocal(level + 1, i)
		if lname == name then
			return lval, i
		end
		i = i + 1
	until lname == nil
	return nil, -1
end

local function get_upvalue(level, name)
	local func = debug.getinfo(level + 1).func
	local i = 1
	local lname, lval
	repeat
		local lname, lval = debug.getupvalue(func, i)
		if lname == name then
			return lval, i
		end
		i = i + 1
	until lname == nil
	return nil, -1
end

local function get_local_or_upvalue(level, name)
	local lval, i = get_local_var(level + 1, name)
	if i ~= -1 then
		return lval, i, true
	end
	lval, i = get_upvalue(level + 1, name)
	return lval, i, false
end

local function p(obj_str, log_flag, level, hex_flag)
	local lval, i = get_local_or_upvalue(level + 1, obj_str)
	local output
	if i ~= -1 then
		output = "local " .. obj_str .. " = " .. g.dump(lval, hex_flag)
	else
		local obj = assert(g.loadstring('return ' .. obj_str))()
		output = obj_str .. " = " .. g.dump(obj, hex_flag)
	end

	for k, v in pairs(g.print_enum) do
		output = output:gsub("(" .. k .. " = )(%d+),", function(s1, s2)
			local str = v[tonumber(s2)]
			if not str then
				str = '?'
			end
			return s1 .. s2 .. ", -- " .. str
		end)
	end

	if log_flag then
		g.log("%s\n", output)
	else
		g.printf("%s\n", output)
	end
end

function g.p(obj_str, log_flag, hex_flag)
	p(obj_str, log_flag, 2, hex_flag)
end

local function print_all_local_variables(log_flag, level)
	level = level + 1
	local i = 1
	while true do
		local lname, lval = debug.getlocal(level, i)
		if lname == nil then
			break
		end
		if type(lval) ~= 'function' then
			p(lname, log_flag, level)
		end
		i = i + 1
	end
	local func = debug.getinfo(level).func
	i = 1
	while true do
		local lname, lval = debug.getupvalue(func, i)
		if lname == nil then
			break
		end
		if type(lval) ~= 'function' and not(lname == 'g' and lval == Rogue) then
			p(lname, log_flag, level)
		end
		i = i + 1
	end
end

function g.breakpoint(log_flag)
	if not g.DEBUG or not vim then
		return
	end
	local level = 2
	local prompt = '\n'..g.__FILE_LINE__(level)..'\n'..'Breakpoint: '
	while true do
		local input = vim.eval('input("'..prompt..'", "", "tag")')
		if input == '' then
			break
		end
		g.printf(" \n")
		local idx = input:find('=')
		if idx then
			-- set value
			local obj = input:sub(1, idx-1)
			obj = obj:gsub(' ', '')
			local lval, i, is_local = get_local_or_upvalue(level, obj)
			if i ~= -1 then
				local val = input:sub(idx+1)
				local new_val = assert(g.loadstring('return ' .. val))()
				if is_local then
					debug.setlocal(level, i, new_val)
				else
					local func = debug.getinfo(level).func
					debug.setupvalue(func, i, new_val)
				end
			else
				assert(g.loadstring(input))()
			end
		else
			-- get value
			if log_flag then
				g.log("%s\n", prompt .. input)
			end
			if input == 'local' then
				print_all_local_variables(log_flag, level)
			else
				p(input, log_flag, level)
			end
		end
	end
	g.print_stats(true)
end

function g.__FILE_LINE__(level)
	if not level then
		level = 2
	else
		level = level + 1
	end
	return string.gsub(debug.getinfo(level, 'S').source, '^@', '') .. ':' ..
			debug.getinfo(level, 'l').currentline
end

function g.log_screen()
	for i = 0, g.DROWS-1 do
		g.log("%s\n", g.screen[i])
	end
end

function g.error_handler(e)
	if e == g.EXIT_SUCCESS then
		g.clear_stats()
		return e
	end
	g.cov_suspend()
	g.log("%s\n", debug.traceback(e))
	g.log_screen()
	print_all_local_variables(true, 2)
	g.p("Rogue", true)
	g.cov_resume()
	return e
end

local function cov_hook(event, line)
	local s = string.gsub(debug.getinfo(2, 'S').source, '^@', '')
	if not s:find("%.lua$") then
		return
	end
	if not cov_data[s] then
		cov_data[s] = {}
		cov_data[s].src = {}
	end
	if not cov_data[s][line] then
		cov_data[s][line] = 1
	else
		cov_data[s][line] = cov_data[s][line] + 1
	end
end

function g.cov_start()
	if not g.COVERAGE then
		return
	end
	cov_data = {}
	debug.sethook(cov_hook, "l")
end

function g.cov_stop()
	if not g.COVERAGE then
		return
	end
	debug.sethook()
	for k, v in pairs(cov_data) do
		g.log("%s\n", k)
		local i = 1
		for line in io.lines(k) do
			v.src[i] = line
			i = i + 1
		end
		for idx, line in ipairs(v.src) do
			if not v[idx] then
				g.log(string.rep(' ', 9) .. ':')
			else
				g.log("%9d:", v[idx])
			end
			g.log("%5d:", idx)
			g.log("%s\n", line)
		end
	end
end

function g.cov_suspend()
	if not g.COVERAGE then
		return
	end
	debug.sethook()
end

function g.cov_resume()
	if not g.COVERAGE then
		return
	end
	debug.sethook(cov_hook, "l")
end

