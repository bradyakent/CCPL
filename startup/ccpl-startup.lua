-- add CCPL programs to the path
shell.setPath(shell.path()..":/ccpl/programs")

-- run all scripts in "startup"
for _, file in ipairs(fs.list("/ccpl/startup/")) do
    shell.run("/ccpl/startup/"..file)
end