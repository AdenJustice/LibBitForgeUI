local BACKDROP_CONFIG = {
    bgFile   = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    tile     = true,
    tileSize = 32,
    edgeSize = 32,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 },
}

-- =========================================================
-- LibBitForgeUI.FrameMixin
-- MD card-style frames
-- =========================================================

---@class LibBitForgeUI.FrameMixin: BackdropTemplate
local FrameMixin = {}

--- @param hasTitle boolean? Whether to create a title bar for this frame.
function FrameMixin:OnLoad(hasTitle)
    self:SetClampedToScreen(true)

    local P = LibBitForgeUI.Colors
    self:SetBackdrop(BACKDROP_CONFIG)
    self:SetBackdropColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    self:SetBackdropBorderColor(P.border.r, P.border.g, P.border.b, P.border.a)

    if hasTitle then
        local titleBar = self:CreateTexture(nil, "BACKGROUND")
        titleBar:SetTexture("Interface/Buttons/WHITE8X8")
        titleBar:SetHeight(32)
        titleBar:SetVertexColor(0.251, 0.318, 0.710, 1)
        titleBar:SetPoint("TOPLEFT")
        titleBar:SetPoint("TOPRIGHT")
        self.TitleBar = titleBar

        local title = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetJustifyH("CENTER")
        title:SetJustifyV("MIDDLE")
        title:SetHeight(32)
        title:SetTextColor(1, 1, 1, 1)
        title:SetPoint("TOPLEFT", self, "TOPLEFT", 12, 0)
        title:SetPoint("TOPRIGHT", self, "TOPRIGHT", -12, 0)
        self.Title = title
    end
end

--- Set the title bar text.
---@param text string
function FrameMixin:SetTitle(text)
    local titleFS = self.Title
    if titleFS then
        titleFS:SetText(text)
    else
        error("Attempted to set title on a frame without a title bar.", 2)
    end
end

LibBitForgeUI.Mixins.Frame = FrameMixin

--- =========================================================
--- LibBitForgeUI.CreateFrame
--- Factory function for creating frames with the appropriate mixin.
--- =========================================================

--- @param parent any The parent frame.
--- @param title string? Optional title text.
--- @return LibBitForgeUI.FrameMixin frame The created frame.
function LibBitForgeUI.CreateFrame(parent, title)
    --- @class LibBitForgeUI.FrameMixin
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local isValidTitle = title and type(title) == "string" and string.trim(title) ~= ""

    Mixin(frame, FrameMixin)
    frame:OnLoad(isValidTitle)

    if title and type(title) == "string" and string.trim(title) ~= "" then
        frame:SetTitle(title)
    end

    return frame
end
