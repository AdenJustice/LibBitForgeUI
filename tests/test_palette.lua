-- LibBitForgeUI's palette and fonts -- the twelve ColorMixin objects, the
-- sixteen Font objects, SetFonts's in-place override, GetPixel, and the
-- separator texture built from the palette. The constraint the whole move
-- exists to protect is at the bottom: an upgrade reuses every colour and
-- font object rather than replacing it out from under a widget that already
-- holds a reference to one.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")

-- the palette

local COLOR_KEYS = {
    "point", "hover", "danger", "bg", "bgDisabled", "surface", "disabled",
    "text", "textHover", "textDisabled", "edge", "edgeHover",
}

local colorCount = 0
for _ in pairs(lib.Colors) do colorCount = colorCount + 1 end
harness.assertEqual(colorCount, 12, "lib.Colors has exactly twelve entries")

for _, key in ipairs(COLOR_KEYS) do
    local color = lib.Colors[key]
    harness.assert(color ~= nil, "lib.Colors." .. key .. " exists")
    harness.assertEqual(type(color and color.GetRGBA), "function",
        "lib.Colors." .. key .. " is a ColorMixin")
end

-- danger is BitForge_EUI's own refusal red, promoted rather than invented --
-- pinned against its own hex so a transcription typo fails here, not in game.
local dangerR, dangerG, dangerB, dangerA = lib.Colors.danger:GetRGBA()
local expectedR, expectedG, expectedB, expectedA = CreateColorFromHexString("FFFF4D4D"):GetRGBA()
harness.assertEqual(dangerR, expectedR, "danger's red channel matches the pinned hex")
harness.assertEqual(dangerG, expectedG, "danger's green channel matches the pinned hex")
harness.assertEqual(dangerB, expectedB, "danger's blue channel matches the pinned hex")
harness.assertEqual(dangerA, expectedA, "danger's alpha channel matches the pinned hex")

-- the fonts

local fontCount = 0
for _ in pairs(lib.Fonts) do fontCount = fontCount + 1 end
harness.assertEqual(fontCount, 16, "lib.Fonts has exactly sixteen entries")

for key, font in pairs(lib.Fonts) do
    harness.assertEqual(font.frameType, "Font", "lib.Fonts." .. key .. " is a Font object")
end

-- SetFonts mutates a Font object in place -- a widget holds a reference to it
-- through SetFontObject, and a replaced object would silently stop tracking
-- further calls.
local normalBefore = lib.Fonts.Normal
lib:SetFonts({ Normal = { size = 20 } })
harness.assertEqual(lib.Fonts.Normal, normalBefore, "SetFonts mutates the existing Font object")
harness.assertEqual(lib.Fonts.Normal.calls.SetFont[2], 20, "and applies the override")

-- GetPixel

harness.assertEqual(type(lib.GetPixel()), "number", "GetPixel() returns a number")
harness.assert(lib.GetPixel(3) > lib.GetPixel(), "GetPixel(3) is larger than the default")

-- CreateSeparatorTexture

local separatorParent = harness.newFrame("Frame", "SeparatorTestParent")
harness.setFrameGeometry(separatorParent, { left = 0, right = 100, top = 0, bottom = 10 })
local separator = lib.CreateSeparatorTexture(separatorParent)
harness.assertEqual(separator.calls.SetTexture[1],
    "Interface/Common/UI-TooltipDivider-Transparent", "the separator draws Blizzard's divider texture")
harness.assertEqual(separator.calls.SetVertexColor[1], lib.Colors.point.r,
    "tinted with the palette's point colour")
harness.assertEqual(separator.calls.SetVertexColor[4], 0.5, "at half alpha")

-- the upgrade path -- the constraint this file exists to protect

local colorRefs = {}
for key, color in pairs(lib.Colors) do
    colorRefs[key] = color
end
local fontRefs = {}
for key, font in pairs(lib.Fonts) do
    fontRefs[key] = font
end

-- Intercept the hex the palette resolves for "point", the way a real minor
-- bump would ship a changed hex literal, so the reload below can prove the
-- new value actually reaches the reused object -- not merely that the
-- object survived. `or` in the palette loop would pass identity here while
-- leaving the previous minor's RGBA in place forever.
local realCreateColorFromHexString = _G.CreateColorFromHexString
local POINT_HEX, CHANGED_POINT_HEX = "FF45B7D1", "FF00FF00"
_G.CreateColorFromHexString = function(hexString)
    if hexString == POINT_HEX then
        return realCreateColorFromHexString(CHANGED_POINT_HEX)
    end
    return realCreateColorFromHexString(hexString)
end

harness.loadLibraryAgain(2)

_G.CreateColorFromHexString = realCreateColorFromHexString

for key, color in pairs(colorRefs) do
    harness.assertEqual(lib.Colors[key], color, "upgrade reuses the same " .. key .. " colour object")
end
for key, font in pairs(fontRefs) do
    harness.assertEqual(lib.Fonts[key], font, "upgrade reuses the same " .. key .. " font object")
end

local newPointR, newPointG, newPointB, newPointA = lib.Colors.point:GetRGBA()
local wantR, wantG, wantB, wantA = realCreateColorFromHexString(CHANGED_POINT_HEX):GetRGBA()
harness.assertEqual(newPointR, wantR, "upgrade applies the new minor's point red channel")
harness.assertEqual(newPointG, wantG, "upgrade applies the new minor's point green channel")
harness.assertEqual(newPointB, wantB, "upgrade applies the new minor's point blue channel")
harness.assertEqual(newPointA, wantA, "upgrade applies the new minor's point alpha channel")

harness.done()
