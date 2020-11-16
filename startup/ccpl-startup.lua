local installPath = "/CCPL/"

-- add CCPL to the path
shell.setPath(shell.path()..":"..installPath.."programs")

-- run all scripts in "startup"
for _, file in ipairs(fs.list(installPath.."startup/")) do
    shell.run(file)
end