-- =========================================================
-- LibBitForgeUI edit box mixins
-- BitForgeEditBoxTemplate          – single-line MD text field
-- BitForgeMultiLineEditBoxTemplate – multi-line MD text field
-- =========================================================

local BACKDROP_CONFIG = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile     = true,
    tileSize = 32,
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- =========================================================
-- Shared: backdrop focus highlight (applied via Mixin in OnLoad)
-- =========================================================

---@class LibBitForgeUI.EditBoxBaseMixin: BackdropTemplateMixin
local EditBoxBaseMixin = {}

function EditBoxBaseMixin:OnEditFocusGained()
    local c = LibBitForgeUI.Colors.primary
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

function EditBoxBaseMixin:OnEditFocusLost()
    local c = LibBitForgeUI.Colors.border
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

local function ApplyBackdrop(frame, editBox)
    local P = LibBitForgeUI.Colors
    frame:SetBackdrop(BACKDROP_CONFIG)
    frame:SetBackdropColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    frame:SetBackdropBorderColor(P.border.r, P.border.g, P.border.b, P.border.a)
    editBox:SetTextColor(P.text.r, P.text.g, P.text.b, P.text.a)
    editBox:SetFont(STANDARD_TEXT_FONT, 12, "")
end

-- =========================================================
-- Single-line: self is both the backdrop frame and the edit box
-- =========================================================

---@class LibBitForgeUI.EditBoxMixin: EditBox, LibBitForgeUI.EditBoxBaseMixin
local EditBoxMixin = CreateFromMixins(EditBoxBaseMixin)

function EditBoxMixin:OnLoad()
    ApplyBackdrop(self, self)
    self:SetScript("OnEditFocusGained", function(f) f:OnEditFocusGained() end)
    self:SetScript("OnEditFocusLost", function(f) f:OnEditFocusLost() end)
    self:SetScript("OnEnterPressed", function(f) f:OnEnterPressed() end)
    self:SetScript("OnEscapePressed", function(f) f:OnEscapePressed() end)
    self:SetScript("OnTextChanged", function(f, userInput) f:OnTextChanged(userInput) end)
end

function EditBoxMixin:OnEnterPressed()
    self:ClearFocus()
end

function EditBoxMixin:OnEscapePressed()
    self:ClearFocus()
end

function EditBoxMixin:OnTextChanged()
end

-- =========================================================
-- Multi-line: self is the outer Frame; self.EditBox is the input
-- =========================================================

---@class LibBitForgeUI.MultiLineEditBoxMixin: LibBitForgeUI.FrameMixin, LibBitForgeUI.EditBoxBaseMixin
local MultiLineEditBoxMixin = CreateFromMixins(LibBitForgeUI.FrameMixin, EditBoxBaseMixin)

function MultiLineEditBoxMixin:OnLoad()
    -- Create the inner EditBox programmatically to avoid $parent naming
    -- ambiguity when nested inside a ScrollChild.
    local editBox = CreateFrame("EditBox", nil, self.ScrollFrame)
    editBox:SetSize(self.ScrollFrame:GetWidth(), 20)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    self.ScrollFrame:SetScrollChild(editBox)
    self.EditBox = editBox

    ApplyBackdrop(self, editBox)

    -- Keep the inner edit box width in sync with the scroll frame
    self.ScrollFrame:HookScript("OnSizeChanged", function(scrollFrame)
        editBox:SetWidth(scrollFrame:GetWidth())
    end)

    -- Route focus events from the inner EditBox up to self (which owns the backdrop)
    editBox:SetScript("OnEditFocusGained", function() self:OnEditFocusGained() end)
    editBox:SetScript("OnEditFocusLost", function() self:OnEditFocusLost() end)
    editBox:SetScript("OnEscapePressed", function() self:OnEscapePressed() end)
end

function MultiLineEditBoxMixin:OnEscapePressed()
    self.EditBox:ClearFocus()
end

LibBitForgeUI.EditBoxBaseMixin = EditBoxBaseMixin
LibBitForgeUI.EditBoxMixin = EditBoxMixin
LibBitForgeUI.MultiLineEditBoxMixin = MultiLineEditBoxMixin
