--[[ NOTES:
List of tags:
- isFunction
- isAssignment
- isExported

isFunction:
is the comment documenting a function?

isAssignment:
is the comment documenting an assignment?

isExported:
is the comment documenting an exported variable (function or otherwise)?



Documentation types:
- FULL
- EXPORTED

FULL:
Document every top-level function and assignment.

EXPORTED:
Document everything that gets exported.



Extra flags:
- COMMENTED
- FUNCTIONS

COMMENTED:
Document only commented top-level functions and assignments.

FUNCTIONS:
Document only top-level functions.



Special documentation types:
- SOURCE

SOURCE:
Document every top-level comment, and show the blocks of code in between all of them.
--]]

local io = require("io")

local arguments = { ... }

local srcFile = io.open(arguments[1], "r")
local outFile = io.open(arguments[2], "w")
local typeOfDocs = string.upper(arguments[3] or "FULL")
local commented = string.upper(arguments[4] or "YES")

local ignoreFlag = "!ignore"

--#### Helper Functions #############################

-- writeLine creates a wrapper for `file:write()` that automatically puts a `\n` at the end of `line`.
local writeLine = function(file) -- returns: function(string)
    return function(line)
        file:write(line.."\n")
    end
end

-- writeReturn creates a function for writing newlines to the `file`.
local writeReturns = function(file) -- returns: function(number)
    return function(numberOfReturns)
        if not numberOfReturns then error("ERROR! must have some number of returns.") end
        for i=1,numberOfReturns do
            file:write("\n")
        end
    end
end

-- formatCommentLine formats a line of a comment block to be placed in `commentBlock.lines`.
-- (removes all "#" symbols and removes any trailing spaces or "#" symbols)
local formatCommentLine = function(line) -- returns: string
    return line:gsub("^#* ?(.-)[%s#]*$", "%1")
end

-- isPropertyOf returns true when a variable's `name` is a property of `baseObject`.
-- Also returns true if name == baseObject.
local isPropertyOf = function(name, baseObject) -- returns: boolean
    return baseObject == name:match("([%a%d_]+)[%:%.]?.*")
end

--#### Important Functions #########################

