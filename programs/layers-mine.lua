local tex, mining, ux = require("/ccpl")("tex","mining","ux")

local usage = {
    {"width",{"length",{"height",{"offset",nil,true}}}}
}

local args = { ... }
local width = tonumber(args[1])
local length = tonumber(args[2])
local height = tonumber(args[3])
local offset = tonumber(args[4]) or 4
if not (length and width and height) then
    ux.displayUsage("layers-mine", usage)
    return
end

local filter = {
    tags = {
        ["forge:ores"] = true
    }
}
local _, blockInfo = tex.inspectDown()
while blockInfo and blockInfo.name ~= "minecraft:bedrock" do
    tex.digDown()
    tex.down()
    _, blockInfo = tex.inspectDown()
end
tex.up(offset, true)

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
    goTo({ x=1, y=1, z=1 }, { x=0, z=-1 }) -- origin, facing the chest
    tex.dropAll()
    goTo(returnPos, returnDir)
end

handlers.done = function()
    goTo({ x=1, y=1, z=1 }, { x=0, z=-1 })
    tex.dropAll()
    tex.turnAround()
end

local start = os.clock()
mining.layers(filter, width, length, height, handlers)
local stop = os.clock()
local timeTaken = stop - start
print("Time taken:", string.format("%.1fs",timeTaken))