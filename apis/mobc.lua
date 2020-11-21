local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.tex")

local Queue = { first=0, last=-1 }

function Queue:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Queue:push(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

function Queue:pop()
    local first = self.first
    local value = self[first]
    self[first] = nil
    self.first = first + 1
    return value
end

function Queue:isEmpty()
    if self.first > self.last then
        return true
    end
    return false
end

local function includes(table, pos)
    return (
        pos.x > 0 and
        pos.z > 0 and
        pos.z < #table and
        pos.x < #table[pos.z]
    )
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

local function findNearestBlock(mob, pos, dir, placed, searched, queue)
    if queue then
		searched[pos.z][pos.x] = true
		if mob.model[pos.y][pos.z][pos.x] > 0 and not placed[pos.z][pos.x] then
            placed[pos.z][pos.x] = true
			return pos, placed
		end
		
		local newPos = {x=pos.x+dir.x, y=pos.y, z=pos.z+dir.z}
		if includes(mob.model[pos.y], newPos) and not searched[newPos.z][newPos.x] then
			queue:push({pos=newPos, dir=dir})
		end
		local left = turnDir(dir, "left")
		newPos = {x=pos.x+left.x, y=pos.y, z=pos.z+left.z}
		if includes(mob.model[pos.y], newPos) and not searched[newPos.z][newPos.x] then
			queue:push({pos=newPos, dir=left})
		end
		local right = turnDir(dir, "right")
		newPos = {x=pos.x+right.x, y=pos.y, z=pos.z+right.z}
		if includes(mob.model[pos.y], newPos) and not searched[newPos.z][newPos.x] then
			queue:push({pos=newPos, dir=right})
		end
		return nil, placed
	else
		queue = Queue:new()
		queue:push({pos=pos, dir=dir})
		searched = {}
		for i=1,mob.depth do
			searched[i] = {}
		end
		local result
		while not queue:isEmpty() do
			local possible = queue:pop()
			result, placed = findNearestBlock(mob, possible.pos, possible.dir, placed, searched, queue)
			if result then
				return result, placed
			end
		end
		return nil, placed
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
    local placed = {} -- searched only needs to hold the current layer, as the turtle won't move up unless the entire layer has been printed.
    for i=1,mob.depth do
        placed[i] = {}
    end
    local totalMaterials = 0
    
    for _, material in ipairs(mob.materials) do
        tcode.materials[i] = { name=material.name, amount=material.amount }
        totalMaterials = totalMaterials + material.amount
    end
    local extruded = 0
    local i = 0
    while extruded < totalMaterials do
        i=i+1
        local blockPos
        blockPos, placed = findNearestBlock(mob, pos, dir, placed)
        if blockPos then
            local instruction = goToPos(pos,dir,blockPos)
            while instruction do
                tcode.instructions[#tcode.instructions+1] = instruction
                tcode.data[#tcode.data+1] = mob.model[pos.y][pos.z][pos.x]
                if mob.model[pos.y][pos.z][pos.x] > 0 then
                    extruded = extruded + 1
                end
                if instruction == "forward" then
                    pos = {x=pos.x+dir.x, y=pos.y, z=pos.z+dir.z}
                elseif instruction == "left" then
                    dir = turnDir(dir, "left")
                    pos = {x=pos.x+dir.x, y=pos.y, z=pos.z+dir.z}
                elseif instruction == "right" then
                    dir = turnDir(dir, "right")
                    pos = {x=pos.x+dir.x, y=pos.y, z=pos.z+dir.z}
                end
                instruction = goToPos(pos,dir,blockPos)
            end
        else
            tcode.data[#tcode.data+1] = mob.model[pos.y][pos.z][pos.x]
            if mob.model[pos.y][pos.z][pos.x] > 0 then
                extruded = extruded + 1
            end
            if not (pos.y == mob.height) then
                placed = {}
                for j=1,mob.depth do
                    placed[j] = {}
                end
                tcode.instructions[#tcode.instructions+1] = "up"
                dir = {x=-dir.x, z=-dir.z}
                pos = {x=pos.x, y=pos.y+1, z=pos.z}
                placed[pos.z][pos.x] = true
            end
        end
        if i > 20 then
            print("Inf loop.")
            return tcode
        end
    end
    return tcode
end

return {
    tcodeToMob=tcodeToMob,
    naiveMobToTcode=naiveMobToTcode,
    mobToTcode=mobToTcode
}