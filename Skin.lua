local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local skin = lib.Skin

local max = math.max
local select = select
local setmetatable = setmetatable
local type = type

local windowShellByFrame = setmetatable({}, { __mode = "k" })

local function ResolveRGBA(colorOrRed, green, blue, alpha)
    if colorOrRed == nil then
        return nil
    end

    if type(colorOrRed) == "table" then
        if colorOrRed.GetRGBA then
            return colorOrRed:GetRGBA()
        end

        return colorOrRed.r or 1, colorOrRed.g or 1, colorOrRed.b or 1, colorOrRed.a or 1
    end

    if type(colorOrRed) == "number" then
        return colorOrRed, green or 1, blue or 1, alpha or 1
    end

    return nil
end

function skin.GetSolidBackdrop()
    return {
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        tile = false,
        edgeSize = lib.GetPixel(),
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    }
end

function skin.ApplyColorTexture(textureObject, colorOrRed, green, blue, alpha)
    if not textureObject then
        return
    end

    local red, greenValue, blueValue, alphaValue = ResolveRGBA(colorOrRed, green, blue, alpha)
    if not red then
        return
    end

    textureObject:SetColorTexture(red, greenValue, blueValue, alphaValue)
end

function skin.ApplyVertexColor(textureObject, colorOrRed, green, blue, alpha)
    if not textureObject then
        return
    end

    local red, greenValue, blueValue, alphaValue = ResolveRGBA(colorOrRed, green, blue, alpha)
    if not red then
        return
    end

    textureObject:SetVertexColor(red, greenValue, blueValue, alphaValue)
end

function skin.HideTexture(textureObject, clearSource)
    if not textureObject then
        return
    end

    textureObject:SetAlpha(0)

    if clearSource then
        if textureObject.SetAtlas then
            textureObject:SetAtlas(nil)
        end

        if textureObject.SetTexture then
            textureObject:SetTexture(nil)
        end
    end
end

function skin.StripFrameTextures(frameObject, options)
    if not frameObject then
        return
    end

    options = options or {}

    if options.hideNineSlice ~= false and frameObject.NineSlice then
        frameObject.NineSlice:SetAlpha(0)
    end

    if options.hideBorder ~= false and frameObject.Border then
        frameObject.Border:SetAlpha(0)
    end

    if options.hideBg ~= false and frameObject.Bg then
        frameObject.Bg:SetAlpha(0)
    end

    if options.hideBG ~= false and frameObject.BG then
        frameObject.BG:SetAlpha(0)
    end

    if options.stripRegions == false or not frameObject.GetRegions then
        return
    end

    local skipOwnedRegions = options.skipOwnedRegions ~= false
    local regionCount = select("#", frameObject:GetRegions())
    for regionIndex = 1, regionCount do
        local regionObject = select(regionIndex, frameObject:GetRegions())
        if regionObject and regionObject.IsObjectType and regionObject:IsObjectType("Texture") then
            if not (skipOwnedRegions and regionObject._bfOwned) then
                regionObject:SetAlpha(0)
            end
        end
    end
end

---@param targetFrame Frame  Sized and levelled against; needs GetFrameLevel.
function skin.CreateBackdropUnderlay(targetFrame, options)
    if not targetFrame then
        return nil
    end

    options = options or {}

    local parentFrame = options.parent or targetFrame
    local backdropFrame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")

    if options.setAllPoints ~= false then
        backdropFrame:SetAllPoints(targetFrame)
    end

    local frameLevelOffset = options.frameLevelOffset or -1
    backdropFrame:SetFrameLevel(max(1, targetFrame:GetFrameLevel() + frameLevelOffset))
    backdropFrame:SetBackdrop(options.backdrop or skin.GetSolidBackdrop())

    local bgRed, bgGreen, bgBlue, bgAlpha = ResolveRGBA(
        options.backgroundColor or options.backgroundRed,
        options.backgroundGreen,
        options.backgroundBlue,
        options.backgroundAlpha)
    if bgRed then
        backdropFrame:SetBackdropColor(bgRed, bgGreen, bgBlue, bgAlpha)
    end

    local borderRed, borderGreen, borderBlue, borderAlpha = ResolveRGBA(
        options.borderColor or options.borderRed,
        options.borderGreen,
        options.borderBlue,
        options.borderAlpha)
    if borderRed then
        backdropFrame:SetBackdropBorderColor(borderRed, borderGreen, borderBlue, borderAlpha)
    end

    if options.enableMouse == true then
        backdropFrame:EnableMouse(true)
    elseif options.enableMouse == false then
        backdropFrame:EnableMouse(false)
    end

    if options.markOwned == true then
        backdropFrame._bfOwned = true
    end

    return backdropFrame
end

function skin.BuildWindowShell(frameObject, options)
    if not frameObject then
        return nil
    end

    options = options or {}
    local includeHeader = options.includeHeader == true
    local includeInnerTop = options.includeInnerTop ~= false
    local headerHeight = options.headerHeight or 30

    local shell = windowShellByFrame[frameObject]
    if not shell then
        shell = {}
        windowShellByFrame[frameObject] = shell
    end

    if not shell.background then
        shell.background = frameObject:CreateTexture(nil, "BACKGROUND", nil, -8)
        shell.background:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.background:SetPoint("BOTTOMRIGHT", frameObject, "BOTTOMRIGHT", -1, 1)
    end

    if includeHeader and not shell.header then
        shell.header = frameObject:CreateTexture(nil, "BACKGROUND", nil, -7)
        shell.header:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.header:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -1, -1)
        shell.header:SetHeight(headerHeight)
    elseif includeHeader and shell.header then
        shell.header:SetHeight(headerHeight)
    end

    if not shell.borderTop then
        shell.borderTop = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderTop:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.borderTop:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -1, -1)
        shell.borderTop:SetHeight(1)
    end

    if not shell.borderBottom then
        shell.borderBottom = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderBottom:SetPoint("BOTTOMLEFT", frameObject, "BOTTOMLEFT", 1, 1)
        shell.borderBottom:SetPoint("BOTTOMRIGHT", frameObject, "BOTTOMRIGHT", -1, 1)
        shell.borderBottom:SetHeight(1)
    end

    if not shell.borderLeft then
        shell.borderLeft = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderLeft:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.borderLeft:SetPoint("BOTTOMLEFT", frameObject, "BOTTOMLEFT", 1, 1)
        shell.borderLeft:SetWidth(1)
    end

    if not shell.borderRight then
        shell.borderRight = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderRight:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -1, -1)
        shell.borderRight:SetPoint("BOTTOMRIGHT", frameObject, "BOTTOMRIGHT", -1, 1)
        shell.borderRight:SetWidth(1)
    end

    if includeInnerTop and not shell.innerTop then
        shell.innerTop = frameObject:CreateTexture(nil, "BORDER", nil, 6)
        shell.innerTop:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 2, -2)
        shell.innerTop:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -2, -2)
        shell.innerTop:SetHeight(1)
    end

    return shell
end

function skin.StyleScrollBar(scrollBar, options)
    if not scrollBar then
        return nil
    end

    options = options or {}

    scrollBar:SetAlpha(options.scrollBarAlpha or 0.85)

    local thumbTexture = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
    if thumbTexture then
        if options.thumbColor then
            skin.ApplyVertexColor(thumbTexture, options.thumbColor)
        end

        thumbTexture:SetAlpha(options.thumbAlpha or 0.95)
    end

    return thumbTexture
end
