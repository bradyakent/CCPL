local function confirm(message, color)
    if term.isColor() == false or not color then
        color = colors.white
    end
    term.setTextColor(color)
    print(message.." (y/n)")
    local userIn = read():lower()
    if userIn == "y" or userIn == "yes" then
        return true
    else
        return false
    end
end


local function _usage(prev, optionsTable, level)
	if type(optionsTable[1]) ~= "string" then
		error("option[1] must be a string",level+2)
	end
	if optionsTable[2] and type(optionsTable[2]) ~= "table" and type(optionsTable[2]) ~= "string" then
		error("option[2] must be a table, string, or nil",level+2)
	end
	if optionsTable[3] and type(optionsTable[3]) ~= "boolean" then
		error("option[3] must be a boolean or nil",level+2)
	end

	local text = prev

	if optionsTable[3] then
		text = text.." ["..optionsTable[1].."]"
	else
		text = text.." <"..optionsTable[1]..">"
	end
	
	if optionsTable[2] == nil or optionsTable[2] == {} then
		print(text)
		return true
    end
    
    if type(optionsTable[2]) == "string" then
		text = text.." <"..optionsTable[2]..">"
		print(text)
		return true
	end

	if type(optionsTable[2][1]) == "string" then
		optionsTable[2] = { optionsTable[2] }
	end
	for _, option in ipairs(optionsTable[2]) do
		assert(_usage(text, option, level + 1), "optionsTable formatted incorrectly")
		return true
	end
end

local function displayUsage(name, optionsTable)
	print("Usage:")
	for _, option in ipairs(optionsTable) do
		assert(_usage(name, option, 0), "optionsTable formatted incorrectly")
	end
end

return {
    confirm=confirm,
    displayUsage=displayUsage
}