local gui = require("/ccpl")("gui")

local filename = args[1]
io.input(filename)

--#### GUI setup
local mainLoop = true
local screen = gui.Screen:new(term.getSize())
screen:render()

--#### GUI Objects and methods
local resultDisplay = gui.Object:new(screen, 1, 1, screen.width, screen.height-1)
local inputField = gui.Object:new(screen, 1, screen.height, screen.width, 1)
local exitButton = gui.Object:new(screen, screen.width-6, screen.height, 4, 1)
function exitButton:onClick()
    mainLoop = false
end

--#### GUI Functions
local function initialize()
    resultDisplay:fill(colors.black, colors.white)

    inputField:fill(colors.gray, colors.white)

    exitButton:fill(colors.red, colors.white)
    exitButton:write(2, 1, "Exit")
end

--#### Other data
local query = ""
local scrollAmount = 0
local searchResults = {}

--#### Data functions
local function matches(line, inputQuery)
    if string.find(line, inputQuery, 1, true) ~= -1 then
        return true
    end
    return false
end

local function getSearchResults()
    searchResults = {}
    for i, line in ipairs(io.lines()) do
        if matches(line, query) then
            searchResults[#searchResults+1] = line
        end
    end
end

local function displayResults()
    resultDisplay:erase()
    for i=1,resultDisplay.height do
        resultDisplay.write(1, 1, searchResults[scrollAmount+i])
    end
end

--#### Main loop
initialize()
screen:render()

local event = {}
while mainLoop do
    term.setCursorBlink(true)
    event = { os.pullEvent() }
    if event[1] == "char" then
        query = query..event[2]
    elseif event[1] == "key" then
        if event[2] == keys.backspace and query ~= "" then
            query = query:sub(1, -2)
        end
    elseif event[1] == "mouse_click" then
        if exitButton:contains(event[3], event[4]) then
            mainLoop = false
        end
    end
    inputField:write(1, 1, query)

    getSearchResults()
    displayResults()
    screen:render()
end

term.setBackgroundColor(colors.black)
term.setCursorPos(1, 1)
term.clear()