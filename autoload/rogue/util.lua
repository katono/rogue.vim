local g = Rogue -- alias

g.loadstring = nil
if _VERSION >= 'Lua 5.2' then
	g.loadstring = load
else
	g.loadstring = loadstring
end

g.bxor = nil

local bit_exists, bit = pcall(require, "bit")
if bit_exists then
	g.bxor = bit.bxor
elseif _VERSION >= 'Lua 5.2' then
	g.bxor = bit32.bxor
else
	g.bxor = function(x, y)
		local n = 0
		local ret = 0

		repeat
			local bit_x = x % 2
			local bit_y = y % 2
			if bit_x ~= bit_y then
				ret = ret + 2 ^ n
			end
			x = g.int_div(x, 2)
			y = g.int_div(y, 2)
			n = n + 1
		until x == 0 and y == 0
		return ret
	end
end

function g.get_vim_variable(var)
	if vim then
		if vim.eval("exists('" .. var .. "')") ~= 0 then
			return vim.eval(var)
		end
	end
	return ''
end

function g.set_vim_variable(var, value)
	if vim then
		if type(value) == 'number' then
			vim.command('let ' .. var .. ' = ' .. tostring(value))
		elseif type(value) == 'string' then
			vim.command('let ' .. var .. ' = "' .. value .. '"')
		end
	end
end

local function dump(obj, indent_depth, dumped_table_list, hex_flag)
	if not indent_depth then
		indent_depth = 0
	end
	if not dumped_table_list then
		dumped_table_list = {}
	end

	local t = type(obj)
	local s
	if t == 'table' then
		local exists = false
		for i, v in ipairs(dumped_table_list) do
			if v == tostring(obj) then
				exists = true
			end
		end
		s = '{'
		if exists then
			s = s .. ' ... '
		else
			table.insert(dumped_table_list, tostring(obj))
			local indent = '  '
			local is_empty = true
			for k, v in pairs(obj) do
				is_empty = false
				s = s .. '\n' .. string.rep(indent, indent_depth + 1)
				if type(k) == 'string' then
					s = s .. k
				else
					s = s .. '[' .. k .. ']'
				end
				s = s .. ' = '
				s = s .. dump(v, indent_depth + 1, dumped_table_list, hex_flag)
				s = s .. ','
			end
			if not is_empty then
				s = s .. '\n' .. string.rep(indent, indent_depth)
			end
		end
		s = s .. '} ' .. tostring(obj)

		if indent_depth == 0 and not s:find('{ ... } table') then
			s = s:gsub(' table:[ xX%x]*', '')
		end
	elseif t == 'string' then
		s = '"' .. obj .. '"'
	elseif hex_flag and t == 'number' then
		s = string.format('0x%x', obj)
	else
		s = tostring(obj)
	end

	return s
end

function g.dump(obj, hex_flag)
	return dump(obj, nil, nil, hex_flag)
end

function g.int_div(dividend, divisor)
	return math.floor(dividend / divisor)
end

function g.table_is_empty(tbl)
	if next(tbl) == nil then
		return true
	else
		return false
	end
end

function g.strwidth(s)
	local len
	if vim then
		len = vim.eval('strwidth("' .. s .. '")')
	else
		len = #s
	end
	return len
end

function g.getftime(fname)
	local t
	if vim then
		t = vim.eval('getftime("' .. fname .. '")')
	else
		t = -1
	end
	return t
end

function g.split(str, sep)
	local ret = {}
	while true do
		local idx = str:find(sep, 1, true)
		if not idx then
			table.insert(ret, str)
			break
		end
		if idx == 1 then
			str = str:sub(idx + 1)
		else
			local prev = str:sub(1, idx - 1)
			str = str:sub(idx + 1)
			table.insert(ret, prev)
		end
	end
	return ret
end

function g.msleep(n)
	if vim then
		vim.command('sleep ' .. tostring(n) .. 'm')
	end
end

g.EXIT_SUCCESS = 'g.EXIT_SUCCESS'
function g.exit(e)
	local level = 2
	if e == nil then
		e = g.EXIT_SUCCESS
	end
	if e == g.EXIT_SUCCESS then
		level = 0
	end
	error(e, level)
end

function g.expand_fname(fname, dir)
	fname = fname:gsub('\\', '/')
	if string.char(fname:byte(1)) == '~' then
		fname = fname:gsub('~/', g.home_dir)
	elseif not (fname:find('^/.*') or fname:find('^[A-Za-z]:/.*')) then
		fname = dir .. fname
	end
	return fname
end

function g.iconv_from_utf8(str)
	if g.needs_iconv then
		str = str:gsub("'", "''")
		str = vim.eval("iconv('" .. str .. "', 'utf-8', s:save_encoding)")
	end
	return str
end

function g.iconv_to_utf8(str)
	if g.needs_iconv then
		str = str:gsub("'", "''")
		str = vim.eval("iconv('" .. str .. "', s:save_encoding, 'utf-8')")
	end
	return str
end
