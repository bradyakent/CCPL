local _p = settings.get("ccpl.path")
local slots = require(_p.."ccpl.apis.slots")

--performs floor division
local function fdiv(top, bottom)
    return (top - (top%bottom)) / bottom
end

--moves turtle a specified distance forward
local function forward(distance)
    for i=1,distance do
        turtle.forward()
    end
end

local function handleCrop(forcePlant)
    local exists, info = turtle.inspectDown()
    if exists then
        if info.state.age == 7 then
            turtle.digDown()
        else
            return
        end
    elseif forcePlant == nil then
        return
    end
    while turtle.placeDown() == false do
        turtle.select(((turtle.getSelectedSlot())%16)+1)
    end
end

local function farm(x, y)
    x = tonumber(x)
    y = tonumber(y)
    turtle.forward()
    for i=1,x do
        for j=1,y do
            handleCrop()
            if j < y then turtle.forward() end
        end
        if i < x then
            if i%2 == 1 then
                turtle.turnRight()
                turtle.forward()
                turtle.turnRight()
            else
                turtle.turnLeft()
                turtle.forward()
                turtle.turnLeft()
            end
        end
    end
    if y%2 == 1 then
        turtle.turnLeft()
        turtle.turnLeft()
        forward(y-1)
    end
    turtle.turnRight()
    forward(x-1)
    turtle.turnRight()
    turtle.back()
    for i=1,16 do
        turtle.select(i)
        turtle.dropDown()
    end
end

local function createFarm(x, y)
    x = tonumber(x)
    y = tonumber(y)
    --error checking
    if x == 0 or y == 0 then
        error("Farm dimensions must be greater than 0",2)
    end

    local plotsX = fdiv(x-1,9)+1
    local plotsY = fdiv(y-1,9)+1
    local offsetX = fdiv((x-1)%9,2)
    local offsetY = fdiv((y-1)%9,2)
    local plots = plotsX * plotsY
    local cropSpaces = (x*y) - plots
    local pStacks = fdiv(cropSpaces,64)
    local pNonfill = cropSpaces%64
    
    --allow the user to bypass warnings about a farm too big
    if plots > 15 then
        printError("Warning: the turtle cannot hold enough buckets, would you like to continue? (yes/no)")
        if read() ~= "yes" then
            error("Farm creation exited",2)
        end
    end
    if plots + pStacks + 2 > 16 then
        printError("Warning: the turtle doesn't have enough space for all the plantable items, would you like to continue? (yes/no)")
        if read() ~= "yes" then
            error("Farm creation exited",2)
        end
    end

    --display slots to user
    local items = {
        {name="Chest",amount=1},
    }
    for i=1,plots do
        items[#items+1] = {name="Water Bucket",amount=1}
    end
    for i=1,pStacks do
        items[#items+1] = {name="Plantable item",amount=64}
    end
    items[#items+1] = {name="Plantable item",amount=pNonfill}
    slots.displaySlots(items)

    --place chest
    turtle.up()
    turtle.select(1)
    turtle.placeDown()
    turtle.forward()

    --place water
    local waterUsed = 0
    forward(offsetY)
    turtle.turnRight()
    forward(offsetX)
    turtle.down()
    for j=1,plotsY do
        turtle.digDown()
        turtle.select(waterUsed + 2)
        turtle.placeDown()
        waterUsed = waterUsed + 1
        for i=1,plotsX-1 do
            forward(9)
            turtle.digDown()
            turtle.select(waterUsed + 2)
            turtle.placeDown()
            waterUsed = waterUsed + 1
        end
        if j<plotsY then
            if j%2==1 then
                turtle.turnLeft()
                forward(9)
                turtle.turnLeft()
            else
                turtle.turnRight()
                forward(9)
                turtle.turnRight()
            end
        end
    end

    --return to chest corner
    turtle.up()

    if plotsY%2 == 1 then
        turtle.turnRight()
        turtle.turnRight()
        forward(9*(plotsX-1))
    end
    forward(offsetX)
    turtle.turnLeft()

    forward((9*(plotsY-1))+offsetY)
    turtle.turnRight()
    turtle.turnRight()

    --till land
    for i=1,x do
        for j=1,y do
            if turtle.digDown() then
                handleCrop(true)
            end
            if j < y then turtle.forward() end
        end
        if i < x then
            if i%2 == 1 then
                turtle.turnRight()
                turtle.forward()
                turtle.turnRight()
            else
                turtle.turnLeft()
                turtle.forward()
                turtle.turnLeft()
            end
        end
    end
    if y%2 == 1 then
        turtle.turnLeft()
        turtle.turnLeft()
        forward(y-1)
    end
    turtle.turnRight()
    forward(x-1)
    turtle.turnRight()
    turtle.back()
end

return {
    createFarm = createFarm,
    farm = farm
}