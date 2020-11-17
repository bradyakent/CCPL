local complete = require("cc.shell.completion")
local CCPLdir = fs.getDir(fs.getDir(shell.getRunningProgram()))

shell.setCompletionFunction(CCPLdir.."/programs/gist.lua",complete.build(
    { complete.choice, {"install ", "update "} },
    complete.file
))