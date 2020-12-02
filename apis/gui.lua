local termWidth, termHeight = term.getSize()

-- helper functions
local function listAdd(list, item)
    list = { next=list, value=item }
    return true
end

local function listRemove(list, item)
    local previous
    local current = list
    while current and current.value ~= item do
        previous = current
        current = current.next
    end
    if not current then return false end
    if current.value == item then
        previous.next = current.next
    end
    return current.value
end

local function toBlit(color)
    return string.format("%x", math.floor(math.log(color) / math.log(2)))
end

local function snip(string1, string2, i)
    if type(string1) ~= "string" then error("expected string, got "..type(string1),2) end
    if type(string2) ~= "string" then error("expected string, got "..type(string2),2) end
    if type(i) ~= "number" then error("expected number, got "..type(i),2) end
    if (i == 1) and string1:len() == string2:len() then
        return string2
    else
        return string1:sub(1,i-1)..string2:sub(1,string1:len()-i+1)..string1:sub(i+string2:len())
    end
end

-- set up buffer for displaying GUI elements
local buffer = {
    text={},
    textColors={},
    bgColors={},
    changedLines={}
}
for line=1,termHeight do
    buffer.text[line] = string.rep(" ",termWidth)
    buffer.textColors[line] = string.rep(toBlit(term.getTextColor()),termWidth)
    buffer.bgColors[line] = string.rep(toBlit(term.getBackgroundColor()),termWidth)
    buffer.changedLines[line] = true
end

local function render()
    for line=1,termHeight do
        if buffer.changedLines[line] then
            term.setCursorPos(1,line)
            term.blit(buffer.text[line],buffer.textColors[line],buffer.bgColors[line])
            buffer.changedLines[line] = false
        end
    end
end

-- keep track of a list of guiObjects
local objectList = nil

local guiObject = {
    x=0,
    y=0,
    width=0,
    height=0,
    text={},
    textColors={},
    bgColors={},
    textColor=colors.white,
    bgColor=colors.black
}

function guiObject:new(x1, y1, x2, y2, textColor, bgColor)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x1 = x1
    o.y1 = y1
    o.width = x2 - x1 + 1
    o.height = y2 - y1 + 1
    if textColor then o.textColor = textColor end
    if bgColor then o.bgColor = bgColor end
    for line=1,o.height do
        o.text[line] = (" "):rep(o.width)
        o.textColors[line] = toBlit(o.textColor):rep(o.width)
        o.bgColors[line] = toBlit(o.bgColor):rep(o.width)
    end
    listAdd(objectList,o)
    return o
end

function guiObject:delete()
    listRemove(objectList,self)
end

function guiObject:contains(x, y)
    return (
        x >= self.x1 and x <= self.x1 + self.width - 1 and
        y >= self.y1 and y <= self.y1 + self.height - 1
    )
end

function guiObject:blit(text, textColors, bgColors)
    self.text = text
    self.textColors = textColors
    self.bgColors = bgColors
end

function guiObject:setBgColor(color, x1, y1, x2, y2)
    if color then self.bgColor = color end
    x1 = x1 or 1
    y1 = y1 or 1
    local lines = self.height
    local width = self.width
    if y2 then
        lines = y2 - y1 + 1
    end
    if x2 then
        width = x2 - x1 + 1
    end
    for line=y1,y1+lines-1 do
        self.bgColors[line] = snip(self.bgColors[line], toBlit(self.bgColor):rep(width), x1)
    end
end

function guiObject:setTextColor(color, x1, y1, x2, y2)
    if color then self.textColor = color end
    x1 = x1 or 1
    y1 = y1 or 1
    local lines = self.height
    local width = self.width
    if y2 then
        lines = y2 - y1 + 1
    end
    if x2 then
        width = x2 - x1 + 1
    end
    for line=y1,y1+lines-1 do
        self.textColors[line] = snip(self.textColors[line], toBlit(self.textColor):rep(width), x1)
    end
end

function guiObject:setText(text, x, y)
    x = x or 1
    y = y or 1
    self.text[y] = snip(self.text[y], text, x)
end

function guiObject:clearText(x1, y1, x2, y2)
    x1 = x1 or 1
    y1 = y1 or 1
    local lines = self.height
    local width = self.width
    if y2 then
        lines = y2 - y1 + 1
    end
    if x2 then
        width = x2 - x1 + 1
    end
    for line=y1,y1+lines-1 do
        self.text[line] = snip(self.text[line], (" "):rep(width), x1)
    end
end

function guiObject:loadBuffer()
    local lineDisplayed = {}
    for bLine=self.y1, self.y1+self.height-1 do
        lineDisplayed = {
            text=buffer.text[bLine],
            textColors=buffer.textColors[bLine],
            bgColors=buffer.bgColors[bLine]
        }
        buffer.text[bLine] = snip(buffer.text[bLine], self.text[bLine-self.y1+1], self.x1)
        buffer.textColors[bLine] = snip(buffer.textColors[bLine], self.textColors[bLine-self.y1+1], self.x1)
        buffer.bgColors[bLine] = snip(buffer.bgColors[bLine], self.bgColors[bLine-self.y1+1], self.x1)
        if (
            buffer.text[bLine] ~= lineDisplayed.text or
            buffer.textColors[bLine] ~= lineDisplayed.textColors or
            buffer.bgColors[bLine] ~= lineDisplayed.bgColors
        ) then buffer.changedLines[bLine] = true end
    end
end

function guiObject:fillText(color, x1, y1, x2, y2)
    self:setTextColor(color, x1, y1, x2, y2)
    self:loadBuffer()
end

function guiObject:write(text, x, y, color)
    if type(text) == "string" then text = { text } end
    if type(text) == "number" then text = { tostring(text) } end
    if type(text) ~= "table" then error("expecting string or table, got "..type(text), 2) end
    for line=y,y+#text-1 do
        self:setText(text[line-y+1], x, line)
        if color then self:setTextColor(color, x, line, x+text[line-y+1]:len(), line) end
    end
    self:loadBuffer()
end

function guiObject:fill(color, keepText)
    self:setBgColor(color)
    if not keepText then
        self:clearText()
    end
    self:loadBuffer()
end

function guiObject:draw(color, x1, y1, x2, y2, keepText)
    x2 = x2 or x1
    y2 = y2 or y1
    self:setBgColor(color, x1, y1, x2, y2)
    if not keepText then
        self:clearText()
    end
    self:loadBuffer()
end

function guiObject:drawHollow(color, x1, y1, x2, y2, keepText)
    x2 = x2 or x1
    y2 = y2 or y1
    self:setBgColor(color, x1, y1, x2, y1) -- top
    self:setBgColor(color, x1, y2, x2, y2) -- bottom
    self:setBgColor(color, x1, y1, x1, y2) -- left
    self:setBgColor(color, x2, y1, x2, y2) -- right
    if not keepText then
        self:clearText()
    end
    self:loadBuffer()
end

local function objAt(x, y)
    local currListItem = objectList
    while currListItem and not currListItem.value:contains(x, y) do
        currListItem = currListItem.next
    end
    if currListItem then return currListItem.value end
    return nil
end

return {
    render=render,
    Object=guiObject,
    objAt=objAt
}