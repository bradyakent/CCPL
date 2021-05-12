-- Generalized jingles for different types of ores
local sound = require("/ccpl")("sound")
local s = nil

local function init(name, instrument)
    instrument = instrument or "bit"
    s = sound.init(name, instrument)
end

local function coal()
    s.play(9,0.25)
    s.play(13,0)
end

local function iron()
    s.play(11,0.25)
    s.play(18,0.25)
    s.play(15,0.25)
    s.play(11,0)
end

local function gold()
    s.play(8,0.25)
    s.play(15,0.25)
    s.play(15,0.25)
    s.play(19,0)
end

local function redstone()
    s.play(9,0.25)
    s.play(16,0)
end

local function lapis()
    s.play({8,14},0.5)
    s.play({8,15},0.25)
    s.play({8,20},0)
end

local function diamond()
    s.play({17,22},0.5)
    s.play(14,0.25)
    s.play({10,17},0.25)
    s.play(10,0.5)
    s.play({10,14},0.25)
    s.play(17,0.25)
    s.play({13,21},0.25)
    s.play({10,22},0.5)
    s.play({10,17,22},0)
end

local function bad()
    s.play(6,0.5)
    s.play(0,0)
end

return {
    init=init,
    coal=coal,
    iron=iron,
    gold=gold,
    redstone=redstone,
    lapis=lapis,
    diamond=diamond,
    bad=bad
}