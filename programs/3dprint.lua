-- implements basic farming API usage
local _p = settings.get("ccpl.path")
local tex = require(_p.."ccpl.apis.tex")
local tprint = require(_p.."ccpl.apis.tprint")
local ux = require(_p.."ccpl.apis.ux")

local usage = {
    {"scan",{"width",{"height",{"depth","file-name"}}}},
    {"print","file-name"}
}

ux.displayUsage("3dprint",usage)