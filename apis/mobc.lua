local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.path")

local function tcodeToMob(tcodeObj)
    local mob = {
        width=tcodeObj.width,
        height=tcodeObj.height,
        depth=tcodeObj.depth,
        model={},
        materials={}
    }
    for i=1,tcodeObj.height do
        mob.model[i] = {}
        for j=1,tcodeObj.depth do
            mob.model[i][j] = {}
        end
    end
    for i, material in ipairs(tcodeObj.materials) do
        mob.materials[i] = { name=material.name, amount=material.amount }
    end

    local pos = {
        x=1,
        y=1,
        z=tcodeObj.depth
    }
    local dir = {
        x=0,
        z=-1
    }
    for i in ipairs(tcodeObj.data) do
        mob.model[pos.y][pos.z][pos.x] = tcodeObj.data[i]
        if tcodeObj.instructions[i] == "forward" then
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif tcodeObj.instructions[i] == "right" then
            dir.x, dir.z = dir.z, -dir.x
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif tcodeObj.instructions[i] == "left" then
            dir.x, dir.z = -dir.z, dir.x
            pos.x = pos.x + dir.x
            pos.z = pos.z + dir.z
        elseif tcodeObj.instructions[i] == "up" then
            dir.x, dir.z = -dir.x, -dir.z
            pos.y = pos.y + 1
        end
    end
    return mob
end

local function naiveMobToTcode(mob)
    local tcode = {
        width=mob.width,
        height=mob.height,
        depth=mob.depth,
        data={},
        instructions={},
        materials={}
    }
    for i, material in ipairs(mob.materials) do
        tcode.materials[i] = { name=material.name, amount=material.amount }
    end

    
end

return {
    tcodeToMob=tcodeToMob
}