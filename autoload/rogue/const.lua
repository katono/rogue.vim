local g = Rogue -- alias

g.print_enum = {}

-- g.dungeon
g.NOTHING  = 0
g.OBJECT   = 1
g.MONSTER  = 2
g.STAIRS   = 3
g.HORWALL  = 4
g.VERTWALL = 5
g.DOOR     = 6
g.FLOOR    = 7
g.TUNNEL   = 8
g.TRAP     = 9
g.HIDDEN   = 10
g.dungeon_desc = {
	[g.NOTHING]  = "NOTHING",
	[g.OBJECT]   = "OBJECT",
	[g.MONSTER]  = "MONSTER",
	[g.STAIRS]   = "STAIRS",
	[g.HORWALL]  = "HORWALL",
	[g.VERTWALL] = "VERTWALL",
	[g.DOOR]     = "DOOR",
	[g.FLOOR]    = "FLOOR",
	[g.TUNNEL]   = "TUNNEL",
	[g.TRAP]     = "TRAP",
	[g.HIDDEN]   = "HIDDEN",
}

-- what_is
g.GOLD   = 1
g.FOOD   = 2
g.ARMOR  = 3
g.WEAPON = 4
g.SCROL  = 5
g.POTION = 6
g.WAND   = 7
g.RING   = 8
g.AMULET = 9
g.print_enum.what_is = {
	[g.GOLD]   = "GOLD",
	[g.FOOD]   = "FOOD",
	[g.ARMOR]  = "ARMOR",
	[g.WEAPON] = "WEAPON",
	[g.SCROL]  = "SCROL",
	[g.POTION] = "POTION",
	[g.WAND]   = "WAND",
	[g.RING]   = "RING",
	[g.AMULET] = "AMULET",
}
g.ALL_OBJECTS = {
	[g.GOLD]   = true,
	[g.FOOD]   = true,
	[g.ARMOR]  = true,
	[g.WEAPON] = true,
	[g.SCROL]  = true,
	[g.POTION] = true,
	[g.WAND]   = true,
	[g.RING]   = true,
	[g.AMULET] = true,
}

-- which_kind
g.LEATHER  = 0
g.RINGMAIL = 1
g.SCALE    = 2
g.CHAIN    = 3
g.BANDED   = 4
g.SPLINT   = 5
g.PLATE    = 6
g.ARMORS   = 7
g.print_enum.which_kind_armor = {
	[g.LEATHER]  = "LEATHER",
	[g.RINGMAIL] = "RINGMAIL",
	[g.SCALE]    = "SCALE",
	[g.CHAIN]    = "CHAIN",
	[g.BANDED]   = "BANDED",
	[g.SPLINT]   = "SPLINT",
	[g.PLATE]    = "PLATE",
	[g.ARMORS]   = "ARMORS",
}

g.BOW              = 0
g.DART             = 1
g.ARROW            = 2
g.DAGGER           = 3
g.SHURIKEN         = 4
g.MACE             = 5
g.LONG_SWORD       = 6
g.TWO_HANDED_SWORD = 7
g.WEAPONS          = 8
g.print_enum.which_kind_weapon = {
	[g.BOW]              = "BOW",
	[g.DART]             = "DART",
	[g.ARROW]            = "ARROW",
	[g.DAGGER]           = "DAGGER",
	[g.SHURIKEN]         = "SHURIKEN",
	[g.MACE]             = "MACE",
	[g.LONG_SWORD]       = "LONG_SWORD",
	[g.TWO_HANDED_SWORD] = "TWO_HANDED_SWORD",
	[g.WEAPONS]          = "WEAPONS",
}

g.MAX_PACK_COUNT = 24

