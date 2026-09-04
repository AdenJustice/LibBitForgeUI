local ipairs = ipairs
local insert = table.insert
local concat = table.concat

local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
local colors = UI.Colors
local metrics = UI.Metrics

local DropdownButtonMixin = DropdownButtonMixin

local BORDER_BACKDROP = {
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = UI.GetPixel(),
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

--- The closed box's three painted states, resolved in one place. The hover
--- highlight and the greyed state both write the border, so a widget where each
--- owned half of it would paint whichever fired last.
---@param dropdown BitForge.DropdownMixin
---@param state "NORMAL" | "HOVER" | "DISABLED"
local function UpdateState(dropdown, state)
    local disabled = state == "DISABLED"
    local borderColor = colors.edge
    if disabled then
        borderColor = colors.bgDisabled
    elseif state == "HOVER" then
        borderColor = colors.point
    end

    dropdown:SetBackdropBorderColor(borderColor:GetRGBA())
    -- Paints two different things: the label when a selection is set, and the
    -- placeholder when it is not. The placeholder would want textMuted, but
    -- splitting them needs the dropdown to know whether it holds a selection
    -- -- a widget change, not a colour one -- so this stays on text.
    dropdown.Label:SetTextColor((disabled and colors.textDisabled or colors.text):GetRGB())
    -- The arrow wears no tint of its own at rest, so reviving restores the
    -- texture's own white rather than painting the label's grey onto a glyph
    -- that never carried it.
    if disabled then
        dropdown.Arrow:SetVertexColor(colors.textDisabled:GetRGB())
    else
        dropdown.Arrow:SetVertexColor(1, 1, 1, 1)
    end
end

---@class BitForge.DropdownMixin : Button, BackdropTemplate, DropdownButtonMixin
local DropdownMixin = CreateFromMixins(DropdownButtonMixin)

function DropdownMixin:OnLoad()
    -- Fields read by DropdownButtonMixin.OnLoad_Intrinsic for menu anchoring.
    self.menuPoint = "TOPLEFT"
    self.menuRelativePoint = "BOTTOMLEFT"
    self.menuPointX = 0
    self.menuPointY = 0

    DropdownButtonMixin.OnLoad_Intrinsic(self)

    self:SetSize(metrics.dropdownWidth, metrics.control)
    self:EnableMouseWheel(true) -- OnLoad_Intrinsic disables it; re-enable for rotation

    -- Colours come later, from UpdateState, once the regions it paints exist.
    self:SetBackdrop(BORDER_BACKDROP)

    -- The ground is a texture rather than the backdrop's own bgFile because
    -- Skin.lua's host-skin bridge strips it by name (frameObject.Bg) when a
    -- host takes the surface over -- a bgFile has no name a host can find.
    -- On the raised plane rather than the window's own bg, which is the
    -- indistinguishability `raised` exists to fix.
    local bg = self:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface/Buttons/WHITE8X8")
    bg:SetAllPoints()
    bg:SetVertexColor(colors.raised.r, colors.raised.g, colors.raised.b, colors.raised.a)
    self.Bg = bg

    local label = self:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutline")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetPoint("LEFT", self, "LEFT", metrics.md, 0)
    label:SetPoint("RIGHT", self, "RIGHT",
        -(metrics.arrow + metrics.md + metrics.xs), 0)
    label:SetPoint("TOP", self, "TOP", 0, 0)
    label:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
    self.Label = label

    local arrow = self:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(metrics.arrow, metrics.arrow)
    arrow:SetPoint("RIGHT", self, "RIGHT", -metrics.md, 0)
    arrow:SetTexture(UI.GetMedia("arrow_down"))
    self.Arrow = arrow

    -- DropdownButtonMixin intrinsic scripts must be wired manually in pure-Lua contexts.
    self:HookScript("OnMouseDown", DropdownButtonMixin.OnMouseDown_Intrinsic)
    self:HookScript("OnMouseWheel", DropdownButtonMixin.OnMouseWheel_Intrinsic)

    -- Hover border highlight. IsEnabled first: a greyed button still takes
    -- OnEnter, the same trap CheckButtonMixin's own OnEnter documents in
    -- Buttons.lua.
    self:HookScript("OnEnter", function(f)
        if f:IsEnabled() then UpdateState(f, "HOVER") end
    end)
    self:HookScript("OnLeave", function(f)
        if not f:IsMenuOpen() then
            UpdateState(f, f:IsEnabled() and "NORMAL" or "DISABLED")
        end
    end)

    -- The greyed state. SetEnabled(false) already stops the menu and the wheel
    -- -- OpenMenu and OnMouseWheel_Intrinsic both return early on IsEnabled
    -- (Blizzard_Menu/DropdownButton.lua) -- but says so nowhere on screen, so
    -- without these the box keeps a live border and a live label: a control
    -- that provably does nothing looking like one that does.
    self:HookScript("OnDisable", function(f) UpdateState(f, "DISABLED") end)
    self:HookScript("OnEnable", function(f) UpdateState(f, "NORMAL") end)

    UpdateState(self, "NORMAL")

    UI.ApplyMinimum(self, "Dropdown")
end

--- Called by DropdownButtonMixin when the selection changes; the label then
--- shows the selected option texts joined with ", ".
function DropdownMixin:UpdateToMenuSelections(menuDescription, selections)
    local text = self._placeholder or ""
    if selections and #selections > 0 then
        local parts = {}
        for _, desc in ipairs(selections) do
            local t = desc.text
            if t then
                insert(parts, t)
            end
        end
        if #parts > 0 then
            text = concat(parts, ", ")
        end
    end
    self.Label:SetText(text)
end

function DropdownMixin:OnMenuOpened(menu)
    DropdownButtonMixin.OnMenuOpened(self, menu)
    self.Arrow:SetTexture(UI.GetMedia("arrow_up"))
    UpdateState(self, "HOVER")
end

function DropdownMixin:OnMenuClosed(menu)
    DropdownButtonMixin.OnMenuClosed(self, menu)
    self.Arrow:SetTexture(UI.GetMedia("arrow_down"))
    if not self:IsEnabled() then
        UpdateState(self, "DISABLED")
    else
        UpdateState(self, self:IsMouseOver() and "HOVER" or "NORMAL")
    end
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

UI.Mixins.Dropdown = DropdownMixin

--- Example usage:
---   local dd = UI.CreateDropdown(parent, "Select an option")
---   dd:SetupMenu(function(dropdown, root)
---     root:CreateRadio("Option A", getter, setter, "A")
---     root:CreateRadio("Option B", getter, setter, "B")
---   end)
---
---@param parent      any
---@param placeholder string?
---@return BitForge.DropdownMixin
function UI.CreateDropdown(parent, placeholder)
    ---@class BitForge.DropdownMixin
    local dropdown = CreateFrame("Button", nil, parent, "BackdropTemplate")
    Mixin(dropdown, DropdownMixin)
    dropdown:OnLoad()
    if placeholder then
        dropdown:SetPlaceholder(placeholder)
    end
    return dropdown
end
