local tex = require("/ccpl")("tex")

local args = { ... }
local width = tonumber(args[1]) or 1
local height = tonumber(args[2]) or 1


--#### Movement Functions
local function right(dist)
    tex.turnRight()
    tex.forward(dist or 1)
    tex.turnLeft()
end

local function left(dist)
    tex.turnLeft()
    tex.forward(dist or 1)
    tex.turnRight()
end

local function up(dist)
    tex.up(dist or 1)
end

local function down(dist)
    tex.down(dist or 1)
end

--#### Data Structures
local allItems = {}

--#### Data Functions
local function logItem(name, count, chestID)
    local itemLog = allItems[name]
    if itemLog == nil then
        itemLog = {
            count=count,
            chestIDs={chestID}
        }
    else
        itemLog.count = itemLog.count + count
        local chestIDAlreadyLogged = false
        for i, existingID in ipairs(itemLog.chestIDs) do
            if chestID == existingID then
                chestIDAlreadyLogged = true
                break
            end
        end
        if not chestIDAlreadyLogged then
            itemLog.chestIDs[#itemLog.chestIDs+1] = chestID
        end
    end
end

local function writeToLog()
    for name, data in pairs(allItems) do
        print(name)
        print("   count: "..data.count)
        write("  chests: ")
        for _, id in ipairs(data.chestIDs) do
            write(id.." ")
        end
        print()
    end
end

--#### Running Code
local currentChest = 1

for y=1,height do
    if y ~= 1 then up() end
    for x=1,width do
        if x ~= 1 then
            if y%2 == 1 then
                right()
            else
                left()
            end
        end
        local chest = peripheral.wrap("front")
        for _, item in pairs(chest.list()) do
            logItem(item.name, item.count, currentChest)
        end
    end

    currentChest = currentChest + 1
end

down(height-1)
writeToLog()