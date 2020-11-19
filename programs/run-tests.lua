local _p = settings.get("ccpl.path")
local farming = require(_p.."ccpl.apis.farming")
local tex = require(_p.."ccpl.apis.tex")
local ux = require(_p.."ccpl.apis.ux")

shell.run("farm create 3 3")
print("farm create works!")

shell.run("farm harvest 3 3")
print("farm harvest works!")

tex.forward(10)

shell.run("gist install gist-test.lua https://gist.github.com/BradyFromDiscord/f3326d540a49dd25d86894ad93f8b3da")
shell.run("gist-test")
print("gist install works!")

shell.run("gist update gist-test.lua https://gist.github.com/BradyFromDiscord/f3326d540a49dd25d86894ad93f8b3da")
shell.run("gist-test")
print("gist update works!")

shell.run("make-room 3 3 3")
print("make-room works!")