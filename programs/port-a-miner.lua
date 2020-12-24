local tex, mining, ux, storage = require("/ccpl")("tex","mining","ux","storage")

local usage = {
    {"length",{"width",{"height"}}}
}

local args = { ... }
local length = tonumber(args[1])
local width = tonumber(args[2])
local height = tonumber(args[3])
if not (length and width and height) then
    ux.displayUsage("layers-mine", usage)
    return
end

if fs.exists("port-a-miner.wh") then
    storage.sync("port-a-miner.wh")
else
    storage.resize(9, 3)
    storage.update("port-a-miner.wh")
end

local function unpack()
    local function getBins()
        tex.select(1)
        for i=1,9 do
            tex.suck()
        end
    end
    local function placeRow(left, offset)
        local turn1, turn2
        if left then
            turn1, turn2 = tex.left, tex.right
        else
            turn1, turn2 = tex.right, tex.left
        end
        tex.up(offset)
        turn1()
        tex.forward(1, true)
        turn2()
        tex.forward(1, true)
        for i=1,9 do
            tex.select(i)
            tex.digDown()
            tex.placeDown()
            if i < 9 then tex.forward(1, true) end
        end
        tex.select(1)
        tex.back(9)
        turn1()
        tex.back()
        turn2()
        tex.down(offset)
    end
    tex.right()
    tex.forward(2, true)
    tex.dig()
    tex.place()
    for i=1,6 do
        getBins()
        tex.back()
        tex.left()
        tex.up()
        placeRow((i%2 == 1), math.floor((i-1)/2))
        tex.down()
        tex.right()
        tex.forward()
    end
    tex.back(2)
    tex.left()
end

local function pack()
    local function packBins()
        for i=1,9 do
            tex.select(i)
            tex.drop()
        end
        tex.select(1)
    end
    local function digRow(left, offset)
        local turn1, turn2
        if left then
            turn1, turn2 = tex.left, tex.right
        else
            turn1, turn2 = tex.right, tex.left
        end
        tex.up(offset)
        turn1()
        tex.forward()
        turn2()
        tex.select(1)
        tex.forward(9, true)
        tex.back(9)
        turn1()
        tex.back()
        turn2()
        tex.down(offset)
    end
    tex.right()
    tex.forward(2)
    for i=1,6 do
        tex.back()
        tex.left()
        digRow((i%2 == 1), math.floor((i-1)/2))
        tex.right()
        tex.forward()
        packBins()
    end
    tex.dig()
    tex.back(2)
    tex.left()
end

local function store()
    tex.right()
    tex.forward()
    tex.left()
    storage.put()
    tex.select(1)
    storage.update("port-a-miner.wh")
    tex.right()
    tex.back()
    tex.left()
end

local filter = {
    tags = {
        ["forge:ores"] = true
    }
}

unpack()

local _, blockInfo = tex.inspectDown()
while blockInfo and blockInfo.name ~= "minecraft:bedrock" do
    tex.digDown()
    tex.down()
    _, blockInfo = tex.inspectDown()
end
tex.up(4, true)

local handlers = {}

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

handlers.full = function()
    local returnPos = tex.getPosition()
    local returnDir = tex.getDirection()
    goTo({ x=1, y=1, z=1 }, { x=0, z=1 }) -- origin
    store()
    goTo(returnPos, returnDir)
end

handlers.done = function()
    goTo({ x=1, y=1, z=1 }, { x=0, z=1 }) -- origin
    store()
    pack()
end

local start = os.clock()
mining.layers(filter, length, width, height, handlers)
local stop = os.clock()
local timeTaken = stop - start
print("Time taken:", string.format("%.1fs",timeTaken))