g.PROTECT_ARMOR     = 0
g.HOLD_MONSTER      = 1
g.ENCH_WEAPON       = 2
g.ENCH_ARMOR        = 3
g.IDENTIFY          = 4
g.TELEPORT          = 5
g.SLEEP             = 6
g.SCARE_MONSTER     = 7
g.REMOVE_CURSE      = 8
g.CREATE_MONSTER    = 9
g.AGGRAVATE_MONSTER = 10
g.MAGIC_MAPPING     = 11
g.SCROLS            = 12
g.print_enum.which_kind_scroll = {
	[g.PROTECT_ARMOR]     = "PROTECT_ARMOR",
	[g.HOLD_MONSTER]      = "HOLD_MONSTER",
	[g.ENCH_WEAPON]       = "ENCH_WEAPON",
	[g.ENCH_ARMOR]        = "ENCH_ARMOR",
	[g.IDENTIFY]          = "IDENTIFY",
	[g.TELEPORT]          = "TELEPORT",
	[g.SLEEP]             = "SLEEP",
	[g.SCARE_MONSTER]     = "SCARE_MONSTER",
	[g.REMOVE_CURSE]      = "REMOVE_CURSE",
	[g.CREATE_MONSTER]    = "CREATE_MONSTER",
	[g.AGGRAVATE_MONSTER] = "AGGRAVATE_MONSTER",
	[g.MAGIC_MAPPING]     = "MAGIC_MAPPING",
	[g.SCROLS]            = "SCROLS",
}

g.INCREASE_STRENGTH = 0
g.RESTORE_STRENGTH  = 1
g.HEALING           = 2
g.EXTRA_HEALING     = 3
g.POISON            = 4
g.RAISE_LEVEL       = 5
g.BLINDNESS         = 6
g.HALLUCINATION     = 7
g.DETECT_MONSTER    = 8
g.DETECT_OBJECTS    = 9
g.CONFUSION         = 10
g.LEVITATION        = 11
g.HASTE_SELF        = 12
g.SEE_INVISIBLE     = 13
g.POTIONS           = 14
g.print_enum.which_kind_potion = {
	[g.INCREASE_STRENGTH] = "INCREASE_STRENGTH",
	[g.RESTORE_STRENGTH]  = "RESTORE_STRENGTH",
	[g.HEALING]           = "HEALING",
	[g.EXTRA_HEALING]     = "EXTRA_HEALING",
	[g.POISON]            = "POISON",
	[g.RAISE_LEVEL]       = "RAISE_LEVEL",
	[g.BLINDNESS]         = "BLINDNESS",
	[g.HALLUCINATION]     = "HALLUCINATION",
	[g.DETECT_MONSTER]    = "DETECT_MONSTER",
	[g.DETECT_OBJECTS]    = "DETECT_OBJECTS",
	[g.CONFUSION]         = "CONFUSION",
	[g.LEVITATION]        = "LEVITATION",
	[g.HASTE_SELF]        = "HASTE_SELF",
	[g.SEE_INVISIBLE]     = "SEE_INVISIBLE",
	[g.POTIONS]           = "POTIONS",
}

g.TELE_AWAY       = 0
g.SLOW_MONSTER    = 1
g.CONFUSE_MONSTER = 2
g.INVISIBILITY    = 3
g.POLYMORPH       = 4
g.HASTE_MONSTER   = 5
g.PUT_TO_SLEEP    = 6
g.MAGIC_MISSILE   = 7
g.CANCELLATION    = 8
g.DO_NOTHING      = 9
g.WANDS           = 10
g.print_enum.which_kind_wand = {
	[g.TELE_AWAY]       = "TELE_AWAY",
	[g.SLOW_MONSTER]    = "SLOW_MONSTER",
	[g.CONFUSE_MONSTER] = "CONFUSE_MONSTER",
	[g.INVISIBILITY]    = "INVISIBILITY",
	[g.POLYMORPH]       = "POLYMORPH",
	[g.HASTE_MONSTER]   = "HASTE_MONSTER",
	[g.PUT_TO_SLEEP]    = "PUT_TO_SLEEP",
	[g.MAGIC_MISSILE]   = "MAGIC_MISSILE",
	[g.CANCELLATION]    = "CANCELLATION",
	[g.DO_NOTHING]      = "DO_NOTHING",
	[g.WANDS]           = "WANDS",
}

