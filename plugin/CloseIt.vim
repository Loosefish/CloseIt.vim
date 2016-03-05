" Configuration {{{ "
if !exists("g:CloseItTrigger")
	let g:CloseItTrigger = "<S-SPACE>"
endif
execute "inoremap " . g:CloseItTrigger . " <C-\\><C-o>:call <SID>CloseItAuto()<CR>"

let s:defaultClosers = { '(': ')', '{': '}', '[': ']' }
" }}} Configuration "


function! s:CloseItAuto() " {{{1 "
	if exists("b:CloseItPairs")
		let s:closers = b:CloseItPairs
	elseif exists("g:CloseItPairs")
		let s:closers = g:CloseItPairs
	else
		let s:closers = s:defaultClosers
	endif
	let s:openPattern = '\M' . join(keys(s:closers), '\|')

	" Check if cursor is inside a string
	if col('.') ==# col('$')
		let inString = s:isStringEx(line('.'), col('.') - 1)
	else
		let inString = s:isStringEx(line('.'), col('.'))
	endif
	if inString
		return s:CloseItInString()
	else
		return s:CloseIt()
	endif
endfunction " 1}}}


function! s:CloseIt() " {{{1
	let startview = winsaveview()
	let startpos = getcurpos()

	let until = max([0, startview['lnum'] - 1024])
	while search(s:openPattern, 'Wb', until) > 0
		if !s:isClosed(startpos[1], startpos[2], 's:isString()') && !s:isString()
			call s:insertCloser(startview)
			return 1
		endif
	endwhile
	call winrestview(startview)
	return 0
endfunction " 1}}}


function! s:CloseItInString() " {{{1
	let startview = winsaveview()
	let startpos = getcurpos()

	while search(s:openPattern, 'Wb') > 0
		if !s:isString()
			break
		endif
		if !s:isClosed(startpos[1], startpos[2], '!s:isString()')
			call s:insertCloser(startview)
			return 1
		endif
	endwhile
	" no pending opener inside strings - try regular
	call winrestview(startview)

	if s:CloseIt()
		" since the opener is not part of a string we remove the inserted char
		" if it is inside a string
		let inString = s:isStringEx(line('.'), col('.'))

		if inString
			if col('.') ==# col('$') - 1
				normal! x
			else
				normal! X
			endif
			call winrestview(startview)
			return 0
		else
			return 1
		endif
	endif
endfunction " 1}}}


function! s:isClosed(beforeline, beforecol, skip) " {{{1
	let startview = winsaveview()
	let opener = getline('.')[col('.') - 1]
	let [mline, mcol] = searchpairpos('\M' . opener, '', '\M' . s:closers[opener], 'W', a:skip, a:beforeline)
	if [mline, mcol] ==# [0, 0]
		let closed = 0
	elseif mline ==# a:beforeline
		let closed = mcol <= a:beforecol
	else
		let closed = mline <= a:beforeline
	endif
	call winrestview(startview)
	return closed
endfunction " 1}}}


function! s:insertCloser(startview) " {{{1
	let closeChar = s:closers[getline(".")[col(".") - 1]]
	if col('.') + 1 ==# col('$') && a:startview['lnum'] !=# line('.')
		let closeChar = "\<CR>" . closeChar
	endif
	call winrestview(a:startview)
	if a:startview['col'] == 0 && col('$') == 1  " Empty line
		execute 'normal! a' . closeChar . "\<ESC>$"
	elseif a:startview['col'] == col('$') - 1  " End of line
		execute 'normal! a' . closeChar . "\<ESC>$"
	else
		execute 'normal! i' . closeChar . "\<RIGHT>"
	endif
endfunction " 1}}}


function! s:isString() " {{{1
	return synIDattr(synID(line("."), col("."), 0), "name") =~? "string"
endfunction " 1}}}


function! s:isStringEx(l, c) " {{{1
	return synIDattr(synID(a:l, a:c, 0), "name") =~? "string"
endfunction " 1}}}
