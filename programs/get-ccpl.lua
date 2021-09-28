--paths to ignore when grabbing CCPL
local ignore = {
    "LICENSE",
    "README.md"
}

local args = { ... }
--[[ 
(optional) URL of the branch you want to download

possible flags:
-b <branch>  : Get CCPL from a specific branch.
-f           : Force file/directory overwrites
-i <path>    : Install CCPL to the specified path. May break CCPL programs if not careful.
-l [filename]: output debug info to a file. filename defaults to "/log.txt"
-s           : pause after every outputLog() call.
-d           : download tests
--]]

local logFile
local currentFlag = ""
local askAboutOverwrites = true
local debugLog = false
local takeSteps = false
local downloadTest = false
local installPath = "/"
local logPath = "/log.txt"
local branch = "stable"
local sourceURL = "https://github.com/inq-cloud/CCPL/tree/"
for _, arg in ipairs(args) do
    --check currentFlag
    if currentFlag == "-b" then
        branch = arg
        currentFlag = ""
    elseif currentFlag == "-l" then
        if arg:sub(1,1) ~= "-" then
            logPath = arg
        end
        currentFlag = ""
    elseif currentFlag == "-i" then
        if arg:sub(arg:len()) ~= "/" then arg = arg.."/" end
        installPath = arg
        currentFlag = ""
        printError("WARNING! A custom install path will cause CCPL's internal programs to break.")
        print("Are you sure you want to continue? (y/n)")
        local userIn = read():lower()
        if not (userIn == "yes" or userIn == "y") then
            do return end
        end
    else
        --check if there is a new flag
        if arg == "-l" then
            debugLog = true
            currentFlag = "-l"
        elseif arg == "-b" then
            currentFlag = "-b"
        elseif arg == "-f" then
            askAboutOverwrites = false
        elseif arg == "-i" then
            currentFlag = "-i"
        elseif arg == "-s" then
            takeSteps = true
        elseif arg == "-t" then
            downloadTest = true
        else
            sourceURL = arg
        end
    end
end

if not downloadTest then
    ignore[#ignore+1] = "ccpl/programs/run-tests.lua"
end

if debugLog then
    logFile = fs.open(logPath,"w")
end

local function outputLog(input, color)
    if not color or term.isColor() == false then
        color = colors.white
    end
    if debugLog then
        logFile.writeLine(input)
    end
    term.setTextColor(color)
    print(input)
    term.setTextColor(colors.white)
    if takeSteps then
        read()
        term.scroll(-1)
    end
end

local function acceptOverwrites(pathToFile)
    if askAboutOverwrites == true and fs.exists(pathToFile) then
        outputLog(pathToFile.." is about to be overwritten! Would you like to continue? (y/n)",colors.red)
        local userIn = read():lower()
        if (userIn == "yes" or userIn == "y") then
            return true
        else
            return false
        end
    else
        return true
    end
end

local function includes(tArray, sVal)
    for i, item in ipairs(tArray) do
        if item == sVal then
            return true
        end 
    end
    return false
end

--takes URL in the form of "https://raw.githubusercontent.com/{username}/{repo-name}/tree/{tree-name}/"
--and returns an object
--owner = {username}
--repo = {repo-name}
--tree = {tree-name}
--treeObj = <array w/ the path and type of every item in the repo>
local function parseURL(URL)
	local _, last = URL:find("github.com/",1,true)
    local snip = URL:sub(last+1,URL:len()+1)
    local URLpath = {}
    outputLog("- ".."Snipping URL:",colors.lightBlue)
    for x in snip:gmatch("[%w-]+") do
        outputLog("- "..x,colors.gray)
		URLpath[#URLpath+1] = x
    end
    if not URLpath[4] then
        URLpath[4] = "main"
    end
    local apiResult = http.get("https://api.github.com/repos/"..URLpath[1].."/"..URLpath[2].."/branches/"..URLpath[4])
    local apiObj = textutils.unserializeJSON(apiResult.readAll())
    outputLog("\n- ".."Grabbing treeObj from",colors.lightBlue)
    outputLog("- "..apiObj.commit.commit.tree.url.."?recursive=1",colors.lightBlue)
    local treeObj = textutils.unserializeJSON(http.get(apiObj.commit.commit.tree.url.."?recursive=1").readAll())

    outputLog("\n- ".."Building simpleTreeObj:",colors.lightBlue)
    local simpleTreeObj = {}
    for i=1,#treeObj.tree do
        outputLog("- "..treeObj.tree[i].path,colors.gray)
        simpleTreeObj[#simpleTreeObj+1] = {path=treeObj.tree[i].path, type=treeObj.tree[i].type}
    end
    local result = {
        owner=URLpath[1],
        repo=URLpath[2],
        tree=URLpath[4],
        treeObj=simpleTreeObj
    }
    return result
end

outputLog("Parsing URL...", colors.yellow)
local info = parseURL(sourceURL..branch.."/")
outputLog("URL parsed!", colors.lime)

outputLog("\nCreating file structure/downloading files:",colors.yellow)
for i, item in ipairs(info.treeObj) do
    if not includes(ignore, item.path) then
        if item.type == "tree" then
            outputLog("Dir found! Creating "..installPath.."ccpl/"..item.path,colors.cyan)
            if not acceptOverwrites(installPath.."ccpl/"..item.path) then printError("Aborted.") do return end end
            fs.makeDir(installPath.."ccpl/"..item.path)
        elseif item.type == "blob" then
            outputLog("File found! Downloading "..installPath.."ccpl/"..item.path,colors.orange)
            if not acceptOverwrites(installPath.."ccpl/"..item.path) then printError("Aborted.") do return end end
            local dataToWrite = http.get("https://raw.githubusercontent.com/"..info.owner.."/"..info.repo.."/"..info.tree.."/"..item.path).readAll()
            local fileToWrite = fs.open(installPath.."ccpl/"..item.path,"w")
            fileToWrite.write(dataToWrite)
            fileToWrite.close()
        end
    end
end

if not fs.exists("/startup") then
    fs.makeDir("/startup")
end

if fs.exists("/startup/ccpl-startup.lua") then
    outputLog("Warning: ccpl-startup.lua found! There may be incompatibilities if you don't overwrite it.",colors.red)
    if not acceptOverwrites("/startup/ccpl-startup.lua") then do return end end
    fs.delete("/startup/ccpl-startup.lua")
end

fs.move(installPath.."ccpl/startup/ccpl-startup.lua","/startup/ccpl-startup.lua")

outputLog("\nFinished!",colors.lime)
if debugLog then
    logFile.close()
end
sleep(0.5)
outputLog("Rebooting...",colors.yellow)
sleep(1)
os.reboot()
