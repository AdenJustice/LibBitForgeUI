-- =========================================================
-- LibBitForgeUI.DropdownMixin
-- Mixin for BitForgeDropdownTemplate
-- MD-style single-select dropdown
-- =========================================================

---@class LibBitForgeUI.DropdownMixin: LibBitForgeUI.FrameMixin
local DropdownMixin = CreateFromMixins(LibBitForgeUI.FrameMixin)

local BACKDROP              = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile     = true,
    tileSize = 32,
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}

local ITEM_HEIGHT           = 24
local LIST_PADDING          = 4

function DropdownMixin:OnLoad()
    local P = LibBitForgeUI.Colors

    -- Header backdrop
    self.Header:SetBackdrop(BACKDROP)
    self.Header:SetBackdropColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    self.Header:SetBackdropBorderColor(P.border.r, P.border.g, P.border.b, P.border.a)

    -- Wire header click via closure so it has access to the dropdown frame
    self.Header:SetScript("OnClick", function() self:_Toggle() end)

    -- Popup list backdrop
    self.List:SetBackdrop(BACKDROP)
    self.List:SetBackdropColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    self.List:SetBackdropBorderColor(P.border.r, P.border.g, P.border.b, P.border.a)

    -- State
    self._value       = nil
    self._items       = {}
    self._itemButtons = {}
    self._placeholder = ""
    self._onChange    = nil
    self._open        = false

    self:_RefreshHeaderText()
    self:SetScript("OnHide", function(f) f:OnHide() end)
end

function DropdownMixin:OnHide()
    self.List:Hide()
    self._open = false
    self.Header.Chevron:SetText("▾")
end

--- Set the placeholder text shown when no value is selected.
---@param text string
function DropdownMixin:SetPlaceholder(text)
    self._placeholder = text or ""
    if self._value == nil then
        self:_RefreshHeaderText()
    end
end

--- Load the option list. Each entry must have value and label fields.
---@param items { value: any, label: string }[]
function DropdownMixin:SetItems(items)
    -- Destroy old rows
    for _, btn in ipairs(self._itemButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    self._itemButtons = {}
    self._items       = items or {}

    local P           = LibBitForgeUI.Colors
    local listW       = self:GetWidth()

    for i, item in ipairs(self._items) do
        local row = CreateFrame("Button", nil, self.List)
        row:SetSize(listW - 2, ITEM_HEIGHT)
        row:SetPoint("TOPLEFT", self.List, "TOPLEFT",
            1, -(LIST_PADDING / 2) - (i - 1) * ITEM_HEIGHT)

        -- Hover highlight (HIGHLIGHT layer is shown automatically on mouse-over)
        local highlightTex = row:CreateTexture(nil, "HIGHLIGHT")
        highlightTex:SetAllPoints()
        highlightTex:SetColorTexture(
            P.primaryHover.r, P.primaryHover.g,
            P.primaryHover.b, P.primaryHover.a)

        -- Background: transparent by default; tinted when this row is selected
        local normalTex = row:CreateTexture(nil, "BACKGROUND")
        normalTex:SetAllPoints()
        normalTex:SetColorTexture(0, 0, 0, 0)
        row._normalTex = normalTex

        -- Row label
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", row, "LEFT", 8, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        label:SetJustifyH("LEFT")
        label:SetText(item.label)
        label:SetTextColor(1, 1, 1, 1)

        row._value = item.value

        local dd = self
        row:SetScript("OnClick", function()
            dd:_OnItemClick(item.value)
        end)

        self._itemButtons[i] = row
    end

    -- Resize list to fit all rows
    local listH = #self._items * ITEM_HEIGHT + LIST_PADDING
    self.List:SetSize(listW, listH)

    -- Re-apply selected-row highlight
    self:_RefreshSelectedRow()
end

--- Return the currently selected value.
---@return any
function DropdownMixin:GetValue()
    return self._value
end

--- Set the selected value programmatically. Does NOT fire the onChange callback.
---@param value any
function DropdownMixin:SetValue(value)
    self._value = value
    self:_RefreshHeaderText()
    self:_RefreshSelectedRow()
end

--- Register a callback fired when the user picks an item.
---@param fn fun(value: any)
function DropdownMixin:SetOnChange(fn)
    self._onChange = fn
end

-- ── Private ──────────────────────────────────────────────

function DropdownMixin:_Toggle()
    if self._open then
        self.List:Hide()
        self.Header.Chevron:SetText("▾")
    else
        self.List:Show()
        self.Header.Chevron:SetText("▴")
    end
    self._open = not self._open
end

function DropdownMixin:_OnItemClick(value)
    self:SetValue(value)
    self.List:Hide()
    self.Header.Chevron:SetText("▾")
    self._open = false
    if self._onChange then
        self._onChange(value)
    end
end

function DropdownMixin:_RefreshHeaderText()
    if self._value == nil then
        self.Header.Text:SetText(self._placeholder)
        self.Header.Text:SetTextColor(0.6, 0.6, 0.6, 1)
    else
        local displayLabel = tostring(self._value)
        for _, item in ipairs(self._items) do
            if item.value == self._value then
                displayLabel = item.label
                break
            end
        end
        self.Header.Text:SetText(displayLabel)
        self.Header.Text:SetTextColor(1, 1, 1, 1)
    end
end

function DropdownMixin:_RefreshSelectedRow()
    local P = LibBitForgeUI.Colors
    for _, row in ipairs(self._itemButtons) do
        if row._value == self._value then
            row._normalTex:SetColorTexture(
                P.primary.r, P.primary.g,
                P.primary.b, 0.4)
        else
            row._normalTex:SetColorTexture(0, 0, 0, 0)
        end
    end
end

LibBitForgeUI.DropdownMixin = DropdownMixin
