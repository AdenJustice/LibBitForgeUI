local function applyColor(texture, color)
    texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

-- =========================================================
-- LibBitForgeUI.ButtonMixin
-- Mixin for BitForgeButtonTemplate
-- MD-style contained button (filled, primary colour)
-- =========================================================

---@class LibBitForgeUI.ButtonMixin: Button
local ButtonMixin = LibBitForgeUI.ButtonMixin or {}

function ButtonMixin:OnLoad()
    local P = LibBitForgeUI.Colors
    applyColor(self:GetNormalTexture(), P.primary)
    applyColor(self:GetHighlightTexture(), P.primaryHover)
    applyColor(self:GetPushedTexture(), P.primaryDark)
    applyColor(self:GetDisabledTexture(), P.disabled)
    self:SetScript("OnClick", function(f, btn) f:OnClick(btn) end)
    self:SetScript("OnEnter", function(f) f:OnEnter() end)
    self:SetScript("OnLeave", function(f) f:OnLeave() end)
    self:SetScript("OnMouseDown", function(f, btn) f:OnMouseDown(btn) end)
    self:SetScript("OnMouseUp", function(f, btn) f:OnMouseUp(btn) end)
end

---@param button string  "LeftButton" | "RightButton" | ...
function ButtonMixin:OnClick(button)
end

function ButtonMixin:OnEnter()
end

function ButtonMixin:OnLeave()
end

---@param button string
function ButtonMixin:OnMouseDown(button)
end

---@param button string
function ButtonMixin:OnMouseUp(button)
end

-- =========================================================
-- LibBitForgeUI.ScrollElementAsButtonMixin
-- Mixin for BitForgeScrollElementAsButtonTemplate
-- Boilerplate virtual Button for use as a ScrollBox element.
-- =========================================================

---@class LibBitForgeUI.ScrollElementAsButtonMixin: LibBitForgeUI.ButtonMixin
local ScrollElementAsButtonMixin = CreateFromMixins(ButtonMixin)

function ScrollElementAsButtonMixin:OnLoad()
    local P = LibBitForgeUI.Colors
    applyColor(self:GetHighlightTexture(), P.primaryHover)
    self:SetScript("OnClick", function(f, btn) f:OnClick(btn) end)
    self:SetScript("OnEnter", function(f) f:OnEnter() end)
    self:SetScript("OnLeave", function(f) f:OnLeave() end)
    self:SetScript("OnMouseDown", function(f, btn) f:OnMouseDown(btn) end)
    self:SetScript("OnMouseUp", function(f, btn) f:OnMouseUp(btn) end)
end

--- Called by the element factory when this frame is recycled for a new data entry.
--- Override in your consumer mixin:
---   function MyElementMixin:Init(data) self.Label:SetText(data.text) end
---@param data any
function ScrollElementAsButtonMixin:Init(data)
end

---@param button string  "LeftButton" | "RightButton" | ...
function ScrollElementAsButtonMixin:OnClick(button)
end

function ScrollElementAsButtonMixin:OnEnter()
end

function ScrollElementAsButtonMixin:OnLeave()
end

---@param button string
function ScrollElementAsButtonMixin:OnMouseDown(button)
end

---@param button string
function ScrollElementAsButtonMixin:OnMouseUp(button)
end


-- =========================================================
-- LibBitForgeUI.CheckboxMixin
-- Mixin for BitForgeCheckboxTemplate
-- MD-style checkbox: filled square background whose tint
-- toggles between Colors.primary (checked) and Colors.disabled (unchecked).
-- =========================================================

---@class LibBitForgeUI.CheckboxMixin: CheckButton
local CheckboxMixin = {}

function CheckboxMixin:OnLoad()
    local P = LibBitForgeUI.Colors
    applyColor(self:GetNormalTexture(), P.disabled)
    applyColor(self:GetCheckedTexture(), P.primary)
    applyColor(self:GetHighlightTexture(), P.primaryHover)
end

-- =========================================================
-- LibBitForgeUI.ScrollElementAsCheckMixin
-- Mixin for BitForgeScrollElementAsCheckTemplate
-- Boilerplate virtual CheckButton for use as a ScrollBox element.
-- =========================================================

---@class LibBitForgeUI.ScrollElementAsCheckMixin: LibBitForgeUI.CheckboxMixin
local ScrollElementAsCheckMixin = CreateFromMixins(CheckboxMixin)

function ScrollElementAsCheckMixin:OnLoad()
    local P = LibBitForgeUI.Colors
    applyColor(self:GetNormalTexture(), P.disabled)
    applyColor(self:GetCheckedTexture(), P.primary)
    applyColor(self:GetHighlightTexture(), P.primaryHover)
    self:SetScript("OnClick", function(f, btn) f:OnClick(btn) end)
    self:SetScript("OnEnter", function(f) f:OnEnter() end)
    self:SetScript("OnLeave", function(f) f:OnLeave() end)
end

--- Called by the element factory when this frame is recycled for a new data entry.
--- Override in your consumer mixin:
---   function MyElementMixin:Init(data) self:SetChecked(data.checked) end
---@param data any
function ScrollElementAsCheckMixin:Init(data)
end

---@param button string  "LeftButton" | "RightButton" | ...
function ScrollElementAsCheckMixin:OnClick(button)
end

function ScrollElementAsCheckMixin:OnEnter()
end

function ScrollElementAsCheckMixin:OnLeave()
end


LibBitForgeUI.ButtonMixin = ButtonMixin
LibBitForgeUI.CheckboxMixin = CheckboxMixin
LibBitForgeUI.ScrollElementAsButtonMixin = ScrollElementAsButtonMixin
LibBitForgeUI.ScrollElementAsCheckMixin = ScrollElementAsCheckMixin
