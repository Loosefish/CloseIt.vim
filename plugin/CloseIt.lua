-- Knowing if a closing char would be part of a string can be tricky.
-- Not possible without a list of delimiters per language?
-- What about delimiters with multiple chars?
--
-- One could initially insert a char in vim and check it's class (BARF!).
-- Or call a second function after insertion which checks (also BARF!).
--
-- How it works now:
-- s String
-- " Delimiter
-- x Not string
-- _ End of line (nothing)
-- | Cursor (column = position of second char)
-- ^ Beginning of line
--
-- s|s  -> true +
-- s|"  -> true +
-- s|x  -> true (eg. bash var in "")
-- s|_  -> true +
--
-- "|s  -> true +
-- "|"  -> true +
-- "|x  -> false +
-- "|_  -> !is_string(line, col - 1) +
--
-- x|s  -> false
-- x|"  -> false +
-- x|x  -> false +
-- x|_  -> false +
--
-- ^|s  -> true +
-- ^|"  -> false + better: check end of prev. line
-- ^|x  -> false +
-- ^|_  -> false +

local all = "([%(%)%[%]%{%}])"
local open = {['['] = ']'; ['{'] = '}'; ['('] = ')'}
local string_pattern = "[sS][tT][rR][iI][nN][gG]"
local string_delim_pattern = "[qQ][uU][oO][tT][eE]"
local string_delim = "[\"']"

-- For some languages it's better to ignore strings
local ignore_strings = false
local blacklist = { sh=true, terraform=true }

-- Char types enum
local STRING = 0
local DELIM = 1
local END = 2
local OTHER = 3


-- Build search pattern and matching pairs from vim "&matchpairs"
function setup(args)
    -- TODO: Can we keep buffer local state in lua somehow?
    all = "(["
    open = {}
    iter = string.gmatch(vim.eval("&matchpairs"), "(.):(.),?")
    for o,c in iter do
        all = all .. "%" .. o .. "%" .. c
        open[o] = c
    end
    all = all .. "])"

    if blacklist[vim.eval("&filetype")] then
        ignore_strings = true
    end
end


function char_type(line, col)
    local syn_name = vim.eval('synIDattr(synID(' .. line .. ',' .. col .. ', 0), "name")')

    if syn_name == "" then
        return END

    elseif syn_name:find(string_pattern) then
        if string.sub(vim.window().buffer[line], col, col):find(string_delim) then
            return DELIM
        end
        return STRING

    -- For Python (maybe guard?)
    elseif syn_name:find(string_delim_pattern) then
        return DELIM
    end

    return OTHER
end


local function is_string(line, col)
    if ignore_strings then
        return false
    elseif col > 1 then
        local pre = char_type(line, col - 1)
        if pre == OTHER or pre == END then
            return false
        elseif pre == STRING then
            return true
        else  -- pre == DELIM
            local this = char_type(line, col)
            if this == STRING or this == DELIM then
                return true
            elseif this == END then
                return not is_string(line, col - 1)
            else
                return false
            end
        end
    end

    return char_type(line, col) == STRING
end


-- Seach the given line for a pending opener.
-- Stops if unbalanced pairs are encountered.
-- Otherwise continues with the previous line.
--
-- line: number of current line
-- col: number of column in line from where to start searching (may be nil)
-- in_string: if search started inside a string (boolean)
-- stack: table of encountered closers
-- autoline: number of starting line (should only be set to get auto newline)
local function find_in_line(line, col, in_string, stack, autoline)
    local rev = string.reverse(vim.window().buffer[line])

    if col then
        col = #rev + 1 - col
    else
        col = 1
    end

    while true do
        local i, _, char = string.find(rev, all, col)
        if i then
            col = i + 1
            -- only process match if same as original
            if in_string == is_string(line, #rev + 1 - i) then
                if open[char] ~= nil then
                    -- found opener -> check stack
                    if #stack == 0 then
                        -- stack empty -> done
                        if autoline and i == 1 and line ~= autoline then
                            return "\r" .. open[char]
                        else
                            return open[char]
                        end
                    elseif stack[#stack] == open[char] then
                        -- matches top -> pop
                        stack[#stack] = nil
                    else
                        -- no match -> unbalanced expression
                        return nil
                    end
                else
                    -- found closer -> push
                    stack[#stack + 1] = char
                end
            end
        elseif line > 1 then
            -- check previous line
            return find_in_line(line - 1, nil, in_string, stack, autoline)
        else
            -- no more lines
            return nil
        end
    end
end


-- Returns a closer for the nearest pending opener. If autoline is set and the
-- pending opener is last in its' line a linebreak will be inserted as well.
function find_closer(line, col, autoline)
    setup()
    if autoline then
        autoline = line
    else
        autoline = nil
    end
    local in_string = is_string(line, col)

    if col > 1 then
        return find_in_line(line, col - 1, in_string, {}, autoline)
    elseif line > 1 then
        return find_in_line(line - 1, nil, in_string, {}, autoline)
    end
    return nil
end


-- For benchmarking.
function measure(line, col, autoline)
    local start = os.clock()
    local res = find_closer(line, col, autoline)
    print(os.clock() - start)
    return res
end
