local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")

local EXPECTED = {
    -- the spacing scale
    xs = 4, sm = 8, md = 12, lg = 16,
    xl = 24, control = 32, row = 28, controlSmall = 24,
    -- widget defaults and ornaments, here so no literal reaches a sizing call
    defaultWidth = 200, buttonWidth = 120, dropdownWidth = 160,
    scrollHeight = 120, windowWidth = 600, windowHeight = 460,
    icon = 16, tick = 20, arrow = 14, thumbWidth = 6, thumbHeight = 18,
}

for key, value in pairs(EXPECTED) do
    harness.assertEqual(lib.Metrics[key], value, "Metrics." .. key .. " is " .. value)
end

for key in pairs(lib.Metrics) do
    harness.assert(EXPECTED[key] ~= nil, "Metrics carries no key the table above does not name: " .. key)
end

-- The scale and the floors are tables an embedder holds, so an upgrade must
-- update them IN PLACE. This is the failure lib.Colors carried until SetColor
-- started writing through SetRGBA: values from the minor that loaded first win
-- forever, and nothing errors.
--
-- Identity and a surviving marker are not enough to catch that. Every value in
-- both tables is poisoned first, exactly as test_palette.lua intercepts a hex
-- to prove a new minor's colours reach the reused objects: `metrics.xs =
-- metrics.xs or 4`, or a SetMinimum that returns early for a key it already
-- has, keeps identity and the marker intact while pinning the first minor's
-- numbers in place forever.
local POISON = -1

local metricsBefore = lib.Metrics
local minimumsBefore = lib.Minimums
local buttonFloorBefore = lib.Minimums.Button

metricsBefore.marker = true
for key in pairs(EXPECTED) do
    lib.Metrics[key] = POISON
end
for _, floor in pairs(lib.Minimums) do
    floor.minWidth, floor.minHeight = POISON, POISON
end

harness.loadLibraryAgain(2)

harness.assertEqual(lib.Metrics, metricsBefore, "an upgrade reuses lib.Metrics")
harness.assert(lib.Metrics.marker, "and does not wipe what was in it")
harness.assertEqual(lib.Minimums, minimumsBefore, "an upgrade reuses lib.Minimums")
-- The floor OBJECT, not just the table holding it: FrameMixin:OnLoad and
-- CreateTextWindow both read one out and hand its two numbers to
-- SetResizeBounds, so a replaced entry orphans whatever held it.
harness.assertEqual(lib.Minimums.Button, buttonFloorBefore,
    "and the floor objects inside it")

for key, value in pairs(EXPECTED) do
    harness.assertEqual(lib.Metrics[key], value,
        "the new minor's Metrics." .. key .. " reaches the reused table")
end
harness.assertEqual(lib.Minimums.Button.minWidth, 64,
    "the new minor's Button floor reaches the reused floor object")
harness.assertEqual(lib.Minimums.Button.minHeight, 24, "on both axes")

lib.Metrics.marker = nil

lib:SetMetrics({ control = 28 })
harness.assertEqual(lib.Metrics.control, 28, "an embedder can retune the scale")
lib:SetMetrics({ control = 32 })

local ok, err = pcall(function() lib:SetMetrics({ contrl = 28 }) end)
harness.assert(not ok, "a misspelt metric raises rather than doing nothing")
harness.assert(tostring(err):find("contrl", 1, true) ~= nil,
    "and the message names the key that was not recognised")

local fontsOk, fontsErr = pcall(function() lib:SetFonts({ Nrmal = { size = 9 } }) end)
harness.assert(not fontsOk, "a misspelt font variant raises too")
harness.assert(tostring(fontsErr):find("Nrmal", 1, true) ~= nil,
    "and names the variant")

harness.done()
