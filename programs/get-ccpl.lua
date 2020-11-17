--paths to ignore when grabbing CCPL
local ignore = {
    "LICENSE",
    "README.md"
}

local args = { ... }
--[[ 
(optional) URL of the branch you want to download

possible flags:
-f           : Force file/directory overwrites
-i <path>    : Install CCPL to the specified path. May break CCPL programs if not careful.
-l [filename]: output debug info to a file. filename defaults to "/log.txt"
--]]

local logFile
local currentFlag = ""
local askAboutOverwrites = true
local debugLog = false
local installPath = "/"
local logPath = "/log.txt"
local sourceURL = "https://github.com/BradyFromDiscord/CCPL/tree/development/"
for _, arg in ipairs(args) do
    --check currentFlag
    if currentFlag == "-l" then
        if arg:sub(1,1) ~= "-" then
            logPath = arg
        end
        currentFlag = ""
    elseif currentFlag == "-i" then
        if arg:sub(arg:len()) ~= "/" then arg = arg.."/" end
        installPath = arg
        currentFlag = ""
        printError("WARNING! A custom install path may lead to unintentional bugs when running programs that depend on CCPL.")
        print("Are you sure you want to continue? (y/n)")
        local userIn = read():lower()
        if (userIn == "yes" or userIn == "y") then
            return true
        else
            return false
        end
    else
        --check if there is a new flag
        if arg == "-l" then
            debugLog = true
            currentFlag = "-l"
        elseif arg == "-f" then
            askAboutOverwrites = false
        elseif arg == "-i" then
            currentFlag = "-i"
        else
            sourceURL = arg
        end
    end
end

if debugLog then
    logFile = fs.open(logPath,"w")
end

local function outputLog(input)
    if debugLog then
        logFile.writeLine(input)
    end
    print(input)
end

local function acceptOverwrites(pathToFile)
    if askAboutOverwrites and fs.exists(pathToFile) then
        print(pathToFile.." is about to be overwritten! Would you like to continue? (y/n)")
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
    outputLog("- ".."Snipping URL:")
    for x in snip:gmatch("%w+") do
        outputLog("- "..x)
		URLpath[#URLpath+1] = x
    end
    if not URLpath[4] then
        URLpath[4] = "main"
    end
    local apiResult = http.get("https://api.github.com/repos/"..URLpath[1].."/"..URLpath[2].."/branches/"..URLpath[4])
    local apiObj = textutils.unserializeJSON(apiResult.readAll())
    outputLog("\n- ".."Grabbing treeObj from")
    outputLog("- "..apiObj.commit.commit.tree.url.."?recursive=1")
    local treeObj = textutils.unserializeJSON(http.get(apiObj.commit.commit.tree.url.."?recursive=1").readAll())

    outputLog("\n- ".."Building simpleTreeObj:")
    local simpleTreeObj = {}
    for i=1,#treeObj.tree do
        outputLog("- "..treeObj.tree[i].path)
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

if settings.getDetails("ccpl.path").value == nil then
    settings.define("ccpl.path",{
        description="The parent directory of CCPL.",
        default="/",
        type="string"
    })
    settings.set("ccpl.path",installPath)
    settings.save()
else
    if settings.get("ccpl.path") == installPath and askAboutOverwrites then
        print("Old CCPL found! Would you like to overwrite it? (y/n)")
        local userIn = read():lower()
        if not (userIn == "yes" or userIn == "y") then
            printError("Aborted.")
            do return end
        end
    end
end

outputLog("Parsing URL...")
local info = parseURL(sourceURL)
outputLog("URL parsed!")

outputLog("\nCreating file structure/downloading files:")
for i, item in ipairs(info.treeObj) do
    if not includes(ignore, item.path) then
        if item.type == "tree" then
            outputLog("Dir found! Creating "..installPath.."ccpl/"..item.path)
            if not acceptOverwrites(installPath.."ccpl/"..item.path) then printError("Aborted.") do return end end
            fs.makeDir(installPath.."ccpl/"..item.path)
        elseif item.type == "blob" then
            outputLog("File found! Downloading "..installPath.."ccpl/"..item.path)
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

local baseFile = fs.open("/startup/ccpl-startup.lua","w")
local startingFile = fs.open(installPath.."ccpl/startup/ccpl-startup.lua","r")
startingFile.readLine()
local startupString = startingFile.readAll()
baseFile.write(startupString)
baseFile.close()
fs.delete(installPath.."ccpl/startup/ccpl-startup.lua")

outputLog("\nFinished!")
if debugLog then
    logFile.close()
end