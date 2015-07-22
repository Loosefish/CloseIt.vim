if !exists("g:CloseItTrigger")
	let g:CloseItTrigger = "<S-SPACE>"
endif
execute "inoremap " . g:CloseItTrigger . " <C-\\><C-o>:call <SID>CloseItAuto()<CR>"


if exists("g:CloseItPairs")
	let s:closers = g:CloseItPairs
else
	let s:closers = { '(': ')', '{': '}', '[': ']' }
endif
let s:openPattern = '\M' . join(keys(s:closers), '\|')


function! s:CloseItAuto() " {{{1 "
	if col('.') ==# col('$')
		let inString = s:isStringEx(line('.'), col('.') - 1)
	else
		let inString = s:isStringEx(line('.'), col('.'))
	endif
	if inString
		echom "String"
		call s:CloseItInString()
	else
		echom "No string"
		call s:CloseIt()
	endif
endfunction " 1}}}


function! s:CloseIt() " {{{1
	let startview = winsaveview()
	let startpos = getcurpos()

	while search(s:openPattern, 'Wb') > 0
		if !s:Closed(startpos[1], startpos[2]) && !s:isString()
			let closeChar = s:closers[getline(".")[col(".") - 1]]
			if col('.') + 1 ==# col('$')	" TODO: and EOL not at start pos
				let closeChar = 'o' . closeChar
			endif
			call winrestview(startview)
			if col('.') == col('$') && col('.') != 1
				execute 'normal! a' . closeChar . '$'
			else
				execute 'normal! ha' . closeChar . 'l'
			endif
			return
		endif
	endwhile
	call winrestview(startview)
endfunction " 1}}}


function! s:CloseItInString() " {{{1
	let startview = winsaveview()
	let startpos = getcurpos()

	while search(s:openPattern, 'Wb') > 0
		if !s:isString()
			break
		endif
		if !s:ClosedInString(startpos[1], startpos[2])
			let closeChar = s:closers[getline(".")[col(".") - 1]]
			if col('.') + 1 ==# col('$')	" TODO: and EOL not at start pos
				let closeChar = 'o' . closeChar
			endif
			call winrestview(startview)
			if col('.') == col('$') && col('.') != 1
				execute 'normal! a' . closeChar . '$'
			else
				execute 'normal! ha' . closeChar . 'l'
			endif
			return
		endif
	endwhile
	call winrestview(startview)
endfunction " 1}}}


function! s:ClosedInString(beforeline, beforecol) " {{{1
	let startview = winsaveview()
	let opener = getline('.')[col('.') - 1]
	let [mline, mcol] = searchpairpos( '\M' . opener, '', '\M' . s:closers[opener], 'W')
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


function! s:Closed(beforeline, beforecol) " {{{1
	let startview = winsaveview()
	let opener = getline('.')[col('.') - 1]
	let [mline, mcol] = searchpairpos( '\M' . opener, '', '\M' . s:closers[opener], 'W', 's:isString()')
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


function! s:isString() " {{{1
	return synIDattr(synID(line("."), col("."), 0), "name") =~? "string"
endfunction " 1}}}

function! s:isStringEx(l, c) " {{{1
	return synIDattr(synID(a:l, a:c, 0), "name") =~? "string"
endfunction " 1}}}
