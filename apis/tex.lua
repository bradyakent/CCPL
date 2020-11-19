local function forward(distance, dig)
    if distance == nil then
        distance = 1
    end
    for _=1,distance do
        if dig == true then
            while turtle.detect() do
                local res, reason = turtle.dig()
                if not res then
                    return res, reason
                end
            end
        end
        local res, reason = turtle.forward()
        if not res then
            return res, reason
        end
    end
    return true
end

local function back(distance)
    if distance == nil then
        distance = 1
    end
    for _=1,distance do
        local res, reason = turtle.back()
        if not res then
            return res, reason
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
        local res, reason = turtle.up()
        if not res then
            return res, reason
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
        local res, reason = turtle.down()
        if not res then
            return res, reason
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
        if turtle.getItemDetail(i) then
            local slot = turtle.getItemDetail(i).name
            for _, item in ipairs(items) do
                if slot == item then
                    return i
                end
            end
        end
    end
    return nil
end

local function dropAll()
    local currentSlot = turtle.getSelectedSlot()
    for i=1,16 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(currentSlot)
end

local function dropAllDown()
    local currentSlot = turtle.getSelectedSlot()
    for i=1,16 do
        turtle.select(i)
        turtle.dropDown()
    end
    turtle.select(currentSlot)
end

local function dropAllUp()
    local currentSlot = turtle.getSelectedSlot()
    for i=1,16 do
        turtle.select(i)
        turtle.dropUp()
    end
    turtle.select(currentSlot)
end

-- creates a path iterator through a volume
local function vPath(width, height, depth)
    local dirs = {"forward", "left", "right", "up"}
    local dt = 1
    local wt = 1
    local ht = 1
    return function()
        if ht == height and wt == width and dt == depth then
            return nil
        end
        if dt == depth then
            dt = 1
            if wt == width then
                wt = 1
                ht = ht + 1
                return dirs[4]
            end
            --if width is even, flip turn direction at every even height
            --if wt % 2 == 1, turn right, else turn left
            
            if (width%2 == 0 and ht % 2 == 0) and (wt%2 == 0) or (wt%2 == 1) then
                wt = wt + 1
                return dirs[3]
            else
                wt = wt + 1
                return dirs[2]
            end
        end
        dt = dt + 1
        return dirs[1]
    end
end

local tex = {
    forward = forward,
    back = back,
    up = up,
    down = down,
    left = left,
    right = right,
    turnAround = turnAround,
    findStack = findStack,
    dropAll = dropAll,
    dropAllDown = dropAllDown,
    dropAllUp = dropAllUp,
    vPath = vPath
}

for f, v in pairs(turtle) do
    if tex[f] == nil then
        tex[f] = v
    end
end

return tex