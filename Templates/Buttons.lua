--- =========================================================
--- local references
--- =========================================================

local _min = math.min

local colors = LibBitForgeUI.Colors

local BUTTON_H_PADDING = 48 -- 24px each side
local BORDER_BACKDROP = {
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}


--- =========================================================
--- Helper functions
--- =========================================================

local function applyColor(texture, color)
    texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

local function updateLayout(btn, width, height)
    local hasIcon = btn.Icon ~= nil
    local hasLabel = btn.Label ~= nil
    local minSize = _min(width, height)

    if hasIcon then
        btn.Icon:ClearAllPoints()
    end
    if hasLabel then
        btn.Label:ClearAllPoints()
    end

    if hasIcon and hasLabel then
        local iconSize = minSize - 8
        btn.Icon:SetSize(iconSize, iconSize)
        btn.Icon:SetPoint("LEFT", btn, "LEFT", 12, 0)

        btn.Label:SetJustifyH("LEFT")
        btn.Label:SetPoint("LEFT", btn.Icon, "RIGHT", 8, 0)
        btn.Label:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
        btn.Label:SetPoint("TOP", btn, "TOP", 0, 0)
        btn.Label:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
    elseif hasIcon then
        local iconSize = minSize - 8
        btn.Icon:SetSize(iconSize, iconSize)
        btn.Icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    elseif hasLabel then
        btn.Label:SetJustifyH("CENTER")
        btn.Label:SetAllPoints()
    end
end

local function updateTint(btn)
    applyColor(btn:GetNormalTexture(), colors.disabled)
    applyColor(btn:GetCheckedTexture(), colors.primary)
end

local function updateCheckButtonBorder(btn)
    local c = btn:GetChecked() and colors.primary or colors.disabled
    btn:SetBackdropBorderColor(c.r, c.g, c.b, c.a)

    if btn.Label then
        btn.Label:SetTextColor(c.r, c.g, c.b, c.a)
    end
end