g.STEALTH          = 0
g.R_TELEPORT       = 1
g.REGENERATION     = 2
g.SLOW_DIGEST      = 3
g.ADD_STRENGTH     = 4
g.SUSTAIN_STRENGTH = 5
g.DEXTERITY        = 6
g.ADORNMENT        = 7
g.R_SEE_INVISIBLE  = 8
g.MAINTAIN_ARMOR   = 9
g.SEARCHING        = 10
g.RINGS            = 11
g.print_enum.which_kind_ring = {
	[g.STEALTH]          = "STEALTH",
	[g.R_TELEPORT]       = "R_TELEPORT",
	[g.REGENERATION]     = "REGENERATION",
	[g.SLOW_DIGEST]      = "SLOW_DIGEST",
	[g.ADD_STRENGTH]     = "ADD_STRENGTH",
	[g.SUSTAIN_STRENGTH] = "SUSTAIN_STRENGTH",
	[g.DEXTERITY]        = "DEXTERITY",
	[g.ADORNMENT]        = "ADORNMENT",
	[g.R_SEE_INVISIBLE]  = "R_SEE_INVISIBLE",
	[g.MAINTAIN_ARMOR]   = "MAINTAIN_ARMOR",
	[g.SEARCHING]        = "SEARCHING",
	[g.RINGS]            = "RINGS",
}

g.RATION = 0
g.FRUIT  = 1
g.print_enum.which_kind_food = {
	[g.RATION] = "RATION",
	[g.FRUIT]  = "FRUIT",
}

-- in_use_flags
g.NOT_USED      = 0
g.BEING_WIELDED = 1
g.BEING_WORN    = 2
g.ON_LEFT_HAND  = 3
g.ON_RIGHT_HAND = 4
g.print_enum.in_use_flags = {
	[g.NOT_USED]      = "NOT_USED",
	[g.BEING_WIELDED] = "BEING_WIELDED",
	[g.BEING_WORN]    = "BEING_WORN",
	[g.ON_LEFT_HAND]  = "ON_LEFT_HAND",
	[g.ON_RIGHT_HAND] = "ON_RIGHT_HAND",
}
function g.ON_EITHER_HAND(in_use_flags)
	if in_use_flags == g.ON_LEFT_HAND or
		in_use_flags == g.ON_RIGHT_HAND then
		return true
	else
		return false
	end
end
function g.BEING_USED(in_use_flags)
	if in_use_flags == g.BEING_WIELDED or
		in_use_flags == g.BEING_WORN or
		in_use_flags == g.ON_LEFT_HAND or
		in_use_flags == g.ON_RIGHT_HAND then
		return true
	else
		return false
	end
end

-- trap_type
g.NO_TRAP           = -1
g.TRAP_DOOR         = 0
g.BEAR_TRAP         = 1
g.TELE_TRAP         = 2
g.DART_TRAP         = 3
g.SLEEPING_GAS_TRAP = 4
g.RUST_TRAP         = 5
g.TRAPS             = 6

g.STEALTH_FACTOR = 3
g.R_TELE_PERCENT = 8

g.UNIDENTIFIED = 0
g.IDENTIFIED   = 1
g.CALLED       = 2

g.DROWS = 24
g.DCOLS = 80
g.MAX_TITLE_LENGTH = 30
g.MAXSYLLABLES = 40
g.MAX_METAL = 14
g.WAND_MATERIALS = 30
g.GEMS = 14

g.GOLD_PERCENT = 46

g.INIT_HP = 12

g.MAXROOMS = 9
g.BIG_ROOM = 10
g.NO_ROOM = -1

g.PASSAGE = -3

g.AMULET_LEVEL = 26

-- is_room
g.R_NOTHING = 1
g.R_ROOM    = 2
g.R_MAZE    = 3
g.R_DEADEND = 4
g.R_CROSS   = 5
g.print_enum.is_room = {
	[g.R_NOTHING] = "R_NOTHING",
	[g.R_ROOM]    = "R_ROOM",
	[g.R_MAZE]    = "R_MAZE",
	[g.R_DEADEND] = "R_DEADEND",
	[g.R_CROSS]   = "R_CROSS",
}

g.MAX_EXP_LEVEL = 21
g.MAX_EXP = 9999999
g.MAX_GOLD = 900000
g.MAX_ARMOR = 99
g.MAX_HP = 800
g.MAX_STRENGTH = 99
g.LAST_DUNGEON = 99


