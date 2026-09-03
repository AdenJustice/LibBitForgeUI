local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")

harness.assert(lib ~= nil, "the library registers with LibStub")
harness.assertEqual(LibStub("LibBitForgeUI-1.0"), lib,
    "and is reachable by its major version")

-- The whole reason the tables are declared `lib.X = lib.X or {}`: a widget
-- built by an older minor holds a reference into these, so a replacement on
-- upgrade orphans it silently.
local colorsBefore, fontsBefore = lib.Colors, lib.Fonts
colorsBefore.marker = true
harness.loadLibraryAgain(2)
harness.assertEqual(lib.Colors, colorsBefore, "an upgrade reuses lib.Colors")
harness.assertEqual(lib.Fonts, fontsBefore, "an upgrade reuses lib.Fonts")
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
