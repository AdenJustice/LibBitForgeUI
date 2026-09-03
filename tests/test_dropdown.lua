-- BitForge.UI.CreateDropdown -- the shared multi-select dropdown.
--
-- What is driven here is the one thing a view cannot: what the closed box
-- PAINTS. Every other widget in BitForge/APIs/UI/Templates got a greyed state
-- with its OnDisable/OnEnable hooks and this one did not, and the gap does not
-- read as a bug from the outside -- SetEnabled(false) really does stop the
-- menu opening and the wheel turning, because Blizzard's OpenMenu and
-- OnMouseWheel_Intrinsic both return early on IsEnabled. It only reads as a
-- bug to the player, who is shown a live-looking box that silently does
-- nothing. A view test asserting IsEnabled() == false passes either way, which
-- is why the assertions below are here and against the real file, the way
-- test_core_ui_close_button.lua drives the close button's own glyph.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
dofile("Templates/Dropdown.lua")

local UI = lib
local colors = UI.Colors

harness.assertEqual(type(UI.CreateDropdown), "function", "the factory is published")
harness.assertEqual(type(UI.Mixins.Dropdown), "table",
    "and the mixin is registered beside the others")

local parent = harness.newFrame("Frame", "DropdownTestParent")
local dropdown = UI.CreateDropdown(parent, "Select an option")

harness.assertEqual(dropdown.frameType, "Button", "the widget is a Button")
harness.assertEqual(dropdown.frameParent, parent, "parented where it was asked to be")
harness.assertEqual(dropdown.IsMenuOpen, UI.Mixins.Dropdown.IsMenuOpen,
    "and carries Blizzard's DropdownButtonMixin, so the menu plumbing is the client's")

local EDGE = { colors.edge:GetRGBA() }
local BORDER_DISABLED = { colors.bgDisabled:GetRGBA() }
local POINT = { colors.point:GetRGBA() }
local TEXT = { colors.text:GetRGB() }
local TEXT_DISABLED = { colors.textDisabled:GetRGB() }
local UNTINTED = { 1, 1, 1 }

--- The border the backdrop was last painted, as r, g, b, a.
local function borderColor()
    local painted = dropdown.calls.SetBackdropBorderColor
    return { painted[1], painted[2], painted[3], painted[4] }
end

--- What the closed box's own two regions were last painted. Read together
--- because a greyed dropdown whose label went grey and whose arrow stayed
--- white is half a state, not a state.
local function labelColor()
    local painted = dropdown.Label.calls.SetTextColor
    return { painted[1], painted[2], painted[3] }
end

local function arrowColor()
    local painted = dropdown.Arrow.calls.SetVertexColor
    return { painted[1], painted[2], painted[3] }
end

--- Drive one of the widget's own scripts. Guarded rather than indexed
--- straight, because a widget that stopped installing one of these hooks is
--- precisely the regression this file exists to catch -- and a raise there
--- would take every assertion after it down with it instead of reporting one.
local function fire(script, ...)
    local handler = dropdown.scripts[script]
    if handler then handler(dropdown, ...) end
end

-- at rest

harness.assertDeepEqual(borderColor(), EDGE, "at rest the border is the palette's edge")
harness.assertDeepEqual(labelColor(), TEXT, "and the label the palette's text")
harness.assertDeepEqual(arrowColor(), UNTINTED,
    "the arrow carries no tint of its own -- it is drawn as its texture ships")

-- The hooks the client reaches through SetEnabled: Enable and Disable both
-- fire these whichever of the three a caller used, so a widget carrying them
-- greys itself and one without them cannot.
harness.assertEqual(type(dropdown.scripts.OnDisable), "function",
    "the widget answers OnDisable")
harness.assertEqual(type(dropdown.scripts.OnEnable), "function", "and OnEnable")

-- greyed

dropdown:SetEnabled(false)
fire("OnDisable")

-- The assertion this file exists for. Not "equals textDisabled" alone: what
-- shipped before was a label still painted colors.text over a box that could
-- not be opened, so the regression to catch is the label reading as live.
harness.assertEqual(labelColor()[1] ~= TEXT[1] or labelColor()[2] ~= TEXT[2]
    or labelColor()[3] ~= TEXT[3], true,
    "a disabled dropdown's label is not the colour of a live one")
harness.assertDeepEqual(labelColor(), TEXT_DISABLED,
    "it is the disabled text colour, the same one both button mixins use")
harness.assertDeepEqual(arrowColor(), TEXT_DISABLED, "and the arrow greys with it")
harness.assertDeepEqual(borderColor(), BORDER_DISABLED,
    "the border drops to bgDisabled rather than staying the live edge")

-- A disabled button still takes OnEnter in the client -- the trap
-- CheckButtonMixin's own OnEnter documents in Buttons.lua -- so a dropdown
-- that lit its border on hover would announce a menu that cannot open.
fire("OnEnter")
harness.assertDeepEqual(borderColor(), BORDER_DISABLED,
    "pointing at a greyed dropdown does not light its border")
harness.assertDeepEqual(labelColor(), TEXT_DISABLED, "nor brighten its label")

-- And letting go of it settles back to the greyed border, not to the live edge
-- OnLeave used to write unconditionally.
fire("OnLeave")
harness.assertDeepEqual(borderColor(), BORDER_DISABLED,
    "and letting go leaves it greyed rather than reviving the edge")

-- A menu left open when the widget was disabled closes onto the greyed state
-- rather than onto the hover it would read from the pointer.
dropdown.IsMouseOver = function() return true end
dropdown:OnMenuClosed(nil)
harness.assertDeepEqual(borderColor(), BORDER_DISABLED,
    "a menu closing over a greyed dropdown does not repaint it live")

-- revived

dropdown:SetEnabled(true)
fire("OnEnable")

harness.assertDeepEqual(labelColor(), TEXT, "enabling puts the label back")
harness.assertDeepEqual(arrowColor(), UNTINTED,
    "and the arrow back to untinted, not to the label's grey it never wore")
harness.assertDeepEqual(borderColor(), EDGE, "with the live edge on the border")

fire("OnEnter")
harness.assertDeepEqual(borderColor(), POINT,
    "a live dropdown still lights its border under the pointer")
fire("OnLeave")
harness.assertDeepEqual(borderColor(), EDGE, "and settles back when the pointer leaves")

-- The hover highlight is the border's alone: brightening the label on hover is
-- CheckButtonMixin's behaviour, and a dropdown's label is its VALUE, so a
-- colour change there would read as the value having changed.
harness.assertDeepEqual(labelColor(), TEXT, "hovering never repaints the label")

-- An open menu holds the highlight, which is what says the box is the one the
-- menu belongs to while the pointer is down in the list.
dropdown:OnMenuOpened({})
harness.assertDeepEqual(borderColor(), POINT, "an open menu holds the border lit")
harness.assertEqual(dropdown:IsMenuOpen(), true, "and the widget knows it is open")

dropdown.IsMouseOver = function() return false end
dropdown:OnMenuClosed(nil)
harness.assertDeepEqual(borderColor(), EDGE,
    "closing it away from the pointer settles back to the edge")
harness.assertEqual(dropdown:IsMenuOpen(), false, "and the menu is no longer open")

harness.report()
