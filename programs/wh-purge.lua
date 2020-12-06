local storage, tex = require("/ccpl")("storage","tex")
storage.sync("info.wh")

local list
local empty = false
while not empty do
    list = storage.list()
    if #list == 0 then empty = true break end
    local itemList = {}
    local slotsEmpty = 16
    for _, stock in ipairs(list) do
        itemList[#itemList+1] = { name=stock.name, amount=math.min(stock.amount, slotsEmpty*64) }
        slotsEmpty = slotsEmpty - math.min(math.ceil(stock.amount/64),slotsEmpty)
        if slotsEmpty == 0 then
            break
        end
    end
    storage.get(itemList)
    tex.turnAround()
    tex.dropAll()
    tex.turnAround()
end