-- No magic numbers in a sizing call under Templates/. The guard that keeps the
-- suite spacious over time is this, not a runtime clamp: a clamp stops one bad
-- call, a test stops the numbers coming back.
--
-- It reads source text rather than loading anything, so it is the one test here
-- that needs no harness stubs.
--
-- Known blind spot: a number bound to a local and passed by name is invisible
-- here -- `local WIDTH = 200; self:SetSize(WIDTH, metrics.control)` passes.
-- If the size you need is not on the scale, add a named token to lib.Metrics
-- instead of hiding the literal behind a local; a local defeats this test's
-- whole purpose rather than satisfying it.
local harness = dofile("tests/harness.lua")

-- Function -> the argument positions that carry a size. Positions are 1-based
-- within the parenthesised list as written, so a PixelUtil call's first
-- argument is the region and its last are snap hints, neither of which is a
-- size. A plain method is reached with ':' and carries no region argument of
-- its own -- self is implicit -- so its size positions start at 1, one lower
-- than the matching PixelUtil variant's.
local CHECKED = {
    ["SetSize"]              = { 1, 2 },
    ["SetWidth"]             = { 1 },
    ["SetHeight"]            = { 1 },
    ["SetTextInsets"]        = { 1, 2, 3, 4 },
    ["PixelUtil.SetSize"]    = { 2, 3 },
    ["PixelUtil.SetWidth"]   = { 2 },
    ["PixelUtil.SetHeight"]  = { 2 },
}

--- Every Templates/ file lib.xml loads, read from lib.xml rather than copied
--- into a list here. A ninth template is a line in that file and nothing else,
--- so a hand-kept copy would leave it scanned by nobody -- which is the exact
--- failure this test exists to prevent, in the test itself.
---@return string[]
local function templateFiles()
    local handle = assert(io.open("lib.xml", "r"), "cannot open lib.xml")
    local xml = handle:read("a")
    handle:close()

    local files = {}
    for file in xml:gmatch('<Script%s+file="([^"]+)"') do
        -- The client reads Windows-separated paths out of XML; io.open here
        -- wants this platform's own separator.
        local path = file:gsub("\\", "/")
        if path:find("^Templates/") then
            files[#files + 1] = path
        end
    end

    assert(#files > 0,
        "lib.xml lists no Templates/ file -- the scan below would pass vacuously")
    return files
end

local FILES = templateFiles()

--- Split an argument list on top-level commas, so `max(a, b)` stays one
--- argument and `GetPixel()` survives intact.
local function splitArguments(text)
    local args, depth, current = {}, 0, {}
    for i = 1, #text do
        local c = text:sub(i, i)
        if c == "(" or c == "[" then depth = depth + 1 end
        if c == ")" or c == "]" then depth = depth - 1 end
        if c == "," and depth == 0 then
            args[#args + 1] = table.concat(current)
            current = {}
        else
            current[#current + 1] = c
        end
    end
    args[#args + 1] = table.concat(current)
    return args
end

--- The parenthesised list following `open`, balanced. Scans only the line it
--- is given -- a call whose argument list continues onto the next physical
--- line returns nil here and is silently skipped, same as an unopened call.
local function argumentList(line, open)
    local depth, i = 0, open
    while i <= #line do
        local c = line:sub(i, i)
        if c == "(" then depth = depth + 1 end
        if c == ")" then
            depth = depth - 1
            if depth == 0 then return line:sub(open + 1, i - 1) end
        end
        i = i + 1
    end
    return nil
end

local function hasNumericLiteral(argument)
    for number in argument:gmatch("%f[%w%.]%-?%d[%d%.]*") do
        if tonumber(number) ~= 0 then return number end
    end
    return nil
end

local offenders = {}

for _, path in ipairs(FILES) do
    local handle = assert(io.open(path, "r"), "cannot open " .. path)
    local lineNumber = 0
    for line in handle:lines() do
        lineNumber = lineNumber + 1
        if not line:match("^%s*%-%-") then
            for call, positions in pairs(CHECKED) do
                local pattern = call:gsub("%.", "%%.")
                -- A method call is reached with ':' and a PixelUtil one with
                -- '.', and the table's keys already carry the difference.
                local prefix = call:find("%.") and pattern or (":" .. pattern)
                local at = line:find(prefix .. "%s*%(")
                if at then
                    local open = line:find("%(", at)
                    local list = argumentList(line, open)
                    if list then
                        local args = splitArguments(list)
                        for _, position in ipairs(positions) do
                            local argument = args[position]
                            if argument then
                                local literal = hasNumericLiteral(argument)
                                if literal then
                                    offenders[#offenders + 1] = ("%s:%d  %s argument %d is the literal %s  --  %s")
                                        :format(path, lineNumber, call, position, literal, line:match("^%s*(.-)%s*$"))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    handle:close()
end

harness.assert(#offenders == 0, table.concat({
    "no sizing call under Templates/ carries a magic number",
    "",
    table.concat(offenders, "\n"),
    "",
    "A size here comes from lib.Metrics, lib.Minimums or lib.GetPixel().",
    "If the value you need is not on the scale, ADD A TOKEN to lib.Metrics and",
    "give it a name -- do not bind the number to a local to get past this test.",
    "A local passes the scan and defeats its whole purpose.",
}, "\n"))

harness.done()
