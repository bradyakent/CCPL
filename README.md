# CCPL
## ComputerCraft Personal Library

This library is essentially just a collection of APIs and programs that I've written. Instead of having to write the same code over and over again, I decided to make an easily installable library/package/whatever the correct term for this thing is.

### Installation Instructions

1. Download `get-ccpl.lua` by running `wget https://github.com/BradyFromDiscord/CCPL/tree/development/programs/get-ccpl.lua`
2. Run `get-ccpl.lua`
And that's it! You can use the programs as if they were vanilla.

-------------
## Advanced Stuff

You only need this stuff if you're going to be programming with CCPL.

### Advanced Installation

There are custom flags that you may use with the `get-ccpl.lua` program:

| Flag             | Usage                                                         |
|------------------|---------------------------------------------------------------|
| `-f`             | Force overwrites (does not stop custom path warning)          |
| `-i <path>`      | Install CCPL at `<path>`, may break badly written programs    |
| `-l [path/file]` | Dumps debug output to a log file. File defaults to `/log.txt` |
| `-s`             | Steps through debug output, in case you're into that          |

### Using the APIs

Since there is no way to add custom paths to `require()`'s list of paths, and I have an option to install CCPL in a custom path, I needed a way to reference my APIs no matter where they are, even though `require()` would need an absolute path. 
This is the snippet to do that:
```lua
local _p = settings.get("ccpl.path")
local {api-name-here} = require(_p.."ccpl.apis.{api-name-here}")
```

Essentially, I have a custom setting that saves the location that CCPL is installed. As long as you append that path before `ccpl.apis`, your program will be able to use the API, even if CCPL is in a custom path.
