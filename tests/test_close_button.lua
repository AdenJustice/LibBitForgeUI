-- BitForge.UI.CreateCloseButton -- the suite's own close button.
--
-- It replaced Blizzard's UIPanelCloseButton at every window in the suite, and
-- the point of the exercise was that three things the template carried had to
-- survive the swap: the narration mixin a screen reader announces the button
-- through, an explicit hover affordance, and frame level 510. Nothing in the
-- game complains when one of those is dropped -- the button still closes the
-- window -- so each is asserted here rather than left to be noticed.
--
-- The rest is the glyph. It is drawn, so its weight is arithmetic rather than
-- an asset's, and the same widget is asked for at 16 and at 24.
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
harness.assertEqual(#button.Glyph, 2, "and is two strokes")

local descending, ascending = button.Glyph[1], button.Glyph[2]
harness.assertEqual(descending == ascending, false, "which are separate regions")

-- Textures, not Lines: a host that removes an addon's own art by fading every
-- region that answers IsObjectType("Texture") has to be able to see these.
harness.assertEqual(descending.frameType, "CreateTexture", "a stroke is a Texture region")
harness.assertEqual(ascending.frameType, "CreateTexture", "and so is the other, not a Line")

-- A solid colour rather than an atlas: the widget owns its colour, so the
-- palette can move without an asset being redrawn.
harness.assertDeepEqual(
    { descending.calls.SetColorTexture[1], descending.calls.SetColorTexture[2],
        descending.calls.SetColorTexture[3], descending.calls.SetColorTexture[4] },
    { 1, 1, 1, 1 }, "each stroke is a solid white texture")

-- Both strokes anchor at the very same point, so the X is centred without
-- needing a pair of offsets mirrored against each other.
local descendingPoint = descending.calls.SetPoint
local ascendingPoint = ascending.calls.SetPoint

harness.assertEqual(descendingPoint[1], "CENTER", "a stroke anchors to the button's centre")
harness.assertEqual(descendingPoint[2], button, "directly")
harness.assertEqual(descendingPoint[4], 0, "with no offset")
harness.assertEqual(descendingPoint[5], 0, "in either direction")
harness.assertDeepEqual(ascendingPoint, descendingPoint,
    "and the second stroke anchors at exactly the same point")

-- The two strokes cross: rotated a quarter turn apart rather than parallel,
-- which would still look like a line. Only the difference between the two
-- angles is asserted, not either literal value, so a convention change
-- (radians vs degrees, sign) fails this rather than passing it by accident.
local descendingRotation = descending.calls.SetRotation[1]
local ascendingRotation = ascending.calls.SetRotation[1]
harness.assertEqual(math.abs(descendingRotation - ascendingRotation), math.pi / 2,
    "the two strokes are rotated a quarter turn apart, so they cross")

-- The whole reason for this change: a host's FadeRegions sets alpha to 0 on
-- every region that answers IsObjectType("Texture"). Simulating exactly that
-- against both strokes should leave nothing of the glyph drawn.
descending:SetAlpha(0)
ascending:SetAlpha(0)
harness.assertEqual(descending.calls.SetAlpha[1], 0, "a host's fade reaches the first stroke")
harness.assertEqual(ascending.calls.SetAlpha[1], 0,
    "and the second, leaving nothing of the glyph drawn")

-- glyph colours

local DANGER = { colors.danger:GetRGBA() }
local HOVER = { colors.textHover:GetRGBA() }
local DISABLED = { colors.textDisabled:GetRGBA() }

--- What the two strokes were last painted, as one answer -- the X is one glyph
--- and a widget that coloured half of it is a defect, not a state.
local function strokeColor()
    local first = descending.calls.SetVertexColor
    local second = ascending.calls.SetVertexColor
    harness.assertDeepEqual({ first[1], first[2], first[3], first[4] },
        { second[1], second[2], second[3], second[4] },
        "both strokes are painted the same")
    return { first[1], first[2], first[3], first[4] }
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

--- The stroke weight and the reach of one arm, for a button of `edge`.
local function glyphMetrics(closeButton)
    local width, height = closeButton.Glyph[1].calls.SetSize[1], closeButton.Glyph[1].calls.SetSize[2]
    return height, width / 2
end

local wideStroke, wideReach = glyphMetrics(button)
local smallStroke, smallReach = glyphMetrics(small)

harness.assertEqual(smallStroke < wideStroke, true,
    "the smaller button draws the lighter stroke")
harness.assertEqual(smallReach < wideReach, true, "and the shorter arm")

-- Proportional, not merely smaller: an X that kept its weight while its box
-- shrank is the blot the ratios exist to avoid. 16/24 either way.
harness.assertEqual(smallStroke / wideStroke, 16 / 24,
    "the stroke holds its proportion of the button")
harness.assertEqual(smallReach / wideReach, 16 / 24, "and so does the reach")

-- The glyph fits inside the button rather than running to its edge: the button
-- is the hit target and the X is the mark on it.
harness.assertEqual(wideReach * 2 < 24, true, "the X sits inside its button")

-- A caller that sizes the button after building it gets a glyph to match. This
-- is the path BitForge_TaskTome used before the size became a factory
-- argument, and the one any consumer takes who resizes a window's furniture.
button.scripts.OnSizeChanged(button, 16, 16)
harness.assertEqual(glyphMetrics(button), smallStroke,
    "a later resize relays the glyph out")

-- the pixel-grid floor

-- The stroke is a fraction of the button, so at a UI scale coarse enough it
-- would fall below one physical pixel and the X would thin away. GetPixel is
-- the floor. Driven by shrinking the button rather than the scale, since one
-- physical pixel is a fixed size and the proportional stroke is not.
local floorParent = harness.newFrame("Frame", "CloseButtonFloorParent")
local tiny = UI.CreateCloseButton(floorParent, 4)
local tinyStroke = tiny.Glyph[1].calls.SetSize[2]

harness.assertEqual(tinyStroke, UI.GetPixel(),
    "a button too small for a proportional stroke still draws one physical pixel")
harness.assertEqual(tinyStroke > 4 * (smallStroke / 16), true,
    "which is thicker than the proportion alone would have given")

harness.report()
