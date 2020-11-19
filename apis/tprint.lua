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

local function handleBlock(houseObj, up)
    local func = (up and tex.inspectUp or tex.inspect)
    if func() then
        local _, block = func()
        local material = getIndex(houseObj.materials, block.name)
        if material then
            houseObj.materials[material].amount = houseObj.materials[material].amount + 1
            houseObj.data[#houseObj.data + 1]=material
        else
            houseObj.materials[#houseObj.materials + 1] = { name=block.name, amount=1 }
            houseObj.data[#houseObj.data + 1] = #houseObj.materials + 1
        end
    else
        houseObj.data[#houseObj.data + 1] = 0
    end
end

local function scan(name, width, height, depth)
    local result = {
        name=name,
        width=width,
        height=height,
        depth=depth,
        data={},
        materials={}
    }
    handleBlock(result)
    tex.forward(1,true)
    for instruction in tex.vPath(width, height, depth) do
        if instruction == "left" then
            tex.left()
            handleBlock(result)
            tex.forward(1,true)
            tex.left()
        elseif instruction == "right" then
            tex.right()
            handleBlock(result)
            tex.forward(1,true)
            tex.right()
        elseif instruction == "up" then
            tex.turnAround()
            handleBlock(result,true)
            tex.up(1,true)
        elseif instruction == "forward" then
            handleBlock(result)
            tex.forward(1,true)
        end
    end
    return result
end

local function print(houseObj)
    ux.displaySlots(houseObj.materials)
    local vPath = tex.createVPath(houseObj.width,houseObj.height,houseObj.depth)
    i = 0
    for instruction in vPath() do
        i = i + 1
        if instruction == "left" then
            tex.left()
            tex.forward()
            tex.left()
        elseif instruction == "right" then
            tex.right()
            tex.forward()
            tex.right()
        elseif instruction == "up" then
            tex.turnAround()
            tex.up()
        else
            tex.forward()
        end
        extrude(houseObj.data, i)
    end
end

return {
    scan=scan,
    print=print
}