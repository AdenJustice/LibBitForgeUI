-- UI.CreateFrame, and the two things about it nobody was checking: the
-- window ground's opacity comes from the bg token rather than a constant in
-- the factory, and the title bar's text is dark on the accent rather than
-- white on it. White on point measured 2.35:1 for as long as this factory
-- has existed, because no test looked at the pairing the factory itself
-- hard-codes both halves of.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
dofile("Templates/Frame.lua")

local plain = lib.CreateFrame(harness.newFrame("Frame"))
local ground = plain.calls.SetBackdropColor
harness.assertEqual(ground[1], lib.Colors.bg.r, "the ground takes bg's red channel")
harness.assertEqual(ground[2], lib.Colors.bg.g, "the ground takes bg's green channel")
harness.assertEqual(ground[3], lib.Colors.bg.b, "the ground takes bg's blue channel")
harness.assertEqual(ground[4], lib.Colors.bg.a,
    "and its alpha -- the factory holds no opacity constant of its own")

local titled = lib.CreateFrame(harness.newFrame("Frame"), "Inventory")
harness.assert(titled.Title ~= nil, "a titled frame builds a title")
harness.assertEqual(titled.TitleBar.calls.SetVertexColor[1], lib.Colors.point.r,
    "the title bar is painted with the accent")

local titleColor = titled.Title.calls.SetTextColor
harness.assertEqual(titleColor[1], lib.Colors.bg.r, "the title's text is bg, not white")
harness.assertEqual(titleColor[2], lib.Colors.bg.g, "on the green channel too")
harness.assertEqual(titleColor[3], lib.Colors.bg.b, "and the blue")
harness.assertEqual(titleColor[4], nil,
    "with no alpha argument -- bg's own alpha is the window ground's, not the text's")

harness.assertEqual(titled.Title.calls.SetText[1], "Inventory",
    "and the title carries the text it was created with")

local untitled = lib.CreateFrame(harness.newFrame("Frame"), "   ")
harness.assertEqual(untitled.Title, nil, "a whitespace-only title builds no title bar")
local ok = pcall(function() untitled:SetTitle("late") end)
harness.assert(not ok, "and setting one afterwards raises rather than doing nothing")

harness.done()
