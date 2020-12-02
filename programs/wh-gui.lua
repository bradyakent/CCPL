local storage, gui = require("/ccpl")("storage","gui")

if not fs.exists("info.wh") then
    print("info.wh does not exist! \nRun \"warehouse new <depth> <height>\" to generate info.wh.")
    do return end
end
storage.sync("info.wh")

local mainLoop = true

local screen = gui.Screen:new(term.getSize())
screen:render()

local helpDisplay = gui.Object:new(screen, 1, 1, screen.width, screen.height)

local closeButton = gui.Object:new(screen, screen.width-6, 1, 7, 1)
function closeButton:onClick()
    mainLoop = false
end

local bottomText = gui.Object:new(screen, 1, screen.height, screen.width, 1)

local listingLabel = gui.Object:new(screen, 1, 1, screen.width-6, 1)

local listing = gui.Object:new(screen, 1, 2, screen.width-6, screen.height-2)
listing:draw(listing.width-4, 1, colors.gray, 4, listing.height)
listing.list = storage.list()
listing.objects = {}
listing.inputs = {}
listing.requested = {}
listing.requested.n = 0
listing.scrollOffset = 0

local function displayClicked(object)
    if not object.helpText then return end
    bottomText:erase()
    bottomText:write(1, 1, object.helpText, colors.yellow)
end

local function handleInput(object)
    if not object.linkedLocation then return end
    bottomText:write(1, 1, "Press enter when finished", colors.yellow)
    object:erase()
    screen:render()
    term.setCursorPos(object.x,object.y)
    local userInput = read()
    if userInput:len() > 4 then userInput = 0 end
    listing.requested[object.linkedLocation] = tonumber(userInput) or 0
    if (object.linkedLocation > listing.requested.n) then listing.requested.n = object.linkedLocation end
    bottomText:erase()
end

