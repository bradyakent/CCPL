local logFile = fs.open("/log.txt","w")

local function outputLog(input)
    logFile.writeLine(input)
    print(input)
end


local args = { ... }
--args[1] (optional) branch URL

local ignore = {"LICENSE","README.md"} --paths to ignore when grabbing CCPL

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
	local z, last = URL:find("github.com/",1,true)
    local snip = URL:sub(last+1,URL:len()+1)
    local URLpath = {}
    outputLog("Snipping URL:")
    for x in snip:gmatch("%w+") do
        outputLog(x)
		URLpath[#URLpath+1] = x
    end
    if not URLpath[4] then
        URLpath[4] = "main"
    end
    local apiResult = http.get("https://api.github.com/repos/"..URLpath[1].."/"..URLpath[2].."/branches/"..URLpath[4])
    local apiObj = textutils.unserializeJSON(apiResult.readAll())
    outputLog("\nGrabbing treeObj from")
    outputLog(apiObj.commit.commit.tree.url.."?recursive=1")
    local treeObj = textutils.unserializeJSON(http.get(apiObj.commit.commit.tree.url.."?recursive=1").readAll())

    outputLog("\nBuilding simpleTreeObj:")
    local simpleTreeObj = {}
    for i=1,#treeObj.tree do
        outputLog(treeObj.tree[i].path)
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

local sourceURL = "https://github.com/BradyFromDiscord/CCPL/tree/development/"
if args[1] then
    sourceURL = args[1]
end

outputLog("Parsing URL...")
local info = parseURL(sourceURL)
outputLog("URL parsed!")

outputLog("\nCreating file structure/downloading files:")
for i, item in ipairs(info.treeObj) do
    if not includes(ignore, item.path) then
        if item.type == "tree" then
            outputLog("Dir found! Creating /CCPL/"..item.path)
            fs.makeDir("/CCPL/"..item.path)
        elseif item.type == "blob" then
            outputLog("File found! Downloading /CCPL/"..item.path)
            local dataToWrite = http.get("https://raw.githubusercontent.com/"..info.owner.."/"..info.repo.."/"..info.tree.."/"..item.path).readAll()
            local fileToWrite = fs.open("/CCPL/"..item.path,"w")
            fileToWrite.write(dataToWrite)
            fileToWrite.close()
        end
    end
end
outputLog("\nFinished!")