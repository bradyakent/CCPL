local tex = require("/ccpl")("tex")

local checked = {}
local mined = {}

local function alreadyQueued(dig, direction, inBounds)
    local currPos = tex.getPosition()
    local currDir = tex.getDirection()
    local newPos
    if direction == "forward" then
        newPos = { x=currPos.x+currDir.x, y=currPos.y, z=currPos.z+currDir.z }
    elseif direction == "up" then
        newPos = { x=currPos.x, y=currPos.y+1, z=currPos.z }
    elseif direction == "down" then
        newPos = { x=currPos.x, y=currPos.y-1, z=currPos.z }
    elseif direction == "left" then
        newPos = { x=currPos.x-currDir.z, y=currPos.y, z=currPos.z+currDir.x }
    elseif direction == "right" then
        newPos = { x=currPos.x+currDir.z, y=currPos.y, z=currPos.z-currDir.x }
    end
    if inBounds then
        if not inBounds(newPos) then
            return true -- pretend like the new position is already going to be checked; will skip digging/checking that new position
        end
    end
    local index = textutils.serialize(newPos)
    if dig then
        if mined[index] then return true end
        mined[index] = true
    else
        if checked[index] then return true end
    end
    checked[index] = true
    return false
end

local function matchesFilter(filter, table)
    if type(filter) ~= type(table) then return false end
    if type(filter) ~= "table" and filter ~= table then return false end
    for key, filterField in pairs(filter) do
        local value2 = table[key]
		if type(filterField) ~= "table" then
			if filterField ~= value2 then
				return false
			end
        else
            if not matchesFilter(filterField, value2) then
                return false
            end
        end
    end
    return true
end

local function consolidate()
    local selectedSlot = tex.getSelectedSlot()
    local emptyItemStack = false
    for i=1,16 do
        for j=i+1,16 do
            if tex.getItemDetail(j) then
                if not tex.getItemDetail(i) or tex.getItemDetail(j).name == tex.getItemDetail(i).name then
                    tex.select(j)
                    tex.transferTo(i)
                    if not tex.getItemDetail(j) then
                        emptyItemStack = true
                    end
                end
            end
        end
    end
    tex.select(selectedSlot)
    return emptyItemStack
end

local function isFull()
    for i=1,16 do
        if tex.getItemCount(i) == 0 then return false end
    end
    return true
end

local function checkAdj(filter, dig, handlers)
    if isFull() then
        consolidate()
        if isFull() and handlers.full then handlers.full() end
    end
    local checkLeft = alreadyQueued(dig,"left",handlers.inBounds) == false
    local checkForward = alreadyQueued(dig,"forward",handlers.inBounds) == false
    local checkRight = alreadyQueued(dig,"right",handlers.inBounds) == false
    local checkUp = alreadyQueued(dig,"up",handlers.inBounds) == false
    local checkDown = alreadyQueued(dig,"down",handlers.inBounds) == false
    if checkForward then
        local block, blockInfo = tex.inspect()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    tex.forward(1, true)
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)), handlers)
                    tex.back()
                    if handlers.fillIn and (dig or (block and matchesFilter(filter, blockInfo))) then
                        handlers.fillIn(tex.place)
                    end
                end
            end
        end
    end
    if checkLeft then
        tex.left()
        local block, blockInfo = tex.inspect()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    tex.forward(1, true)
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)), handlers)
                    tex.back()
                    if handlers.fillIn and (dig or (block and matchesFilter(filter, blockInfo))) then
                        handlers.fillIn(tex.place)
                    end
                end
            end
        end
        tex.right()
    end
    if checkRight then
        tex.right()
        local block, blockInfo = tex.inspect()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    tex.forward(1, true)
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)), handlers)
                    tex.back()
                    if handlers.fillIn and (dig or (block and matchesFilter(filter, blockInfo))) then
                        handlers.fillIn(tex.place)
                    end
                end
            end
        end
        tex.left()
    end
    if checkUp then
        local block, blockInfo = tex.inspectUp()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    tex.up(1, true)
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)), handlers)
                    tex.down()
                    if handlers.fillIn and (dig or (block and matchesFilter(filter, blockInfo))) then
                        handlers.fillIn(tex.placeUp)
                    end
                end
            end
        end
    end
    if checkDown then
        local block, blockInfo = tex.inspectDown()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    tex.down(1, true)
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)), handlers)
                    tex.up()
                    if handlers.fillIn and (dig or (block and matchesFilter(filter, blockInfo))) then
                        handlers.fillIn(tex.placeDown)
                    end
                end
            end
        end
    end
end

local function collectVein(filter, handlers)
    checked = {}
    mined = {}
    checkAdj(filter, false, handlers)
end

local function extract(filter, distance, handlers)
    for _=1,distance do
        tex.forward(1, true)
        collectVein(filter, handlers)
    end
    for _=1,distance do
        tex.back()
    end
end

local function amtOfNewBlocks(pos, table, lookAhead, handlers)
    local result = 0
    for x=pos.x-lookAhead,pos.x+lookAhead do
        local startingY = pos.y - (lookAhead - math.abs(x - pos.x))
        local endingY = pos.y + (lookAhead - math.abs(x - pos.x))
        for y=startingY,endingY do
            local startingZ = pos.z - (lookAhead - math.abs(x - pos.x) - math.abs(y - pos.y))
            local endingZ = pos.z + (lookAhead - math.abs(x - pos.x) - math.abs(y - pos.y))
            for z=startingZ,endingZ do
                local thisPos = { x=x, y=y, z=z }
                --local posValue = math.abs(lookAhead + 1 - (math.abs(x - pos.x) + math.abs(y - pos.y) + math.abs(z - pos.z)))
                if not handlers.inBounds(thisPos) then
                    result = result + 0.1
                elseif not table[textutils.serialize(thisPos)] then
                    result = result + 1
                end
            end
        end
    end
    return result
