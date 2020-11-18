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
        if not turtle.forward() then
            return false
        end
    end
    return true
end

local function back(distance)
    if distance == nil then
        distance = 1
    end
    for _=1,distance do
        if not turtle.back() then
            return false
        end
    end
    return true
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
        if not turtle.up() then
            return false
        end
    end
    return true
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
        if not turtle.down() then
            return false
        end
    end
    return true
end

local function left()
    return turtle.turnLeft()
end

local function right()
    return turtle.turnRight()
end

local function turnAround()
    if turtle.turnLeft() and turtle.turnLeft() then
        return true
    end
    return false
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