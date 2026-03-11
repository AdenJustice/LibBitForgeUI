local function applyColor(texture, color)
    texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

-- Edge sets per position:
--   indicator edge  = the outer edge where the thin line sits
--   open edge       = the content-adjacent edge (no border drawn)
--   side borders    = the two edges that frame the tab on the sides
local EDGE_CONFIG = {
    bottom = { indicator = "BOTTOM", open = "TOP", sides = { "LEFT", "RIGHT" } },
    top    = { indicator = "TOP", open = "BOTTOM", sides = { "LEFT", "RIGHT" } },
    left   = { indicator = "TOP", open = "RIGHT", sides = { "LEFT", "BOTTOM" } },
    right  = { indicator = "TOP", open = "LEFT", sides = { "RIGHT", "BOTTOM" } },
}

-- Anchor the indicator texture to one horizontal/vertical edge of the button.
local function anchorIndicator(indicator, button, edge)
    indicator:ClearAllPoints()
    if edge == "BOTTOM" then
        indicator:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        indicator:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    elseif edge == "TOP" then
        indicator:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        indicator:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    elseif edge == "LEFT" then
        indicator:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        indicator:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    elseif edge == "RIGHT" then
        indicator:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
        indicator:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    end
end

-- Anchor each border texture to its own edge (1px thick).
local function anchorBorders(button)
    local b = button
    b.BorderTop:ClearAllPoints()
    b.BorderTop:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.BorderTop:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)

    b.BorderBottom:ClearAllPoints()
    b.BorderBottom:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    b.BorderBottom:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)

    b.BorderLeft:ClearAllPoints()
    b.BorderLeft:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.BorderLeft:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)

    b.BorderRight:ClearAllPoints()
    b.BorderRight:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    b.BorderRight:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
end

-- =========================================================
-- LibBitForgeUI.TabButtonMixin
-- Mixin for BitForgeTabButtonTemplate
-- MD-style tab button: thin indicator line for hover/selected,
-- plus border highlighting and bg fill when selected.
-- =========================================================

---@class LibBitForgeUI.TabButtonMixin: CheckButton
local TabButtonMixin = {}

function TabButtonMixin:OnLoad()
    self:SetSize(80, 32)
    -- Background fill (shown when selected, was in XML)
    local bg = self:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface/Buttons/WHITE8X8")
    bg:SetPoint("TOPLEFT")
    bg:SetPoint("BOTTOMRIGHT")
    bg:Hide()
    self.Bg = bg
    -- 1px border strips (was in XML)
    local borderTop = self:CreateTexture(nil, "ARTWORK")
    borderTop:SetTexture("Interface/Buttons/WHITE8X8")
    borderTop:SetHeight(1)
    borderTop:Hide()
    self.BorderTop = borderTop
    local borderBottom = self:CreateTexture(nil, "ARTWORK")
    borderBottom:SetTexture("Interface/Buttons/WHITE8X8")
    borderBottom:SetHeight(1)
    borderBottom:Hide()
    self.BorderBottom = borderBottom
    local borderLeft = self:CreateTexture(nil, "ARTWORK")
    borderLeft:SetTexture("Interface/Buttons/WHITE8X8")
    borderLeft:SetWidth(1)
    borderLeft:Hide()
    self.BorderLeft = borderLeft
    local borderRight = self:CreateTexture(nil, "ARTWORK")
    borderRight:SetTexture("Interface/Buttons/WHITE8X8")
    borderRight:SetWidth(1)
    borderRight:Hide()
    self.BorderRight = borderRight
    -- 2px indicator line (was in XML)
    local indicator = self:CreateTexture(nil, "OVERLAY")
    indicator:SetTexture("Interface/Buttons/WHITE8X8")
    indicator:SetHeight(2)
    indicator:Hide()
    self.Indicator = indicator
    -- Label FontString (was in XML)
    local label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -4)
    label:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)
    self:SetFontString(label)
    self.Label     = label

    self._position = "bottom"
    self._hovered  = false
    anchorIndicator(self.Indicator, self, "BOTTOM")
    anchorBorders(self)
    self:SetScript("OnClick", function(f) f:OnClick() end)
    self:SetScript("OnEnter", function(f) f:OnEnter() end)
    self:SetScript("OnLeave", function(f) f:OnLeave() end)
end

--- Inform the button which side of the content frame it sits on.
--- "bottom" → indicator at bottom edge; "top" / "left" / "right" → indicator at top edge.
---@param pos "bottom"|"top"|"left"|"right"
function TabButtonMixin:SetTabPosition(pos)
    self._position = pos or "bottom"
    local cfg = EDGE_CONFIG[self._position] or EDGE_CONFIG.bottom
    anchorIndicator(self.Indicator, self, cfg.indicator)
    self:_UpdateVisuals()
