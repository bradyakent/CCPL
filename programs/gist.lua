local args = { ... }
--args[1]: install, update
--args[2]: <file-name>
--args[3]: <gist-raw-url>

if fs.exists(args[2]) then
    if args[1] == "install" then
        print("File name already exists; would you like to replace it? (yes/no)")
        local userIn = read():lower()
        if userIn ~= "yes" and userIn ~= "y" then
            printError("Aborted.")
            do return end
        end
    end
    shell.run("rm",args[2])
end

local z, last = string.find(args[3],"gist.github.com/")
local urlPath = string.sub(args[3], last+1) -- output: {username}/{gist-hash (32 char)}
z, last = string.find(urlPath, "/")
local username = string.sub(urlPath,1,last-1)
local gistHash = string.sub(urlPath,last+1,last+33)

local internalURL = "https://gist.github.com/"..username.."/"..gistHash.."/raw/"

print("Downloading gist...")
shell.run("wget",internalURL,args[2])