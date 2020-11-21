local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.tex")
local tprint = require(_p.."ccpl.apis.tprint")
local mobc = require(_p.."ccpl.apis.mobc")

local args = { ... }

if args[1] == "scan" then
    local tcode = tprint.scan(tonumber(args[2]),tonumber(args[3]),tonumber(args[4]))
    local mob = mobc.tcodeToMob(tcode)
    local file = fs.open("test.mob","w")
    file.write(textutils.serialize(mob))
    file.close()
    tex.down(args[3]-1)
else
    local file = fs.open("test.mob","r")
    local mob = textutils.unserialize(file.readAll())
    file.close()
    local tcode = mobc.mobToTcode(mob)
    file = fs.open("output.tcode","w")
    file.write(textutils.serialize(tcode))
    file.close()
    tprint.print(tcode)
end