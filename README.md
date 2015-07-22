# CloseIt.vim #
Smart insertion of closing characters from insert mode.

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

Strings are handled automatically: if you try trigger *CloseIt* while editing a string only opening characters in other strings are considered and vice versa.\
Note: Support depends on the syntax file for the current file type and works best if the syntax definition differentiates between string delimiters and the actual strings.
## Configuration ##
The Default key combination is *shift + space*, you can change it by setting `g:CloseItTrigger`:
```
let g:CloseItTrigger = "<F5>"
```

By default the following pairs are recognized:
| Opener | Closer |
| ------ | ------ |
| `(`    | `)`    |
| `[`    | `]`    |
| `{`    | `}`    |

Define your own pairs by setting `g:CloseItPairs`:
```
let g:CloseItPairs = { '(': ')', '{': '}', '<': '>' }
```

Buffer local pairs are supported as well, just use `b:CloseItPairs`.

Note: If the opening and closing characters are the same (e. g. `"`) the plugin will mistake closing characters for openings.
