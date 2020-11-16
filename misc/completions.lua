local gistOptions = {"install ","update "}
local function completeGist(shell, i, cText, previousParams)
    local results = {}
    if i == 1 then
        results = completeMultipleChoice(gistOptions, cText)
    elseif i == 2 and previousParams[2] == "update" then
        results = fs.complete(cText, "/", true, false)
    end
    return results
end
shell.setCompletionFunction(fs.getDir().."programs/gist",completeGist)