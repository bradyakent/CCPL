local tex, mining, ux = require("/ccpl")("tex","mining","ux")

local usage = {
    {"length",{"width",{"height",{"density",{"weighting",nil,true},true}}}}
}

local args = { ... }
local length = tonumber(args[1])
local width = tonumber(args[2])
local height = tonumber(args[3])
local density = args[4] and tonumber(args[4]) or 0.125
if not (length and width and height and density) then
    ux.displayUsage("chaos-mine", usage)
    return
end

local pathLength = math.floor(density*length*width*height)

local fillBlocks
local _, blockInfo = tex.inspectDown()
while blockInfo and blockInfo.name ~= "minecraft:bedrock" do
    tex.digDown()
    tex.down()
    _, blockInfo = tex.inspectDown()
end
tex.up(4, true)

local bottomLeftCorner = tex.getPosition()
local topRightCorner = {
    x=bottomLeftCorner.x + width - 1,
    y=bottomLeftCorner.y + height - 1,
    z=bottomLeftCorner.z + length - 1,
}

local myBounds = tex.newBounds(bottomLeftCorner, topRightCorner)

local handlers = {}
local fillIn = nil

fillBlocks = {
    "minecraft:torch"
}
fillIn = function(maxAttempts)
    local placeAttempts = 0
    return function(placeFunction)
        if placeAttempts == maxAttempts then
            local prevSlot = tex.getSelectedSlot()
            local fillSlot
            for _, name in ipairs(fillBlocks) do
                fillSlot = tex.findStack(name)
                if fillSlot then
                    tex.select(fillSlot)
                    placeFunction()
                    tex.select(prevSlot)
                    break
                end
            end
            placeAttempts = 0
        else
            placeAttempts = placeAttempts + 1
        end
    end
end

local function goTo(pos, dir)
    local distanceX = math.abs(pos.x - tex.getPosition().x)
    local distanceY = math.abs(pos.y - tex.getPosition().y)
    local distanceZ = math.abs(pos.z - tex.getPosition().z)
    local directionX = (pos.x > tex.getPosition().x) and 1 or -1
    local directionY = (pos.y > tex.getPosition().y) and 1 or -1
    local directionZ = (pos.z > tex.getPosition().z) and 1 or -1
    if directionY == -1 then
        tex.down(distanceY, true)
    end
    if directionZ == 1 then
        while tex.getDirection().z ~= 1 do
            tex.left()
        end
        tex.forward(distanceZ, true)
    end
    while tex.getDirection().x ~= directionX do
        tex.left()
    end
    tex.forward(distanceX, true)
    if directionZ == -1 then
        while tex.getDirection().z ~= -1 do
            tex.left()
        end
        tex.forward(distanceZ, true)
    end
    if directionY == 1 then
        tex.up(distanceY, true)
    end
    while not (tex.getDirection().x == dir.x and tex.getDirection().z == dir.z) do
        tex.left()
    end
end

handlers.inBounds = function(position)
    return myBounds:contains(position)
end


handlers.full = function()
    local returnPos = tex.getPosition()
    local returnDir = tex.getDirection()
    goTo({ x=1, y=1, z=1 }, { x=0, z=-1 }) -- origin, facing the chest
    for slot=1,16 do
        local shouldDrop = true
        for _, block in ipairs(fillBlocks) do
            if tex.getItemDetail(slot).name == block or tex.getItemDetail(slot).name == "minecraft:torch" then
                shouldDrop = false
            end
        end
        if shouldDrop then
            tex.select(slot)
            tex.drop()
        end
    end
    goTo(returnPos, returnDir)
end

handlers.done = function()
    goTo({ x=1, y=1, z=1 }, { x=0, z=-1 })
    tex.dropAll()
    tex.turnAround()
end
if args[5] then
    local weight = tonumber(args[5])
    handlers.weighting = function()
        return 1+(weight*2), 1+weight
    end
end

handlers.fillIn = fillIn(18)
local start = os.clock()
mining.chaos(pathLength, 5, handlers)
local stop = os.clock()
local timeTaken = stop - start
print("Time taken:", string.format("%.1fs",timeTaken))