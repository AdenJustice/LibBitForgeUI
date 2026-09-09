-- UI.CreateScrollList: the widget six embedders were each building by hand,
-- and which six of them left unstyled because StyleScrollBar was a separate
-- call. The factory's whole point is that the bar comes back styled and the
-- caller sizes one frame rather than two.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
dofile("Templates/ScrollList.lua")

local function initRow() end

-- linear, all defaults

local linear = lib.CreateScrollList(harness.newFrame("Frame"), { initializer = initRow })

harness.assertEqual(linear.ScrollBox.frameTemplate, "WowScrollBoxList",
    "the box is built from the client's list template")
harness.assertEqual(linear.ScrollBar.frameType, "EventFrame",
    "MinimalScrollBar is an EventFrame, not a Frame")
harness.assertEqual(linear.ScrollBar.frameTemplate, "MinimalScrollBar",
    "and the bar is built from it")
harness.assertEqual(linear.View.frameType, "ScrollBoxListLinearView",
    "a list with no tree option gets the linear view")
harness.assertEqual(linear.View.calls.SetElementExtent[1], lib.Metrics.row,
    "a row is as tall as the scale's row token")
harness.assertEqual(linear.View.calls.SetElementInitializer[1], "Button",
    "rows are buttons unless the caller says otherwise")
harness.assertEqual(linear.View.calls.SetElementInitializer[2], initRow,
    "and the caller's initializer fills them")
harness.assertEqual(linear.ScrollBox.initialisedWith, linear.View,
    "the box is bound to the view")
harness.assertEqual(linear.ScrollBar.initialisedWith, linear.View,
    "and so is the bar")

-- the miss this factory exists to make impossible
harness.assertEqual(linear.ScrollBar.calls.SetAlpha[1], 0.85,
    "the bar comes back styled without the caller asking")

-- the floor
harness.assert(lib.Minimums.ScrollList ~= nil, "ScrollList has a floor")
harness.assert(linear:GetWidth() >= lib.Minimums.ScrollList.minWidth,
    "and a fresh list is at or above it on width")
harness.assert(linear:GetHeight() >= lib.Minimums.ScrollList.minHeight,
    "and on height")

-- tree, and the overrides

local tree = lib.CreateScrollList(harness.newFrame("Frame"), {
    tree        = true,
    initializer = initRow,
    elementType = "Frame",
    extent      = 40,
    indent      = 24,
})

harness.assertEqual(tree.View.frameType, "ScrollBoxListTreeListView",
    "options.tree picks the tree view constructor")
harness.assertEqual(tree.View.constructorArgs[1], 24,
    "the indent is the tree view's first constructor argument")
harness.assertEqual(tree.View.calls.SetElementExtent[1], 40, "the extent override applies")
harness.assertEqual(tree.View.calls.SetElementInitializer[1], "Frame",
    "and so does the element type")

local defaultTree = lib.CreateScrollList(harness.newFrame("Frame"), {
    tree = true, initializer = initRow,
})
harness.assertEqual(defaultTree.View.constructorArgs[1], lib.Metrics.md,
    "an unset indent comes from the scale, not from a literal")

-- a list with no initializer draws empty rows forever and says nothing, so
-- the factory refuses rather than building one.
local ok, err = pcall(function()
    lib.CreateScrollList(harness.newFrame("Frame"), {})
end)
harness.assert(not ok, "a list with no initializer raises")
harness.assert(tostring(err):find("initializer", 1, true) ~= nil, "and the message names it")

harness.done()
