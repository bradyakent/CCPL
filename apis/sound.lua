local function play(name, pitches, length, volume, instrument)
    if(type(pitches) == "number") then
        pitches = { pitches }
    end
    length = length or 1
    volume = volume or 2
    instrument = instrument or "flute"
    for i, pitch in ipairs(pitches) do
        peripheral.call(name, "playNote", instrument, volume, pitch)
    end
    sleep(length/2)
end

local function playSound(name, soundName, length, volume)
    length = length or 1
    volume = volume or 1
    peripheral.call(name, "playSound", soundName, volume, 1)
    sleep(length)
end

local function init(name, defaultInst)
    local obj = {}
    obj.play = function(pitches, length, volume, instrument)
        instrument = instrument or defaultInst
        play(name, pitches, length, volume, instrument)
    end
    obj.playSound = function(soundName, length, volume)
        playSound(name, soundName, length, volume)
    end
    return obj
end

return {
    play = play,
    playSound = playSound,
    init = init
}