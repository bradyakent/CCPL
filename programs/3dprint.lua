-- implements basic tprint API usage
local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.tex")
local tprint = require(_p.."ccpl.apis.tprint")
local ux = require(_p.."ccpl.apis.ux")

local args = { ... }

local usage = {
    {"scan",{"width",{"height",{"depth","file-name"}}}},
    {"print","file-name"}
}

if args[1] == "scan" then
    if #args ~= 5 then ux.displayUsage("3dprint",usage) do return end end

    for i=2,4 do
        args[i] = tonumber(args[i])
        if args[i] == nil then ux.displayUsage("3dprint",usage) do return end end
    end

    if string.find(args[5], ".tcode",1,true) == nil then args[5] = args[5]..".tcode" end

    if fs.exists(args[5]) then
        if not ux.confirm(args[5].." already exists! Would you like to replace it?",colors.red) then do return end end
    end

    local file = fs.open(args[5],"w")
    file.write(textutils.serialize(tprint.scan(args[5],tonumber(args[2]),tonumber(args[3]),tonumber(args[4]))))
    file.close()

    tex.down(args[3]-1)
    tex.left()
    tex.forward(args[2]-1)
    tex.left()
    tex.forward(args[4])
    tex.turnAround()
    print("Scanned! You can print this structure by running \"3dprint print "..args[5].."\".")

elseif args[1] == "print" then
    if #args ~= 2 then ux.displayUsage("3dprint",usage) do return end end

    if fs.exists(args[2]..".tcode") then args[2] = args[2]..".tcode" end

    if not fs.exists(args[2]) then ux.displayUsage("3dprint",usage) do return end end

    local file = fs.open(args[2],"r")
    local tcodeObj = textutils.unserialize(file.readAll())
    file.close()
    tprint.print(tcodeObj)
    print("Printed!")
else
    ux.displayUsage("3dprint",usage)
end