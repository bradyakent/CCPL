--[[
chestnet interface:

create a network
add and remove chests from that network
    Add chest
    Remove chest
    Set chest type (Normal, Input, Output)
- Should chests have different uses? "Inputs", "Outputs", etc.?
    Maybe?
    Inputs: Cannot be pushed to (any items in an Input were placed by the player, a turtle, a hopper, etc.)
    Outputs: Cannot be pulled from (any items here will be taken by a player, turtle, etc.)
    Normal/Default: Acts as general storage
collect/"sync"/"audit" data on all items in the network
move items around the network, updating the data along the way
- What does it mean to move items? What methods would you like to have?
    Consolidate items: make full stacks so chests dont get full as fast
    Pull: get the necessary items from anywhere in the network (You cannot pull from Output chests)
    Push: put the items into the network anywhere possible (You cannot push to Input chests)

]]

local chestnet = {}
chestnet.__index = chestnet

local function makeNewItem(itemTable, chestName, slot)
    return {
        data=itemTable,
        chest=chestName,
        slot=slot
    }
end

function chestnet:create(o)
    o = o or {}
    o.connections = {}
    o.items = {}
    o.aliases = {}
    setmetatable(o, chestnet)
    return o
end

function chestnet:connect(chestName, alias)
    self.connections[chestName] = peripheral.wrap(chestName)
    if(alias) then
        self:setAlias(chestName, alias)
    end
    self.connections[chestName].type = "normal"
end

function chestnet:disconnect(chestNameOrAlias)
    self.connections:remove(self:getChest(chestNameOrAlias))

end

function chestnet:setAlias(chestName, alias)
    self.aliases[alias] = chestName
end

function chestnet:getChest(chestNameOrAlias)
    if(self.connections[chestNameOrAlias]) then
        return self.connections[chestNameOrAlias]
    end
    if(self.aliases[chestNameOrAlias] and self.connections[self.aliases[chestNameOrAlias]]) then
        return self.connections[self.aliases[chestNameOrAlias]]
    end
end

function chestnet:setType(chestNameOrAlias, type)
    if(type == "input") then
        self:getChest(chestNameOrAlias).type = "input"
    elseif(type == "output") then
        self:getChest(chestNameOrAlias).type = "output"
    else
        self:getChest(chestNameOrAlias).type = "normal"
    end
end

function chestnet:updateItemList()
    self.items = {}
    for chestName, chest in pairs(self.connections) do
        for slot, chestItem in pairs(chest.list()) do
            if not self.items[chestItem.name] then
                self.items[chestItem.name] = {}
            end
            self.items[chestItem.name][#self.items[chestItem.name]+1] = makeNewItem(chestItem, chestName, slot)
        end
    end
end

function chestnet:pull(chestNameOrAlias, itemName, count, destinationSlot)
    local foundItems = self.items[itemName]
    if not foundItems then return false, "item not in the network" end

    local destination = self:getChest(chestNameOrAlias)
    if destination.type == "input" then
        return false, "destination cannot be of type 'input'"
    end

    count = count or foundItems[1].chest.getItemDetail(foundItems[1].slot).maxCount
    for index, item in ipairs(foundItems) do
        if item.chest ~= "output" then
            local transferred = destination.pullItems(item.chest, item.slot, count, destinationSlot)
            count = count - transferred
            if count <= 0 then
                break
            end
        end
    end
    if count <= 0 then
        return false, "not enough items in the network"
    end
    return true
end

function chestnet:push(chestNameOrAlias, sourceSlot, count)
    local source = self:getChest(chestNameOrAlias)
    if source.type == "output" then
        return false, "source cannot be of type 'output'"
    end

    local sourceItem = source.getItemDetail(sourceSlot)
    count = count or sourceItem.count
    for index, item in ipairs(self.items[sourceItem.name]) do
        if item.chest == "normal" then
            local transferred = item.chest.pullItems(chestNameOrAlias, sourceSlot, count)
            count = count - transferred
            if count <= 0 then
                break
            end
        end
    end

    if count == 0 then return true end

    for _, chest in ipairs(self.connections) do
        local itemList = chest.list()
        for slot=1,chest.size() do
            if itemList[slot] == nil then
                if item.chest == "normal" then
                    local transferred = item.chest.pullItems(chestNameOrAlias, sourceSlot, count)
                    count = count - transferred
                    if count <= 0 then
                        break
                    end
                end
            end
        end
        if count <= 0 then
            break
        end
    end

    if count > 0 then
        return false, "not enough space in the network"
    end
    return true
end

return chestnet