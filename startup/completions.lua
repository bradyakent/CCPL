local complete = require("cc.shell.completion")
local CCPLdir = fs.getDir(shell.dir())

shell.setCompletionFunction(CCPLdir.."/programs/gist.lua",complete.build(
    { complete.choice, {"install ", "update "} },
    complete.file
))