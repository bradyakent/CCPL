local complete = require("cc.shell.completion")
local CCPLPath = settings.get("ccpl.path")

local function fileIf(theShell, thisArg, prevArgs, text)
    if prevArgs[2] == text then
        return complete.file(theShell, thisArg)
    end
end

-- programs/gist.lua
shell.setCompletionFunction(CCPLPath.."ccpl/programs/gist.lua",complete.build(
    { complete.choice, {"install ", "update "} },
    { fileIf, "update " }
))

--programs/farm.lua
shell.setCompletionFunction(CCPLPath.."ccpl/programs/farm.lua",complete.build({ complete.choice, {"create ", "harvest "} }))