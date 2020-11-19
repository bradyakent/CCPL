local CCPLPath = settings.get("ccpl.path")

-- add CCPL programs to the path
shell.setPath(shell.path()..":"..CCPLPath.."ccpl/programs")

-- run all scripts in "startup"
for _, file in ipairs(fs.list(CCPLPath.."ccpl/startup/")) do
    shell.run(CCPLPath.."ccpl/startup/"..file)
end