local _p = settings.get("ccpl.path")
local gui = require(_p.."ccpl.apis.gui")
local storage = require(_p.."ccpl.apis.storage")

local width, height = term.getSize()
local mainLoop = true

term.setBackgroundColor(colors.black)
term.clear()

local exitButton = gui.Object:new(width-6,1,width,1,true)
exitButton:fill(colors.red)
exitButton:write(2,1,"Close",colors.white)
function exitButton:onClick()
    mainLoop = false
end

local helper = gui.Object:new(1,height, width, height)

local listingLabels = gui.Object:new(1,1,width-8,1)
listingLabels:write(1, 1, "i    Block Name")
listingLabels:write(listingLabels:width()-9, 1, "Stock Pull")

local listing = gui.Object:new(1,2,width-8,height-1,true)
listing.scrollOffset = 1
listing.length = 1
listing.displayed = {}
listing.list = {}
listing.requested = {}
listing.requested.n = 0

function listing:populate()
    local list = { table.unpack(storage.list(), listing.scrollOffset) }
    listing.length = 0
    listing.displayed = {}
    for _, item in ipairs(list) do
        listing.displayed[#listing.displayed+1] = item
        listing.length = listing.length + 1
        if not listing:contains(1,listing.length + listing.y1 - 1) then break end
        local itemText = item.location..": "..item.name:sub(item.name:find(":")+1)
        if #itemText > listing:width() - 10 then
            itemText = itemText:sub(1,listing:width() - 13).."..."
        end
        listing:write(1, listing.length, itemText, colors.white, colors.black)
        listing:write(listing:width()-#tostring(item.amount)-4, listing.length, tostring(item.amount), colors.white, colors.black)
        listing:draw(listing:width()-3, listing.length, colors.gray, listing:width(), listing.length)
        if listing.requested[item.location] then
            listing:write(listing:width()-#tostring(listing.requested[item.location])+1, listing.length, tostring(listing.requested[item.location]), colors.white, colors.gray)
        else
            listing:write(listing:width(), listing.length, tostring(0), colors.white, colors.gray)
        end
    end
end

function listing:onClick(x, y)
    local innerX = listing:x(x)
    local innerY = listing:y(y)
    if innerX >= 1 and innerX <= listing:width() - 10 then
        helper:write(1,1,listing.displayed[innerY].name:sub(listing.displayed[innerY].name:find(":")+1),colors.yellow,colors.black)
    elseif innerX >= listing:width()-3 and innerX <= listing:width() then
        if listing.displayed[innerY] then
            local userIn
            listing:draw(listing:width()-3,innerY,colors.gray,listing:width(),innerY)
            term.setCursorPos(listing:width()-3,y)
            userIn = tonumber(read())
            if not userIn then userIn = 0 end
            listing.requested[listing.displayed[innerY].location] = tonumber(userIn)
            if (listing.displayed[innerY].location > listing.requested.n) then listing.requested.n = listing.displayed[innerY].location end
        end
    end
end

function listing:onScroll(direction)
    listing.scrollOffset = listing.scrollOffset + direction
    if listing.scrollOffset < 1 then
        listing.scrollOffset = 1
    end
end

local clearButton = gui.Object:new(width-6,height-9,width,height-7,true)
clearButton:fill(colors.blue)
clearButton:write(2,2,"Clear",colors.white)
function clearButton:onClick()
    listing.requested = {}
    listing.requested.n = 0
end

local getButton = gui.Object:new(width-6,height-6,width,height-4,true)
getButton:fill(colors.cyan)
getButton:write(3,2,"Get",colors.white)
function getButton:onClick()
    local itemTable = {}
    for i=1,listing.requested.n do
        if listing.requested[i] then
            itemTable[#itemTable+1] = { name=storage.queryLocation(i).name, amount=listing.requested[i] }
        end
    end
    local passed, failReason = storage.get(itemTable)
    if not passed then
        if failReason == "Not enough items" then
            helper:write(1,1,"Not enough of the requested items.", colors.red, colors.black)
        else
            helper:write(1,1,"The turtle can't hold that many items.", colors.red, colors.black)
        end
    else
        storage.update("info.wh")
        listing.requested = {}
        listing.requested.n = 0
    end
end

local putButton = gui.Object:new(width-6,height-3,width,height-1,true)
putButton:fill(colors.blue)
putButton:write(3,2,"Put",colors.white)
function putButton:onClick()
    local passed, failReason = storage.put()
    storage.update("info.wh")
    if not passed then
        if failReason == "Warehouse full" then
            helper:write(1,1,"Warning: Warehouse full", colors.red, colors.black)
        end
    end
end

while mainLoop do
    storage.sync("info.wh")
    listing.list = storage.list()
    listing:fill(colors.black)
    listing:populate()
    local e, b, x, y = os.pullEvent()
    if e ~= "mouse_up" then helper:fill(colors.black) end
    if e == "mouse_click" then
        local clicked = gui.objAt(x, y)
        if clicked then clicked:onClick(x, y) end
    elseif e == "mouse_scroll" then
        listing:onScroll(b)
    end
end

term.setBackgroundColor(colors.black)
term.setCursorPos(1,1)
term.clear()