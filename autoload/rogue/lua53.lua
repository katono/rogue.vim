local g = Rogue -- alias

-- This file is loaded only when Lua 5.3 or later,
-- because using new features.

function g.lua53_bxor(x, y)
	return x ~ y
end
