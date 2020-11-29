local _p = settings.get("ccpl.path")
local gui = require(_p.."ccpl.apis.gui")
local storage = require(_p.."ccpl.apis.storage")

if not fs.exists("info.wh") then
    print("info.wh does not exist! \nRun \"warehouse new <depth> <height>\" to generate info.wh.")
    do return end
end

local width, height = term.getSize()
local mainLoop = true

local exitButton = gui.Object:new(width-6,1,width,1)
exitButton:fill(colors.red)
exitButton:write("Close",2,1,colors.white)
function exitButton:onClick()
    mainLoop = false
end

local helper = gui.Object:new(1, height, width, height)

local listingLabels = gui.Object:new(1,1,width-8,1)
listingLabels:write("i    Block Name", 1, 1)
listingLabels:write("Stock Pull", listingLabels.width-9, 1)

local listing = gui.Object:new(1,2,width-8,height-1)
listing.scrollOffset = 1
listing.length = 1
listing.displayed = {}
listing.list = {}
listing.requested = {}
listing.requested.n = 0
listing:fill(colors.black)

function listing:populate()
    local list = { table.unpack(storage.list(), listing.scrollOffset) }
    listing.length = 0
    listing.displayed = {}
    for _, item in ipairs(list) do
        listing.displayed[#listing.displayed+1] = item
        listing.length = listing.length + 1
        if not listing:contains(1,listing.length + listing.y1 - 1) then break end
        listing:draw(colors.black, 1, listing.length, listing.width, listing.length)
        local itemText = item.location..": "..item.name:sub(item.name:find(":")+1)
        if #itemText > listing.width - 10 then
            itemText = itemText:sub(1,listing.width - 13).."..."
        end
        listing:write(itemText, 1, listing.length, colors.white, colors.black)
        listing:write(tostring(item.amount), listing.width-#tostring(item.amount)-4, listing.length, colors.white, colors.black)
        listing:draw(colors.gray, listing.width-3, listing.length, listing.width, listing.length)
        if listing.requested[item.location] then
            listing:write(tostring(listing.requested[item.location]), listing.width-#tostring(listing.requested[item.location])+1, listing.length, colors.white, colors.gray)
        else
            listing:write(tostring(0), listing.width, listing.length, colors.white, colors.gray)
        end
    end
    gui.render()
end

function listing:onClick(x, y)
    local innerX = listing:x(x)
    local innerY = listing:y(y)
    if innerX >= 1 and innerX <= listing.width - 10 then
        helper:fill(colors.black)
        helper:write(listing.displayed[innerY].name:sub(listing.displayed[innerY].name:find(":")+1),1,1,colors.yellow,colors.black)
        gui.render()
    elseif innerX >= listing.width-3 and innerX <= listing.width then
        if listing.displayed[innerY] then
            helper:fill(colors.black)
            helper:write("Press enter when done...", 1, 1, colors.yellow, colors.black)
            local userIn
            listing:draw(colors.gray,listing.width-3,innerY,listing.width,innerY)
            gui.render()
            term.setCursorPos(listing.width-3,y)
            userIn = tonumber(read())
            if not userIn then userIn = 0 end
            helper:fill(colors.black)
            listing.requested[listing.displayed[innerY].location] = tonumber(userIn)
            if (listing.displayed[innerY].location > listing.requested.n) then listing.requested.n = listing.displayed[innerY].location end
        end
    end
    gui.render()
end

function listing:onScroll(direction)
    listing.scrollOffset = listing.scrollOffset + direction
    if #listing.list - listing.scrollOffset < listing.height then
        listing.scrollOffset = #listing.list - listing.height + 1
    end
    if listing.scrollOffset < 1 then
        listing.scrollOffset = 1
    end
end

local clearButton = gui.Object:new(width-6,height-9,width,height-7)
clearButton:fill(colors.blue)
clearButton:write("Clear",2,2,colors.white)
function clearButton:onClick()
    listing.requested = {}
    listing.requested.n = 0
end

local getButton = gui.Object:new(width-6,height-6,width,height-4)
getButton:fill(colors.cyan)
getButton:write("Get",3,2,colors.white)
function getButton:onClick()
    helper:fill(colors.black)
    helper:write("Getting items...", 1, 1, colors.yellow, colors.black)
    gui.render()
    local itemTable = {}
    for i=1,listing.requested.n do
        if listing.requested[i] then
            itemTable[#itemTable+1] = { name=storage.queryLocation(i).name, amount=listing.requested[i] }
        end
    end
    local passed, failReason = storage.get(itemTable)
    if not passed then
        if failReason == "Not enough items" then
            helper:fill(colors.black)
            helper:write("Not enough of the requested items.", 1, 1, colors.red, colors.black)
            gui.render()
        else
            helper:fill(colors.black)
            helper:write("The turtle can't hold that many items.", 1, 1, colors.red, colors.black)
            gui.render()
        end
    else
        helper:fill(colors.black)
        helper:write("Done!", 1, 1, colors.green, colors.black)
        storage.update("info.wh")
        listing.requested = {}
        listing.requested.n = 0
    end
end

local putButton = gui.Object:new(width-6,height-3,width,height-1)
putButton:fill(colors.blue)
putButton:write("Put", 3, 2, colors.white)
function putButton:onClick()
    helper:write("Putting away items...", 1, 1, colors.yellow, colors.black)
    gui.render()
    local passed, failReason = storage.put()
    storage.update("info.wh")
    if not passed then
        if failReason == "Warehouse full" then
            helper:fill(colors.black)
            helper:write("Warning: Warehouse full", 1, 1, colors.red, colors.black)
            gui.render()
        end
    else
        helper:fill(colors.black)
        helper:write("Done!", 1, 1, colors.green, colors.black)
        gui.render()
    end
end

storage.sync("info.wh")
listing.list = storage.list()
helper:fill(colors.black)
helper:write("Click on an item to see its name", 1, 1, colors.yellow)
while mainLoop do
    listing:populate()
    gui.render()
    local e, b, x, y = os.pullEvent()
    if e ~= "mouse_up" and e ~= "key_up" then helper:fill(colors.black) end
    if e == "mouse_click" then
        local clicked = gui.objAt(x, y)
        if clicked then clicked:onClick(x, y) end
        storage.sync("info.wh")
        listing.list = storage.list()
    elseif e == "mouse_scroll" then
        listing:onScroll(b)
    end
end

term.setBackgroundColor(colors.black)
term.setCursorPos(1,1)
term.clear()
print("nice")