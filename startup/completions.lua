local complete = require("cc.shell.completion")
local CCPLdir = fs.getDir(fs.getDir(shell.getRunningProgram()))

local function fileIf(theShell, thisArg, prevArgs)
    if prevArgs[2] == "update" then
        return complete.file(theShell, thisArg)
    end
end

shell.setCompletionFunction(CCPLdir.."/programs/gist.lua",complete.build(
    { complete.choice, {"install ", "update "} },
    fileIf
))