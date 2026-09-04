-- The floors, and the correspondence that keeps them honest in both
-- directions. A new widget shipping with no entry is the silent
-- hand-maintained-list failure this project keeps cataloguing, so the test
-- asserts every mixin has a floor AND every floor names a real mixin --
-- neither direction alone would catch it.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
for _, file in ipairs({
    "Frame", "Buttons", "CloseButton", "EditBox",
    "Dropdown", "Bar", "Slider", "TextWindow",
}) do
    dofile("Templates/" .. file .. ".lua")
end

for name in pairs(lib.Mixins) do
    harness.assert(lib.Minimums[name] ~= nil,
        name .. " has a floor in lib.Minimums")
    harness.assertEqual(type(lib["Create" .. name]), "function",
        name .. " has a factory named after its mixin")
end

for name in pairs(lib.Minimums) do
    harness.assert(lib.Mixins[name] ~= nil,
        "lib.Minimums." .. name .. " names a widget that exists")
    local floor = lib.Minimums[name]
    harness.assert(type(floor.minWidth) == "number" and floor.minWidth > 0,
        name .. " has a positive minWidth")
    harness.assert(type(floor.minHeight) == "number" and floor.minHeight > 0,
        name .. " has a positive minHeight")
end

-- ApplyMinimum grows what is under the floor and leaves the rest alone.
-- harness.setFrameGeometry takes a rectangle (left/right/top/bottom), not a
-- width/height pair, so a 0..10 span on each axis is how a 10x10 frame is
-- expressed here.
local frame = harness.newFrame("Frame")
harness.setFrameGeometry(frame, { left = 0, right = 10, top = 10, bottom = 0 })
lib.ApplyMinimum(frame, "Button")
harness.assertEqual(frame:GetWidth(), 64, "a too-narrow frame is grown to the floor")
harness.assertEqual(frame:GetHeight(), 24, "and so is a too-short one")

local roomy = harness.newFrame("Frame")
harness.setFrameGeometry(roomy, { left = 0, right = 300, top = 100, bottom = 0 })
lib.ApplyMinimum(roomy, "Button")
harness.assertEqual(roomy:GetWidth(), 300, "a frame already above the floor is not shrunk")
harness.assertEqual(roomy:GetHeight(), 100, "on either axis")

-- A factory's floor has to survive whatever the widget does to its own size
-- AFTER it. UI.CreateButton always calls SetText when there is a label, and
-- SetText computes a width from the label -- zero measured glyphs here, plus
-- 2 * xl of padding, is 48, under Button's floor of 64. Without a second
-- ApplyMinimum inside SetText no labelled button ever reaches its floor, which
-- is every button built with text.
local labelled = lib.CreateButton(nil, harness.newFrame("Frame"), nil, "OK")
harness.assertEqual(labelled:GetWidth(), lib.Minimums.Button.minWidth,
    "a labelled button whose text computes narrower than the floor still measures the floor")
harness.assertEqual(labelled:GetHeight(), lib.Metrics.control,
    "and keeps the height its factory gave it")

-- The sibling path, and the reason the harness has to model SetWidth and
-- SetHeight rather than SetSize alone: this widget sets its height in OnLoad
-- and its width in one branch of it, so the pair the floor reads is one no
-- single call ever wrote.
local ticked = lib.CreateCheckButton(nil, harness.newFrame("Frame"), nil, true)
harness.assertEqual(ticked:GetWidth(), lib.Metrics.controlSmall,
    "an icon-only check button is as wide as its own branch asked for")
harness.assertEqual(ticked:GetHeight(), lib.Metrics.row,
    "and as tall as the row it sits in")

local ok, err = pcall(function() lib.ApplyMinimum(roomy, "Tabb") end)
harness.assert(not ok, "an unknown key raises rather than silently doing nothing")
harness.assert(tostring(err):find("Tabb", 1, true) ~= nil, "and the message names it")

harness.done()
