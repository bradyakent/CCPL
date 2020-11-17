local complete = require("cc.shell.completion")
local programDir = fs.getDir(shell.dir()).."/programs/"

shell.setCompletionFunction(programDir.."gist.lua",complete.build(
    { complete.choice, {"install ", "update"} },
    complete.file
))