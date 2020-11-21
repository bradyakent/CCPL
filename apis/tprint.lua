local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.tex")
local ux = require(_p.."ccpl.apis.ux")

local function getIndex(array, value)
    for i, item in ipairs(array) do
        if item.name == value then
            return i
        end
    end
    return nil
end

local function extrude(data, currIndex)
    if data[currIndex] ~= 0 then
        tex.select(data[currIndex])
        tex.placeDown()
    end
end

local function handleBlock(tcodeObj, up)
    local func = (up and tex.inspectUp or tex.inspect)
    if func() then
        local _, block = func()
        local material = getIndex(tcodeObj.materials, block.name)
        if material then
            tcodeObj.materials[material].amount = tcodeObj.materials[material].amount + 1
            tcodeObj.data[#tcodeObj.data + 1]=material
        else
            tcodeObj.materials[#tcodeObj.materials + 1] = { name=block.name, amount=1 }
            tcodeObj.data[#tcodeObj.data + 1] = #tcodeObj.materials
        end
    else
        tcodeObj.data[#tcodeObj.data + 1] = 0
    end
end

local function scan(width, height, depth)
    local result = {
        width=width,
        height=height,
        depth=depth,
        data={},
        instructions={},
        materials={}
    }
    handleBlock(result)
    tex.forward(1,true)
    for instruction in tex.vPath(width, height, depth) do
        result.instructions[#result.instructions + 1] = instruction
        if instruction == "left" then
            tex.left()
            handleBlock(result)
            tex.forward(1,true)
        elseif instruction == "right" then
            tex.right()
            handleBlock(result)
            tex.forward(1,true)
        elseif instruction == "up" then
            handleBlock(result,true)
            tex.up(1,true)
        elseif instruction == "forward" then
            handleBlock(result)
            tex.forward(1,true)
        elseif instruction == "back" then
            tex.turnAround()
            handleBlock(result)
            tex.forward(1,true)
        end
    end
    return result
end

local function print(tcodeObj)
    ux.displaySlots(tcodeObj.materials)
    tex.up()
    for i in ipairs(tcodeObj.data) do
        extrude(tcodeObj.data, i)
        if tcodeObj.instructions[i] == "left" then
            tex.left()
            tex.forward()
        elseif tcodeObj.instructions[i] == "right" then
            tex.right()
            tex.forward()
        elseif tcodeObj.instructions[i] == "up" then
            tex.up()
        elseif tcodeObj.instructions[i] == "forward" then
            tex.forward()
        elseif tcodeObj.instructions[i] == "back" then
            tex.turnAround()
            tex.forward()
        end
    end
end

return {
    scan=scan,
    print=print
}