local slots = {}

--Easily display what needs to be in each slot
function slots.displaySlots(itemTable)
    local w, displayHeight = term.getSize()
    local linesPrinted = 0
    for i=1,16 do
        if itemTable[i] ~= nil then 
            if itemTable[i].amount ~= 0 then
                print("Slot "..i..": "..itemTable[i].name.." - "..itemTable[i].amount)
                linesPrinted = linesPrinted + 1
                if linesPrinted == displayHeight - 2 then
                    print("Press enter to scroll")
                    read()
                    linesPrinted = 0
                end
            end
        end
    end
    print("Press enter to continue")
    read()
end

return slots