
let s:FILE_DIR = fnamemodify(expand("<sfile>"), ':h') . '/'
let s:FILE_DIR = substitute(s:FILE_DIR, '\\', '/', 'g')
function! rogue#rogue#main(args)
	if !has('lua')
		echo "Sorry. Rogue.vim needs '+lua'."
		return
	endif
	let resume = 0
	if luaeval('type(Rogue)') ==# 'table' &&
			\ luaeval('tostring(Rogue.suspended)') ==# 'true'
		if a:args ==# '--resume'
			let resume = 1
		else
			let c = confirm(luaeval('Rogue.mesg[544]'),
							\ "&Yes\n&No\n&Cancel", 1)
			if c == 1
				let resume = 1
			elseif c == 2
				let resume = 0
			else
				return
			endif
		endif
	endif
	if !resume
		execute 'luafile ' . s:FILE_DIR . 'main.lua'
		execute 'luafile ' . s:FILE_DIR . 'const.lua'
		execute 'luafile ' . s:FILE_DIR . 'curses.lua'
		execute 'luafile ' . s:FILE_DIR . 'debug.lua'
		execute 'luafile ' . s:FILE_DIR . 'hit.lua'
		execute 'luafile ' . s:FILE_DIR . 'init.lua'
		execute 'luafile ' . s:FILE_DIR . 'invent.lua'
		execute 'luafile ' . s:FILE_DIR . 'level.lua'
		execute 'luafile ' . s:FILE_DIR . 'message.lua'
		execute 'luafile ' . s:FILE_DIR . 'monster.lua'
		execute 'luafile ' . s:FILE_DIR . 'move.lua'
		execute 'luafile ' . s:FILE_DIR . 'object.lua'
		execute 'luafile ' . s:FILE_DIR . 'pack.lua'
		execute 'luafile ' . s:FILE_DIR . 'play.lua'
		execute 'luafile ' . s:FILE_DIR . 'random.lua'
		execute 'luafile ' . s:FILE_DIR . 'ring.lua'
		execute 'luafile ' . s:FILE_DIR . 'room.lua'
		execute 'luafile ' . s:FILE_DIR . 'save.lua'
		execute 'luafile ' . s:FILE_DIR . 'score.lua'
		execute 'luafile ' . s:FILE_DIR . 'spechit.lua'
		execute 'luafile ' . s:FILE_DIR . 'throw.lua'
		execute 'luafile ' . s:FILE_DIR . 'trap.lua'
		execute 'luafile ' . s:FILE_DIR . 'use.lua'
		execute 'luafile ' . s:FILE_DIR . 'util.lua'
		execute 'luafile ' . s:FILE_DIR . 'zap.lua'
	endif

	silent edit `='Rogue-clone II'`
	silent only
	nohlsearch
	setl ts=8 et
	setl nonumber
	setl norelativenumber
	setl nolist
	setl buftype=nofile
	setl noswapfile
	setl bufhidden=wipe
	setl nowrap
	setl nocursorline
	setl nocursorcolumn
	setl foldcolumn=0
	setl conceallevel=3
	setl concealcursor=n
	let save_cpo        = &cpo
	let s:save_encoding = &encoding
	let save_ruler      = &ruler
	let save_showmode   = &showmode
	let save_showcmd    = &showcmd
	let save_showmatch  = &showmatch
	let save_cmdheight  = &cmdheight
	let save_laststatus = &laststatus
	let save_more       = &more
	let save_guicursor  = &guicursor
	set cpo&vim
	let &encoding   = 'utf-8'
	let &ruler      = 0
	let &showmode   = 0
	let &showcmd    = 0
	let &showmatch  = 0
	let &cmdheight  = 1
	let &laststatus = 0
	let &more       = 0
	let &guicursor  = 'a:hor1-Ignore-blinkon0'
	if (!exists("g:rogue#color") || g:rogue#color)
		setl filetype=rogue
	endif

	let s:args = a:args
	execute 'lua Rogue.main()'

	let &cpo        = save_cpo
	let &encoding   = s:save_encoding
	let &ruler      = save_ruler
	let &showmode   = save_showmode
	let &showcmd    = save_showcmd
	let &showmatch  = save_showmatch
	let &cmdheight  = save_cmdheight
	let &laststatus = save_laststatus
	let &more       = save_more
	let &guicursor  = save_guicursor
	bdelete
endfunction

