local g = Rogue -- alias

local rntb = {
	[0] =    3, 0x9a319039, 0x32d9c024, 0x9b663182, 0x5da1f342,
	0xde3b81e0, 0xdf0a6fb5, 0xf103bc02, 0x48f340fb, 0x7449e56b,
	0xbeb1dbb0, 0xab5c5918, 0x946554fd, 0x8c2e680f, 0xeb3d799f,
	0xb11ee0b7, 0x2d436b86, 0xda672e2a, 0x1588ca88, 0xe369735d,
	0x904f35f7, 0xd7158fd6, 0x6fa6f051, 0x616e6b96, 0xac94efdc,
	0x36413f93, 0xc622c298, 0xf5a42ab8, 0x8a88d77b, 0xf5ad9d0e,
	0x8999220b, 0x27fb47b9
}

local fptr = 4
local rptr = 1
local state = 1
local rand_type = 3
local rand_deg = 31
local rand_sep = 3
local end_ptr = 32

local function rrandom()
	local i
	if rand_type == 0 then
		-- 1103515245 = 129749 * 8505
		rntb[state] = (((((rntb[state] * 129749) % 0x80000000) * 8505) + 12345)) % 0x80000000
		i = rntb[state]
	else
		rntb[fptr] = (rntb[fptr] + rntb[rptr]) % 0x100000000
		i = g.int_div(rntb[fptr], 2) % 0x80000000
		fptr = fptr + 1
		if fptr >= end_ptr then
			fptr = state
			rptr = rptr + 1
		else
			rptr = rptr + 1
			if rptr >= end_ptr then
				rptr = state
			end
		end
	end
	return i
end

function g.srrandom(x)
	rntb[state] = x
	if rand_type ~= 0 then
		for i = 1, rand_deg-1 do
			-- 1103515245 = 129749 * 8505
			rntb[state + i] = ((((rntb[state + i - 1] * 129749) % 0x100000000) * 8505) + 12345) % 0x100000000
		end
		fptr = state + rand_sep
		rptr = state
		for i = 0, (10 * rand_deg)-1 do
			rrandom()
		end
	end
end

function g.get_rand(x, y)
	if x > y then
		x, y = y, x
	end
	local lr = rrandom()
	lr = lr % 0x00008000
	local r = lr
	r = (r % ((y - x) + 1)) + x
	return r
end

function g.rand_percent(percentage)
	return g.get_rand(1, 100) <= percentage
end

function g.coin_toss()
	if (rrandom() % 2) == 0 then
		return false
	else
		return true
	end
end


--[[
function g.srrandom(x)
	math.randomseed(x)
end


function g.get_rand(x, y)
	if x > y then
		x, y = y, x
	end
	return math.random(x, y)
end


function g.rand_percent(percentage)
	return g.get_rand(1, 100) <= percentage
end

function g.coin_toss()
	if (g.get_rand(0, 1) % 2) == 0 then
		return false
	else
		return true
	end
end
--]]
