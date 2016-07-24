# CloseIt.vim #
Smart, semi-automatic insertion of closing parentheses, braces, etc.

`x = ((3 + 2) * (4 + 9<CURSOR>` *\<CloseIt\>*

`x = ((3 + 2) * (4 + 9)<CURSOR>` *\<CloseIt\>* 

`x = [(3 + 2) * (4 + 9)]<CURSOR>`

When triggering *CloseIt* the last opening character without a matching closing character (before the cursor) will be located. If such a character can be found the corresponding closing character will be inserted.

If the opening character is at the end of a line a line break will be inserted as well.
```
int main () {
	return 0;<CURSOR>
```
*\<CloseIt\>*
```
int main () {
	return 0;
}<CURSOR>
```

Strings are handled automatically: if you trigger *CloseIt* while editing a string only opening characters in other strings are considered and vice versa.

Note: This can get wonky with multi-char string delimiters (`"""`) and nested delimiters (`"Foo 'bar' baz"`).

## Configuration ##
Create an insert mode binding for `<Plug>CloseIt`.
```
imap <S-SPACE> <Plug>CloseIt
```

CloseIt uses matching pairs defined in `&matchpairs`, usually set by a file type plugin. But you can easily define your own global or buffer local pairs.
```
set matchpairs="<:>"
setlocal matchpairs="^:$"
```
