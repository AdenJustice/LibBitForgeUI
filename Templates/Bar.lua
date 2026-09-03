local type = type

local PixelUtil = PixelUtil

local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
---@type BitForge.UI.Colors
local colors = UI.Colors
local skin = UI.Skin

local BAR_TEXTURE = "Interface/Buttons/WHITE8X8"
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 8

-- A native StatusBar rather than a pair of hand-resized textures, because the
-- widget already owns the two things a hand-rolled bar has to re-derive on
-- every update: it clamps SetValue into the range, and it renders a fill of
-- zero width without the `max(1, ...)` guard Slider.lua writes by hand.
--
-- That the client clamps is not an assumption. Blizzard_SharedXML/
-- SmoothStatusBar.lua clamps its lerp target into the bar's own range before
-- interpolating -- pointless unless GetValue can never answer outside it, since
-- an unclamped target would otherwise converge on its own. A zero-width range
-- is likewise a shape the client is fed in earnest: Blizzard_UIPanels_Game/
-- Mainline/ReputationFrame.lua hands a faction it has no data for 0, 0, 0.
--
-- No border. A consumer that wants one draws it over the top, so a bar sitting
-- inside a row that already has an outline does not stack two.

---@class BitForge.BarMixin : StatusBar
local BarMixin = {}

function BarMixin:OnLoad()
    PixelUtil.SetSize(self, DEFAULT_WIDTH, DEFAULT_HEIGHT)
    self:SetOrientation("HORIZONTAL")

    -- The unfilled remainder. Full width of the frame and behind the fill, so
    -- what shows through is the track rather than whatever is under the bar.
    local track = self:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(self)
    self.Track = track

    self:SetStatusBarTexture(BAR_TEXTURE)
    self.Fill = self:GetStatusBarTexture()

    self:SetBarColor(colors.point)
    self:SetTrackColor(colors.edge)

    self:SetMinMaxValues(0, 1)
    self:SetValue(0)
end

--- Colour the filled portion, from a ColorMixin or loose r, g, b[, a] numbers:
--- a palette token is already a ColorMixin, while a class or faction colour is
--- often unpacked before it gets here.
---@param colorOrRed ColorMixin|number
---@param green? number
---@param blue? number
---@param alpha? number
function BarMixin:SetBarColor(colorOrRed, green, blue, alpha)
    skin.ApplyColorTexture(self.Fill, colorOrRed, green, blue, alpha)
end

--- Colour the background track, in the same two forms SetBarColor accepts.
---@param colorOrRed ColorMixin|number
---@param green? number
---@param blue? number
---@param alpha? number
function BarMixin:SetTrackColor(colorOrRed, green, blue, alpha)
    skin.ApplyColorTexture(self.Track, colorOrRed, green, blue, alpha)
end

--- Fill the bar to `value` out of `maxValue`.
---
--- A convenience over the native SetMinMaxValues/SetValue pair, which stay
--- available for a caller that wants a floor other than zero.
---
--- A missing, zero or negative maxValue renders empty rather than raising:
--- "nothing known yet" and "no progress to show" are ordinary answers from a
--- data source, not faults, and a bar is drawn from the same paint pass as
--- everything else on its row. A value past maxValue is left to the widget,
--- which clamps it to full.
---@param value number|nil
---@param maxValue number|nil
function BarMixin:SetProgress(value, maxValue)
    if type(maxValue) ~= "number" or maxValue <= 0 then
        -- 0..1 at zero rather than 0..0, so "empty" does not depend on how the
        -- client resolves a range with no width.
        self:SetMinMaxValues(0, 1)
        self:SetValue(0)
        return
    end

    self:SetMinMaxValues(0, maxValue)
    self:SetValue(type(value) == "number" and value or 0)
end

UI.Mixins.Bar = BarMixin

---@param parent any
---@return BitForge.BarMixin
function UI.CreateBar(parent)
    ---@class BitForge.BarMixin
    local bar = CreateFrame("StatusBar", nil, parent)
    Mixin(bar, BarMixin)
    bar:OnLoad()
    return bar
end
