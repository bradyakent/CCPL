local absolute = {
    position={ x=1, y=1, z=1 },
    direction={ x=0, z=1 }
}

local function getPosition()
    return {
        x=absolute.position.x,
        y=absolute.position.y,
        z=absolute.position.z
    }
end

local function getDirection()
    return {
        x = absolute.direction.x,
        z = absolute.direction.z
    }
end

local function newBounds(corner1, corner2)
    local minX = math.min(corner1.x, corner2.x)
    local minY = math.min(corner1.y, corner2.y)
    local minZ = math.min(corner1.z, corner2.z)
    local maxX = math.max(corner1.x, corner2.x)
    local maxY = math.max(corner1.y, corner2.y)
    local maxZ = math.max(corner1.z, corner2.z)
    local bounds = {
        { x=minX, y=minY, z=minZ },
        { x=maxX, y=maxY, z=maxZ }
    }
    function bounds:contains(position)
        if position == nil then position = absolute.position end
        return (
            position.x >= bounds[1].x and position.x <= bounds[2].x and
            position.y >= bounds[1].y and position.y <= bounds[2].y and
            position.z >= bounds[1].z and position.z <= bounds[2].z
        )
    end
    return bounds
end

local function forward(distance)
    if distance == nil then distance = 1 end
    absolute.position.x = absolute.position.x + (absolute.direction.x*distance)
    absolute.position.z = absolute.position.z + (absolute.direction.z*distance)
end

local function back(distance)
    if distance == nil then distance = 1 end
    absolute.position.x = absolute.position.x - (absolute.direction.x*distance)
    absolute.position.z = absolute.position.z - (absolute.direction.z*distance)
end

local function up(distance)
    if distance == nil then distance = 1 end
    absolute.position.y = absolute.position.y + distance
end

local function down(distance)
    if distance == nil then distance = 1 end
    absolute.position.y = absolute.position.y - distance
end

local function left()
    absolute.direction.x, absolute.direction.z = -absolute.direction.z, absolute.direction.x
end

local function right()
    absolute.direction.x, absolute.direction.z = absolute.direction.z, -absolute.direction.x
end

return {
    getPosition=getPosition,
    getDirection=getDirection,
    newBounds=newBounds,
    forward=forward,
    back=back,
    up=up,
    down=down,
    left=left,
    right=right
}