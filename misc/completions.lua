local complete = require("cc.shell.completion")

local gistFunction = complete.build(
    { complete.choice, {"install", "update"} },
    complete.file
)
shell.setCompletionFunction(fs.getDir().."programs/gist",complete.build())