# Table of Contents:
- [Table of Contents](table-of-contents)
- [Undocumented Functions and Variables](#undocumented-functions-and-variables)
    - [`tex`](#tex)
    - [`Queue`](#queue)
    - [`Queue:new`](#queuenew)
    - [`Queue:push`](#queuepush)
    - [`Queue:pop`](#queuepop)
    - [`Queue:isEmpty`](#queueisempty)
    - [`Queue:len`](#queuelen)
    - [`includes`](#includes)
    - [`turnDir`](#turndir)
    - [`tcodeToMob`](#tcodetomob)
    - [`naiveMobToTcode`](#naivemobtotcode)
    - [`getDist`](#getdist)
    - [`goToPos`](#gotopos)
    - [`findNearestBlock`](#findnearestblock)
    - [`mobToTcode`](#mobtotcode)

----------------------------------------

Undocumented Functions and Variables
------------------------------------
Below are the undocumented symbols in this module.

***If an exported function or variable shows up here, please be a good person and document it.***

Documentation is important. Don't make other people dig through your source code to figure out what something does.

### `tex`
***Undocumented***
```lua
local tex = require("/ccpl")("tex")
```

### `Queue`
***Undocumented***
```lua
local Queue = { first=0, last=-1 }
```

### `Queue:new`
***Undocumented***
```lua
function Queue:new(o)
```

### `Queue:push`
***Undocumented***
```lua
function Queue:push(value)
```

### `Queue:pop`
***Undocumented***
```lua
function Queue:pop()
```

### `Queue:isEmpty`
***Undocumented***
```lua
function Queue:isEmpty()
```

### `Queue:len`
***Undocumented***
```lua
function Queue:len()
```

### `includes`
***Undocumented***
```lua
local function includes(table, pos)
```

### `turnDir`
***Undocumented***
```lua
local function turnDir(currDir, direction)
```

### `tcodeToMob`
***Undocumented***
```lua
local function tcodeToMob(tcodeObj)
```

### `naiveMobToTcode`
***Undocumented***
```lua
local function naiveMobToTcode(mob)
```

### `getDist`
***Undocumented***
```lua
local function getDist(curr, dest)
```

### `goToPos`
***Undocumented***
```lua
local function goToPos(currPos, currDir, destPos)
```

### `findNearestBlock`
***Undocumented***
```lua
local function findNearestBlock(mob, pos, dir, placed, queued, queue)
```

### `mobToTcode`
***Undocumented***
```lua
local function mobToTcode(mob)
```
