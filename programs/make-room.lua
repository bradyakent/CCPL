local tex, ux = require("ccpl")("tex","ux")

local args = { ... }

local width = tonumber(args[1])
local height = tonumber(args[2])
local depth = tonumber(args[3])

local usage = {
    {"width",{"height","depth"}}
}

local function fdiv(top, bottom)
    return (top - (top%bottom)) / bottom
end

if #args ~= 3 or type(width) ~= "number" or type(height) ~= "number" or type(depth) ~= "number" then
    ux.displayUsage("make-room",usage)
    do return end
end

local half = fdiv(width, 2)

tex.forward(1,true)
tex.left()
tex.forward(half,true)
tex.right()

for instruction in tex.vPath(width, height, depth) do
    if instruction == "up" then
        tex.up(1, true)
    elseif instruction == "left" then
        tex.left()
        tex.forward(1, true)
    elseif instruction == "right" then
        tex.right()
        tex.forward(1, true)
    elseif instruction == "forward" then
        tex.forward(1, true)
    elseif instruction == "back" then
        tex.turnAround()
        tex.forward(1, true)
    end
end
tex.down(height-1)