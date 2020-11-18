local function forward(distance, dig)
    if distance == nil then
        distance = 1
    end
    for _=1,distance do
        if dig == true then
            while turtle.detect() do
                turtle.dig()
            end
        end
        turtle.forward()
    end
end

local function back(distance)
    if distance == nil then
        distance = 1
    end
    for _=1,distance do
        turtle.back()
    end
end

local function up(distance, dig)
    if distance == nil then
        distance = 1
    end
    for _=1,distance do
        if dig == true then
            while turtle.detectUp() do
                turtle.digUp()
            end
        end
        turtle.up()
    end
end

local function down(distance, dig)
    if distance == nil then
        distance = 1
    end
    for _=1,distance do
        if dig == true then
            while turtle.detectDown() do
                turtle.digDown()
            end
        end
        turtle.down()
    end
end

local function left()
    turtle.turnLeft()
end

local function right()
    turtle.turnRight()
end

local function turnAround()
    turtle.turnLeft()
    turtle.turnLeft()
end

-- can take a string or table of strings
local function findStack(items)
    if type(items) ~= "table" then items = { items } end
    for i=1,16 do
        local slot = turtle.getItemDetail(i)
        for _, item in ipairs(items) do
            if slot == item then
                return i
            end
        end
    end
    return nil
end

local tex = {
    forward = forward,
    back = back,
    up = up,
    down = down,
    left = left,
    right = right,
    turnAround = turnAround,
    findStack = findStack
}
for f, v in pairs(turtle) do
    print(f)
    print(v)
    if tex[f] == nil then
        tex[f] = v
    end
end

return tex