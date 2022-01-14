--#### Module gui.lua ################
-- The gui module can be used to draw a GUI to the screen of a computer or turtle.
--
-- To use gui.lua, you have access to `Screen` and `Object`.
--
-- `Screen` is a very fast wrapper for drawing to the screen.
-- You "write" data to the `Screen`'s buffers, then render the `Screen` all at once.
--
-- `Object` allows a more abstract method of interacting with a `Screen` instance.
-- `Object`s can be drawn within, filled with a color, written onto with text, and moved within the dimensions of its attached `Screen`.
-- Once the `Object` has been drawn to its `Screen`, calling `:render()` on that `Screen` instance will draw the `Object` to the `Screen`.
--
-- Please note that drawing an `Object` to a `Screen` will *not* immediately display that `Object` on the `Screen`.
-- Instead, you must `:render()` the `Screen` for the `Object` to display.

--#### Setup #########################

-- Imported modules:
local expect = require("/ccpl")("expect").expect

-- toBlit converts a normal CC color value to its `blit` equivalent.
local function toBlit(color)
    return string.format("%x", math.floor(math.log(color) / math.log(2)))
end

--#### GUI Constructs ##########################

--## Buffer:
-- The Buffer class is an abstraction of one "layer" of a `Screen`.
-- The three layers of a `Screen` are the background color layer,
-- the text color layer, and the text layer. Each one of these layers runs on a Buffer,
-- which actually holds the data stored in the `Screen`.
--
-- The Buffer class isn't an exported class, so most users of the gui module won't need to know about it.
-- Nonetheless, knowing how it works is a good thing, so here's the documentation.

-- Buffer is a class which abstracts a 2d array of character data.
-- It's used as part of `Screen`.
local Buffer = {}
Buffer.__index = Buffer

-- creates a new instance of `Buffer` of width `width` and height `height`.
-- Also fills the entire `Buffer` with `fillChar`.
function Buffer:new(fillChar, width, height) -- returns: Buffer
    expect(1, fillChar, "string")
    expect(2, width, "number")
    expect(3, height, "number")

    local o = {}
    for line=1,height do
        o[line] = string.rep(fillChar,width)
    end
    o.width = width
    o.height = height
    setmetatable(o, Buffer)
    return o
end

-- pushes `newData` into the `Buffer` at line `line`.
-- Optionally offset the data horizontally by `xOffset` characters.
function Buffer:pushData(newData, line, xOffset) -- returns: boolean
    expect(1, newData, "string")
    expect(2, line, "number")
    expect(3, xOffset, "number", "nil")
    if line < 1 then error("Arg 2 must be > 0", 2) end
    
    xOffset = xOffset or 1
    if xOffset < 1 then error("Arg 3 must be > 0", 2) end
    
    local oldLine = self[line]
    if xOffset == 1 and newData:len() == self[line]:len() then
        self[line] = newData
    else
        self[line] =
            self[line]:sub(1,xOffset-1).. -- first section of Buffer[line+yOffset]
            newData:sub(1,self.width-xOffset+1).. -- newData up to the end of the available buffer
            self[line]:sub(xOffset+newData:len()) -- finish string by appending whatever's left of the original line
    end
    -- return true if data has changed
    return self[line] ~= oldLine
end

--## Screen:
-- (TODO) Screen description here

-- The Screen class is an abstraction of the CC function `term.blit()`, the fastest way to display data in a CC terminal.
-- Using it is far easier than using `term.blit()` directly, which is why I made it.
local Screen = {}
Screen.__index = Screen


