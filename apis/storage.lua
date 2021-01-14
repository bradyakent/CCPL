--[[
warehouse object construction:
depth and height
contents:
    odds on left, evens on right
    given an index,
        find horizontal: math.floor(index/2) % depth
        find vertical: math.floor((index/2)/height)
        find side: (index%2) and "right" or "left"
]]

local tex = require("/ccpl")("tex")

local warehouse = {
    depth=0,
    height=0,
    contents={},
    requests={
        put=false
    }
}

local pos = {
    y=1,
    z=0,
    side=-1
}

local function sync(fileName)
    local file = fs.open(fileName,"r")
    warehouse.depth = tonumber(file.readLine())
    warehouse.height = tonumber(file.readLine())
    for i=1, 2*warehouse.depth*warehouse.height do
        local name = file.readLine()
        local amtStr = file.readLine()
        if name ~= "" then
            warehouse.contents[i] = {
                name = name,
                amount = tostring(amtStr)
            }
        end
    end
    warehouse.requests.put = (file.readLine() == "true")
    for i=1,#warehouse.requests do
        warehouse.requests[i] = {
            name = file.readLine(),
            location = tonumber(file.readLine()),
            amount = tonumber(file.readLine())
        }
    end
    file.close()
end

local function update(fileName)
    local file = fs.open(fileName,"w")
    file.writeLine(tostring(warehouse.depth))
    file.writeLine(tostring(warehouse.height))
    for i=1, 2*warehouse.depth*warehouse.height do
        if warehouse.contents[i] then
            file.writeLine(warehouse.contents[i].name)
            file.writeLine(tostring(warehouse.contents[i].amount))
        end
    end
    file.writeLine(tostring(warehouse.requests.put))
    for i=1,#warehouse.requests do
        file.writeLine(tostring(warehouse.requests[i].name))
        file.writeLine(tostring(warehouse.requests[i].location))
        file.writeLine(tostring(warehouse.requests[i].amount))
    end
    file.close()
end

local function resize(depth, height)
    warehouse.depth = depth
    warehouse.height = height
end

local function requestGet(itemTable)
    local slotsUsed = 0
    for _, item in ipairs(itemTable) do
        local remainingAmount = item.amount
        slotsUsed = slotsUsed + math.ceil(item.amount/64)
        --go in reverse order so the turtle favors pulling from later indexes first
        for i=(2*warehouse.depth*warehouse.height),1,-1 do
            if warehouse.contents[i] then
                if warehouse.contents[i].name == item.name then
                    warehouse.requests[#warehouse.requests+1] = {
                        name=item.name,
                        location=i,
                        amount=math.min(remainingAmount, warehouse.contents[i].amount)
                    }
                    remainingAmount = (remainingAmount - math.min(remainingAmount, warehouse.contents[i].amount))
                    warehouse.contents[i].amount = warehouse.contents[i].amount - warehouse.requests[#warehouse.requests].amount
                    if warehouse.contents[i].amount == 0 then
                        warehouse.contents[i] = nil
                    end
                    if remainingAmount == 0 then break end
                end
            end
        end
        if remainingAmount > 0 then
            return false, "Not enough items"
        end
        if slotsUsed > 16 then
            return false, "Not enough space"
        end
    end
    return true
end

local function requestPut()
    warehouse.requests.put = true
end

local function turtleGoTo(location)
    -- if facing a chest, turn straight again
    if pos.side == 0 then
        tex.left()
    elseif pos.side == 1 then
        tex.right()
    end
    pos.side = -1

    -- if location is 0, return home
    if location == 0 then
        tex.down(pos.y-1)
        tex.back(pos.z)
        pos.z = 0
        pos.y = 1
        return
    end

    local position = math.floor((location-1)/2)
    -- move to correct depth within the warehouse
    local depth = (position % warehouse.depth) + 1
    if depth < pos.z then
        tex.back(pos.z-depth)
    else
        tex.forward(depth-pos.z)
    end
    pos.z = depth

    -- move to correct height within the warehouse
    local height = math.floor(position/warehouse.depth) + 1
    if height < pos.y then
        tex.down(pos.y-height)
    else
        tex.up(height-pos.y)
    end
    pos.y = height

    -- face chest on either side
    local side = location % 2 -- 0 is right, 1 is left
    if side == 0 then
        tex.right()
    else
        tex.left()
    end
    pos.side = side
end

local function get(itemTable)
    tex.select(1)
    if itemTable then
        local passed, failReason = requestGet(itemTable)
        if not passed then
            return passed, failReason
        end
    end
    if not itemTable then
        if warehouse.requests[1] == nil then
            error("itemTable and warehouse.requests empty!",2)
        end
    end
    for _, item in ipairs(warehouse.requests) do
        turtleGoTo(item.location)
        while item.amount > 0 do
            while tex.getItemCount() > 0 do tex.select((tex.getSelectedSlot()%16) + 1) end
            tex.suck()
            item.amount = item.amount - tex.getItemCount()
        end
        tex.drop(-item.amount)
    end
    turtleGoTo(0)
    warehouse.requests = {}
    return true
end

local function put()
    local full = {}
    for slot=1,16 do
        tex.select(slot)
        local stack = tex.getItemDetail()
        if stack then
            for i=1,(2*warehouse.depth*warehouse.height) do
                if not full[i] and warehouse.contents[i] and warehouse.contents[i].name == stack.name then
                    turtleGoTo(i)
                    tex.drop()
                    warehouse.contents[i].amount = warehouse.contents[i].amount + (stack.count - tex.getItemCount())
                    stack.count = tex.getItemCount()
                    if stack.count == 0 then
                        break
                    end
                    full[i] = true
                end
            end
            if stack.count > 0 then
                for i=1,(2*warehouse.depth*warehouse.height) do
                    -- create new info if location is empty
                    if warehouse.contents[i] == nil then
                        warehouse.contents[i] = { name=stack.name, amount=0 }
                        turtleGoTo(i)
                        tex.drop()
                        warehouse.contents[i].amount = warehouse.contents[i].amount + (stack.count - tex.getItemCount())
                        stack.count = tex.getItemCount()
                        if stack.count == 0 then
                            break
                        end
                    end
                end
            end
        end
    end
    warehouse.requests.put = false
    turtleGoTo(0)
    for slot=1,16 do
        if turtle.getItemCount(slot) > 0 then
            return false, "Warehouse full"
        end
    end
    return true
end

local function audit()
    local faults = {}
    for i=1,2*warehouse.depth*warehouse.height do
        turtleGoTo(i)
        local chest = peripheral.wrap("front")
        for key, val in pairs(chest.list()) do
            if not warehouse.contents[i] then
                warehouse.contents[i] = {
                    name = val.name,
                    amount = val.count
                }
            else
                if warehouse.contents[i].name == val.name then
                    warehouse.contents[i].amount = warehouse.contents[i].amount + val.count
                else
                    faults[#faults+1] = i
                end
            end
        end
        print(textutils.serialize(warehouse.contents[i]))
    end
    turtleGoTo(0)

    if #faults > 0 then
        return false, faults
    else
        return true
    end
end

local function queryLocation(location)
    return warehouse.contents[location]
end

local function list()
    local returnList = {}
    for location=1,2*warehouse.depth*warehouse.height do
        local item = warehouse.contents[location]
        if item then
            returnList[#returnList+1] = { name=item.name, amount=item.amount, location=location }
        end
    end
    return returnList
end

return {
    resize=resize,
    requestGet=requestGet,
    requestPut=requestPut,
    get=get,
    put=put,
    update=update,
    sync=sync,
    queryLocation=queryLocation,
    list=list,
    audit=audit
}