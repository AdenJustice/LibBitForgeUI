-- BitForge.UI.CreateBar -- the shared flat progress bar.
--
-- The bar is a native StatusBar rather than two hand-resized textures, which is
-- the whole point of the widget: the client owns the range, clamps into it, and
-- draws a zero-width fill without the guard Slider.lua writes by hand. The
-- cases below are the ones a consumer actually feeds it -- a faction with no
-- data yet, a renown track already at its ceiling -- and each has to render
-- rather than raise, because a bar is painted from the same pass as the row
-- around it and a raise there takes the whole list with it.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
dofile("Templates/Bar.lua")

local UI = lib
local colors = UI.Colors

harness.assertEqual(type(UI.CreateBar), "function", "the factory is published")
harness.assertEqual(type(UI.Mixins.Bar), "table", "and the mixin is registered beside the others")

local parent = harness.newFrame("Frame", "BarTestParent")
local bar = UI.CreateBar(parent)

harness.assertEqual(bar.frameType, "StatusBar",
    "the bar is a native StatusBar, not a Frame carrying two textures")
harness.assertEqual(bar.frameParent, parent, "parented where it was asked to be")


local fillColor = bar.Fill.calls.SetColorTexture
local trackColor = bar.Track.calls.SetColorTexture
local pointRed, pointGreen, pointBlue, pointAlpha = colors.point:GetRGBA()
local edgeRed, edgeGreen, edgeBlue, edgeAlpha = colors.edge:GetRGBA()

harness.assertDeepEqual({ fillColor[1], fillColor[2], fillColor[3], fillColor[4] },
    { pointRed, pointGreen, pointBlue, pointAlpha },
    "the fill defaults to the palette's point colour")
harness.assertDeepEqual({ trackColor[1], trackColor[2], trackColor[3], trackColor[4] },
    { edgeRed, edgeGreen, edgeBlue, edgeAlpha },
    "and the track behind it to the edge colour")

-- The track is a texture of the bar's own, not the status bar texture the
-- widget resizes -- colouring one must never have coloured the other.
harness.assertEqual(bar.Track == bar.Fill, false,
    "track and fill are separate regions")


bar:SetProgress(30, 120)
local minimum, maximum = bar:GetMinMaxValues()
harness.assertEqual(minimum, 0, "SetProgress floors the range at zero")
harness.assertEqual(maximum, 120, "and takes its ceiling from maxValue")
harness.assertEqual(bar:GetValue(), 30, "the value lands as given")

-- A renown track at its ceiling, or any source that counts past the threshold
-- it reports. The widget clamps; nothing here has to.
bar:SetProgress(500, 120)
harness.assertEqual(bar:GetValue(), 120, "a value past the maximum clamps to full")

-- A faction the client has no data for reports 0/0. Blizzard's own reputation
-- rows hand the widget exactly that, so it renders empty rather than raising.
local zeroOk = pcall(bar.SetProgress, bar, 50, 0)
harness.assertEqual(zeroOk, true, "a maxValue of zero does not raise")
harness.assertEqual(bar:GetValue(), 0, "it renders empty")

-- And a source that has answered nothing at all yet.
bar:SetProgress(30, 120)
local nilOk = pcall(bar.SetProgress, bar, 50, nil)
harness.assertEqual(nilOk, true, "a missing maxValue does not raise")
harness.assertEqual(bar:GetValue(), 0, "it renders empty too, rather than keeping the last fill")

-- Negative, which no honest source produces but a subtraction between two
-- thresholds can.
local negativeOk = pcall(bar.SetProgress, bar, 50, -10)
harness.assertEqual(negativeOk, true, "a negative maxValue does not raise")
harness.assertEqual(bar:GetValue(), 0, "and renders empty")

-- A missing value against a real maximum is an empty bar, not a raise: a row
-- can know its ceiling before it knows its progress.
local nilValueOk = pcall(bar.SetProgress, bar, nil, 120)
harness.assertEqual(nilValueOk, true, "a missing value does not raise")
harness.assertEqual(bar:GetValue(), 0, "and reads as no progress")

-- The native pair stays available underneath, for a caller wanting a floor
-- other than zero.
bar:SetMinMaxValues(100, 200)
bar:SetValue(150)
harness.assertEqual(bar:GetValue(), 150, "SetMinMaxValues/SetValue still work directly")

-- colour forms

local CLASS_COLOR = CreateColor(0.25, 0.78, 0.92, 1)
bar:SetBarColor(CLASS_COLOR)
fillColor = bar.Fill.calls.SetColorTexture
harness.assertDeepEqual({ fillColor[1], fillColor[2], fillColor[3], fillColor[4] },
    { 0.25, 0.78, 0.92, 1 },
    "SetBarColor takes a ColorMixin")

bar:SetBarColor(0.1, 0.2, 0.3, 0.4)
fillColor = bar.Fill.calls.SetColorTexture
harness.assertDeepEqual({ fillColor[1], fillColor[2], fillColor[3], fillColor[4] },
    { 0.1, 0.2, 0.3, 0.4 },
    "and loose r, g, b, a numbers, through the same resolver")

-- Alpha defaults rather than being required, as everywhere else in the skin.
bar:SetBarColor(0.5, 0.6, 0.7)
fillColor = bar.Fill.calls.SetColorTexture
harness.assertEqual(fillColor[4], 1, "an omitted alpha resolves to opaque")

bar:SetTrackColor(CLASS_COLOR)
trackColor = bar.Track.calls.SetColorTexture
harness.assertDeepEqual({ trackColor[1], trackColor[2], trackColor[3], trackColor[4] },
    { 0.25, 0.78, 0.92, 1 },
    "SetTrackColor accepts both forms as well")

bar:SetTrackColor(0.9, 0.8, 0.7, 0.6)
trackColor = bar.Track.calls.SetColorTexture
harness.assertDeepEqual({ trackColor[1], trackColor[2], trackColor[3], trackColor[4] },
    { 0.9, 0.8, 0.7, 0.6 },
    "loose numbers included")

harness.report()
