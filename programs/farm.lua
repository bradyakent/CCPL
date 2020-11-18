-- implements basic farming API usage
local _p = settings.get("ccpl.path")
local farming = require(_p.."ccpl.apis.farming")

local function printUsage()
    print("Usage:")
    print("farm create <x> <y>")
    print("farm harvest <x> <y>")
end

local args = { ... }

-- error checking
if type(args[2]) ~= "number" or type(args[3]) ~= "number" then
    printUsage()
    do return end
end
if args[2] < 1 or args[3] < 1 then
    printUsage()
    do return end
end

if args[1] == "create" then
    farming.createFarm(args[2], args[3])
elseif args[1] == "harvest" then
    farming.farm(args[2], args[3])
else
    printUsage()
end