inoremap <S-SPACE> <C-\><C-o>:call <SID>CloseIt()<CR>

let s:closers = { '(': ')', '{': '}', '[': ']' }
let s:openersEscaped = { '(': '(', '{': '{', '[': '\[' }
let s:closersEscaped = { '(': ')', '{': '}', '[': '\]' }
let s:openPattern = join(values(s:openersEscaped), '\|')

function! s:CloseIt() " {{{1
	let startview = winsaveview()
	let startpos = getcurpos()

	while search(s:openPattern, 'Wb') > 0
		if !s:Closed(startpos[1], startpos[2]) && synIDattr(synID(line("."), col("."), 0), "name") !~? "string"
			let closeChar = s:closers[getline(".")[col(".") - 1]]
			if col('.') + 1 ==# col('$')
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
	let [mline, mcol] = searchpairpos(s:openersEscaped[opener], '', s:closersEscaped[opener], 'W', 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string"')
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
