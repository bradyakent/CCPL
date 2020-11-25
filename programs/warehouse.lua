local _p = settings.get("ccpl.path")
local storage = require(_p.."ccpl.apis.storage")
local ux = require(_p.."ccpl.apis.ux")

local args = { ... }

local usage = {
    {"new",{"depth",{"height"}}},
    {"get",{"item-name",{"amt",{"...",nil,true}}}},
    {"get",{"location",{"amt",{"...",nil,true}}}},
    {"put"},
    {"list"}
}

-- error checking
if (
    (args[1] ~= "get" and args[1] ~= "put" and args[1] ~= "list" and args[1] ~= "new") or
    (args[1] == "get" and #args < 3) or
    (args[1] == "new" and (#args ~= 3 or tonumber(args[2]) == nil or tonumber(args[3]) == nil))
) then
    ux.displayUsage("warehouse",usage)
    do return end
end

if args[1] == "new" then
    if fs.exists("info.wh") then
        if not ux.confirm("info.wh already exists! Would you like to replace it?",colors.red) then do return end end
    end
    storage.resize(tonumber(args[2]),tonumber(args[3]))
    storage.update("info.wh")
    print("info.wh created!")
    do return end
end
if not fs.exists("info.wh") then
    print("info.wh not found! Run \"warehouse new <depth> <height>\" to generate info.wh.")
    do return end
end

storage.sync("info.wh")

if args[1] == "get" then
    -- parse arguments
    local itemTable = {}
    for i=2,#args,2 do
        if tonumber(args[i]) ~= nil then -- if the user is using locations instead of item names, query for them
            if storage.queryLocation(tonumber(args[i])) == nil then
                print("Location "..args[i].." is empty!")
                do return end
            end
            args[i] = storage.queryLocation(tonumber(args[i])).name
        end
        itemTable[i/2] = { name=args[i], amount=tonumber(args[i+1]) }
    end

    -- try getting items
    local passed, failReason = storage.get(itemTable)

    -- only update file if storage.get() passed (turtle doesn't do anything on a fail)
    if not passed then
        if failReason == "Not enough items" then
            print("The warehouse couldn't find all/enough of the requested items.")
        else
            print("The turtle can't hold so many items, try removing some requested items.")
        end
        do return end
    end
    storage.update("info.wh")
elseif args[1] == "put" then
    -- put away all items
    local passed, failReason = storage.put()

    -- update file right away; even on fail, the turtle may put some items away.
    storage.update("info.wh")

    -- warn user about failure
    if not passed then
        if failReason == "Warehouse full" then
            print("The warehouse couldn't store some items, try expanding it.")
        end
    end
elseif args[1] == "list" then
    storage.list()
end