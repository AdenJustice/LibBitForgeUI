-- BitForge.UI.CreateCloseButton -- the suite's own close button.
--
-- It replaced Blizzard's UIPanelCloseButton at every window in the suite, and
-- the point of the exercise was that three things the template carried had to
-- survive the swap: the narration mixin a screen reader announces the button
-- through, an explicit hover affordance, and frame level 510. Nothing in the
-- game complains when one of those is dropped -- the button still closes the
-- window -- so each is asserted here rather than left to be noticed.
--
-- The rest is the glyph -- an X inside a square outline. It is a baked asset
-- rather than drawn strokes, sized and anchored rather than laid out
-- arithmetically, and the same widget is asked for at 16 and at 24.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
dofile("Templates/CloseButton.lua")

local UI = lib
local colors = UI.Colors

harness.assertEqual(type(UI.CreateCloseButton), "function", "the factory is published")
harness.assertEqual(type(UI.Mixins.CloseButton), "table",
    "and the mixin is registered beside the others")

local parent = harness.newFrame("Frame", "CloseButtonTestParent")
local button = UI.CreateCloseButton(parent)

harness.assertEqual(button.frameType, "Button", "the widget is a Button")
harness.assertEqual(button.frameParent, parent, "parented where it was asked to be")
harness.assertEqual(button.frameTemplate, nil,
    "and inherits no Blizzard template -- the art is this file's")

-- what UIPanelCloseButton carried

-- Blizzard's own mixin, not a copy of it: NarrationGetName answers the client's
-- string, which is what a screen reader reads out.
harness.assertEqual(button.NarrationGetName, UIPanelCloseButtonNarrationMixin.NarrationGetName,
    "the button carries Blizzard's narration mixin")
harness.assertEqual(button:NarrationGetName(), NARRATION_OBJECT_CLOSE_BUTTON,
    "and announces itself as the client's close button")

-- 510 in the template, and not decoration: these windows put scroll frames and
-- backdrops over their own top-right corner, and a close button left at its
-- parent's level goes behind them.
local frameLevel = button.calls.SetFrameLevel
harness.assertEqual(frameLevel and frameLevel[1], 510,
    "the frame level is set explicitly, so the button stays above its siblings")

-- The hover affordance. BitForge_TaskTome's header gives its other icon buttons
-- a highlight by hand and documents that the close button brings its own, so
-- one that quietly stopped doing so would leave that comment lying.
local highlight = button.calls.SetHighlightTexture
harness.assertEqual(highlight and highlight[1], "Interface/Buttons/WHITE8X8",
    "a highlight texture is set")
harness.assertEqual(highlight and highlight[2], "ADD",
    "and blended additively, as the template's RedButton-Highlight was")

harness.assertEqual(type(button.scripts.OnEnter), "function", "the pointer is answered")
harness.assertEqual(type(button.scripts.OnLeave), "function", "and letting go of it too")


