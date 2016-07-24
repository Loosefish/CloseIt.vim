" CloseIt.vim
" Description: Smart, semi-automatic insertion of closing parentheses, braces, etc.
" Author: Loosefish
" Homepage: https://github.com/Loosefish
" License: MIT

if !has("lua")
    echoerr "CloseIt.vim requires Lua (:help +lua)!"
    finish
end
if exists("g:loaded_CloseIt")
    finish
endif
let g:loaded_CloseIt = 1

execute 'luafile ' . expand('<sfile>:p:h') . '/CloseIt.lua'


function! s:CloseIt()
    let closer = luaeval('find_closer(' . line('.') . ',' . col('.') . ',true)')
    if type(closer) == 0
        return ''
    endif
    return closer
endfunction


imap <unique><expr> <Plug>CloseIt <SID>CloseIt()
