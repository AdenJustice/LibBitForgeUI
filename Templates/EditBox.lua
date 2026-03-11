-- =========================================================
-- Shared: backdrop focus highlight (applied via Mixin in OnLoad)
-- =========================================================

local BACKDROP_CONFIG = {
    bgFile   = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    tile     = true,
    tileSize = 32,
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function applyBackdrop(frame)
    local P = LibBitForgeUI.Colors

    frame:SetBackdrop(BACKDROP_CONFIG)
    frame:SetBackdropColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    frame:SetBackdropBorderColor(P.border.r, P.border.g, P.border.b, P.border.a)

    frame:SetTextColor(P.text.r, P.text.g, P.text.b, P.text.a)
    frame:SetFont(STANDARD_TEXT_FONT, 12, "")
end


local function onEditFocusGained(self)
    local c = LibBitForgeUI.Colors.primary
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

local function onEditFocusLost(self)
    local c = LibBitForgeUI.Colors.border
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

local function onEnterPressed(self)
    self:ClearFocus()
end

local function onEscapePressed(self)
    self:ClearFocus()
end


-- =========================================================
-- Single-line: self is both the backdrop frame and the edit box
-- =========================================================

---@class LibBitForgeUI.EditBoxMixin: EditBox
local EditBoxMixin = {}

function EditBoxMixin:OnLoad()
    self:SetSize(200, 32)
    self:SetAutoFocus(false)
    self:SetTextInsets(8, 8, 0, 0)

    applyBackdrop(self)

    self:HookScript("OnEditFocusGained", onEditFocusGained)
    self:HookScript("OnEditFocusLost", onEditFocusLost)
    self:HookScript("OnEnterPressed", onEnterPressed)
    self:HookScript("OnEscapePressed", onEscapePressed)
    self:SetScript("OnTextChanged", self.OnTextChanged)
end

function EditBoxMixin:OnTextChanged()
end

-- =========================================================
-- Multi-line: self is the outer Frame; self.ScrollBox is the input
-- =========================================================

---@class LibBitForgeUI.ScrollEditBoxMixin: LibBitForgeUI.FrameMixin, ScrollingEditBoxTemplate
local ScrollEditBoxMixin = {}

function ScrollEditBoxMixin:OnLoad()
    self:SetSize(200, 120)

    -- self.ScrollBox and self.ScrollBox.EditBox are created by ScrollingEditBoxTemplate.
    -- fontName, defaultFontName, useDefaultEscapeHandling are set by its KeyValues.
    -- OnShow/OnMouseDown are wired by its Scripts. ScrollingEditBoxMixin.OnLoad is
    -- called automatically by the template at CreateFrame time.
    --- @class ScrollingEditBoxTemplate_ScrollBox_EditBox: BackdropTemplate
    local editBox = self.ScrollBox.EditBox
    Mixin(editBox, BackdropTemplateMixin)
    editBox:OnBackdropLoaded()
    applyBackdrop(editBox)
    self:SetTextInsets(8, 8, 4, 4)

    self:RegisterCallback("OnFocusGained", function(_, eb)
        local c = LibBitForgeUI.Colors.primary
        eb:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    self:RegisterCallback("OnFocusLost", function(_, eb)
        local c = LibBitForgeUI.Colors.border
        eb:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
end

function ScrollEditBoxMixin:OnShow()
    ScrollingEditBoxMixin.OnShow(self)
end

function ScrollEditBoxMixin:OnMouseDown()
    ScrollingEditBoxMixin.OnMouseDown(self)
end

LibBitForgeUI.EditBoxMixin = EditBoxMixin
LibBitForgeUI.ScrollEditBoxMixin = ScrollEditBoxMixin

--- =========================================================
--- Factory functions
--- =========================================================

---@param parent Frame
---@return LibBitForgeUI.EditBoxMixin
function LibBitForgeUI.CreateEditBox(parent)
    local editBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate") --[[@as LibBitForgeUI.EditBoxMixin]]
    Mixin(editBox, EditBoxMixin)
    editBox:OnLoad()

    return editBox
end

---@param parent Frame
---@return LibBitForgeUI.ScrollEditBoxMixin
function LibBitForgeUI.CreateScrollEditBox(parent)
    local frame = CreateFrame("Frame", nil, parent, "ScrollingEditBoxTemplate") --[[@as LibBitForgeUI.ScrollEditBoxMixin]]
    Mixin(frame, ScrollEditBoxMixin)
    frame:OnLoad()

    return frame
end