harness.assertEqual(type(button.Glyph), "table", "the X is exposed rather than private")
harness.assertEqual(#button.Glyph, 1, "and is a single region")

local glyph = button.Glyph[1]

-- A Texture, not a Line: a host that removes an addon's own art by fading
-- every region that answers IsObjectType("Texture") has to be able to see it.
harness.assertEqual(glyph.frameType, "CreateTexture", "the glyph is a Texture region")

-- A baked asset rather than drawn strokes, reached through the library's own
-- media path -- an embedder that vendors the library elsewhere still finds it.
harness.assertEqual(glyph.calls.SetTexture[1], UI.GetMedia("square-xmark-outline"),
    "the X is loaded from the suite's own icon set rather than drawn")

local glyphPoint = glyph.calls.SetPoint
harness.assertEqual(glyphPoint[1], "CENTER", "the glyph anchors to the button's centre")
harness.assertEqual(glyphPoint[2], button, "directly")
harness.assertEqual(glyphPoint[4], 0, "with no offset")
harness.assertEqual(glyphPoint[5], 0, "in either direction")

-- The whole reason for this change: a host's FadeRegions sets alpha to 0 on
-- every region that answers IsObjectType("Texture"). Simulating exactly that
-- against the glyph should leave nothing of it drawn.
glyph:SetAlpha(0)
harness.assertEqual(glyph.calls.SetAlpha[1], 0,
    "a host's fade reaches the glyph, leaving nothing of it drawn")

-- glyph colours

local DANGER = { colors.danger:GetRGBA() }
local HOVER = { colors.textHover:GetRGBA() }
local DISABLED = { colors.textDisabled:GetRGBA() }

--- What the glyph was last painted, as one answer.
local function strokeColor()
    local call = glyph.calls.SetVertexColor
    return { call[1], call[2], call[3], call[4] }
end

harness.assertDeepEqual(strokeColor(), DANGER,
    "at rest the X is the palette's danger red -- the colour that replaced Blizzard's")

button.scripts.OnEnter(button)
harness.assertDeepEqual(strokeColor(), HOVER,
    "under the pointer it brightens to textHover, over the additive red wash")

button.scripts.OnLeave(button)
harness.assertDeepEqual(strokeColor(), DANGER, "and settles back to red")

button.scripts.OnDisable(button)
harness.assertDeepEqual(strokeColor(), DISABLED,
    "a disabled close button reads as disabled rather than as one that still works")

button.scripts.OnEnable(button)
harness.assertDeepEqual(strokeColor(), DANGER, "and comes back")

-- the sizes

-- 24 is what UIPanelCloseButton was, so every window that never asked for a
-- size keeps the button it had.
local size = button.calls.SetSize
harness.assertDeepEqual({ size[1], size[2] }, { 24, 24 }, "the default is 24x24")

-- BitForge_TaskTome's widget header is a row of 16px icon buttons and asks for
-- one of those.
local small = UI.CreateCloseButton(parent, 16)
local smallSize = small.calls.SetSize
harness.assertDeepEqual({ smallSize[1], smallSize[2] }, { 16, 16 }, "and a size is honoured")

--- The glyph's own edge length, for a button of `edge`. Width and height are
--- equal -- the region is square, so either SetSize argument answers it.
local function glyphSize(closeButton)
    return closeButton.Glyph[1].calls.SetSize[1]
end

local wideGlyph = glyphSize(button)
local smallGlyph = glyphSize(small)

harness.assertEqual(smallGlyph < wideGlyph, true, "the smaller button draws the smaller glyph")

-- Proportional, not merely smaller: an X that kept its size while its box
-- shrank is the blot the reach ratio exists to avoid. 16/24 either way.
harness.assertEqual(smallGlyph / wideGlyph, 16 / 24, "the glyph holds its proportion of the button")

-- The glyph fits inside the button rather than running to its edge: the button
-- is the hit target and the X is the mark on it. The region is the looser
-- measure of the two -- the asset carries its own padding, so the drawn square
-- ends well inside the region this asserts on.
harness.assertEqual(wideGlyph < 24, true, "the X sits inside its button")

-- A caller that sizes the button after building it gets a glyph to match. This
-- is the path BitForge_TaskTome used before the size became a factory
-- argument, and the one any consumer takes who resizes a window's furniture.
button.scripts.OnSizeChanged(button, 16, 16)
harness.assertEqual(glyphSize(button), smallGlyph, "a later resize relays the glyph out")

-- 16 is the floor, so 15 is not a smaller button -- it is 16.
local clamped = UI.CreateCloseButton(harness.newFrame("Frame"), 15)
harness.assertEqual(clamped:GetWidth(), 16, "a below-floor close button is grown to 16")
harness.assertEqual(clamped:GetHeight(), 16, "on both axes")

-- Measuring only the button lets the glyph drift from it silently -- the
-- assertion above passed even while the glyph was still built from the
-- requested 15. The ratio is read back from an unclamped button rather than
-- hard-coded, so this keeps working if GLYPH_REACH_RATIO ever changes. It comes
-- from `small`, which nothing ever resized: the 24 button was driven through
-- OnSizeChanged above, and reading its width back agrees with wideGlyph only
-- for as long as the harness leaves a script-driven resize unmodelled -- an
-- assertion resting on something the harness does NOT do.
local reachRatio = smallGlyph / small:GetWidth()
harness.assertEqual(glyphSize(clamped), clamped:GetWidth() * reachRatio,
    "the glyph scales off the clamped button's real side, not the size that was requested")

harness.report()
