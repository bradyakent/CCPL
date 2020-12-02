local ux,tex = require("/ccpl")("ux","tex")

local plantableList = {
    "minecraft:wheat_seeds",
    "minecraft:potato",
    "minecraft:carrot",
    "minecraft:beetroot_seeds"
}

--performs floor division
local function fdiv(top, bottom)
    return (top - (top%bottom)) / bottom
end

local function handleCrop(forcePlant)
    local exists, info = tex.inspectDown()
    if exists then
        if info.state.age == 7 then
            tex.digDown()
        else
            return
        end
    elseif forcePlant == nil then
        return
    end
    local slot = tex.findStack(plantableList)
    if slot then
        tex.select(slot)
        tex.placeDown()
    end
end

local function farm(x, y)
    x = tonumber(x)
    y = tonumber(y)
    tex.forward()
    for i=1,x do
        for j=1,y do
            handleCrop()
            if j < y then tex.forward() end
        end
        if i < x then
            if i%2 == 1 then
                tex.turnRight()
                tex.forward()
                tex.turnRight()
            else
                tex.turnLeft()
                tex.forward()
                tex.turnLeft()
            end
        end
    end
    if y%2 == 1 then
        tex.turnAround()
        tex.forward(y-1)
    end
    tex.turnRight()
    tex.forward(x-1)
    tex.turnRight()
    tex.back()
    tex.dropAllDown()
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
        if not ux.confirm("Warning: the turtle cannot hold enough buckets, would you like to continue?", colors.yellow) then
            error("farm creation exited",2)
        end
    end
    if plots + pStacks + 2 > 16 then
        if not ux.confirm("Warning: the turtle doesn't have enough space for all the plantable items, would you like to continue?", colors.yellow) then
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
    ux.displaySlots(items)

    --place chest
    tex.up()
    tex.select(1)
    tex.placeDown()
    tex.forward()

    --place water
    local waterUsed = 0
    tex.forward(offsetY)
    tex.turnRight()
    tex.forward(offsetX)
    turtle.down()
    for j=1,plotsY do
        tex.digDown()
        tex.select(waterUsed + 2)
        tex.placeDown()
        waterUsed = waterUsed + 1
        for i=1,plotsX-1 do
            tex.forward(9)
            tex.digDown()
            tex.select(waterUsed + 2)
            tex.placeDown()
            waterUsed = waterUsed + 1
        end
        if j<plotsY then
            if j%2==1 then
                tex.turnLeft()
                tex.forward(9)
                tex.turnLeft()
            else
                tex.turnRight()
                tex.forward(9)
                tex.turnRight()
            end
        end
    end

    --return to chest corner
    tex.up()

    if plotsY%2 == 1 then
        tex.turnAround()
        tex.forward(9*(plotsX-1))
    end
    tex.forward(offsetX)
    tex.turnLeft()

    tex.forward((9*(plotsY-1))+offsetY)
    tex.turnAround()

    --till land
    for i=1,x do
        for j=1,y do
            if tex.digDown() then
                handleCrop(true)
            end
            if j < y then tex.forward() end
        end
        if i < x then
            if i%2 == 1 then
                tex.turnRight()
                tex.forward()
                tex.turnRight()
            else
                tex.turnLeft()
                tex.forward()
                tex.turnLeft()
            end
        end
    end
    if y%2 == 1 then
        tex.turnAround()
        tex.forward(y-1)
    end
    tex.turnRight()
    tex.forward(x-1)
    tex.turnRight()
    tex.back()
    tex.dropAllDown()
end

return {
    createFarm = createFarm,
    farm = farm
}