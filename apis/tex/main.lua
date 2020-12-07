if not turtle then return nil end
local LPS = require("/ccpl")("tex.lps")

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
        else
            LPS.forward()
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
        else
            LPS.back()
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
        else
            LPS.up()
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
        else
            LPS.down()
        end
    end
    return true
end

local function left()
    LPS.left()
    return turtle.turnLeft()
end

local function right()
    LPS.right()
    return turtle.turnRight()
end

local function turnAround()
    LPS.left()
    LPS.left()
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
    local dirs = {"forward", "left", "right", "up", "back"}
    local depthTravelled = 1
    local widthTravelled = 1
    local heightTravelled = 1
    local shiftRight = false
    local shiftLeft = false
    local goBack = false
    return function()
        --the turtle has been through every block
        if heightTravelled == height and widthTravelled == width and depthTravelled == depth then
            return nil
        end

        --if either of these flags are true, the turtle is in the middle of shifting columns
        --that means the turtle will turn, then move forward along the depth axis
        --therefore, dt must be incremented by 1
        if shiftRight == true then
            depthTravelled = depthTravelled + 1
            shiftRight = false
            return dirs[3]
        elseif shiftLeft == true then
            depthTravelled = depthTravelled + 1
            shiftLeft = false
            return dirs[2]
        elseif goBack == true then
            depthTravelled = depthTravelled + 1
            goBack = false
            return dirs[5]
        end

        --if the turtle has reached the end of a column
        if depthTravelled == depth then
            --reset dt; the turtle is starting on a new column
            depthTravelled = 1
            --if the turtle has reached the end of a layer
            if widthTravelled == width then
                goBack = true
                --reset the width travelled
                widthTravelled = 1
                --go to the next layer
                heightTravelled = heightTravelled + 1
                return dirs[4]
            end
            --if the turtle is in the middle of a layer, shift columns
            --if width is even, flip turn direction at every even height
            --if wt % 2 == 1, turn right, else turn left
            local flip = (width%2 == 0 and heightTravelled % 2 == 0)
            if (widthTravelled%2 == 0 and flip) or (widthTravelled%2 == 1 and not flip) then
                shiftRight = true
                widthTravelled = widthTravelled + 1
                return dirs[3]
            else
                shiftLeft = true
                widthTravelled = widthTravelled + 1
                return dirs[2]
            end
        end
        depthTravelled = depthTravelled + 1
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
    vPath = vPath,
    getPosition = LPS.getPosition,
    getDirection = LPS.getDirection,
    newBounds = LPS.newBounds
}

for f, v in pairs(turtle) do
    if tex[f] == nil then
        tex[f] = v
    end
end

return tex