if not term.isColor() then
    error("term doesn't support gui API", 2)
end

local guiObject = {
    x1=0,
    y1=0,
    x2=0,
    y2=0,
    bgColor=colors.black,
    textColor=colors.white
}

local guiObjectList = {}

function guiObject:new(x1, y1, x2, y2, interactable)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x1 = x1
    o.y1 = y1
    o.x2 = x2
    o.y2 = y2
    o.interactable = false
    if interactable then o.interactable = true end
    guiObjectList[#guiObjectList+1] = o
    return o
end

function guiObject:x(x)
    return x - self.x1 + 1
end

function guiObject:y(y)
    return y - self.y1 + 1
end

function guiObject:width()
    return self.x2 - self.x1 + 1
end

function guiObject:height()
    return self.y2 - self.y1 + 1
end

function guiObject:fill(color)
    if color then self.bgColor = color end
    term.setBackgroundColor(self.bgColor)
    paintutils.drawFilledBox(self.x1,self.y1,self.x2,self.y2)
end

function guiObject:contains(x, y)
    return (
        self.x1 <= x and self.x2 >= x and
        self.y1 <= y and self.y2 >= y
    )
end

function guiObject:write(x, y, text, newTextColor, newBgColor)
    if not self:contains(x + self.x1 - 1, y + self.y1 - 1) then error("coords outside of GUI object bounds",2) end
    if newTextColor then self.textColor = newTextColor end
    if newBgColor then self.bgColor = newBgColor end
    term.setTextColor(self.textColor)
    term.setBackgroundColor(self.bgColor)
    term.setCursorPos(x + self.x1 - 1, y + self.y1 - 1)
    local maxTextLength = self.x2 - x + 1
    term.write(text:sub(1,maxTextLength))
end

function guiObject:draw(x, y, color, x2, y2)
    if not self:contains(x + self.x1 - 1, y + self.y1 - 1) then error("coords outside of GUI object bounds",2) end
    if color then self.bgColor = color end
    term.setBackgroundColor(self.bgColor)
    if x2 and y2 then
        if not self:contains(x2 + self.x1 - 1, y2 + self.y1 - 1) then error("coords outside of GUI object bounds",2) end
        paintutils.drawFilledBox(x + self.x1 - 1, y + self.y1 - 1, x2 + self.x1 - 1, y2 + self.y1 - 1)
    else
        paintutils.drawPixel(x, y)
    end
end

function guiObject:blit(x, y, text, textColorString, bgColorString)
    if not self:contains(x + self.x1 - 1, y + self.y1 - 1) then error("coords outside of GUI object bounds",2) end
    term.setCursorPos(x + self.x1 - 1, y + self.y1 - 1)
    term.blit(text, textColorString, bgColorString)
end

local function objAt(x, y)
    local result
    for _, obj in ipairs(guiObjectList) do
        if obj:contains(x, y) and obj.interactable then
            result = obj
        end
    end
    return result
end

return {
    Object=guiObject,
    objAt=objAt
}