local function onEnter(btn)
    local color = colors.primaryHover
    btn:SetBackdropBorderColor(color.r, color.g, color.b, color.a)

    if btn.Label then
        btn.Label:SetTextColor(1, 1, 1, 1)
    end

    if btn.Icon then
        applyColor(btn.Icon, colors.primaryHover)
    end

    if btn.tooltipText then
        GameTooltip:SetOwner(btn, btn.tooltipAnchor or "ANCHOR_RIGHT")
        GameTooltip:SetText(btn.tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

local function onLeave(btn)
    local color = colors.primaryDark
    btn:SetBackdropBorderColor(color.r, color.g, color.b, color.a)

    if btn.Label then
        btn.Label:SetTextColor(1, 1, 1, 1)
    end

    if btn.Icon then
        applyColor(btn.Icon, colors.primary)
    end

    if btn.tooltipText then
        GameTooltip:Hide()
    end
end

local function onMouseDown(btn, button)
    if btn.Icon then
        applyColor(btn.Icon, colors.primaryDark)
    end
end

local function onMouseUp(btn, button)
    if btn.Icon then
        applyColor(btn.Icon, colors.primary)
    end
end


-- =========================================================
-- LibBitForgeUI.ButtonMixin
-- MD-style contained button (borderlined, primary colour)
-- =========================================================

---@class LibBitForgeUI.ButtonMixin: Button, BackdropTemplate
local ButtonMixin = {}

--- Initializes the button with default textures and styles.
--- If both icon and text are provided, both will be shown.
---@param hasIcon boolean?  Whether to show an icon (if texture is set later)
---@param hasLabel boolean?  Whether to show a text label (if text is set later)
function ButtonMixin:OnLoad(hasIcon, hasLabel)
    assert(hasIcon or hasLabel, "At least one of icon or text must be provided")

    self:SetSize(120, 36)
    self:SetNormalTexture("Interface/Buttons/WHITE8X8")
    self:SetHighlightTexture("Interface/Buttons/WHITE8X8", "ADD")
    self:SetPushedTexture("Interface/Buttons/WHITE8X8")
    self:SetDisabledTexture("Interface/Buttons/WHITE8X8")

    applyColor(self:GetNormalTexture(), colors.primary)
    applyColor(self:GetHighlightTexture(), colors.primaryHover)
    applyColor(self:GetPushedTexture(), colors.primaryDark)
    applyColor(self:GetDisabledTexture(), colors.disabled)

    local P = colors.primaryDark
    self:SetBackdrop(BORDER_BACKDROP)
    self:SetBackdropBorderColor(P.r, P.g, P.b, P.a)

    if hasLabel then
        local label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetJustifyH("CENTER")
        label:SetJustifyV("MIDDLE")
        label:SetAllPoints()
        label:SetTextColor(1, 1, 1, 1)
        self:SetFontString(label)

        self.Label = label
    end

    if hasIcon then
        local icon = self:CreateTexture(nil, "OVERLAY")
        icon:SetSize(16, 16)
        icon:SetPoint("CENTER", self, "CENTER", 0, 0)
        self.Icon = icon
    end

    self:HookScript("OnEnter", onEnter)
    self:HookScript("OnLeave", onLeave)
    self:HookScript("OnMouseDown", onMouseDown)
    self:HookScript("OnMouseUp", onMouseUp)
    self:HookScript("OnSizeChanged", updateLayout)
end

---@param text string
function ButtonMixin:SetText(text)
    if self.Label then
        self.Label:SetText(text)
        self:SetWidth(self.Label:GetUnboundedStringWidth() + BUTTON_H_PADDING)
    else
        error("Button does not have a label.", 2)
    end
end

---@param texture string|number
function ButtonMixin:SetIcon(texture)
    if self.Icon then
        self.Icon:SetTexture(texture)
    else
        error("Button does not have an icon.", 2)
    end
end

function ButtonMixin:SetTooltips(text, anchor)
    self.tooltipText = text
    self.tooltipAnchor = anchor
end

LibBitForgeUI.Mixins.Button = ButtonMixin


-- =========================================================
-- LibBitForgeUI.CheckButtonMixin
-- Checkbox with optional tick icon and/or text label.
-- Border colour indicates checked state.
-- =========================================================

---@class LibBitForgeUI.CheckButtonMixin: CheckButton, BackdropTemplate
local CheckButtonMixin = {}

---@param hasIcon boolean?  Whether to show a tick icon for the checked state
---@param hasLabel boolean?  Whether to show a text label
function CheckButtonMixin:OnLoad(hasIcon, hasLabel)
    assert(hasIcon or hasLabel, "At least one of icon or text must be provided")

    self:SetHeight(24)

    local D = colors.disabled
    self:SetBackdrop(BORDER_BACKDROP)
    self:SetBackdropBorderColor(D.r, D.g, D.b, D.a)

    if hasIcon then
        self:SetNormalTexture(LibBitForgeUI.GetMedia("unchecked"))
        self:SetCheckedTexture(LibBitForgeUI.GetMedia("checked"))
        self:SetHighlightTexture(LibBitForgeUI.GetMedia("checked"), "ADD")
        updateTint(self)
        applyColor(self:GetHighlightTexture(), colors.primaryHover)

        local normalTex = self:GetNormalTexture()
        normalTex:ClearAllPoints()
        normalTex:SetSize(20, 20)
        normalTex:SetPoint("LEFT", self, "LEFT", 0, 0)

        local checkedTex = self:GetCheckedTexture()
        checkedTex:ClearAllPoints()
        checkedTex:SetSize(20, 20)
        checkedTex:SetPoint("LEFT", self, "LEFT", 0, 0)

        local highlightTex = self:GetHighlightTexture()
        highlightTex:ClearAllPoints()
        highlightTex:SetSize(20, 20)
        highlightTex:SetPoint("LEFT", self, "LEFT", 0, 0)

        self.hasIcon = true
    else
        self:SetHighlightTexture("")
    end

    if hasLabel then
        local label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetJustifyV("MIDDLE")
        label:SetTextColor(1, 1, 1, 1)

        if hasIcon then
            label:SetJustifyH("LEFT")
            label:SetPoint("LEFT", self, "LEFT", 26, 0)
        else
            label:SetJustifyH("CENTER")
            label:SetAllPoints()
        end

        self:SetFontString(label)
        self.Label = label
    end

    -- width for icon-only: icon (20px) + horizontal padding
    -- label cases: SetText will set the correct width once text is provided
    if hasIcon and not hasLabel then
        self:SetWidth(24)
    end

    self:HookScript("OnEnter", onEnter)
    self:HookScript("OnLeave", onLeave)
    self:HookScript("OnSizeChanged", updateLayout)
    hooksecurefunc(self, "SetChecked", updateCheckButtonBorder)

    updateCheckButtonBorder(self)
end

function CheckButtonMixin:SetText(text)
    if not self.Label then
        error("CheckButton does not have a label.", 2)
    end

    self.Label:SetText(text)
    local w = self.Label:GetUnboundedStringWidth()
    self:SetWidth(self.hasIcon and (26 + w + 8) or (w + BUTTON_H_PADDING))
end

---@param normalTex string|number
---@param checkedTex string|number
function CheckButtonMixin:SetIcon(normalTex, checkedTex)
    if not self.hasIcon then
        error("CheckButton was not initialized with an icon.", 2)
    end

    self:SetNormalTexture(normalTex)
    self:SetCheckedTexture(checkedTex)
    self:SetHighlightTexture(checkedTex, "ADD")
    updateTint(self)
end

function CheckButtonMixin:SetTooltips(text, anchor)
    self.tooltipText = text
    self.tooltipAnchor = anchor
end

function CheckButtonMixin:HookSetChecked(func)
    hooksecurefunc(self, "SetChecked", func)
end

LibBitForgeUI.Mixins.CheckButton = CheckButtonMixin

--- =========================================================
--- Factory function
--- =========================================================

--- Creates a button with optional text and/or icon.
--- If both text and icon are provided, uses ButtonWithIconMixin.
---@param name string?
---@param parent Frame?
---@param icon string|number?  Texture path or atlas for the button icon
---@param text string?  Button label text
---@return LibBitForgeUI.ButtonMixin button
function LibBitForgeUI.CreateButton(name, parent, icon, text)
    if not (icon or (text and text ~= "")) then
        error("At least one of icon or text must be provided", 2)
    end

    --- @class LibBitForgeUI.ButtonMixin
    local btn = CreateFrame("Button", name, parent or UIParent, "BackdropTemplate")
    Mixin(btn, ButtonMixin)
    btn:OnLoad(icon ~= nil, text ~= nil)

    if icon then btn:SetIcon(icon) end
    if text then btn:SetText(text) end

    return btn
end

--- Creates a check button with optional text and/or tick icon.
--- If both text and icon are provided, uses CheckButtonMixin.
---@param name string?
---@param parent Frame?
---@param text string?  Button label text
---@param hasIcon boolean?  Whether to show a tick icon for the checked state
---@param iconNormal string|number?  Texture path or atlas for the unchecked state icon (only if hasIcon is true)
---@param iconChecked string|number?  Texture path or atlas for the checked state icon (only if hasIcon is true)
---@return LibBitForgeUI.CheckButtonMixin checkButton
function LibBitForgeUI.CreateCheckButton(name, parent, text, hasIcon, iconNormal, iconChecked)
    local cb = CreateFrame("CheckButton", name, parent or UIParent, "BackdropTemplate") --[[@as LibBitForgeUI.CheckButtonMixin]]
    Mixin(cb, CheckButtonMixin)
    cb:OnLoad(hasIcon, text ~= nil)

    if hasIcon and iconNormal and iconChecked then cb:SetIcon(iconNormal, iconChecked) end
    if text then cb:SetText(text) end

    return cb
end
