local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.path")

local Queue = {}
function Queue.new()
    return { first=0, last=-1 }
end

function Queue.push(queue, value)
    local last = queue.last + 1
    queue.last = last
    queue[last] = value
end

function Queue.pop(queue)
    local first = queue.first
    local value = queue[first]
    queue[first] = nil
    queue.first = first + 1
    return value
end

function Queue.empty(queue)
    if queue.first > queue.last then
        return true
    end
    return false
end

local function turnDir(currDir, direction)
    local dir = {}
    if direction == "right" then
        dir.x, dir.z = -currDir.z, currDir.x
    elseif direction == "left" then
        dir.x, dir.z = currDir.z, -currDir.x
    end
    return dir
end

local function tcodeToMob(tcodeObj)
    local mob = {
        width=tcodeObj.width,
        height=tcodeObj.height,
        depth=tcodeObj.depth,
        model={},
        materials={}
    }
    for i=1,tcodeObj.height do
        mob.model[i] = {}
        for j=1,tcodeObj.depth do
            mob.model[i][j] = {}
        end
    end
    for i, material in ipairs(tcodeObj.materials) do
        mob.materials[i] = { name=material.name, amount=material.amount }
    end

    local pos = {
        x=1,
        y=1,
        z=tcodeObj.depth
    }
    local dir = {
        x=0,
        z=-1
    }
    for i in ipairs(tcodeObj.data) do
        mob.model[pos.y][pos.z][pos.x] = tcodeObj.data[i]
        if tcodeObj.instructions[i] == "forward" then
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif tcodeObj.instructions[i] == "right" then
            dir = turnDir(dir,"right")
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif tcodeObj.instructions[i] == "left" then
            dir = turnDir(dir,"left")
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif tcodeObj.instructions[i] == "up" then
            dir.x, dir.z = -dir.x, -dir.z
            pos.y = pos.y + 1
        end
    end
    return mob
end

local function naiveMobToTcode(mob)
    local tcode = {
        width=mob.width,
        height=mob.height,
        depth=mob.depth,
        data={},
        instructions={},
        materials={}
    }
    for i, material in ipairs(mob.materials) do
        tcode.materials[i] = { name=material.name, amount=material.amount }
    end

    local pos = {
        x=1,
        y=1,
        z=mob.depth
    }
    local dir = {
        x=0,
        z=-1
    }
    tcode.data[#tcode.data + 1] = mob.model[pos.y][pos.z][pos.x]
    for instruction in tex.vPath(mob.width, mob.height, mob.depth) do
        tcode.instructions[#tcode.instructions+1] = instruction
        if instruction == "forward" then
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif instruction == "right" then
            dir = turnDir(dir,"right")
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif instruction == "left" then
            dir = turnDir(dir,"left")
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif instruction == "up" then
            dir.x, dir.z = -dir.x, -dir.z
            pos.y = pos.y + 1
        end
        tcode.data[#tcode.data + 1] = mob.model[pos.y][pos.z][pos.x]
    end
    return tcode
end

local function getDist(curr, dest)
    return math.abs(dest - curr)
end

local function goToPos(currPos, currDir, destPos)
    -- if the two positions are equal, you're at the destination
    if currPos.x == destPos.x and currPos.y == destPos.y and currPos.z == destPos.z then
        return nil
    end
    -- if the current direction would get you closer to the destination, move forward
    if (
        getDist(currPos.x + currDir.x, destPos.x) < getDist(currPos.x, destPos.x) or
        getDist(currPos.z + currDir.z, destPos.z) < getDist(currPos.z, destPos.z)
    ) then
        return "forward"
    end

    -- if turning right would get you closer to the destination, turn right
    local right = turnDir(currDir,"right")
    if (
        getDist(currPos.x + right.x, destPos.x) < getDist(currPos.x, destPos.x) or
        getDist(currPos.z + right.z, destPos.z) < getDist(currPos.z, destPos.z)
    ) then
        return "right"
    end

    -- if turning left would get you closer to the destination, turn left
    local left = turnDir(currDir,"left")
    if (
        getDist(currPos.x + left.x, destPos.x) < getDist(currPos.x, destPos.x) or
        getDist(currPos.z + left.z, destPos.z) < getDist(currPos.z, destPos.z)
    ) then
        return "left"
    end

    -- if a value hasn't been returned yet, the destination is directly behind the turtle
    -- if the turtle can turn left without possibly leaving the bounds, turn left, otherwise turn right
    if (
        (currPos.x == 1 and left.x == 1) or
        (currPos.z == 1 and left.z == 1) or
        (currPos.x > 1 and left.x == -1) or
        (currPos.z > 1 and left.z == -1)
    ) then
        return "left"
    else
        return "right"
    end
end

local function findNearestBlock(mob, pos, dir, searched, queue)
    if queue then
		searched[pos.z][pos.x] = true
		if mob[pos.z][pos.x] > 0 then
			return pos, searched
		end
		
		local newPos = {x=pos.x+dir.x, z=pos.z+dir.z}
		if includes(mob, newPos) and not searched[newPos.z][newPos.x] then
			queue:push({pos=newPos, dir=dir})
		end
		local left = turnDir(dir, "left")
		newPos = {x=pos.x+left.x, z=pos.z+left.z}
		if includes(mob, newPos) and not searched[newPos.z][newPos.x] then
			queue:push({pos=newPos, dir=left})
		end
		local right = turnDir(dir, "right")
		newPos = {x=pos.x+right.x, z=pos.z+right.z}
		if includes(mob, newPos) and not searched[newPos.z][newPos.x] then
			queue:push({pos=newPos, dir=right})
		end
		return nil, searched
	else
		queue = Queue:new()
		queue:push({pos=pos, dir=dir})
		searched = {}
		for i=1,#mob do
			searched[i] = {}
		end
		local result
		while not queue:isEmpty() do
			local possible = queue:pop()
			result, searched = findNearestBlock(mob, possible.pos, possible.dir, queue, searched)
			if result then
				return result
			end
		end
		return nil
	end
end

local function mobToTcode(mob)
    local tcode = {
        width=mob.width,
        height=mob.height,
        depth=mob.depth,
        data={},
        instructions={},
        materials={}
    }
    local pos = {
        x=1,
        y=1,
        z=mob.depth
    }
    local dir = {
        x=0,
        z=-1
    }
    local searched = {} -- searched only needs to hold the current layer, as the turtle won't move up unless the entire layer has been printed.
    for i=1,mob.depth do
        searched[i] = {}
    end
    local totalMaterials = 0
    for _, material in ipairs(mob.materials) do
        totalMaterials = totalMaterials + material.amount
    end
    local extruded = 0
    while extruded < totalMaterials do
        local blockPos, searched = findNearestBlock(mob, pos, dir, searched)
        if blockPos then
            while goToPos(pos,dir,blockPos) do
                tcode.instructions[#tcode.instructions+1] = goToPos(pos,dir,blockPos)
                tcode.data[#tcode.data+1] = mob.model[pos.y][pos.z][pos.x]
            end
        else
            tcode.instructions[#tcode.instructions+1] = "up"
            tcode.data[#tcode.data+1] = mob.model[pos.y][pos.z][pos.x]
        end
    end
    return tcode
end

return {
    tcodeToMob=tcodeToMob,
    naiveMobToTcode=naiveMobToTcode,
    mobToTcode=naiveMobToTcode
}