local tex, ux, mining = require("/ccpl")("tex","ux","mining")
local usage = {
    {"number"}
}
local distance = tonumber(arg[1])
local fillIn = (args[2] == "true")


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

for i=1,distance do
    tex.forward(1, true)
    if not tex.detectDown() then
        tex.select(flooring)
        tex.placeDown()
        tex.select(1)
    end
    mining.collectVein(filter)
    while turtle.detectUp() do tex.digUp() end
    if i%4 == 0 then
        tex.up()
        tex.left()
        mining.extract(filter, 5, fillIn)
        tex.turnAround()
        mining.extract(filter, 5, fillIn)
        tex.left()
        tex.down()
    end
    if i%8 == 7 then
        tex.back()
        while not tex.placeUp() do tex.select(tex.getCurrentSlot()%16+1) end
        tex.forward()
    end
end