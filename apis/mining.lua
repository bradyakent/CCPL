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

local function defaultFilter(blockInfo)
    if string.sub(blockInfo.name, -3, -1) == "ore" then
        return true
    end
    return false
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

local function checkAdj(dig, handlers, noTurn)
    if isFull() then
        consolidate()
        if isFull() and handlers.full then handlers.full() end
    end
    local checkLeft = (noTurn or alreadyQueued(dig,"left",handlers.inBounds)) == false
    local checkForward = alreadyQueued(dig,"forward",handlers.inBounds) == false
    local checkRight = (noTurn or alreadyQueued(dig,"right",handlers.inBounds)) == false
    local checkUp = alreadyQueued(dig,"up",handlers.inBounds) == false
    local checkDown = alreadyQueued(dig,"down",handlers.inBounds) == false
    if checkForward then
        local block, blockInfo = tex.inspect()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))) then
                    if handlers.dig then
                        parallel.waitForAll(function() handlers.dig(blockInfo.name) end, function() tex.forward(1, true) end)
                    else
                        tex.forward(1,true)
                    end
                    checkAdj((block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))), handlers)
                    tex.back()
                    if handlers.fillIn and (dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo)))) then
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
                if dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))) then
                    if handlers.dig then
                        parallel.waitForAll(function() handlers.dig(blockInfo.name) end, function() tex.forward(1, true) end)
                    else
                        tex.forward(1,true)
                    end
                    checkAdj((block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))), handlers)
                    tex.back()
                    if handlers.fillIn and (dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo)))) then
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
                if dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))) then
                    if handlers.dig then
                        parallel.waitForAll(function() handlers.dig(blockInfo.name) end, function() tex.forward(1, true) end)
                    else
                        tex.forward(1,true)
                    end
                    checkAdj((block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))), handlers)
                    tex.back()
                    if handlers.fillIn and (dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo)))) then
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
                if dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))) then
                    if handlers.dig then
                        parallel.waitForAll(function() handlers.dig(blockInfo.name) end, function() tex.up(1, true) end)
                    else
                        tex.up(1,true)
                    end
                    checkAdj((block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))), handlers)
                    tex.down()
                    if handlers.fillIn and (dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo)))) then
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
                if dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))) then
                    if handlers.dig then
                        parallel.waitForAll(function() handlers.dig(blockInfo.name) end, function() tex.down(1, true) end)
                    else
                        tex.down(1,true)
                    end
                    checkAdj((block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo))), handlers)
                    tex.up()
                    if handlers.fillIn and (dig or (block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo)))) then
                        handlers.fillIn(tex.placeDown)
                    end
                end
            end
        end
    end
end

local function collectVein(handlers, noTurn)
    checked = {}
    mined = {}
    checkAdj(false, handlers, noTurn)
end

local function extract(distance, handlers)
    for _=1,distance do
        tex.forward(1, true)
        collectVein(handlers)
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
                local posValue = math.abs(lookAhead + 1 - (math.abs(x - pos.x) + math.abs(y - pos.y) + math.abs(z - pos.z)))^3
                if not handlers.inBounds(thisPos) then
                    result = result + 0
                elseif not table[textutils.serialize(thisPos)] then
                    result = result + posValue
                end
            end
        end
    end
    return result
end

local function pushToChecked(table, position)
    table[textutils.serialize(position)] = true
    table[textutils.serialize({ x=position.x+1, y=position.y, z=position.z })] = true
    table[textutils.serialize({ x=position.x-1, y=position.y, z=position.z })] = true
    table[textutils.serialize({ x=position.x, y=position.y+1, z=position.z })] = true
    table[textutils.serialize({ x=position.x, y=position.y-1, z=position.z })] = true
    table[textutils.serialize({ x=position.x, y=position.y, z=position.z+1 })] = true
    table[textutils.serialize({ x=position.x, y=position.y, z=position.z-1 })] = true
end

