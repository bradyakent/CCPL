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

local function printCompletion(theShell, thisArg, prevArgs, text)
    if #prevArgs == 1 then
        return complete.choice(theShell, text, prevArgs, "scan ", "print ")
    end
    if prevArgs[2] == "scan" then
        if #prevArgs < 5 then
            return nil
        end
        return complete.file(theShell, text)
    elseif prevArgs[2] == "print" then
        return complete.file(theShell, text)
    end
end
--programs/3dprint.lua
shell.setCompletionFunction(CCPLPath.."ccpl/programs/3dprint.lua",complete.build({ printCompletion, many=true }))