end

function TabButtonMixin:_UpdateVisuals()
    local P         = LibBitForgeUI.Colors
    local cfg       = EDGE_CONFIG[self._position] or EDGE_CONFIG.bottom
    local selected  = self:GetChecked()

    local borderMap = {
        TOP = self.BorderTop,
        BOTTOM = self.BorderBottom,
        LEFT = self.BorderLeft,
        RIGHT = self.BorderRight,
    }

    self.Bg:Hide()
    self.Indicator:Hide()
    for _, tex in pairs(borderMap) do tex:Hide() end

    if selected then
        self.Bg:Show()
        applyColor(self.Bg, P.bg)
        self.Indicator:Show()
        applyColor(self.Indicator, P.primary)
        for _, edge in ipairs(cfg.sides) do
            borderMap[edge]:Show()
            applyColor(borderMap[edge], P.primary)
        end
    elseif self._hovered then
        self.Indicator:Show()
        self.Indicator:SetVertexColor(P.primaryHover.r, P.primaryHover.g, P.primaryHover.b, 1.0)
    end
end

function TabButtonMixin:OnClick()
    self:_UpdateVisuals()
end

function TabButtonMixin:OnEnter()
    self._hovered = true
    self:_UpdateVisuals()
end

function TabButtonMixin:OnLeave()
    self._hovered = false
    self:_UpdateVisuals()
end

-- =========================================================
-- LibBitForgeUI.TabBarMixin
-- Mixin for BitForgeTabBarTemplate
-- Container that manages a row of tab buttons.
-- =========================================================

---@class LibBitForgeUI.TabBarMixin: Frame
local TabBarMixin = {}

function TabBarMixin:OnLoad()
    self._tabs     = {} -- { { id, button } } ordered list
    self._tabMap   = {} -- id → button
    self._selected = nil
    self._onChange = nil
    self._tabW     = 80
    self._tabH     = 32
    self._position = "bottom"
end

--- Add a tab to the bar.
--- Returns the CheckButton frame so callers can further customise it.
---@param id      any     Unique identifier for this tab
---@param label   string  Text shown on the button
---@return CheckButton
function TabBarMixin:AddTab(id, label)
    local btn = CreateFrame("CheckButton", nil, self)
    Mixin(btn, TabButtonMixin)
    btn:OnLoad()
    btn:SetSize(self._tabW, self._tabH)

    -- Anchor to the right of the previous tab, or to the bar's top-left corner
    local prevEntry = self._tabs[#self._tabs]
    if prevEntry then
        btn:SetPoint("TOPLEFT", prevEntry.button, "TOPRIGHT", 0, 0)
    else
        btn:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    end

    btn:SetText(label)

    -- Wire click: tell the bar a tab was chosen
    local bar = self
    btn:HookScript("OnClick", function()
        bar:SetSelectedTab(id)
    end)

    btn:SetTabPosition(self._position)

    table.insert(self._tabs, { id = id, button = btn })
    self._tabMap[id] = btn

    return btn
end

--- Set the position of the bar relative to its content frame.
--- Propagates to all existing tab buttons.
---@param pos "bottom"|"top"|"left"|"right"
function TabBarMixin:SetPosition(pos)
    self._position = pos or "bottom"
    for _, entry in ipairs(self._tabs) do
        entry.button:SetTabPosition(self._position)
    end
end

--- Select a tab by id. Fires the OnChange callback.
---@param id any
function TabBarMixin:SetSelectedTab(id)
    self._selected = id
    for _, entry in ipairs(self._tabs) do
        local isSelected = (entry.id == id)
        entry.button:SetChecked(isSelected)
        entry.button:_UpdateVisuals()
    end
    if self._onChange then
        self._onChange(id)
    end
end

--- Register a callback fired when the selected tab changes.
---@param fn fun(id: any)
function TabBarMixin:SetOnChange(fn)
    self._onChange = fn
end

--- Set the default dimensions used by future AddTab calls.
--- Does not resize already-created tab buttons.
---@param w number
---@param h number
function TabBarMixin:SetTabSize(w, h)
    self._tabW = w or self._tabW
    self._tabH = h or self._tabH
end

LibBitForgeUI.Mixins.TabButton = TabButtonMixin
LibBitForgeUI.Mixins.TabBar = TabBarMixin

---@param parent any
---@return LibBitForgeUI.TabBarMixin
function LibBitForgeUI.CreateTabBar(parent)
    local bar = CreateFrame("Frame", nil, parent)  --[[@as LibBitForgeUI.TabBarMixin]]
    Mixin(bar, TabBarMixin)
    bar:OnLoad()

    return bar
end
