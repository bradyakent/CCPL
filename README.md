# ComputerCraft Personal Library

This library is essentially just a collection of APIs and programs that I've written. Instead of having to write the same code over and over again, I decided to make an easily installable package.

## Installation Instructions

1. Download `get-ccpl.lua` by running `wget https://raw.githubusercontent.com/inq-cloud/CCPL/stable/programs/get-ccpl.lua`
2. Run `get-ccpl.lua`
And that's it! You can use the programs as if they were vanilla.

## Programs

The following are a list of programs included in this package:

#### farm
Usage: `farm <create/harvest> <x> <y>`
This program allows the user to either create or harvest a farm of "x" by "y" size.
When creating a farm, the farming API will ask for materials in specific slots. If the materials are not provided, the turtle will still create the farm, but you may have to manually place those materials.

#### gist
Usage: `gist <install/update> <file-name> <gist-url>`
This program is a quick way to download programs from Gist. It works similarly to the pastebin program, but allows you to overwrite the file at `file-name`. `update` just bypasses a warning that `install` displays when overwriting a file.

#### make-room
Usage: `make-room <width> <height> <depth>`
This program will dig out a volume, starting from the bottom center. If `width` is even, the extra block will be dug out from the right, so if you need a two-door and want it to be even, put the turtle at the bottom left, then run the program.

#### 3dprint
Usage: `3dprint <scan> <width> <height> <depth> <file-name>` or `3dprint <print> <file-name>`
This program can scan a structure and output a file at `file-name`, or print the file at `file-name`.
When using this program, there are a few things to note:

- Scanning is destructive. The turtle will dig every block in the volume specified. If the volume includes glass or other blocks the turtle is not able to pick up, they will be destroyed.
- Certain blocks and other things in the volume may cause some weirdness. Currently, scan does not know how to get the direction of blocks. It also may not pick up torches and doors correctly, as they must be attached to other blocks.
- If more than 16 slots are necessary to store all the items from the structure when scanning, the generated file won't work correctly.
- Scanning starts in the bottom left corner of the structure, with the turtle facing the bottom left block of the structure.
- Printing also starts in the bottom left corner of the structure, but the first block will be placed where the turtle is located.

It's a good idea to test this program on a small structure to understand what it will do before trying to copy larger structures.
_____________________________

# Advanced Stuff

You only need this stuff if you're going to be programming with CCPL.

## Advanced Installation

There are custom flags that you may use with the `get-ccpl.lua` program:

| Flag             | Usage                                                         |
| ---------------- | ------------------------------------------------------------- |
| `-b <branch>`    | Download CCPL from `<branch>`                                 |
| `-f`             | Force overwrites (does not stop custom path warning)          |
| `-i <path>`      | Install CCPL at `<path>`; will break built-in programs.       |
| `-l [path/file]` | Dumps debug output to a log file. File defaults to `/log.txt` |
| `-s`             | Steps through debug output, in case you're into that          |

## Before using the APIs

You may find that you require more than one API at a time. Instead of requiring each API one at a time, you can actually write something like this:
```lua
local api1, api2 = require("/ccpl")("api1", "api2")
```
You can do this with as many APIs as you need, all in one line. If you want to get really succinct with it, you could do something like:
`local a = { require("/ccpl")("api1", "api2") }`, then reference them via that table as needed.
You can require the APIs the normal way as well, if you prefer:
```lua
local api1 = require("/ccpl.apis.api1")
local api2 = require("/ccpl.apis.api2")
```

If you use my APIs in your own programs, be sure to give the absolute path to CCPL (or the API if you're using the standard `require()` syntax):
```lua
-- CCPL specific syntax
local api1, api2 = require("/your/path/here/ccpl")("api1", "api2")

-- standard require() syntax
local api3 = require("/your/path/here/ccpl.apis.api3")
local api4 = require("/your/path/here/ccpl.apis.api4")
```