-- Creates a new `Screen` instance of width `width` and height `height`.
-- There's an optional `debug` param, but you shouldn't need that.
function Screen:new(width, height, debug) -- returns: Screen
    expect(1, width, "number")
    expect(2, height, "number")
    expect(3, debug, "boolean", "nil")
    if width < 1 then error("Arg 1 must be > 0", 2) end
    if height < 1 then error("Arg 2 must be > 0", 2) end

    local o = {}
    o.width = width
    o.height = height
    o.debug = (debug == true)
    o.buffers = {}
    o.buffers.text = Buffer:new(" ",width,height)
    o.buffers.textColor = Buffer:new(toBlit(colors.white),width,height)
    o.buffers.bgColor = Buffer:new(toBlit(colors.black),width,height)
    o.changedLines = {}
    for line=1,height do o.changedLines[line] = true end
    setmetatable(o, Screen)
    return o
end

-- Renders the `Screen`'s data onto its defined area on the display.
--
-- (BUG) All `Screen` instances are locked to the top left corner of the display.
-- A possible workaround for this is wrapping a `Screen` instance inside of a terminal window.
function Screen:render()
    for line=1,self.height do
        if self.debug then
            self.changedLines[line] = false
        elseif self.changedLines[line] then
            term.setCursorPos(1,line)
            term.blit(self.buffers.text[line],self.buffers.textColor[line],self.buffers.bgColor[line])
            self.changedLines[line] = false
        end
    end
end

