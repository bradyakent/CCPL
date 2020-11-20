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

    local pw = 1
    local ph = 1
    local pd = tcodeObj.depth
    local direction = -1
    for i in ipairs(tcodeObj.data) do
        mob.model[ph][pd][pw] = tcodeObj.data[i]
        if tcodeObj.instructions[i] == "forward" then
            pd = pd + direction
        elseif tcodeObj.instructions[i] == "right" then
            pw = pw + (-direction)
            direction = -direction
        elseif tcodeObj.instructions[i] == "left" then
            pw = pw + direction
            direction = -direction
        elseif tcodeObj.instructions[i] == "up" then
            ph = ph + 1
            direction = -direction
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