return function(...)
	local modNames = { ... }
	local modList = {}
	for _, name in ipairs(modNames) do
		modList[#modList+1] = require("apis."..name)
	end
	return unpack(modList)
end