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

-- Function -> the argument positions that carry a size, for every call whose
-- size sits at a fixed spot regardless of how it is written. Positions are
-- 1-based within the parenthesised list as written, so a PixelUtil call's
-- first argument is the region, and a plain method (reached with ':', self
-- implicit) checks positions one lower than its PixelUtil counterpart.
--
-- PixelUtil.SetPoint belongs here rather than in TRAILING_PAIR below: per
-- its signature at Interface/AddOns/Blizzard_SharedXML/PixelUtil.lua:51 --
-- PixelUtil.SetPoint(region, point, relativeTo, relativePoint, offsetX,
-- offsetY, minOffsetXPixels, minOffsetYPixels) -- it accepts only the full
-- four-anchor form, so its offsets are always arguments 5 and 6 whether or
-- not the two optional snap-hint arguments follow. Checking a fixed pair
-- here is both correct and simpler than arity-keying it; the loop below
-- already skips a position with nothing there, so a shorter call is fine.
local CHECKED = {
    ["SetSize"]              = { 1, 2 },
    ["SetWidth"]             = { 1 },
    ["SetHeight"]            = { 1 },
    ["SetTextInsets"]        = { 1, 2, 3, 4 },
    ["PixelUtil.SetSize"]    = { 2, 3 },
    ["PixelUtil.SetWidth"]   = { 2 },
    ["PixelUtil.SetHeight"]  = { 2 },
    ["PixelUtil.SetPoint"]   = { 5, 6 },
}

-- SetPoint is the one call left that is genuinely variadic: relativePoint
-- defaults to point when omitted, so how many arguments come before the
-- trailing offsets depends on which form was written --
-- :SetPoint(point, x, y) is three, :SetPoint(point, relativeTo, x, y) is
-- four (a real form: e.g. Blizzard_AnimaDiversionUI.lua:289), and
-- :SetPoint(point, relativeTo, relativePoint, x, y) is five. A fixed
-- position table cannot say that, which is why this one is keyed by
-- argument count instead, checking the trailing two positions whatever they
-- are. Any other arity is an anchor with no offsets and has nothing to
-- check.
local TRAILING_PAIR = {
    ["SetPoint"] = { [3] = true, [4] = true, [5] = true },
}

-- Skin.lua is scanned alongside the templates because it draws too --
-- BuildWindowShell sizes a header and five borders. Being outside this list
-- is how its header height stayed 30 through the pass that moved every other
-- one to 32.
local FILES = harness.libraryFiles("Templates/")
FILES[#FILES + 1] = "Skin.lua"

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

            for call, arities in pairs(TRAILING_PAIR) do
                local pattern = call:gsub("%.", "%%.")
                local prefix = call:find("%.") and pattern or (":" .. pattern)
                local at = line:find(prefix .. "%s*%(")
                if at then
                    local open = line:find("%(", at)
                    local list = argumentList(line, open)
                    if list then
                        local args = splitArguments(list)
                        if arities[#args] then
                            for position = #args - 1, #args do
                                local literal = hasNumericLiteral(args[position])
                                if literal then
                                    offenders[#offenders + 1] = ("%s:%d  %s offset argument %d is the literal %s  --  %s")
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
    "no sizing or anchoring call in the library's drawing code carries a magic number",
    "",
    table.concat(offenders, "\n"),
    "",
    "A size here comes from lib.Metrics, lib.Minimums or lib.GetPixel().",
    "If the value you need is not on the scale, ADD A TOKEN to lib.Metrics and",
    "give it a name -- do not bind the number to a local to get past this test.",
    "A local passes the scan and defeats its whole purpose.",
}, "\n"))

harness.done()
