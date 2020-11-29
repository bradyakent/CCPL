local blitLookup = {}
for i = 0, 15 do
    blitLookup[2 ^ i] = string.format("%x", i)
end

local width, height = term.getSize()

local String = setmetatable({0=""}, {__index=function(table, key)
    return table.string:sub(key,key)
end })

function String:set(newString)
    self[0] = newString
end

local buffer = 

for i=1,3 do
    buffer[i] = String
end
for j=1,height do
    buffer[1][j] = (" "):rep(width)
    buffer[2][j] = blitLookup[colors.white]:rep(width)
    buffer[3][j] = blitLookup[colors.black]:rep(width)
end

-- draws the current buffer
local function render()
    for i=1,height do
        term.blit(buffer[1][i],buffer[2][i],buffer[3][i])
    end
end

-- sets character at (x, y) to t, changing the text color to tc and the background color to bc
local function setCharacter(x, y, t, tc, bc)
    buffer[1][y][x] = t
    buffer[2][y][x] = blitLookup[tc]
    buffer[3][y][x] = blitLookup[bc]
end

-- sets line y's buffer string to t, changing the text color to tc and the background color to bc
local function setLine(line, t, tc, bc)
    if type(tc) ~= "number" and type(tc) ~= "string" then error("expecting string or number, got "..type(tc), 2) end
    if type(bc) ~= "number" and type(bc) ~= "string" then error("expecting string or number, got "..type(bc), 2) end
    if type(tc) == "number" then
        tc = blitLookup[tc]:rep(width)
    end
    if type(bc) == "number" then
        bc = blitLookup[bc]:rep(width)
    end
    buffer[1][line] = t
    buffer[2][line] = tc
    buffer[3][line] = bc
end

local function setRect(x, y, t, tc, bc)