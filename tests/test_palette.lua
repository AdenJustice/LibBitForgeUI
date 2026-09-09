-- LibBitForgeUI's palette and fonts -- the sixteen ColorMixin objects, the
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
    "text", "textHover", "textDisabled", "edge", "edgeHover", "selection",
}

local colorCount = 0
for _ in pairs(lib.Colors) do colorCount = colorCount + 1 end
harness.assertEqual(colorCount, 17, "lib.Colors has exactly seventeen entries")

for _, key in ipairs(COLOR_KEYS) do
    local color = lib.Colors[key]
    harness.assert(color ~= nil, "lib.Colors." .. key .. " exists")
    harness.assertEqual(type(color and color.GetRGBA), "function",
        "lib.Colors." .. key .. " is a ColorMixin")
end

-- danger is BitForge_EUI's own refusal red, promoted rather than invented --
-- pinned against its own hex so a transcription typo fails here, not in game.
local dangerR, dangerG, dangerB, dangerA = lib.Colors.danger:GetRGBA()
local expectedR, expectedG, expectedB, expectedA = CreateColorFromHexString("FFFF5F5F"):GetRGBA()
harness.assertEqual(dangerR, expectedR, "danger's red channel matches the pinned hex")
harness.assertEqual(dangerG, expectedG, "danger's green channel matches the pinned hex")
harness.assertEqual(dangerB, expectedB, "danger's blue channel matches the pinned hex")
harness.assertEqual(dangerA, expectedA, "danger's alpha channel matches the pinned hex")

-- point moved from #45B7D1 to a higher-chroma value in the same hue family:
-- L* 69.3 -> 77.9, C* 32.8 -> 40.8, hue 223 -> 218. Pinned so a transcription
-- typo fails here rather than in game.
local pointR, pointG, pointB, pointA = lib.Colors.point:GetRGBA()
local wantPointR, wantPointG, wantPointB, wantPointA =
    CreateColorFromHexString("FF22D3EE"):GetRGBA()
harness.assertEqual(pointR, wantPointR, "point's red channel matches the pinned hex")
harness.assertEqual(pointG, wantPointG, "point's green channel matches the pinned hex")
harness.assertEqual(pointB, wantPointB, "point's blue channel matches the pinned hex")
harness.assertEqual(pointA, wantPointA, "point's alpha channel matches the pinned hex")

-- The window ground's opacity lives in this token's alpha and nowhere else.
-- Frame.lua used to carry it as a private 0.5, which meant every contrast
-- value in the palette was computed against a ground that never appeared.
--
-- Pinned against the hex rather than against 0.95: the alpha byte is F2,
-- which is 242/255 = 0.94901960..., and an equality against the decimal the
-- comment rounds to can never pass. Every other pinned colour in this file
-- compares to CreateColorFromHexString for the same reason.
local bgR, bgG, bgB, bgA = lib.Colors.bg:GetRGBA()
local wantBgR, wantBgG, wantBgB, wantBgA =
    CreateColorFromHexString("F20E0F12"):GetRGBA()
harness.assertEqual(bgR, wantBgR, "bg's red channel matches the pinned hex")
harness.assertEqual(bgG, wantBgG, "bg's green channel matches the pinned hex")
harness.assertEqual(bgB, wantBgB, "bg's blue channel matches the pinned hex")
harness.assertEqual(bgA, wantBgA, "and its alpha does too")
harness.assert(bgA < 1, "bg carries the window ground's opacity, rather than being opaque")

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
local POINT_HEX, CHANGED_POINT_HEX = "FF22D3EE", "FF00FF00"
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

-- selection is derived from point, so an upgrade that changes the accent has
-- to reach it too. A one-time derivation at first load would pass every
-- assertion above and leave this one holding the previous minor's accent.
harness.assertEqual(lib.Colors.selection.r, lib.Colors.point.r,
    "upgrade re-derives selection from the new minor's point")
harness.assertEqual(lib.Colors.selection.a, 0.25, "and keeps its quarter alpha")

-- The ladder is an ordering claim, not a set of values: bg sits below surface
-- sits below raised. disabled is a state, not a rung -- it is checked against
-- surface rather than placed on the ladder. Asserted through relative
-- luminance so the claim survives a later retune of the hexes.
local function luminance(color)
    local function channel(c)
        return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
    end
    local r, g, b = color:GetRGB()
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

for _, key in ipairs({ "raised", "textMuted", "success", "highlight" }) do
    harness.assert(lib.Colors[key] ~= nil, "the palette publishes " .. key)
end

harness.assert(luminance(lib.Colors.bg) < luminance(lib.Colors.surface),
    "bg sits below surface on the ladder")
harness.assert(luminance(lib.Colors.surface) < luminance(lib.Colors.raised),
    "surface sits below raised on the ladder")
harness.assert(luminance(lib.Colors.disabled) < luminance(lib.Colors.surface),
    "the disabled state is a dimmed surface, not a rung of its own")
harness.assert(luminance(lib.Colors.edge) > luminance(lib.Colors.surface),
    "a border lifts above the surface it outlines, rather than cutting into it")
harness.assert(luminance(lib.Colors.edgeHover) > luminance(lib.Colors.edge),
    "and lifts further under the pointer")
harness.assert(luminance(lib.Colors.text) > luminance(lib.Colors.textMuted),
    "body text is brighter than muted text")

-- selection is point at a quarter alpha, derived rather than written as its
-- own hex, so a change to the accent reaches the selection fill in one edit.
local selectionR, selectionG, selectionB, selectionA = lib.Colors.selection:GetRGBA()
harness.assertEqual(selectionR, lib.Colors.point.r, "selection takes point's red channel")
harness.assertEqual(selectionG, lib.Colors.point.g, "selection takes point's green channel")
harness.assertEqual(selectionB, lib.Colors.point.b, "selection takes point's blue channel")
harness.assertEqual(selectionA, 0.25, "at a quarter alpha")

-- The one pairing Frame.lua hard-codes both halves of. Nothing checked it
-- before, which is how white-on-accent at 2.35:1 shipped.
local function contrast(first, second)
    local a, b = luminance(first), luminance(second)
    local lighter, darker = math.max(a, b), math.min(a, b)
    return (lighter + 0.05) / (darker + 0.05)
end

harness.assert(contrast(lib.Colors.bg, lib.Colors.point) >= 4.5,
    "the title bar's own pairing -- bg text on a point band -- clears the AA floor")

harness.done()
