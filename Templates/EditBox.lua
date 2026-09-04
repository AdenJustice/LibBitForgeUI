local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
---@type BitForge.UI.Colors
local colors = UI.Colors
local metrics = UI.Metrics

local PP = UI.GetPixel()
local BACKDROP_CONFIG = {
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    tile = true,
    tileSize = 32,
    edgeSize = PP,
    insets = { left = PP, right = PP, top = PP, bottom = PP },
}

local function ApplyBackdrop(frame)
    frame:SetBackdrop(BACKDROP_CONFIG)
    frame:SetBackdropColor(colors.raised:GetRGBA())
    frame:SetBackdropBorderColor(colors.edge:GetRGBA())
    frame:SetTextColor(colors.text:GetRGB())
    frame:SetFontObject(UI.Fonts.NormalShadow)
end

local function OnEditFocusGained(self)
    self:SetBackdropBorderColor(colors.point:GetRGB())
end

local function OnEditFocusLost(self)
    self:SetBackdropBorderColor(colors.edge:GetRGB())
end

local function OnEnterPressed(self) self:ClearFocus() end
local function OnEscapePressed(self) self:ClearFocus() end

---@class BitForge.EditBoxMixin : EditBox, BackdropTemplate
local EditBoxMixin = {}

function EditBoxMixin:OnLoad()
    self:SetSize(metrics.defaultWidth, metrics.control)
    self:SetAutoFocus(false)
    self:SetTextInsets(metrics.md, metrics.md, 0, 0)

    ApplyBackdrop(self)

    self:HookScript("OnEditFocusGained", OnEditFocusGained)
    self:HookScript("OnEditFocusLost", OnEditFocusLost)
    self:HookScript("OnEnterPressed", OnEnterPressed)
    self:HookScript("OnEscapePressed", OnEscapePressed)
    self:SetScript("OnTextChanged", self.OnTextChanged)

    UI.ApplyMinimum(self, "EditBox")
end

--- Override this in calling code to respond to text changes.
function EditBoxMixin:OnTextChanged() end

UI.Mixins.EditBox = EditBoxMixin

---@class BitForge.ScrollEditBoxMixin : Frame, ScrollingEditBoxTemplate
local ScrollEditBoxMixin = {}

function ScrollEditBoxMixin:OnLoad()
    self:SetSize(metrics.defaultWidth, metrics.scrollHeight)

    -- ScrollingEditBoxTemplate creates self.ScrollBox and self.ScrollBox.EditBox.
    local editBox = self.ScrollBox.EditBox
    Mixin(editBox, BackdropTemplateMixin)
    BackdropTemplateMixin.OnBackdropLoaded(editBox)
    ApplyBackdrop(editBox)
    self:SetTextInsets(metrics.md, metrics.md, metrics.sm, metrics.sm)

    self:RegisterCallback("OnFocusGained", function(_, eb)
        eb:SetBackdropBorderColor(colors.point:GetRGBA())
    end)
    self:RegisterCallback("OnFocusLost", function(_, eb)
        eb:SetBackdropBorderColor(colors.edge:GetRGBA())
    end)

    UI.ApplyMinimum(self, "ScrollEditBox")
end

function ScrollEditBoxMixin:OnShow()
    ScrollingEditBoxMixin.OnShow(self)
end

function ScrollEditBoxMixin:OnMouseDown()
    ScrollingEditBoxMixin.OnMouseDown(self)
end

UI.Mixins.ScrollEditBox = ScrollEditBoxMixin

---@param parent any
---@return BitForge.EditBoxMixin
function UI.CreateEditBox(parent)
    ---@class BitForge.EditBoxMixin
    local editBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    Mixin(editBox, EditBoxMixin)
    editBox:OnLoad()
    return editBox
end

---@param parent any
---@return BitForge.ScrollEditBoxMixin
function UI.CreateScrollEditBox(parent)
    ---@class BitForge.ScrollEditBoxMixin
    local frame = CreateFrame("Frame", nil, parent, "ScrollingEditBoxTemplate")
    Mixin(frame, ScrollEditBoxMixin)
    frame:OnLoad()
    return frame
end
