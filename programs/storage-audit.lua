local tex = require("/ccpl")("tex")

local args = { ... }
local width = tonumber(args[1]) or 1
local height = tonumber(args[2]) or 1
local logFile = args[3] or io.stdout
local verbosity = args[4] or "short-names"
-- full or summary or short-names


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
    if allItems[name] == nil then
        allItems[name] = {
            count=count,
            chestIDs={chestID}
        }
    else
        allItems[name].count = allItems[name].count + count
        local chestIDAlreadyLogged = false
        for i, existingID in ipairs(allItems[name].chestIDs) do
            if chestID == existingID then
                chestIDAlreadyLogged = true
                break
            end
        end
        if not chestIDAlreadyLogged then
            allItems[name].chestIDs[#allItems[name].chestIDs+1] = chestID
        end
    end
end

local function writeToLog()
    io.output(logFile)
    for name, data in pairs(allItems) do
        if verbosity ~= "full" then
            name = string.sub(name, 1, string.find(name, ":"))
        end
        io.write(name)
        if verbosity == "summary" then
            io.write(": "..data.count.."\n")
        else
            io.write("\n")
            io.write("   count: "..data.count.."\n")
            io.write("  chests: ")
            for _, id in ipairs(data.chestIDs) do
                io.write(id.." ")
            end
            io.write("\n")
        end
        io.flush()
    end
    io.close()
end

--#### Running Code
local currentChest = 1

for y=1,height do
    if y ~= 1 then up() end
    for x=1,width do
        if x ~= 1 then right() end
        local chest = peripheral.wrap("front")
        for _, item in pairs(chest.list()) do
            logItem(item.name, item.count, currentChest)
        end
        currentChest = currentChest + 1
    end
    left(width-1)
end

down(height-1)
left(width-1)
writeToLog()