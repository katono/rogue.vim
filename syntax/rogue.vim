
scriptencoding utf-8

if exists("b:current_syntax")
	finish
endif

syn match rogue_WallH	"-"
syn match rogue_WallV	"|"
syn match rogue_Door	"+"
syn match rogue_Tunnel	"#"
syn match rogue_Floor	"\."
syn match rogue_Stairs	"%"
syn match rogue_Trap	"\^"
syn match rogue_Gold	"\*"
syn match rogue_Food	":"
syn match rogue_Armor	"\]"
syn match rogue_Weapon	")"
syn match rogue_Scrol	"?"
syn match rogue_Potion	"!"
syn match rogue_Wand	"/"
syn match rogue_Ring	"="
syn match rogue_Amulet	","
syn match rogue_Monster	"[A-Z]"
syn match rogue_Fighter	"@"

syn match rogue_Message	"\$\$.*" contains=rogue_ConcealedMessage,rogue_Red,rogue_Green,rogue_Yellow,rogue_CyanBg,rogue_RedBg,rogue_GreenFill
syn match rogue_ConcealedMessage	"\$\$" contained conceal

syn match rogue_Red	"(r(.\{-}(r(" contains=rogue_ConcealedRed
syn match rogue_ConcealedRed	"(r(" contained conceal

syn match rogue_Green	"(g(.\{-}(g(" contains=rogue_ConcealedGreen
syn match rogue_ConcealedGreen	"(g(" contained conceal

syn match rogue_Yellow	"(y(.\{-}(y(" contains=rogue_ConcealedYellow
syn match rogue_ConcealedYellow	"(y(" contained conceal

syn match rogue_RedBg	"(R(.\{-}(R(" contains=rogue_ConcealedRedBg
syn match rogue_ConcealedRedBg	"(R(" contained conceal

syn match rogue_CyanBg	"(C(.\{-}(C(" contains=rogue_ConcealedCyanBg
syn match rogue_ConcealedCyanBg	"(C(" contained conceal

syn match rogue_GreenFill	"(G(.\{-}(G(" contains=rogue_ConcealedGreenFill
syn match rogue_ConcealedGreenFill	"(G(" contained conceal


let s:fg = synIDattr(synIDtrans(hlID("rogueWall")), "fg")
if s:fg == '' || s:fg == '-1'
	if &background == "dark"
		hi rogueWall	ctermfg=cyan	guifg=cyan
	else
		hi rogueWall	ctermfg=blue	guifg=blue
	endif
endif
hi def link rogue_WallH		rogueWall
hi def link rogue_WallV		rogueWall
hi def link rogue_Door		rogueWall
hi def link rogue_Tunnel	rogueWall

let s:fg = synIDattr(synIDtrans(hlID("rogueFloor")), "fg")
if s:fg == '' || s:fg == '-1'
	if &background == "dark"
		hi rogueFloor	ctermfg=blue	guifg=blue
	else
		hi rogueFloor	ctermfg=gray	guifg=gray
	endif
endif
hi def link rogue_Floor		rogueFloor

let s:fg = synIDattr(synIDtrans(hlID("rogueItem")), "fg")
if s:fg == '' || s:fg == '-1'
	if &background == "dark"
		hi rogueItem	ctermfg=yellow	guifg=yellow
	else
		hi rogueItem	ctermfg=brown	guifg=brown
	endif
endif
hi def link rogue_Stairs	rogueItem
hi def link rogue_Trap		rogueItem
hi def link rogue_Gold		rogueItem
hi def link rogue_Food		rogueItem
hi def link rogue_Armor		rogueItem
hi def link rogue_Weapon	rogueItem
hi def link rogue_Scrol		rogueItem
hi def link rogue_Potion	rogueItem
hi def link rogue_Wand		rogueItem
hi def link rogue_Ring		rogueItem
hi def link rogue_Amulet	rogueItem

let s:fg = synIDattr(synIDtrans(hlID("rogueMonster")), "fg")
if s:fg == '' || s:fg == '-1'
	if &background == "dark"
		hi rogueMonster	ctermfg=magenta	guifg=magenta
	else
		hi rogueMonster	ctermfg=red	guifg=red
	endif
endif
hi def link rogue_Monster	rogueMonster

let s:fg = synIDattr(synIDtrans(hlID("rogueFighter")), "fg")
if s:fg == '' || s:fg == '-1'
	if &background == "dark"
		hi rogueFighter	ctermfg=green	guifg=green
	else
		hi rogueFighter	ctermfg=darkgreen	guifg=darkgreen
	endif
endif
hi def link rogue_Fighter	rogueFighter

hi def link rogue_Message	Normal

if &background == "dark"
	hi rogue_Red	ctermfg=red	guifg=red
	hi rogue_Green	ctermfg=green	guifg=green
	hi rogue_Yellow	ctermfg=yellow	guifg=yellow
	hi rogue_GreenFill	ctermfg=green	ctermbg=green	guifg=green	guibg=green
else
	hi rogue_Red	ctermfg=darkred	guifg=darkred
	hi rogue_Green	ctermfg=darkgreen	guifg=darkgreen
	hi rogue_Yellow	ctermfg=brown	guifg=brown
	hi rogue_GreenFill	ctermfg=darkgreen	ctermbg=darkgreen	guifg=darkgreen	guibg=darkgreen
endif
hi rogue_CyanBg	ctermfg=red	ctermbg=cyan	guifg=red	guibg=cyan
hi rogue_RedBg	ctermbg=red	guifg=fg	guibg=red


let b:current_syntax = "rogue"
