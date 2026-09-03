-- LibBitForgeUI's reskin/strip primitives -- GetSolidBackdrop,
-- ApplyColorTexture, ApplyVertexColor, HideTexture, StripFrameTextures,
-- CreateBackdropUnderlay, BuildWindowShell and StyleScrollBar. New coverage:
-- Core.lua carried these without a test file of its own, so this one is
-- written against what the code actually does rather than what it should.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
local skin = lib.Skin

-- the shared colour-argument helper -- a ColorMixin, a bare {r,g,b,a} table
-- and loose numbers must all reach the same texture call, and an omitted
-- alpha must come out opaque. Pinned on both colour-taking primitives, since
-- this is the behaviour lua-style.md calls out by name.

local function assertColorCall(callArgs, label)
    harness.assertEqual(callArgs[1], 0.25, label .. " -- red")
    harness.assertEqual(callArgs[2], 0.5, label .. " -- green")
    harness.assertEqual(callArgs[3], 0.75, label .. " -- blue")
    harness.assertEqual(callArgs[4], 1, label .. " -- omitted alpha resolves opaque")
end

for _, applyName in ipairs({ "ApplyColorTexture", "ApplyVertexColor" }) do
    local setCallName = applyName == "ApplyColorTexture" and "SetColorTexture" or "SetVertexColor"

    local mixinTexture = harness.newFrame("Texture")
    skin[applyName](mixinTexture, CreateColor(0.25, 0.5, 0.75))
    assertColorCall(mixinTexture.calls[setCallName], applyName .. " with a ColorMixin")

    local tableTexture = harness.newFrame("Texture")
    skin[applyName](tableTexture, { r = 0.25, g = 0.5, b = 0.75 })
    assertColorCall(tableTexture.calls[setCallName], applyName .. " with a bare {r,g,b,a} table")

    local numberTexture = harness.newFrame("Texture")
    skin[applyName](numberTexture, 0.25, 0.5, 0.75)
    assertColorCall(numberTexture.calls[setCallName], applyName .. " with loose r, g, b numbers")
end

-- an explicit alpha still threads through, on top of the default above
local explicitAlphaTexture = harness.newFrame("Texture")
skin.ApplyColorTexture(explicitAlphaTexture, 0.25, 0.5, 0.75, 0.4)
harness.assertEqual(explicitAlphaTexture.calls.SetColorTexture[4], 0.4,
    "ApplyColorTexture -- an explicit alpha is not overridden")

-- a nil colour argument is a no-op, not an error
local untouchedTexture = harness.newFrame("Texture")
skin.ApplyColorTexture(untouchedTexture, nil)
harness.assertEqual(untouchedTexture.calls.SetColorTexture, nil,
    "ApplyColorTexture with no colour argument does not call SetColorTexture")

-- GetSolidBackdrop

local backdrop = skin.GetSolidBackdrop()
harness.assertEqual(backdrop.bgFile, "Interface/Buttons/WHITE8X8", "solid backdrop bgFile")
harness.assertEqual(backdrop.edgeFile, "Interface/Buttons/WHITE8X8", "solid backdrop edgeFile")
harness.assertEqual(backdrop.tile, false, "solid backdrop is not tiled")
harness.assertEqual(backdrop.edgeSize, lib.GetPixel(), "solid backdrop edgeSize is one pixel")
harness.assertDeepEqual(backdrop.insets, { left = 0, right = 0, top = 0, bottom = 0 },
    "solid backdrop has zero insets")

-- HideTexture, with and without clearSource

local hiddenTexture = harness.newFrame("Texture")
skin.HideTexture(hiddenTexture)
harness.assertEqual(hiddenTexture.calls.SetAlpha[1], 0, "HideTexture sets alpha to 0")
harness.assertEqual(hiddenTexture.calls.SetAtlas, nil,
    "without clearSource, HideTexture leaves SetAtlas untouched")
harness.assertEqual(hiddenTexture.calls.SetTexture, nil,
    "without clearSource, HideTexture leaves SetTexture untouched")

local clearedTexture = harness.newFrame("Texture")
skin.HideTexture(clearedTexture, true)
harness.assertEqual(clearedTexture.calls.SetAlpha[1], 0,
    "HideTexture with clearSource still sets alpha to 0")
harness.assert(clearedTexture.calls.SetAtlas ~= nil, "clearSource calls SetAtlas")
harness.assertEqual(clearedTexture.calls.SetAtlas[1], nil, "...clearing it to nil")
harness.assert(clearedTexture.calls.SetTexture ~= nil, "clearSource calls SetTexture")
harness.assertEqual(clearedTexture.calls.SetTexture[1], nil, "...clearing it to nil")

-- StripFrameTextures leaves a frame's non-texture regions alone

local stripFrame = harness.newFrame("Frame", "StripTestFrame")
stripFrame.NineSlice = harness.newFrame("Frame")
stripFrame.Border = harness.newFrame("Texture")

local textureRegion = harness.newFrame("Texture")
textureRegion.IsObjectType = function(_, objectType) return objectType == "Texture" end

local fontStringRegion = harness.newFrame("FontString")
fontStringRegion.IsObjectType = function(_, objectType) return objectType == "FontString" end

function stripFrame:GetRegions() return textureRegion, fontStringRegion end

