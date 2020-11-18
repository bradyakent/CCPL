local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.tex")

local function fdiv(top, bottom)
    return (top - (top%bottom)) / bottom
end

print("Enter width of the room:")
local width = tonumber(read())
print("Enter depth of the room:")
local depth = tonumber(read())
print("Enter height of the room:")
local height = tonumber(read())

local half = fdiv(width, 2)

tex.forward(1,true)
tex.left()
tex.forward(half,true)
tex.turnAround()

for y = 1, height do
    for x = 1, depth do
        tex.forward(width-1,true)
        if x < depth then
            if depth % 2 == 0 and y % 2 == 0 then
                if x % 2 == 1 then
                    tex.right()
                    tex.forward(1,true)
                    tex.right()
                else
                    tex.left()
                    tex.forward(1,true)
                    tex.left()
                end
            else
                if x % 2 == 1 then
                    tex.left()
                    tex.forward(1,true)
                    tex.left()
                else
                    tex.right()
                    tex.forward(1,true)
                    tex.right()
                end
            end
        end
    end
    if y < height then
        tex.turnAround()
        tex.up(1,true)
    end
end