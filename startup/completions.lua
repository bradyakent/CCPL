local complete = require("cc.shell.completion")
local CCPLPath = settings.get("ccpl.path"):sub(2)

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

local function printCompletion(theShell, argument, prevArgs)
    if #prevArgs == 1 then
        return complete.choice(theShell, argument, prevArgs, { "scan ", "print " })
    elseif prevArgs[2] == "print" or (prevArgs[2] == "scan" and #prevArgs == 5) then
        return complete.file(theShell, argument)
    end
end
--programs/3dprint.lua
shell.setCompletionFunction(CCPLPath.."ccpl/programs/3dprint.lua",complete.build({ printCompletion, many=true }))