local function chaos(amount, lookAhead, handlers)
    local chaosChecked = {}
    local fillInHandler = handlers.fillIn
    handlers.fillIn = function(placeFunction) -- Overload the fillIn handler so chaosMined keeps track of vein-mined blocks as well
        local currPos = tex.getPosition()
        if placeFunction == tex.place then
            local currDir = tex.getDirection()
            currPos.x = currPos.x + currDir.x
            currPos.z = currPos.z + currDir.z
            pushToChecked(chaosChecked, currPos)
        elseif placeFunction == tex.placeUp then
            currPos.y = currPos.y + 1
            pushToChecked(chaosChecked, currPos)
        elseif placeFunction == tex.placeDown then
            currPos.y = currPos.y - 1
            pushToChecked(chaosChecked, currPos)
        end
        if fillInHandler then fillInHandler(placeFunction) end
    end
    local forwardWeight, verticalWeight = 1, 1
    if handlers.weighting then
        forwardWeight, verticalWeight = handlers.weighting()
    end
    for i=1,amount do
        local currPos = tex.getPosition()
        local currDir = tex.getDirection()
        local forward, left, right, up, down
        forward = {
            x=currPos.x+currDir.x, y=currPos.y, z=currPos.z+currDir.z,
            command= function() tex.forward(1, true) end
        }
        forward.preference = amtOfNewBlocks(forward, chaosChecked, lookAhead, handlers) * forwardWeight
        left = {
            x=currPos.x-currDir.z, y=currPos.y, z=currPos.z+currDir.x,
            command=function() tex.left() tex.forward(1, true) end
        }
        left.preference = amtOfNewBlocks(left, chaosChecked, lookAhead, handlers)
        right = {
            x=currPos.x+currDir.z, y=currPos.y, z=currPos.z-currDir.x,
            command=function() tex.right() tex.forward(1, true) end
        }
        right.preference = amtOfNewBlocks(right, chaosChecked, lookAhead, handlers)
        up = {
            x=currPos.x, y=currPos.y+1, z=currPos.z,
            command=function() tex.up(1, true) end
        }
        up.preference = amtOfNewBlocks(up, chaosChecked, lookAhead, handlers) * verticalWeight
        down = {
            x=currPos.x, y=currPos.y-1, z=currPos.z,
            command=function() tex.down(1, true) end
        }
        down.preference = amtOfNewBlocks(down, chaosChecked, lookAhead, handlers) * verticalWeight
        local sorted = { forward, left, right, up, down }
        
        table.sort(sorted, function(pos1, pos2)
            return pos1.preference > pos2.preference
        end)
        for _, element in ipairs(sorted) do
            if handlers.inBounds(element) then
                element.command()
                break
            end
        end
        if not chaosChecked[textutils.serialize(tex.getPosition())] then
            collectVein(handlers, (i % 2 == 0))
        end
        pushToChecked(chaosChecked, currPos)
    end
    if handlers.done then handlers.done() end
end

local function layerGetOre(handlers, height)
    local block, blockInfo
    block, blockInfo = tex.inspectUp()
    if block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo)) then
        tex.digUp()
    end
    block, blockInfo = tex.inspectDown()
    if block and ((handlers.filter and handlers.filter(blockInfo)) or defaultFilter(blockInfo)) then
        tex.digDown()
    end
end

local function layers(width, length, height, handlers)
    tex.up(1, true)
    local numOfLayers = math.ceil(height/3)
    local currentLayer = 1
    local lastLayerOffset = ((height-1)%3)-2
    for instruction in tex.vPath(width, numOfLayers, length) do
        if isFull() then
            consolidate()
            if isFull() and handlers.full then handlers.full() end
        end
        if instruction == "up" then
            currentLayer = currentLayer + 1
            if currentLayer == numOfLayers then
                tex.up(3 + lastLayerOffset, true)
            else
                tex.up(3, true)
            end
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
        layerGetOre(handlers, height)
    end
    if handlers.done then handlers.done() end
end

return {
    collectVein=collectVein,
    extract=extract,
    chaos=chaos,
    layers=layers,
}