-- =========================================================
-- LibBitForgeUI.SliderMixin
-- Mixin for BitForgeSliderTemplate
-- MD-style horizontal slider with a tall-rectangle thumb
-- =========================================================

---@class LibBitForgeUI.SliderMixin: Slider
local SliderMixin = {}

local THUMB_MIN_W = 6
local THUMB_RATIO = 0.05

local function updateFill(self, value, thumbW)
    local min, max = self:GetMinMaxValues()
    local fraction = (max > min) and ((value - min) / (max - min)) or 0
    local trackWidth = self:GetWidth() - thumbW
    self.Fill:SetWidth(math.max(1, trackWidth * fraction))
end

local function applyThumbWidth(self)
    self._thumbW = math.max(self._thumbMinW, self:GetWidth() * self._thumbRatio)
    self.Thumb:SetWidth(self._thumbW)
    updateFill(self, self:GetValue(), self._thumbW)
end

function SliderMixin:OnLoad()
    local c          = LibBitForgeUI.Colors

    self._thumbMinW  = THUMB_MIN_W
    self._thumbRatio = THUMB_RATIO

    -- Track (grey bar)
    self.Track:SetColorTexture(c.border.r, c.border.g, c.border.b, c.border.a)

    -- Fill (primary-coloured left portion)
    self.Fill:SetColorTexture(c.primary.r, c.primary.g, c.primary.b, c.primary.a)

    -- Thumb
    applyThumbWidth(self)
    self.Thumb:SetColorTexture(c.primary.r, c.primary.g, c.primary.b, c.primary.a)

    -- Default range & behaviour
    self:SetMinMaxValues(0, 100)
    self:SetValue(0)
    self:SetValueStep(1)
    self:SetObeyStepOnDrag(true)

    self:SetScript("OnValueChanged", function(_, value, userInput)
        updateFill(self, value, self._thumbW)
        if userInput and self._onChange then
            self._onChange(value)
        end
    end)

    updateFill(self, 0, self._thumbW)
end

--- Set the minimum thumb width in pixels.
---@param minW number
function SliderMixin:SetThumbMinWidth(minW)
    self._thumbMinW = minW
    applyThumbWidth(self)
end

--- Set the thumb width as a fraction of the slider width (e.g. 0.05 = 5%).
---@param ratio number
function SliderMixin:SetThumbRatio(ratio)
    self._thumbRatio = ratio
    applyThumbWidth(self)
end

--- Register a callback invoked on user-driven value changes.
---@param fn fun(value: number)
function SliderMixin:SetOnChange(fn)
    self._onChange = fn
end

LibBitForgeUI.SliderMixin = SliderMixin
