# Table of Contents:
- [Table of Contents](table-of-contents)
- [Module gui.lua](#module-guilua)
- [Setup](#setup)
    - [`expect`](#expect)
    - [`toBlit`](#toblit)
- [GUI Constructs](#gui-constructs)
  - [Buffer](#buffer)
    - [`Buffer`](#buffer)
    - [`Buffer:new`](#buffernew)
    - [`Buffer:pushData`](#bufferpushdata)
  - [Screen](#screen)
    - [`Screen`](#screen)
    - [`Screen:new`](#screennew)
    - [`Screen:render`](#screenrender)
    - [`Screen:updateText`](#screenupdatetext)
    - [`Screen:updateTextColor`](#screenupdatetextcolor)
    - [`Screen:updateBgColor`](#screenupdatebgcolor)
  - [GUI Object](#gui-object)
    - [`list`](#list)
    - [`GUIObject`](#guiobject)
    - [`GUIObject:new`](#guiobjectnew)
    - [`GUIObject:move`](#guiobjectmove)
    - [`GUIObject:delete`](#guiobjectdelete)
    - [`GUIObject:draw`](#guiobjectdraw)
    - [`GUIObject:fill`](#guiobjectfill)
    - [`GUIObject:write`](#guiobjectwrite)
    - [`GUIObject:erase`](#guiobjecterase)
    - [`GUIObject:highlight`](#guiobjecthighlight)
    - [`GUIObject:contains`](#guiobjectcontains)

----------------------------------------

Module gui.lua
--------------
 The gui module can be used to draw a GUI to the screen of a computer or turtle.

 To use gui.lua, you have access to `Screen` and `Object`.

 `Screen` is a very fast wrapper for drawing to the screen.
 You "write" data to the `Screen`'s buffers, then render the `Screen` all at once.

 `Object` allows a more abstract method of interacting with a `Screen` instance.
 `Object`s can be drawn within, filled with a color, written onto with text, and moved within the dimensions of its attached `Screen`.
 Once the `Object` has been drawn to its `Screen`, calling `:render()` on that `Screen` instance will draw the `Object` to the `Screen`.

 Please note that drawing an `Object` to a `Screen` will *not* immediately display that `Object` on the `Screen`.
 Instead, you must `:render()` the `Screen` for the `Object` to display.

----------------------------------------

Setup
-----

### `expect`
Imported modules:
```lua
local expect = require("/ccpl")("expect").expect
```

### `toBlit`
toBlit converts a normal CC color value to its `blit` equivalent.
```lua
local function toBlit(color)
```

----------------------------------------

GUI Constructs
--------------



### Buffer:
 The Buffer class is an abstraction of one "layer" of a `Screen`.
 The three layers of a `Screen` are the background color layer,
 the text color layer, and the text layer. Each one of these layers runs on a Buffer,
 which actually holds the data stored in the `Screen`.

 The Buffer class isn't an exported class, so most users of the gui module won't need to know about it.
 Nonetheless, knowing how it works is a good thing, so here's the documentation.

### `Buffer`
Buffer is a class which abstracts a 2d array of character data.
 It's used as part of `Screen`.
```lua
local Buffer = {}
```

### `Buffer:new`
creates a new instance of `Buffer` of width `width` and height `height`.
 Also fills the entire `Buffer` with `fillChar`.
```lua
function Buffer:new(fillChar, width, height) -- returns: Buffer
```

### `Buffer:pushData`
pushes `newData` into the `Buffer` at line `line`.
 Optionally offset the data horizontally by `xOffset` characters.
```lua
function Buffer:pushData(newData, line, xOffset) -- returns: boolean
```



### Screen:
 (TODO) Screen description here

### `Screen`
The Screen class is an abstraction of the CC function `term.blit()`, the fastest way to display data in a CC terminal.
 Using it is far easier than using `term.blit()` directly, which is why I made it.
```lua
local Screen = {}
```

### `Screen:new`
Creates a new `Screen` instance of width `width` and height `height`.
 There's an optional `debug` param, but you shouldn't need that.
```lua
function Screen:new(width, height, debug) -- returns: Screen
```

### `Screen:render`
Renders the `Screen`'s data onto its defined area on the display.

 (BUG) All `Screen` instances are locked to the top left corner of the display.
 A possible workaround for this is wrapping a `Screen` instance inside of a terminal window.
```lua
function Screen:render()
```

### `Screen:updateText`
Updates the `Screen`'s text `Buffer`, as well as the `changedLines` table.
 `nText` is the data written to the `Buffer`, and it's top-left corner is located at `(x, y)`.
```lua
function Screen:updateText(nText, x, y)
```

### `Screen:updateTextColor`
Updates the `Screen`'s text color `Buffer`, as well as the `changedLines` table.
 `nTextColor` is the data written to the `Buffer`, and it's top-left corner is located at `(x, y)`.
```lua
function Screen:updateTextColor(nTextColor, x, y)
```

### `Screen:updateBgColor`
Updates the `Screen`'s background color `Buffer`, as well as the `changedLines` table.
 `nBgColor` is the data written to the `Buffer`, and it's top-left corner is located at `(x, y)`.
```lua
function Screen:updateBgColor(nBgColor, x, y)
```



### GUI Object:
 (TODO) GUIObject description here

### `list`
A list containing all GUIObjects that haven't been deleted (see `GUIObject:delete()`)
```lua
local list = {}
```

### `GUIObject`
The GUIObject class is an abstraction of elements drawn on a Screen instance.
 The class methods allow interaction with a Screen instance
 in a far easier way than interacting with it directly.
```lua
local GUIObject = {}
```

### `GUIObject:new`
Creates a new GUIObject instance, attached to `screen`. The top left corner
 of the instance is placed at `x` and `y`, with its width and height being `width` and `height`.
```lua
function GUIObject:new(screen, x, y, width, height)
```

### `GUIObject:move`
Moves a GUIObject's top left coordinates to `newX` and `newY`.
 Please note, this does not draw the GUIObject in that spot, it only moves the internal coordinates.
 You will need to re-draw the GUIObject to see the update to its coordinates.
```lua
function GUIObject:move(newX, newY)
```

### `GUIObject:delete`
Removes the GUIObject from the list of all GUIObjects.
 (BUG) list extends over every screen instance. maybe fix that?
```lua
function GUIObject:delete()
```

### `GUIObject:draw`
Draws (fills the bgColor buffer) a given color `color` to the coordinates `x` and `y`.
 Optionally draws a filled rectangle from `x` and `y` with width `width` and height `height`.
```lua
function GUIObject:draw(x, y, color, width, height)
```

### `GUIObject:fill`
Fills the GUIObject with a color `color`.
 `textColor` can be nil (not passed in), a boolean, or number.
 * If `textColor` is nil or false, the bgColor buffer will be filled with `color`.
 * If it is true, the textColor buffer will be filled instead.
 * If it is a number (i.e. a color), `color` will be used to fill the bgColor buffer,
 and `textColor` will be used to fill the textColor buffer.
```lua
function GUIObject:fill(color, textColor)
```

### `GUIObject:write`
Writes text at the coordinates `x` and `y`, optionally with some color `color`.
 The coordinates are relative to the GUIObject itself, not relative to the Screen instance
 attached to the GUIObject.
```lua
function GUIObject:write(x, y, text, color)
```

### `GUIObject:erase`
Erases text from coordinates `x` and `y`, optionally in a rectangle with width `width` and height `height`.
 if all four parameters are omitted, the entire GUIObject's area will be cleared of text.
```lua
function GUIObject:erase(x, y, width, height)
```

### `GUIObject:highlight`
Highlights (fills the textColor buffer) with a given color `color` at `x` and `y`.
 Optionally highlights a rectangular area of `width` and `height`.
```lua
function GUIObject:highlight(x, y, color, width, height)
```

### `GUIObject:contains`
Returns true if the coordinates `x` and `y` are contained within the GUIObject, false if not.
 `x` and `y` are relative to the Screen instance connected to the GUIObject.
```lua
function GUIObject:contains(x, y)
```
