local tex, ux, mining = require("/ccpl")("tex","ux","mining")
local usage = {
    {"number"}
}
local distance = tonumber(arg[1])


if not distance then ux.displayUsage("tunnel",usage) return end

local reqTorches = math.floor((distance + 2) / 8)

local slotsFilled = false
local slots = {}
while not slotsFilled do
    if reqTorches == 0 then
        break
    end
    slots[#slots+1] = { name="Torches", amount="At least "..tostring(math.min(reqTorches,64)) }
    reqTorches = reqTorches-math.min(reqTorches,64)
end
slots[#slots+1] = { name="Flooring", amount="Any" }
local flooring = #slots

ux.displaySlots(slots)

local filter = {
    tags = {
        ["forge:ores"] = true
    }
}
local fillBlocks

local handlers = {}
local fillIn = nil

if arg[2] == "true" then
    fillBlocks = {
        "minecraft:cobblestone",
        "minecraft:diorite",
        "minecraft:granite",
        "minecraft:andesite",
        "minecraft:dirt"
    }
    fillIn = function()
        return function(placeFunction)
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
        end
    end
elseif arg[2] == "torch" then
    fillBlocks = {
        "minecraft:torch"
    }
    fillIn = function(density)
        local placeAttempts = 0
        return function(placeFunction)
            if placeAttempts == density then
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
end

local function goTo(pos, dir)
    local distanceX = math.abs(pos.x - tex.getPosition().x)
    local distanceY = math.abs(pos.y - tex.getPosition().y)
    local distanceZ = math.abs(pos.z - tex.getPosition().z)
    local directionX = (pos.x > tex.getPosition().x) and 1 or -1
    local directionY = (pos.y > tex.getPosition().y) and 1 or -1
    local directionZ = (pos.z > tex.getPosition().z) and 1 or -1
    if directionZ == 1 then
        while tex.getDirection().z ~= 1 do
            tex.left()
        end
        tex.forward(distanceZ, true)
    end
    if directionX == 1 then
        while tex.getDirection().x ~= 1 do
            tex.left()
        end
        tex.forward(distanceX, true)
    else
        while tex.getDirection().x ~= -1 do
            tex.left()
        end
        tex.forward(distanceX, true)
    end
    if directionY == 1 then
        tex.up(distanceY, true)
    else
        tex.down(distanceY, true)
    end
    if directionZ == -1 then
        while tex.getDirection().z ~= -1 do
            tex.left()
        end
        tex.forward(distanceZ, true)
    end
    while tex.getDirection().x ~= dir.x and tex.getDirection().z ~= dir.z do
        tex.left()
    end
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

for i=1,distance do
    tex.forward(1, true)
    if not tex.detectDown() then
        tex.select(flooring)
        tex.placeDown()
        tex.select(1)
    end
    handlers.fillIn = fillIn(14)
    mining.collectVein(filter, handlers)
    while turtle.detectUp() do tex.digUp() end
    if i%4 == 0 then
        tex.up()
        tex.left()
        mining.extract(filter, 5, handlers)
        tex.turnAround()
        mining.extract(filter, 5, handlers)
        tex.left()
        tex.down()
    end
    if i%8 == 7 then
        tex.back()
        if tex.findStack("minecraft:torch") then
            local prevSlot = tex.getSelectedSlot()
            tex.select(tex.findStack("minecraft:torch"))
            tex.placeUp()
            tex.select(prevSlot)
        end
        tex.forward()
    end
end