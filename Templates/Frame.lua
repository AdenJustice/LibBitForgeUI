-- =========================================================
-- LibBitForgeUI.FrameMixin / LibBitForgeUI.TitledFrameMixin
-- Mixins for BitForgeFrameTemplate and BitForgeFrameWithTitleTemplate
-- MD card-style movable frames
-- =========================================================

---@class LibBitForgeUI.FrameMixin: Frame, BackdropTemplateMixin
local FrameMixin = {}

local BACKDROP_CONFIG = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true,
    tileSize = 32,
    edgeSize = 32,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 },
}

function FrameMixin:OnLoad()
    local P = LibBitForgeUI.Colors
    self:RegisterForDrag("LeftButton")
    self:SetBackdrop(BACKDROP_CONFIG)
    self:SetBackdropColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    self:SetBackdropBorderColor(P.border.r, P.border.g, P.border.b, P.border.a)
    self:SetScript("OnDragStart", function(f) f:OnDragStart() end)
    self:SetScript("OnDragStop", function(f) f:OnDragStop() end)
    self:SetScript("OnShow", function(f) f:OnShow() end)
    self:SetScript("OnHide", function(f) f:OnHide() end)
end

function FrameMixin:OnDragStart()
    self:StartMoving()
end

function FrameMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function FrameMixin:OnShow()
end

function FrameMixin:OnHide()
end

---@class LibBitForgeUI.TitledFrameMixin: LibBitForgeUI.FrameMixin
---@field Title FontString
local TitledFrameMixin = CreateFromMixins(LibBitForgeUI.FrameMixin)

--- Set the title bar text.
---@param text string
function TitledFrameMixin:SetTitle(text)
    local titleFS = self.Title
    if titleFS then
        titleFS:SetText(text or "")
    end
end

LibBitForgeUI.FrameMixin = FrameMixin
LibBitForgeUI.TitledFrameMixin = TitledFrameMixin
