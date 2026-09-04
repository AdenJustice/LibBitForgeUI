local trim = string.trim
local max = math.max

local PixelUtil = PixelUtil

local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
local colors = UI.Colors
local metrics = UI.Metrics

local BACKDROP_CONFIG = {
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    tile = true,
    tileSize = 32,
    edgeSize = UI.GetPixel(),
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local BACKDROP_ALPHA = 0.5

---@class BitForge.FrameMixin : BackdropTemplate
---@field Title    FontString?  Present when created with a title bar.
---@field TitleBar Texture?     Present when created with a title bar.
local FrameMixin = {}

---@param hasTitle boolean?  When true, a 32-px primary-colour title bar is added.
function FrameMixin:OnLoad(hasTitle)
    self:SetClampedToScreen(true)
    self:SetBackdrop(BACKDROP_CONFIG)
    self:SetBackdropColor(colors.bg.r, colors.bg.g, colors.bg.b, BACKDROP_ALPHA)
    self:SetBackdropBorderColor(colors.edge:GetRGBA())

    if hasTitle then
        local titleBar = self:CreateTexture(nil, "BORDER")
        titleBar:SetTexture("Interface/Buttons/WHITE8X8")
        PixelUtil.SetHeight(titleBar, metrics.control)
        titleBar:SetVertexColor(colors.point:GetRGBA())
        titleBar:SetPoint("TOPLEFT")
        titleBar:SetPoint("TOPRIGHT")
        self.TitleBar = titleBar

        local title = self:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutlineShadow")
        title:SetJustifyH("CENTER")
        title:SetJustifyV("MIDDLE")
        PixelUtil.SetHeight(title, metrics.control)
        title:SetTextColor(1, 1, 1, 1)
        PixelUtil.SetPoint(title, "TOPLEFT", self, "TOPLEFT", 12, 0)
        PixelUtil.SetPoint(title, "TOPRIGHT", self, "TOPRIGHT", -12, 0)
        self.Title = title
    end

    UI.ApplyMinimum(self, "Frame")
    -- Puts the same floor under the user-drag path. Layered on top of
    -- ApplyMinimum rather than replacing it: whether SetResizeBounds also
    -- clamps a programmatic SetSize is not established from the client
    -- source, so it is not relied on for that.
    local minimum = UI.Minimums.Frame
    self:SetResizeBounds(minimum.minWidth, minimum.minHeight)
end

--- Errors if the frame was created without a title bar.
---@param text string
function FrameMixin:SetTitle(text)
    if not self.Title then
        error("Attempted to set title on a frame without a title bar.", 2)
    end
    self.Title:SetText(text)
end

UI.Mixins.Frame = FrameMixin

---@param parent any
---@param title  string?  Optional title bar text.
---@param name   string?  Optional global frame name, for a window
---                        UISpecialFrames must find by name to close on Escape.
---                        It has to be passed here: a frame's name is fixed at
---                        creation, so a later `_G[name] = frame` is right for
---                        `_G` and still leaves `GetName()` answering nil.
---@return BitForge.FrameMixin
function UI.CreateFrame(parent, title, name)
    local isTitle = title and type(title) == "string" and trim(title) ~= ""

    ---@class BitForge.FrameMixin
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    Mixin(frame, FrameMixin)
    frame:OnLoad(isTitle)
    if isTitle then
        frame:SetTitle(title)
    end
    return frame
end

--- A faint dark glow just outside the frame, for a floating appearance. Sets
--- frame.Shadow rather than returning the frame it creates.
---@param frame any
function UI.ApplyShadow(frame)
    local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    local offSet = UI.GetPixel(2)
    shadow:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
    shadow:SetBackdrop({
        edgeFile = UI.GetMedia("glow"),
        edgeSize = UI.GetPixel(3),
    })
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -offSet, offSet)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offSet, -offSet)
    shadow:SetBackdropBorderColor(0, 0, 0, 0.8)
    frame.Shadow = shadow
end
