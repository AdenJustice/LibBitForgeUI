local max = math.max

local PixelUtil = PixelUtil

local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
---@type BitForge.UI.Colors
local colors = UI.Colors

---@class BitForge.SliderMixin : Slider
local SliderMixin = {}

local function UpdateFill(self)
    local lo, hi = self:GetMinMaxValues()
    local frac = (hi > lo) and ((self:GetValue() - lo) / (hi - lo)) or 0
    self.Fill:SetWidth(max(1, (self:GetWidth() - self.Thumb:GetWidth()) * frac))
end

function SliderMixin:OnLoad()
    self:SetSize(200, 20)
    self:SetOrientation("HORIZONTAL")

    local track = self:CreateTexture(nil, "BACKGROUND")
    PixelUtil.SetHeight(track, 4, 1)
    PixelUtil.SetPoint(track, "LEFT", self, "LEFT", 3, 0)
    PixelUtil.SetPoint(track, "RIGHT", self, "RIGHT", -3, 0)
    track:SetColorTexture(colors.edge:GetRGB())
    self.Track = track

    local fill = self:CreateTexture(nil, "BACKGROUND")
    PixelUtil.SetSize(fill, 1, 4, 1, 1)
    PixelUtil.SetPoint(fill, "LEFT", self, "LEFT", 3, 0)
    fill:SetColorTexture(colors.point:GetRGB())
    self.Fill = fill

    self:SetThumbTexture("Interface/Buttons/WHITE8X8")
    self.Thumb = self:GetThumbTexture()
    self.Thumb:SetSize(6, 18)
    self.Thumb:SetColorTexture(colors.point:GetRGB())

    self:SetMinMaxValues(0, 100)
    self:SetValue(0)
    self:SetValueStep(1)
    self:SetObeyStepOnDrag(true)

    self:SetScript("OnValueChanged", function(_, _, userInput)
        UpdateFill(self)
        if userInput and self._onChange then
            self._onChange(self:GetValue())
        end
    end)

    UpdateFill(self)
end

--- Register a callback fired when the user drags the slider.
---@param fn fun(value: number)
function SliderMixin:SetOnChange(fn)
    self._onChange = fn
end

UI.Mixins.Slider = SliderMixin

---@param parent any
---@return BitForge.SliderMixin
function UI.CreateSlider(parent)
    ---@class BitForge.SliderMixin
    local slider = CreateFrame("Slider", nil, parent)
    Mixin(slider, SliderMixin)
    slider:OnLoad()
    return slider
end