local getNextComment = function(file, currentLine) -- returns: table
    local comment = {
        type = "",
        lines = {},
        symbol = { code="" }
    }

    local line = currentLine
    -- Get the type of comment and all the lines of the comment
    while string.sub(line, 1, 2) == "--" do
        line = string.sub(line, 3)
        if comment.type == "" then
            if string.sub(line, 1, 4) == "####" then
                comment.type = "chunk"
            elseif string.sub(line, 1, 2) == "##" then
                comment.type = "section"
            else
                comment.type = "normal"
            end
            comment.lines[#comment.lines+1] = formatCommentLine(line)
        else
            comment.lines[#comment.lines+1] = line
        end

        line = file:read()
    end

    -- Describe the symbol this comment documents
    if line:find("^local") and not line:find("^local function") then
        comment.symbol.exists = true
        comment.symbol.isAssignment = true
        comment.symbol.name = line:match("local ([%w_%:%.]+)%s*=")
        comment.symbol.code = line
    end
    if line:find("^function") or line:find("^local function") or line:find("^local%s[%w_%:%.]+%s*=%s*function") then
        comment.symbol.exists = true
        comment.symbol.isFunction = true
        if not comment.symbol.isAssignment then
            comment.symbol.name = line:match("function ([%w_%:%.]+)%s*%(")
            comment.symbol.code = line
        end
    end

    if comment.lines[1] or comment.symbol.exists then
        return comment
    end
    return nil
end

local getDocComments = function(commentTable)
    local filteredComments = {}

    for _, comment in ipairs(commentTable) do
        if typeOfDocs == "FULL" then
            if (
                comment.lines[1] and
                comment.lines[1] ~= ignoreFlag and
                (comment.type ~= "normal" or
                comment.symbol.isFunction or
                comment.symbol.isAssignment or
                comment.symbol.isExported)
            ) then
                filteredComments[#filteredComments+1] = comment
            end
        elseif typeOfDocs == "EXPORTED" then
            if (
                comment.lines[1] and
                comment.lines[1] ~= ignoreFlag and
                comment.symbol.isExported
            ) then
                filteredComments[#filteredComments+1] = comment
            end
        end
    end
    return filteredComments
end

local formEmptyComments = function(commentTable)
    local retTable = {}
    for _, comment in ipairs(commentTable) do
        if typeOfDocs == "FULL" then
            if (not comment.lines[1]) and comment.symbol.exists then
                comment.lines[1] = "***Undocumented***"
                retTable[#retTable+1] = comment
            end
        elseif typeOfDocs == "EXPORTED" then
            if (
                (not comment.lines[1])
                and comment.symbol.exists
                and comment.symbol.isExported
            ) then
                comment.lines[1] = "***Undocumented***"
                retTable[#retTable+1] = comment
            end
        end
    end
    return retTable
end

local tagExports = function(exportTable, commentTable)
    for _, export in ipairs(exportTable) do
        for _, comment in ipairs(commentTable) do
            if comment.symbol.name and isPropertyOf(comment.symbol.name, export.localName) then
                comment.symbol.isExported = true
            end
        end
    end
end

--#### Other global declarations ###################

local nodocExportChunk = {
    type = "chunk",
    lines = {
        "Undocumented Exported Functions and Variables",
        "Below are all undocumented exports of this module.",
        "",
        "**If an exported function or variable shows up here, please be a good person and document it.**",
        "Documentation is important. Don't make other people dig through your source code to figure out what something does."
    },
    symbol = {
        isExported = true,
        code = ""
    }
}

--#### Rest of the code ############################

local write = writeLine(outFile)
local newlines = writeReturns(outFile)

local comments = {}
local exportedNames = {}

local line = srcFile:read()

while type(line) ~= "nil" do
    local nextComment = getNextComment(srcFile, line)

    if nextComment then
        comments[#comments+1] = nextComment
    end

    if line:find("^return") then
        while type(line) ~= "nil" do
            local exportName, localName = line:match("%s*([%a%d_]+)%s*=%s*([%a%d_]+)")
            if exportName or localName then
                exportedNames[#exportedNames+1] = {
                    exportName = exportName,
                    localName = localName,
                    lineText = line
                }
            end
            line = srcFile:read()
        end
    end

    line = srcFile:read()
end

srcFile:close()

tagExports(exportedNames, comments)

local filteredComments = getDocComments(comments)
local emptyComments = formEmptyComments(comments)

if emptyComments[1] then
    comments = {}
    for i=1,#filteredComments do
        comments[#comments+1] = filteredComments[i]
    end
    comments[#comments+1] = nodocExportChunk
    for i=1,#emptyComments do
        comments[#comments+1] = emptyComments[i]
    end
else
    comments = filteredComments
end

local toc = {}

for i, comment in ipairs(comments) do
    local nextEntry = {}
    if comment.type == "chunk" then
        nextEntry.layer = 1
        nextEntry.text = comment.lines[1]:gsub("([^:]+[^:%s]):?%s*$","%1")
    elseif comment.type == "section" then
        nextEntry.layer = 2
        nextEntry.text = comment.lines[1]:gsub("([^:]+[^:%s]):?%s*$","%1")
    elseif comment.symbol.name then
        nextEntry.layer = 3
        nextEntry.text = "`"..comment.symbol.name.."`"
    end

    if nextEntry.layer then
        toc[#toc+1] = nextEntry
    end
end

--#### Writing to the output file ####################################

write("# Table of Contents:")
write("- [Table of Contents](table-of-contents)")
for i, entry in ipairs(toc) do
    -- To make the link text (looks like "#some-text-here") from a header:
    -- Start with "#", make the entry text all lower case, remove all punctuation, replace all spaces with "-".
    local linkText = "#"..entry.text:lower():gsub("%p",""):gsub(" ","%-")

    write(string.rep("  ", entry.layer-1).."- ["..entry.text.."]("..linkText..")")
end

for i, comment in ipairs(comments) do
    for lineNumber, line in ipairs(comment.lines) do
        if lineNumber == 1 then
            newlines(1)
            if comment.type == "chunk" then
                write(string.rep("-", 40))
                newlines(1)
                write(line)
                write(string.rep("-", #line))
            elseif comment.type == "section" then
                newlines(2)
                write("### "..line)
            else
                if comment.symbol.name then
                    write("### `"..comment.symbol.name.."`")
                    write(line)
                else
                    write("#### "..line)
                end
            end
        else
            write(line)
        end
    end
    if comment.symbol.code ~= "" then
        write("```lua\n"..comment.symbol.code.."\n```")
    end
end

outFile:close()