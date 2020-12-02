
-- installPath will be defined before get-ccpl writes this file

-- add CCPL programs to the path
shell.setPath(shell.path()..":"..installPath.."ccpl/programs")

-- run all scripts in "startup"
for _, file in ipairs(fs.list(installPath.."ccpl/startup/")) do
    shell.run(installPath.."ccpl/startup/"..file, installPath)
end