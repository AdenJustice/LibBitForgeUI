local function updateFill(self)
    local min, max = self:GetMinMaxValues()
    local frac = (max > min) and ((self:GetValue() - min) / (max - min)) or 0
    self.Fill:SetWidth(math.max(1, (self:GetWidth() - self.Thumb:GetWidth()) * frac))
end

-- LibBitForgeUI.SliderMixin
-- MD-style horizontal slider with a tall-rectangle thumb

---@class LibBitForgeUI.SliderMixin: Slider
local SliderMixin = {}

function SliderMixin:OnLoad()
    local c = LibBitForgeUI.Colors
    self:SetSize(200, 20)
    self:SetOrientation("HORIZONTAL")

    self.Track = self:CreateTexture(nil, "BACKGROUND")
    self.Track:SetHeight(4)
    self.Track:SetPoint("LEFT", self, "LEFT", 3, 0)
    self.Track:SetPoint("RIGHT", self, "RIGHT", -3, 0)
    self.Track:SetColorTexture(c.border.r, c.border.g, c.border.b, c.border.a)

    self.Fill = self:CreateTexture(nil, "BACKGROUND")
    self.Fill:SetSize(1, 4)
    self.Fill:SetPoint("LEFT", self, "LEFT", 3, 0)
    self.Fill:SetColorTexture(c.primary.r, c.primary.g, c.primary.b, c.primary.a)

    self:SetThumbTexture("Interface/Buttons/WHITE8X8")
    self.Thumb = self:GetThumbTexture()
    self.Thumb:SetSize(6, 18)
    self.Thumb:SetColorTexture(c.primary.r, c.primary.g, c.primary.b, c.primary.a)

    self:SetMinMaxValues(0, 100)
    self:SetValue(0)
    self:SetValueStep(1)
    self:SetObeyStepOnDrag(true)

    self:SetScript("OnValueChanged", function(_, _, userInput)
        updateFill(self)
        if userInput and self._onChange then self._onChange(self:GetValue()) end
    end)

    updateFill(self)
end

---@param fn fun(value: number)
function SliderMixin:SetOnChange(fn)
    self._onChange = fn
end

LibBitForgeUI.Mixins.Slider = SliderMixin

---@param parent any
---@return LibBitForgeUI.SliderMixin
function LibBitForgeUI.CreateSlider(parent)
    local slider = CreateFrame("Slider", nil, parent) --[[@as LibBitForgeUI.SliderMixin]]
    Mixin(slider, SliderMixin)
    slider:OnLoad()

    return slider
end
