-- =========================================================
-- LibBitForgeUI.DropdownMixin
-- MD-style dropdown backed by Blizzard's DropdownButtonMixin.
--
-- Primary API (mirrors DropdownButtonMixin):
--   dropdown:SetupMenu(generator)
--     generator signature: function(dropdown, rootDescription) ... end
--     Populate rootDescription with MenuUtil helpers, e.g.:
--       rootDescription:CreateRadio("Label", getter, setter, value)
--       rootDescription:CreateCheckbox("Label", getter, setter)
-- =========================================================

local colors          = LibBitForgeUI.Colors

local BORDER_BACKDROP = {
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}

local DROPDOWN_HEIGHT = 32
local ARROW_SIZE      = 14
local H_PADDING       = 10

-- =========================================================
-- DropdownMixin
-- =========================================================

---@class LibBitForgeUI.DropdownMixin: Button, BackdropTemplate, DropdownButtonMixin
local DropdownMixin   = CreateFromMixins(DropdownButtonMixin)

function DropdownMixin:OnLoad()
    -- These fields are read by DropdownButtonMixin.OnLoad_Intrinsic to build the
    -- menu anchor. They must be set before calling OnLoad_Intrinsic.
    self.menuPoint         = "TOPLEFT"
    self.menuRelativePoint = "BOTTOMLEFT"
    self.menuPointX        = 0
    self.menuPointY        = 0

    DropdownButtonMixin.OnLoad_Intrinsic(self)

    self:SetSize(160, DROPDOWN_HEIGHT)
    self:EnableMouseWheel(true) -- OnLoad_Intrinsic disables it; re-enable for rotation

    -- Backdrop / border
    local P = colors
    self:SetBackdrop(BORDER_BACKDROP)
    self:SetBackdropBorderColor(P.border.r, P.border.g, P.border.b, P.border.a)

    -- Background fill
    local bg = self:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface/Buttons/WHITE8X8")
    bg:SetAllPoints()
    bg:SetVertexColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    self.Bg = bg

    -- Selected-item label
    local label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetTextColor(P.text.r, P.text.g, P.text.b, P.text.a)
    label:SetPoint("LEFT", self, "LEFT", H_PADDING, 0)
    label:SetPoint("RIGHT", self, "RIGHT", -(ARROW_SIZE + H_PADDING + 6), 0)
    label:SetPoint("TOP", self, "TOP", 0, 0)
    label:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
    self.Label = label

    -- Arrow indicator (swapped between arrow_down / arrow_up when menu toggles)
    local arrow = self:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow:SetPoint("RIGHT", self, "RIGHT", -H_PADDING, 0)
    arrow:SetTexture(LibBitForgeUI.GetMedia("arrow_down"))
    self.Arrow = arrow

    -- _Intrinsic scripts are only auto-wired in XML intrinsic contexts.
    -- Route them manually here.
    self:HookScript("OnMouseDown", DropdownButtonMixin.OnMouseDown_Intrinsic)
    self:HookScript("OnMouseWheel", DropdownButtonMixin.OnMouseWheel_Intrinsic)

    -- Hover border highlight
    self:HookScript("OnEnter", function(f)
        local c = colors.primary
        f:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    self:HookScript("OnLeave", function(f)
        if not f:IsMenuOpen() then
            local c = colors.border
            f:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end)
end

-- Called by DropdownButtonMixin whenever the selection set changes.
-- Displays a comma-separated list of selected option texts in the label.
function DropdownMixin:UpdateToMenuSelections(menuDescription, selections)
    local text = self._placeholder or ""
    if selections and #selections > 0 then
        local parts = {}
        for _, desc in ipairs(selections) do
            local t = desc:GetText()
            if t then
                table.insert(parts, t)
            end
        end
        if #parts > 0 then
            text = table.concat(parts, ", ")
        end
    end
    self.Label:SetText(text)
end

function DropdownMixin:OnMenuOpened(menu)
    DropdownButtonMixin.OnMenuOpened(self, menu)
    self.Arrow:SetTexture(LibBitForgeUI.GetMedia("arrow_up"))
    local c = colors.primary
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

function DropdownMixin:OnMenuClosed(menu)
    DropdownButtonMixin.OnMenuClosed(self, menu)
    self.Arrow:SetTexture(LibBitForgeUI.GetMedia("arrow_down"))
    local c = self:IsMouseOver() and colors.primary or colors.border
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

--- Placeholder text shown when nothing is selected.
---@param text string
function DropdownMixin:SetPlaceholder(text)
    self._placeholder = text
    local _, _, selections = self:CollectSelectionData()
    if not selections or #selections == 0 then
        self.Label:SetText(text)
    end
end

LibBitForgeUI.Mixins.Dropdown = DropdownMixin

-- =========================================================
-- LibBitForgeUI.CreateDropdown
-- Factory function
-- =========================================================

--- Create a styled dropdown widget.
---
--- Example:
---   local dd = LibBitForgeUI.CreateDropdown(parent, "Select an option")
---   dd:SetupMenu(function(dropdown, root)
---     root:CreateRadio("Option A", getter, setter, "A")
---     root:CreateRadio("Option B", getter, setter, "B")
---   end)
---
---@param parent Frame
---@param placeholder string? Optional placeholder text displayed when nothing is selected.
---@return LibBitForgeUI.DropdownMixin
function LibBitForgeUI.CreateDropdown(parent, placeholder)
    local dropdown = CreateFrame("Button", nil, parent, "BackdropTemplate") --[[@as LibBitForgeUI.DropdownMixin]]
    Mixin(dropdown, DropdownMixin)
    dropdown:OnLoad()
    if placeholder then
        dropdown:SetPlaceholder(placeholder)
    end
    return dropdown
end
