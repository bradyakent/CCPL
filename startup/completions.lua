local complete = require("cc.shell.completion")

shell.setCompletionFunction("gist.lua",complete.build(
    { complete.choice, {"install", "update"} },
    complete.file
))