-- Updates the `Screen`'s text `Buffer`, as well as the `changedLines` table.
-- `nText` is the data written to the `Buffer`, and it's top-left corner is located at `(x, y)`.
function Screen:updateText(nText, x, y)
    expect(1, nText, "table", "string")
    expect(2, x, "number")
    expect(3, y, "number")
    local snip = math.abs(math.min(x-1,0)) + 1

    if type(nText) == "string" then nText = { nText } end
    for dataLine=1, math.min(#nText, self.height-y+1) do
        if dataLine + y - 1 > 0 then
            self.changedLines[dataLine + y - 1] =
                -- pushData() returns true if the data has changed the line
                self.buffers.text:pushData(nText[dataLine]:sub(snip), dataLine + y - 1, math.max(x,1))
                -- if it hasn't, leave changedLines[] alone
                or self.changedLines[dataLine + y - 1]
        end
    end
end

-- Updates the `Screen`'s text color `Buffer`, as well as the `changedLines` table.
-- `nTextColor` is the data written to the `Buffer`, and it's top-left corner is located at `(x, y)`.
function Screen:updateTextColor(nTextColor, x, y)
    expect(1, nTextColor, "table", "string")
    expect(2, x, "number")
    expect(3, y, "number")
    local snip = math.abs(math.min(x-1,0)) + 1

    if type(nTextColor) == "string" then nTextColor = { nTextColor } end
    for dataLine=1, math.min(#nTextColor, self.height-y+1) do
        if dataLine + y - 1 > 0 then
            self.changedLines[dataLine + y - 1] =
            -- pushData() returns true if the data has changed the line
                self.buffers.textColor:pushData(nTextColor[dataLine]:sub(snip), dataLine + y - 1, math.max(x,1)) or
                -- if it hasn't, leave changedLines[] alone
                self.changedLines[dataLine + y - 1]
        end
    end
end

-- Updates the `Screen`'s background color `Buffer`, as well as the `changedLines` table.
-- `nBgColor` is the data written to the `Buffer`, and it's top-left corner is located at `(x, y)`.
function Screen:updateBgColor(nBgColor, x, y)
    expect(1, nBgColor, "table", "string")
    expect(2, x, "number")
    expect(3, y, "number")
    local snip = math.abs(math.min(x-1,0)) + 1

    if type(nBgColor) == "string" then nBgColor = { nBgColor } end
    for dataLine=1, math.min(#nBgColor, self.height-y+1) do
        if dataLine + y - 1 > 0 then
            self.changedLines[dataLine + y - 1] =
            -- pushData() returns true if the data has changed the line
                self.buffers.bgColor:pushData(nBgColor[dataLine]:sub(snip), dataLine + y - 1, math.max(x,1)) or
                -- if it hasn't, leave changedLines[] alone
                self.changedLines[dataLine + y - 1]
        end
    end
end

local list = {}

local GUIObject = {}
GUIObject.__index = GUIObject

function GUIObject:new(screen, x, y, width, height)
    expect(1, screen, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")

    local o = {}
    o.screen = screen
    o.x = x
    o.y = y
    o.width = width
    o.height = height
    setmetatable(o, GUIObject)

    o.listIndex = #list+1
    list[#list+1] = o
    return o
end

function GUIObject:move(newX, newY)
    expect(1, newX, "number")
    expect(2, newY, "number")
    self.x = newX
    self.y = newY
end

function GUIObject:delete()
    list:remove(self.listIndex)
end

function GUIObject:draw(x, y, color, width, height)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, color, "number")
    expect(4, width, "number", "nil")
    expect(5, height, "number", "nil")
    if not self:contains(x+self.x-1, y+self.y-1) then error("coords must be in GUIObject bounds", 2) end

    width = width or 1
    height = height or 1
    if width > self.width then error("Arg 4 must be < GUIObject width", 2) end
    if height > self.height then error("Arg 5 must be < GUIObject height", 2) end

    local bgColor = toBlit(color)
    local result = {}
    for i=1,height do
        result[i] = bgColor:rep(width)
    end
    self.screen:updateBgColor(result, self.x + x - 1, self.y + y - 1)
end

function GUIObject:fill(color, textColor)
    expect(1, color, "number")
    expect(2, textColor, "boolean", "nil")

    local color_hex = toBlit(color)
    local result = {}
    for i=1,self.height do
        result[i] = color_hex:rep(self.width)
    end
    if textColor then
        self.screen:updateTextColor(result, self.x, self.y)
    else
        self.screen:updateBgColor(result, self.x, self.y)
    end
end

function GUIObject:write(x, y, text, color)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, text, "string")
    expect(4, color, "number", "nil")
    if not self:contains(x+self.x-1, y+self.y-1) then error("coords must be in GUIObject bounds", 2) end

    self.screen:updateText(text:sub(1,x+self.width-1), self.x + x - 1, self.y + y - 1)
    if color then
        local textColor = toBlit(color)
        self.screen:updateTextColor(textColor:rep(#text:sub(1,x+self.width-1)), self.x + x - 1, self.y + y - 1)
    end
end

function GUIObject:erase(x, y, width, height)
    expect(1, x, "number", "nil")
    expect(2, y, "number", "nil")
    expect(3, width, "number", "nil")
    expect(4, height, "number", "nil")
    x = x or 1
    y = y or 1
    width = width or self.width
    height = height or self.height

    if not self:contains(x+self.x-1, y+self.y-1) then error("coords must be in GUIObject bounds", 2) end
    if width > self.width then error("Arg 4 must be < GUIObject width", 2) end
    if height > self.height then error("Arg 5 must be < GUIObject height", 2) end

    local result = {}
    for i=1,height do
        result[i] = (" "):rep(width)
    end
    self.screen:updateText(result, self.x + x - 1, self.y + y - 1)
end

function GUIObject:highlight(x, y, color, width, height)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, color, "number")
    expect(4, width, "number", "nil")
    expect(5, height, "number", "nil")
    if not self:contains(x+self.x-1, y+self.y-1) then error("coords must be in GUIObject bounds", 2) end

    width = width or 1
    height = height or 1
    if width > self.width then error("Arg 4 must be < GUIObject width", 2) end
    if height > self.height then error("Arg 5 must be < GUIObject height", 2) end

    local textColor = toBlit(color)
    local result = {}
    for i=1,height do
        result[i] = textColor:rep(width)
    end
    self.screen:updateTextColor(result, self.x + x - 1, self.y + y - 1)
end

function GUIObject:contains(x, y)
    return (
        -- if x and y are in the bounds of the object, return true.
        x >= self.x and x <= self.x + self.width - 1 and
        y >= self.y and y <= self.y + self.height - 1
    )
end

return {
    Screen=Screen,
    Object=GUIObject,
    list=list
}