local ipairs = ipairs
local min = math.min

local PixelUtil = PixelUtil

local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
---@type BitForge.UI.Colors
local colors = UI.Colors
local skin = UI.Skin

local GLYPH_TEXTURE = "Interface/Buttons/WHITE8X8"
local DEFAULT_SIZE = 24

-- Blizzard's UIPanelCloseButtonNoScripts carries frameLevel="510", and the
-- windows this replaces it in are why: a close button left at its parent's
-- level sits behind any scroll frame or backdrop created after it.
local FRAME_LEVEL = 510

-- The X as fractions of the button's edge -- how far it reaches from the
-- centre, and how heavy its stroke is -- rather than pixel counts, because the
-- same widget is asked for at 16 and at 24 and a glyph holding an absolute
-- weight reads as a blot at the smaller size.
local GLYPH_REACH_RATIO = 0.44
-- No longer read by any function here: the stroke is baked into close_x.tga
-- at GLYPH_STROKE_RATIO / GLYPH_REACH_RATIO of the asset's own side, kept so
-- the shipped proportions are traceable and the asset can be regenerated if
-- either ratio ever moves. Losing the runtime reference also loses
-- UI.GetPixel()'s floor -- a drawn stroke could not thin below one physical
-- pixel; a baked asset scaled down has no such floor.
---@diagnostic disable-next-line: unused-local
local GLYPH_STROKE_RATIO = 0.10

-- Faint, and additive over whatever the window put behind the button. The
-- number is Buttons.lua's, so a close button and an ordinary button light up by
-- the same amount under the pointer.
local HIGHLIGHT_ALPHA = 0.1

-- A Texture rather than a Line, so a host can remove this addon's own art by
-- fading every region that answers IsObjectType("Texture") -- a Line answers
-- no such check, so a host's own X would land on top of ours.

local function BuildGlyph(self)
    local glyph = self:CreateTexture(nil, "ARTWORK")
    glyph:SetTexture(UI.GetMedia("close_x"))

    self.Glyph = { glyph }
end

---@param edge number  The button's shorter side, in UI units.
local function LayoutGlyph(self, edge)
    local reach = edge * GLYPH_REACH_RATIO / 2
    local glyph = self.Glyph[1]

    glyph:SetSize(reach * 2, reach * 2)
    glyph:SetPoint("CENTER", self, "CENTER", 0, 0)
end

---@param state "NORMAL" | "HOVER" | "DISABLED"
local function PaintGlyph(self, state)
    local strokeColor = colors.danger
    if state == "HOVER" then
        strokeColor = colors.textHover
    elseif state == "DISABLED" then
        strokeColor = colors.textDisabled
    end

    for _, stroke in ipairs(self.Glyph) do
        skin.ApplyVertexColor(stroke, strokeColor)
    end
end

---@class BitForge.CloseButtonMixin : Button
local CloseButtonMixin = {}

do
    local function OnEnter(self) PaintGlyph(self, "HOVER") end
    local function OnLeave(self) PaintGlyph(self, "NORMAL") end
    local function OnEnable(self) PaintGlyph(self, "NORMAL") end
    local function OnDisable(self) PaintGlyph(self, "DISABLED") end

    local function OnSizeChanged(self, width, height)
        LayoutGlyph(self, min(width, height))
    end

    ---@param size number?  Edge length in UI units; DEFAULT_SIZE unless given.
    function CloseButtonMixin:OnLoad(size)
        local edge = size or DEFAULT_SIZE

        self:SetFrameLevel(FRAME_LEVEL)

        -- Explicit, because the glyph alone is not an affordance: a flat X that
        -- does not answer the pointer does not read as something to click, and
        -- BitForge_TaskTome's header relies on this button bringing its own
        -- highlight while the icon buttons beside it are given one by hand.
        self:SetHighlightTexture(GLYPH_TEXTURE, "ADD")
        local red, green, blue = colors.danger:GetRGB()
        self:GetHighlightTexture():SetVertexColor(red, green, blue, HIGHLIGHT_ALPHA)

        BuildGlyph(self)

        self:HookScript("OnEnter", OnEnter)
        self:HookScript("OnLeave", OnLeave)
        self:HookScript("OnEnable", OnEnable)
        self:HookScript("OnDisable", OnDisable)
        self:HookScript("OnSizeChanged", OnSizeChanged)

        PixelUtil.SetSize(self, edge, edge)
        LayoutGlyph(self, edge)
        PaintGlyph(self, "NORMAL")
    end
end

UI.Mixins.CloseButton = CloseButtonMixin

--- Create the suite's close button: an X of our own, no Blizzard art.
---
--- Three things UIPanelCloseButton carried are kept here rather than lost with
--- it -- the narration mixin a screen reader reads the button through, a hover
--- affordance, and frame level 510. Its OnClick is not one of them: every
--- window in the suite overrode it, because the template's own hides the
--- button's PARENT, which is a header as often as it is the window.
---@param parent any
---@param size number?  Edge length in UI units; 24 unless given.
---@return BitForge.CloseButtonMixin
function UI.CreateCloseButton(parent, size)
    ---@class BitForge.CloseButtonMixin
    local button = CreateFrame("Button", nil, parent or UIParent)

    -- Blizzard's own narration mixin rather than a copy of NarrationGetName:
    -- the string it answers is the client's, and a copy would drift from it.
    -- Ours goes on last, so a future collision resolves in this file's favour.
    Mixin(button, UIPanelCloseButtonNarrationMixin, CloseButtonMixin)
    button:OnLoad(size)

    return button
end