skin.StripFrameTextures(stripFrame)

harness.assertEqual(textureRegion.calls.SetAlpha[1], 0, "StripFrameTextures hides a texture region")
harness.assertEqual(fontStringRegion.calls.SetAlpha, nil,
    "StripFrameTextures leaves a non-texture region alone")
harness.assertEqual(stripFrame.NineSlice.calls.SetAlpha[1], 0, "StripFrameTextures hides NineSlice")
harness.assertEqual(stripFrame.Border.calls.SetAlpha[1], 0, "StripFrameTextures hides Border")
-- Bg/BG were never assigned on this frame, so OPTIONAL_WIDGET_FIELDS reads
-- them as nil and StripFrameTextures skips them without erroring.

-- StripFrameTextures on a frame with none of the optional pieces set, and no
-- GetRegions at all, still returns rather than erroring.
skin.StripFrameTextures(harness.newFrame("Frame", "BareStripTestFrame"))

-- CreateBackdropUnderlay

local underlayParent = harness.newFrame("Frame", "UnderlayParent")
underlayParent:SetFrameLevel(5)
local underlay = skin.CreateBackdropUnderlay(underlayParent, {
    backgroundColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 },
    borderColor = CreateColor(0.5, 0.6, 0.7),
})
harness.assertEqual(underlay.frameParent, underlayParent,
    "CreateBackdropUnderlay parents to the target frame by default")
harness.assertEqual(underlay.frameLevel, 4,
    "CreateBackdropUnderlay levels one below the target frame")
harness.assertDeepEqual(underlay.calls.SetBackdrop[1], skin.GetSolidBackdrop(),
    "CreateBackdropUnderlay uses the solid backdrop by default")
harness.assertEqual(underlay.calls.SetBackdropColor[1], 0.1,
    "CreateBackdropUnderlay applies the background colour")
harness.assertEqual(underlay.calls.SetBackdropColor[4], 0.4, "...alpha included")
harness.assertEqual(underlay.calls.SetBackdropBorderColor[1], 0.5,
    "CreateBackdropUnderlay applies the border colour")
harness.assertEqual(underlay.calls.SetBackdropBorderColor[4], 1,
    "...an omitted border alpha resolves opaque")

-- BuildWindowShell returns the same keys it returns today

local shellFrame = harness.newFrame("Frame", "ShellTestFrame")
local shell = skin.BuildWindowShell(shellFrame)

local DEFAULT_SHELL_KEYS = {
    "background", "borderTop", "borderBottom", "borderLeft", "borderRight", "innerTop",
}
for _, key in ipairs(DEFAULT_SHELL_KEYS) do
    harness.assert(shell[key] ~= nil, "BuildWindowShell's default shell includes " .. key)
end
harness.assertEqual(shell.header, nil, "BuildWindowShell omits header without includeHeader")

local shellKeyCount = 0
for _ in pairs(shell) do shellKeyCount = shellKeyCount + 1 end
harness.assertEqual(shellKeyCount, #DEFAULT_SHELL_KEYS, "and no extra pieces beyond those")

harness.assertEqual(skin.BuildWindowShell(shellFrame), shell,
    "BuildWindowShell caches and reuses the shell for the same frame")

local headerFrame = harness.newFrame("Frame", "ShellHeaderFrame")
local headerShell = skin.BuildWindowShell(headerFrame, { includeHeader = true, includeInnerTop = false })
harness.assert(headerShell.header ~= nil, "includeHeader = true adds a header piece")
harness.assertEqual(headerShell.innerTop, nil, "includeInnerTop = false omits the inner top piece")

-- StyleScrollBar tolerates a scroll bar missing the optional regions it looks for

local bareScrollBar = { calls = {} }
function bareScrollBar:SetAlpha(alpha) self.calls.SetAlpha = { alpha, n = 1 } end
local bareResult = skin.StyleScrollBar(bareScrollBar)
harness.assertEqual(bareResult, nil,
    "StyleScrollBar with no GetThumbTexture accessor returns nil without erroring")
harness.assertEqual(bareScrollBar.calls.SetAlpha[1], 0.85,
    "...but still applies the default scroll bar alpha")

local emptyThumbScrollBar = harness.newFrame("Slider")
emptyThumbScrollBar.GetThumbTexture = function() return nil end
local emptyThumbResult = skin.StyleScrollBar(emptyThumbScrollBar)
harness.assertEqual(emptyThumbResult, nil,
    "StyleScrollBar with GetThumbTexture answering nil returns nil without erroring")

local scrollBar = harness.newFrame("Slider")
local thumbTexture = harness.newFrame("Texture")
scrollBar.GetThumbTexture = function() return thumbTexture end
local styled = skin.StyleScrollBar(scrollBar, { thumbColor = { r = 1, g = 0, b = 0 } })
harness.assertEqual(styled, thumbTexture, "StyleScrollBar returns the thumb texture it styled")
harness.assertEqual(scrollBar.calls.SetAlpha[1], 0.85, "StyleScrollBar's default scroll bar alpha")
harness.assertEqual(thumbTexture.calls.SetAlpha[1], 0.95, "StyleScrollBar's default thumb alpha")
harness.assertEqual(thumbTexture.calls.SetVertexColor[1], 1,
    "StyleScrollBar applies the given thumb colour")

harness.done()
