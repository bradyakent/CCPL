-- Create State prototype
local State = {}
State.__index = State

-- Create State's metatable
local State_mt = {}
-- When State is called, either load the saved state, or create a new one
State_mt.__call = function(table, filename)
    local o = {}
    -- if this state has been saved once before, read from it
    if fs.exists(filename) then
        local stateFile = fs.open(filename,"r")
        o = textutils.unserialize(stateFile.readAll())
    -- this is the first time the state is being set, let's create a blank State
    else 
        o.filename = filename
        o.isNew = true
    end
    -- set the new instance's metatable to be State (exposes get() and set())
    setmetatable(o, State)
    return o
end

-- Now that State has the behaviors that we want (__call), set its metatable
setmetatable(State, State_mt)

-- State's methods
-- new() forces an overwrite of {filename}; same as State(), but always returns a new State
function State:new(filename)
    local o = {
        filename = filename,
        isNew = true
    }
    if fs.exists(filename) then fs.delete(filename) end
    setmetatable(o, State)
    return o
end

-- get(key) gets the value at self[key]
function State:get(key)
    return self[key]
end

-- set(key, value) sets the value of {key} to {value}, writing this change to the State's file
function State:set(key, value)
    self.isNew = false
    self[key] = value
    local stateFile = fs.open(self.filename,"w")
    stateFile.write(textutils.serialize(self))
    stateFile.close()
end

-- Export it for use in programs
return State