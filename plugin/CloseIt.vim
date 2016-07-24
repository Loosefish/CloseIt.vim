execute 'luafile ' . expand('<sfile>:p:h') . '/CloseIt.lua'

" Configuration
if !exists('g:CloseItTrigger')
	let g:CloseItTrigger = "<S-SPACE>"
endif
execute "inoremap <expr> " . g:CloseItTrigger ." <SID>CloseItLua()"


function! s:CloseItLua()
    let closer = luaeval('find_closer(' . line('.') . ',' . col('.') . ',true)')
    if type(closer) == 0
        return ''
    endif
    return closer
endfunction


