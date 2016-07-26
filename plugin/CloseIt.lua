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
-- s|x  -> true (ex. bash var in "")
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
local string_delim = "[\"']"

-- Char types enum
local STRING = 0
local DELIM = 1
local END = 2
local OTHER = 3


function setup(args)
    -- Can we keep buffer local state in lua somehow?
    all = "(["
    open = {}
    iter = string.gmatch(vim.eval("&matchpairs"), "(.):(.),?")
    for o,c in iter do
        all = all .. "%" .. o .. "%" .. c
        open[o] = c
    end
    all = all .. "])"
end


function char_type(line, col)
    local syn_name = vim.eval('synIDattr(synID(' .. line .. ',' .. col .. ', 0), "name")')

    if syn_name == "" then
        return END
    end

    if syn_name:find(string_pattern) then
        if string.sub(vim.window().buffer[line], col, col):find(string_delim) then
            return DELIM
        end
        return STRING
    end

    return OTHER
end


local function is_string(line, col)
    if col > 1 then
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
                            return "\" .. open[char]
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


function measure(line, col, autoline)
    local start = os.clock()
    local res = find_closer(line, col, autoline)
    print(os.clock() - start)
    return res
end
