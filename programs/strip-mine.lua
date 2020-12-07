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