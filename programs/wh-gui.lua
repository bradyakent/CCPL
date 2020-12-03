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

local searchBar = gui.Object:new(screen, 1, screen.height, screen.width, 1)
local search = { keys={} }
function search:filter(list)
    if not self.keys[1] then return list end
    local returnList = {}
    for _, item in ipairs(list) do
        local attachedKeys = {}
        for _, key in ipairs(self.keys) do
            attachedKeys[#attachedKeys+1] = key
            if not key.attach then
                local passed = true
                for _, part in ipairs(attachedKeys) do
                    if part.amount and item.amount < part.amount then
                        passed = false
                        break
                    end
                    if part.modName then
                        if not item.name:find(part.text, 1, true) then
                            passed = false
                            break
                        end
                    else
                        if not item.name:find(part.text, item.name:find(":")+1, true) then
                            passed = false
                            break
                        end
                    end
                end
                if passed then
                    returnList[#returnList+1] = item
                    break
                end
                attachedKeys = {}
            end
        end
    end
    return returnList
end
function search:generateKeys(userInput)
    local keys = {}
    for modName, text, attach, amount in userInput:gmatch("(@?)([%w_]+)(&?)(#?%d*)") do
        keys[#keys+1] = {
            text=text,
            modName=(modName == "@"),
            amount=(amount:sub(1,1) == "#" and tonumber(amount:sub(2)) or -1),
            attach=(attach == "&")
        }
    end
    self.keys = keys
end

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
    searchBar:erase()
    searchBar:write(1, 1, object.helpText, colors.yellow)
end

local function handleInput(object)
    if not object.linkedLocation then return end
    searchBar:write(1, 1, "Press enter when finished", colors.yellow)
    object:erase()
    screen:render()
    term.setCursorPos(object.x,object.y)
    local userInput = read()
    if userInput:len() > 4 then userInput = 0 end
    listing.requested[object.linkedLocation] = tonumber(userInput) or 0
    if (object.linkedLocation > listing.requested.n) then listing.requested.n = object.linkedLocation end
    searchBar:erase()
    searchBar:write(1, 1, "Click here to search...", colors.gray)
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
        displayObject.helpText = nil -- remove help text
        listing.inputs[index].linkedLocation = nil -- remove linked location for input
        local item = listing.list[index + listing.scrollOffset]
        if item then
            local itemText = item.location..": "..item.name:sub(item.name:find(":")+1)
            if #itemText > listing.width - 10 then
                itemText = itemText:sub(1,listing.width - 13).."..."
            end
            displayObject.helpText = item.name:sub(item.name:find(":")+1)
            displayObject:write(1, 1, itemText)
            displayObject:write(displayObject.width-#tostring(item.amount), 1, tostring(item.amount))

            local input = listing.inputs[index]
            input:fill(colors.gray)
            input.linkedLocation = item.location
            local stringToDisplay = "0"
            if listing.requested[item.location] and listing.requested[item.location] > 0 then
                stringToDisplay = tostring(listing.requested[item.location])
            end
            input:erase()
            input:write(5-stringToDisplay:len(), 1, stringToDisplay)
        else
            listing.inputs[index]:fill(colors.black)
            listing.inputs[index]:erase()
        end
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
    searchBar:erase()
    searchBar:write(1, 1, "Putting away items...", colors.yellow)
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
            searchBar:erase()
            searchBar:write(1, 1, "Warning: Warehouse full", colors.red)
        end
    else
        searchBar:erase()
        searchBar:write(1, 1, "Done!", colors.green)
    end
    listing.list = storage.list()
end

local getButton = gui.Object:new(screen, screen.width-6, screen.height-5, 7, 3)
function getButton:onClick()
    storage.sync("info.wh")
    searchBar:erase()
    searchBar:write(1, 1, "Getting items...", colors.yellow)
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
            searchBar:erase()
            searchBar:write(1, 1, "Not enough of the requested items.", colors.red)
        else
            searchBar:erase()
            searchBar:write(1, 1, "The turtle can't hold that many items.", colors.red)
        end
    else
        searchBar:erase()
        searchBar:write(1, 1, "Done!", colors.green)
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

    listing:erase()
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

function searchBar:onClick(_, _, prepend)
    local userInput = prepend or ""
    search.keys = {}
    listing.list = search:filter(storage.list())
    listing.scrollOffset = 0
    local cursorX, cursorY = userInput:len()+1, 1

    listing:populate()
    searchBar:erase()
    searchBar:write(1,1,userInput,colors.white)
    screen:render()
    term.setCursorPos(cursorX + self.x - 1, cursorY + self.y - 1)
    term.setCursorBlink(true)

    local inputLoop = true
    local event = {}
    while inputLoop do
        -- Handle events
        event = { os.pullEvent() }
        if event[1] == "char" then
            searchBar:write(cursorX,cursorY,event[2],colors.white)
            userInput = (cursorX + 1 < self.width - 1) and userInput..event[2] or userInput
            cursorX = math.min(self.width-1, cursorX + 1)
        elseif event[1] == "key" then
            if event[2] == keys.backspace then
                cursorX = math.max(1, cursorX - 1)
                searchBar:write(cursorX,cursorY," ",colors.white)
                userInput = userInput:sub(1,-2)
            elseif event[2] == keys.enter then
                inputLoop = false
                print(textutils.serialize(search:filter(storage.list())))
            end
        elseif event[1] == "mouse_click" then
            if not searchBar:contains(event[3],event[4]) then
                inputLoop = false
            end
            os.queueEvent(table.unpack(event))
        end

        -- Display updates
        search:generateKeys(userInput)
        listing.list = search:filter(storage.list())
        listing:populate()
        screen:render()
        term.setCursorPos(cursorX + self.x - 1, cursorY + self.y - 1)
    end
    term.setCursorBlink(false)
end

local helpText = {
    {
        'Warehouse GUI help (page 1/2)          ',
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
        'Arrows: Navigation    Enter: Close Help',
    },
    {
        'Warehouse GUI help (page 2/2)          ',
        '=======================================',
        'With the search bar, you can type a    ',
        'list of "keys" you want to display,    ',
        'separated by spaces.                   ',
        '                                       ',
        'Special characters:                    ',
        '@ - Looks for a mod name.              ',
        '& - Item names have to match all keys  ',
        '    attached by &s.                    ',
        '# - In form "key#num", "key" must have ',
        '    at least "num" items available.    ',
        'Arrows: Navigation    Enter: Close Help',
    }
}
function helpButton:onClick()
    local displayHelp = true
    local page = 1
    local event = {}
    while displayHelp do
        helpDisplay:erase()
        helpDisplay:fill(colors.black)
        for line=1,#helpText[page] do
            helpDisplay:write(1, line, helpText[page][line], (line == #helpText[page]) and (colors.yellow) or (colors.white))
        end
        screen:render()
        term.setCursorPos(1,screen.height+1)

        event = { os.pullEvent() }
        if event[1] == "key" then
            if event[2] == keys.enter then
                displayHelp = false
            elseif event[2] == keys.right then
                page = math.min(page + 1, #helpText)
            elseif event[2] == keys.left then
                page = math.max(page - 1, 1)
            end
        end
    end
    helpDisplay:fill(colors.black)
    helpDisplay:fill(colors.white,true)
    helpDisplay:erase()
    init()
end

searchBar:write(1, 1, 'Click "Help!" for more information', colors.yellow)
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
                    searchBar:erase()
                end
            end
        end
    elseif event[1] == "mouse_scroll" then
        listing:onScroll(event[2])
        searchBar:erase()
        searchBar:write(1, 1, "Click here to search...", colors.gray)
    elseif event[1] == "char" then
        searchBar:onClick(nil, nil, event[2])
    elseif event[1] and event[1] ~= "key_up" and event[1] ~= "mouse_up" then
        searchBar:erase()
        searchBar:write(1, 1, "Click here to search...", colors.gray)
    end

    listing:populate()
    screen:render()
    event = { os.pullEvent() }
end

term.setBackgroundColor(colors.black)
term.setCursorPos(1,1)
term.clear()