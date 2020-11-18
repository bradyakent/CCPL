--Easily display what needs to be in each slot
local function displaySlots(itemTable)
    local _, height = term.getSize()
    local result = ""
    for i=1,16 do
        if itemTable[i] ~= nil then 
            if itemTable[i].amount ~= 0 then
                result = result..("Slot "..i..": "..itemTable[i].name.." - "..itemTable[i].amount.."\n")
            end
        end
    end
    textutils.pagedPrint(result, height - 2)
    print("Press enter to continue")
    read()
end

return {
    displaySlots = displaySlots
}