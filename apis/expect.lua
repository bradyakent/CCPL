local function expect(index, variable, ...)
    local args = {...}
    local passed = false
    local typeString = ""
    for i=1,#args do
        typeString = typeString..args[i]..","
        if type(variable) == args[i] then passed = true break end
    end
    if not passed then
        error("Arg "..index.." expected "..typeString.." got "..type(variable), 3)
    end
    return true
end

return { expect = expect }