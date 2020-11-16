local args = { ... }
--args[1] (optional) branch URL

local ignore = {"LICENSE","README.md"} --files to ignore when grabbing CCPL

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
    print("Snipping URL:")
    for x in snip:gmatch("%w+") do
        print(x)
		URLpath[#URLpath+1] = x
    end
    if not URLpath[4] then
        URLpath[4] = "main"
    end
    local apiResult = http.get("https://api.github.com/repos/"..URLpath[1].."/"..URLpath[2].."/branches/"..URLpath[4])
    local apiObj = textutils.unserializeJSON(apiResult.readAll())
    print("Grabbing treeObj from")
    print(apiObj.commit.commit.tree.url.."?recursive=1")
    local treeObj = textutils.unserializeJSON(http.get(apiObj.commit.commit.tree.url.."?recursive=1").readAll())

    print("Building simpleTreeObj:")
    local simpleTreeObj = {}
    for i=1,#treeObj.tree do
        print(treeObj.tree[i].path)
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

print("Parsing URL...")
local info = parseURL(sourceURL)
print("URL parsed!")

for i, item in ipairs(info.treeObj) do
    if item.type == "tree" then
        fs.makeDir("/CCPL/"..item.path)
    elseif item.type == "blob" then
        local dataToWrite = http.get("https://raw.githubusercontent.com/"..info.owner.."/"..info.repo.."/"..info.tree.."/"..item.path).readAll()
        local fileToWrite = fs.open("/CCPL/"..item.path,"w")
        fileToWrite.write(dataToWrite)
        fileToWrite.close()
    end
end