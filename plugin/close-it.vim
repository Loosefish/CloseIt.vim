if !exists("g:CloseItTrigger")
	let g:CloseItTrigger = "<S-SPACE>"
endif
execute "inoremap " . g:CloseItTrigger . " <C-\\><C-o>:call <SID>CloseIt()<CR>"


if exists("g:CloseItPairs")
	let s:closers = g:CloseItPairs
else
	let s:closers = { '(': ')', '{': '}', '[': ']' }
endif
let s:openPattern = '\M' . join(keys(s:closers), '\|')


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


function! s:Closed(beforeline, beforecol) " {{{1
	let startview = winsaveview()
	let opener = getline('.')[col('.') - 1]
	let [mline, mcol] = searchpairpos( '\M' . opener, '', '\M' . s:closers[opener], 'W', 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string"')
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
