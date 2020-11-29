local Buffer = {}
local Buffer_mt = {
    __index=function(instance, key) -- if key is a number, get that line from this instance, otherwise call the corresponding method
        return type(key) == "number" and instance:getLine(key) or Buffer[key]
    end
}


function Buffer:new(dataString)
    return setmetatable({
        data=dataString,
        changed=true
    },Buffer_mt)
end

function Buffer:load(newDataString, start)
    if self.data == newDataString then return end
    if start then newDataString
    self.data = newDataString
    changed = true
end

function Buffer:blit()