end

local function chaos(filter, amount, lookAhead, handlers)
    local chaosMined = {}
    local minedTotal = 0
    local fillInHandler = handlers.fillIn
    handlers.fillIn = function(placeFunction) -- Overload the fillIn handler so chaosMined keeps track of vein-mined blocks as well
        local currPos = tex.getPosition()
        if placeFunction == tex.place then
            local currDir = tex.getDirection()
            currPos.x = currPos.x + currDir.x
            currPos.z = currPos.z + currDir.z
            chaosMined[textutils.serialize(currPos)] = true
        elseif placeFunction == tex.placeUp then
            currPos.y = currPos.y + 1
            chaosMined[textutils.serialize(currPos)] = true
        elseif placeFunction == tex.placeDown then
            currPos.y = currPos.y - 1
            chaosMined[textutils.serialize(currPos)] = true
        end
        if fillInHandler then fillInHandler(placeFunction) end
    end
    for _=1,amount do
        local currPos = tex.getPosition()
        local currDir = tex.getDirection()
        local forward, left, right, up, down
        forward = {
            x=currPos.x+currDir.x, y=currPos.y, z=currPos.z+currDir.z,
            command= function() tex.forward(1, true) end
        }
        forward.preference = amtOfNewBlocks(forward, chaosMined, lookAhead, handlers)
        left = {
            x=currPos.x-currDir.z, y=currPos.y, z=currPos.z+currDir.x,
            command=function() tex.left() tex.forward(1, true) end
        }
        left.preference = amtOfNewBlocks(left, chaosMined, lookAhead, handlers)
        right = {
            x=currPos.x+currDir.z, y=currPos.y, z=currPos.z-currDir.x,
            command=function() tex.right() tex.forward(1, true) end
        }
        right.preference = amtOfNewBlocks(right, chaosMined, lookAhead, handlers)
        up = {
            x=currPos.x, y=currPos.y+1, z=currPos.z,
            command=function() tex.up(1, true) end
        }
        up.preference = amtOfNewBlocks(up, chaosMined, lookAhead, handlers)
        down = {
            x=currPos.x, y=currPos.y-1, z=currPos.z,
            command=function() tex.down(1, true) end
        }
        down.preference = amtOfNewBlocks(down, chaosMined, lookAhead, handlers)
        local sorted = { forward, left, right, up, down }
        io.open("output.txt","a"):write(tostring(forward.preference.." "..left.preference.." "..right.preference.." "..up.preference.." "..down.preference).."\n"):close()

        table.sort(sorted, function(pos1, pos2)
            return pos1.preference > pos2.preference
        end)
        for _, element in ipairs(sorted) do
            if handlers.inBounds(element) then
                element.command()
                break
            end
        end
        minedTotal = minedTotal + 1
        collectVein(filter, handlers)
        chaosMined[textutils.serialize(currPos)] = true
    end
    if handlers.done then handlers.done() end
end

local function collectVein2(filter, handlers)
    if isFull() then
        consolidate()
        if isFull() and handlers.full then handlers.full() end
    end
    local listOfStuff = {}
    local startingPos = tex.getPosition()
    local startingDir = tex.getDirection()
    local _, inspectResults = tex.inspect()
    local forward = {
        x=startingPos.x+startingDir.x,
        y=startingPos.y,
        z=startingPos.z+startingDir.z,
        ore=matchesFilter(filter, inspectResults)
    }
    _, inspectResults = tex.inspectUp()
    local up = {
        x=startingPos.x,
        y=startingPos.y+1,
        z=startingPos.z,
        ore=matchesFilter(filter, inspectResults)
    }
    local down = { x=startingPos.x, y=startingPos.y-1, z=startingPos.z }
    local left = { x=startingPos.x-startingDir.z, y=startingPos.y, z=startingPos.z+startingDir.x }
    local right = { x=startingPos.x+startingDir.z, y=startingPos.y, z=startingPos.z-startingDir.x }
    listOfStuff[#listOfStuff+1] = 
    local collectedVein = false
    while not collectedVein do
        for _, block in pairs(startingPosition) do
            
        end
    end
end

local function layerGetOre(filter, height, currentLayer)
    local block, blockInfo
    if currentLayer*3 <= height then
        block, blockInfo = tex.inspectUp()
        if block and matchesFilter(filter, blockInfo) then
            tex.digUp()
        end
    end
    block, blockInfo = tex.inspectDown()
    if block and matchesFilter(filter, blockInfo) then
        tex.digDown()
    end
end

local function layers(filter, width, length, height, handlers)
    tex.up(1, true)
    local numOfLayers = math.floor((height+1)/3)
    local currentLayer = 1
    local blocksMined = 0
    for instruction in tex.vPath(width, numOfLayers, length) do
        if isFull() then
            consolidate()
            if isFull() and handlers.full then handlers.full() end
        end
        if instruction == "up" then
            currentLayer = currentLayer + 1
            tex.up(3, true)
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
        blocksMined = blocksMined + 1
        layerGetOre(filter, height, currentLayer)
    end
    if handlers.done then handlers.done() end
end

return {
    collectVein=collectVein,
    extract=extract,
    chaos=chaos,
    layers=layers,
}