for line=1,listing.height do
    local displayObject = gui.Object:new(screen, 1, line+listing.y-1, listing.width-5, 1)
    displayObject.onClick = displayClicked
    listing.objects[#listing.objects+1] = displayObject
    local input = gui.Object:new(screen, listing.width-4, line+listing.y-1, 4, 1)
    input.onClick = handleInput
    listing.inputs[#listing.inputs+1] = input
end

function listing:populate()
    for index, displayObject in ipairs(listing.objects) do
        displayObject:erase()
        local item = listing.list[index + listing.scrollOffset]
        if not item then return end
        local itemText = item.location..": "..item.name:sub(item.name:find(":")+1)
        if #itemText > listing.width - 10 then
            itemText = itemText:sub(1,listing.width - 13).."..."
        end
        displayObject.helpText = item.name:sub(item.name:find(":")+1)
        displayObject:write(1, 1, itemText)
        displayObject:write(displayObject.width-#tostring(item.amount), 1, tostring(item.amount))

        local input = listing.inputs[index]
        input.linkedLocation = item.location
        input:erase()
        input:write(5-#tostring(listing.requested[item.location] or 0), 1, tostring(listing.requested[item.location] or 0))
    end
end

function listing:onScroll(direction)
    listing.scrollOffset = listing.scrollOffset + direction
    if #listing.list - listing.scrollOffset < listing.height then
        listing.scrollOffset = #listing.list - listing.height
    end
    if listing.scrollOffset < 0 then
        listing.scrollOffset = 0
    end
end

local putButton = gui.Object:new(screen, screen.width-6, screen.height-8, 7, 3)
function putButton:onClick()
    storage.sync("info.wh")
    bottomText:erase()
    bottomText:write(1, 1, "Putting away items...", colors.yellow)
    screen:render()
    local passed, failReason
    if turtle then
        passed, failReason = storage.put()
    else
        passed = true
    end
    storage.update("info.wh")
    if not passed then
        if failReason == "Warehouse full" then
            bottomText:erase()
            bottomText:write(1, 1, "Warning: Warehouse full", colors.red)
        end
    else
        bottomText:erase()
        bottomText:write(1, 1, "Done!", colors.green)
    end
    listing.list = storage.list()
end

local getButton = gui.Object:new(screen, screen.width-6, screen.height-5, 7, 3)
function getButton:onClick()
    storage.sync("info.wh")
    bottomText:erase()
    bottomText:write(1, 1, "Getting items...", colors.yellow)
    screen:render()
    local itemTable = {}
    for i=1,listing.requested.n do
        if listing.requested[i] then
            itemTable[#itemTable+1] = { name=storage.queryLocation(i).name, amount=listing.requested[i] }
        end
    end
    local passed, failReason
    if turtle then
        passed, failReason = storage.get(itemTable)
    else
        passed = true
    end
    if not passed then
        if failReason == "Not enough items" then
            bottomText:erase()
            bottomText:write(1, 1, "Not enough of the requested items.", colors.red)
        else
            bottomText:erase()
            bottomText:write(1, 1, "The turtle can't hold that many items.", colors.red)
        end
    else
        bottomText:erase()
        bottomText:write(1, 1, "Done!", colors.green)
        storage.update("info.wh")
        listing.requested = {}
        listing.requested.n = 0
    end
    listing.list = storage.list()
end

local clearButton = gui.Object:new(screen, screen.width-6, screen.height-2, 7, 2)
function clearButton:onClick()
    listing.requested = {}
    listing.requested.n = 0
end

local helpButton = gui.Object:new(screen, screen.width-6, 2, 7, 3)

local function init()
    closeButton:fill(colors.red)
    closeButton:write(2,1,"Close")
    listingLabel:write(1, 1, "i   Block", colors.white)
    listingLabel:write(listingLabel.width-10, 1, "Stock Pull", colors.white)
    listing:draw(listing.width-4, 1, colors.gray, 4, listing.height)
    putButton:fill(colors.blue)
    putButton:write(3, 2, "Put")
    getButton:fill(colors.cyan)
    getButton:write(3, 2, "Get")
    helpButton:fill(colors.yellow)
    helpButton:write(2, 2,"Help!", colors.black)
    clearButton:fill(colors.lightGray)
    clearButton:write(2, 1, "Clear", colors.black)
    clearButton:write(2, 2, "Pulls", colors.black)
end

local helpText = {
    'Warehouse GUI help                     ',
    '=======================================',
    'To put items into the warehouse:       ',
    '1. Load the turtle with items          ',
    '2. Click the "Put" button              ',
    '                                       ',
    'To get items from the warehouse:       ',
    '1. Click the grey box next to the item ',
    '   you want                            ',
    '2. Type in how much you want           ',
    '3. Click the "Get" button              ',
    '                                       ',
    'Press enter to continue                ',
}
function helpButton:onClick()
    helpDisplay:erase()
    helpDisplay:fill(colors.gray)
    for line=1,#helpText do
        helpDisplay:write(1, line, helpText[line], colors.green)
    end
    screen:render()
    term.setCursorPos(1,screen.height+1)
    read()
    helpDisplay:fill(colors.black)
    helpDisplay:fill(colors.white,true)
    helpDisplay:erase()
    init()
end

init()
local event = {} -- 1 will be the event type, the following will be the return values
while mainLoop do
    if event[1] == "mouse_click" then
        local x = event[3]
        local y = event[4]
        for i, object in ipairs(gui.list) do
            if object:contains(x, y) then
                if object.onClick then
                    object:onClick(x, y)
                else
                    bottomText:erase()
                end
            end
        end
    elseif event[1] == "mouse_scroll" then
        listing:onScroll(event[2])
    elseif event[1] ~= "key_up" and event[1] ~= "mouse_up" then
        bottomText:erase()
    end

    listing:populate()
    screen:render()
    event = { os.pullEvent() }
end

term.setBackgroundColor(colors.black)
term.setCursorPos(1,1)
term.clear()