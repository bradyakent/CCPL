local _p = settings.get("ccpl.path")
local tprint = require(_p.."ccpl.apis.tprint")

if read() == "yes" then
    local output = fs.open("test.hob", "w")
    output.write(textutils.serialize(tprint.scan("Test", 3, 3, 3)))
    output.close()
else
    local input = fs.open("test.hob", "r")
    tprint.print(textutils.unserialize(input.readAll()))
    input.close()
end