g.PARTY_TIME = 10

g.MAX_TRAPS = 10

g.HIDE_PERCENT = 12

g.MONSTERS = 26

-- m_flags
g.HASTED         =  1
g.SLOWED         =  2
g.INVISIBLE      =  3
g.ASLEEP         =  4
g.WAKENS         =  5
g.WANDERS        =  6
g.FLIES          =  7
g.FLITS          =  8
g.CAN_FLIT       =  9
g.CONFUSED       = 10
g.RUSTS          = 11
g.HOLDS          = 12
g.FREEZES        = 13
g.STEALS_GOLD    = 14
g.STEALS_ITEM    = 15
g.STINGS         = 16
g.DRAINS_LIFE    = 17
g.DROPS_LEVEL    = 18
g.SEEKS_GOLD     = 19
g.FREEZING_ROGUE = 20
g.RUST_VANISHED  = 21
g.CONFUSES       = 22
g.IMITATES       = 23
g.FLAMES         = 24
g.STATIONARY     = 25
g.NAPPING        = 26
g.ALREADY_MOVED  = 27
g.m_flags_desc = {
	[g.HASTED]         = "HASTED",
	[g.SLOWED]         = "SLOWED",
	[g.INVISIBLE]      = "INVISIBLE",
	[g.ASLEEP]         = "ASLEEP",
	[g.WAKENS]         = "WAKENS",
	[g.WANDERS]        = "WANDERS",
	[g.FLIES]          = "FLIES",
	[g.FLITS]          = "FLITS",
	[g.CAN_FLIT]       = "CAN_FLIT",
	[g.CONFUSED]       = "CONFUSED",
	[g.RUSTS]          = "RUSTS",
	[g.HOLDS]          = "HOLDS",
	[g.FREEZES]        = "FREEZES",
	[g.STEALS_GOLD]    = "STEALS_GOLD",
	[g.STEALS_ITEM]    = "STEALS_ITEM",
	[g.STINGS]         = "STINGS",
	[g.DRAINS_LIFE]    = "DRAINS_LIFE",
	[g.DROPS_LEVEL]    = "DROPS_LEVEL",
	[g.SEEKS_GOLD]     = "SEEKS_GOLD",
	[g.FREEZING_ROGUE] = "FREEZING_ROGUE",
	[g.RUST_VANISHED]  = "RUST_VANISHED",
	[g.CONFUSES]       = "CONFUSES",
	[g.IMITATES]       = "IMITATES",
	[g.FLAMES]         = "FLAMES",
	[g.STATIONARY]     = "STATIONARY",
	[g.NAPPING]        = "NAPPING",
	[g.ALREADY_MOVED]  = "ALREADY_MOVED",
}
function g.SPECIAL_HIT(m_flags)
	for k, v in pairs(m_flags) do
		if k == g.RUSTS or
			k == g.HOLDS or
			k == g.FREEZES or
			k == g.STEALS_GOLD or
			k == g.STEALS_ITEM or
			k == g.STINGS or
			k == g.DRAINS_LIFE or
			k == g.DROPS_LEVEL then
			return true
		end
	end
	return false
end

g.WAKE_PERCENT = 45
g.FLIT_PERCENT = 33
g.PARTY_WAKE_PERCENT = 75

-- killed_by other
g.HYPOTHERMIA = 1
g.STARVATION  = 2
g.POISON_DART = 3
g.QUIT        = 4
g.WIN         = 5

-- dir
g.UPWARD    = 0
g.UPRIGHT   = 1
g.RIGHT     = 2
g.RIGHTDOWN = 3
g.DOWN      = 4
g.DOWNLEFT  = 5
g.LEFT      = 6
g.LEFTUP    = 7
g.DIRS      = 8

g.ROW1 = 7
g.ROW2 = 15

g.COL1 = 26
g.COL2 = 52

g.MOVED = 0
g.MOVE_FAILED = -1
g.STOPPED_ON_SOMETHING = -2
g.CANCEL = 'ESC'
g.LIST = '*'

g.HUNGRY = 300
g.WEAK = 150
g.FAINT = 20
g.STARVE = 0

g.MIN_ROW = 1

