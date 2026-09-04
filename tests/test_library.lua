local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")

harness.assert(lib ~= nil, "the library registers with LibStub")
harness.assertEqual(LibStub("LibBitForgeUI-1.0"), lib,
    "and is reachable by its major version")

-- The whole reason the tables are declared `lib.X = lib.X or {}`: a widget
-- built by an older minor holds a reference into these, so a replacement on
-- upgrade orphans it silently. Every published table is named, not only the
-- two whose contents are objects -- a table left off this list is a table no
-- upgrade test covers, which is where lib.Minimums sat. That the VALUES in
-- them survive an upgrade too is tested where each one lives:
-- tests/test_palette.lua for the colours, tests/test_metrics.lua for the scale
-- and the floors.
local PUBLISHED_TABLES = { "Colors", "Fonts", "Mixins", "Skin", "Metrics", "Minimums" }

local before = {}
for _, name in ipairs(PUBLISHED_TABLES) do
    harness.assertEqual(type(lib[name]), "table", "the library publishes lib." .. name)
    before[name] = lib[name]
end

lib.Colors.marker = true
harness.loadLibraryAgain(2)
for _, name in ipairs(PUBLISHED_TABLES) do
    harness.assertEqual(lib[name], before[name], "an upgrade reuses lib." .. name)
end
harness.assert(lib.Colors.marker, "and does not wipe what was in it")

harness.assertEqual(harness.loadLibraryAgain(2), nil,
    "the same minor twice registers nothing")

harness.assertEqual(lib.GetMedia("glow"),
    "Interface/AddOns/BitForge/Libs/LibBitForgeUI/Media/glow",
    "media resolves under the host addon's embed path")

lib:SetMediaPath("Interface/AddOns/Other/Media")
harness.assertEqual(lib.GetMedia("glow"), "Interface/AddOns/Other/Media/glow",
    "and an embedder can override it")

harness.done()
