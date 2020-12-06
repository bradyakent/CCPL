local tex = require("/ccpl")("tex")

local pos = { x=1, y=1, z=1 }
local dir = { x=0, z=1 }
local checked = {}

local function forward()
    pos.x = pos.x + dir.x
    pos.z = pos.z + dir.z
    tex.forward(1, true)
end

local function back()
    pos.x = pos.x - dir.x
    pos.z = pos.z - dir.z
    tex.back()
end

local function up()
    pos.y = pos.y + 1
    tex.up(1, true)
end

local function down()
    pos.y = pos.y - 1
    tex.down(1, true)
end

local function left()
    dir.x, dir.z = -dir.z, dir.x
    tex.left()
end

local function right()
    dir.x, dir.z = dir.z, -dir.x
    tex.right()
end

local function hasBeenChecked(direction)
    local index
    if direction == "forward" then
        index = textutils.serialise({ x=pos.x+dir.x, y=pos.y, z=pos.z+dir.z })
    elseif direction == "up" then
        index = textutils.serialise({ x=pos.x, y=pos.y+1, z=pos.z })
    elseif direction == "down" then
        index = textutils.serialise({ x=pos.x, y=pos.y-1, z=pos.z })
    elseif direction == "left" then
        index = textutils.serialise({ x=pos.x-dir.z, y=pos.y, z=pos.z+dir.x })
    elseif direction == "right" then
        index = textutils.serialise({ x=pos.x+dir.z, y=pos.y, z=pos.z-dir.x })
    end
    if checked[index] then return true end
    checked[index] = true
    return false
end

local function matchesFilter(filter, table)
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

local function checkAdj(filter, dig)
    local checkLeft = hasBeenChecked("left") == false
    local checkForward = hasBeenChecked("forward") == false
    local checkRight = hasBeenChecked("right") == false
    local checkUp = hasBeenChecked("up") == false
    local checkDown = hasBeenChecked("down") == false
    if checkForward then
        local block, blockInfo = tex.inspect()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    forward()
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)))
                    back()
                end
            end
        end
    end
    if checkLeft then
        left()
        local block, blockInfo = tex.inspect()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    forward()
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)))
                    back()
                end
            end
        end
        right()
    end
    if checkRight then
        right()
        local block, blockInfo = tex.inspect()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    forward()
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)))
                    back()
                end
            end
        end
        left()
    end
    if checkUp then
        local block, blockInfo = tex.inspectUp()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    up()
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)))
                    down()
                end
            end
        end
    end
    if checkDown then
        local block, blockInfo = tex.inspectDown()
        if block then
            if blockInfo.name ~= "minecraft:bedrock" then
                if dig or (block and matchesFilter(filter, blockInfo)) then
                    down()
                    checkAdj(filter, (block and matchesFilter(filter, blockInfo)))
                    up()
                end
            end
        end
    end
end

local function collectVein(filter)
    pos = { x=1, y=1, z=1 }
    dir = { x=0, z=1 }
    checked = {}
    checkAdj(filter)
end

local function extract(filter, distance)
    for _=1,distance do
        tex.forward(1, true)
        collectVein(filter)
    end
    for _=1,distance do
        tex.back()
    end
end

local filter = {
    tags={
        ["forge:ores"] = true
    }
}

extract(filter, 16)