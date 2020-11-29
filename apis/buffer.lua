local Buffer = {
    data="",
    changed=false
}

local mt_Buffer = {
}

mt_Buffer.__index = function(instace, key) -- if key is a number, return data at key, otherwise return the function at that key
    return type(key) == "number" and instace.data:sub(key,key) or mt_Buffer[key]
end

mt_Buffer.__newindex = function(instance, key, value)
    instance.data = instance.data:sub(1,key-1)..value:sub(1,1)..instance.data:sub(key+1)
end

mt_Buffer.load = function(instance, newDataString)
    if instance.data == newDataString then return end
    instance.data = newDataString
    changed = true
end