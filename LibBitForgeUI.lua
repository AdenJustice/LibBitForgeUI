local HOST_ADDON = ...

local MAJOR = "LibBitForgeUI-1.0"
-- Present for the test suite alone: a real embedder never sets this, so it
-- reads nil and MINOR is the literal below.
local MINOR = _G.__LibBitForgeUI_TEST_MINOR or 1

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- Published tables are reused and mutated, never replaced. Widgets hold
-- references INTO these: a Font through SetFontObject, a ColorMixin through
-- every skin primitive. Replacing a table on a minor upgrade leaves every
-- widget the old minor built pointing at objects nothing updates again, and
-- it fails silently -- fonts stop tracking SetFonts, colours stop tracking
-- the palette, and nothing errors.
lib.Colors = lib.Colors or {}
lib.Fonts  = lib.Fonts  or {}
lib.Mixins = lib.Mixins or {}
lib.Skin   = lib.Skin   or {}

-- The embed contract. HOST_ADDON is the addon that loaded this file -- the
-- first vararg every .toc-listed file receives -- so the same library serves
-- BitForge and any other embedder without either naming the other. An
-- embedder that vendors it somewhere other than Libs/LibBitForgeUI calls
-- SetMediaPath instead.
local EMBED_SUBPATH = "Libs/LibBitForgeUI"
local mediaPath = HOST_ADDON
    and ("Interface/AddOns/%s/%s/Media"):format(HOST_ADDON, EMBED_SUBPATH)
    or nil

---@param path string  Directory holding the library's textures, no trailing slash.
function lib:SetMediaPath(path)
    mediaPath = path
end

---@param filename string  Relative name without extension, e.g. "checked"
---@return string
function lib.GetMedia(filename)
    if not mediaPath then
        error("LibBitForgeUI: no media path -- the library was loaded without an "
              .. "addon name, so call lib:SetMediaPath() before building widgets", 2)
    end
    return mediaPath .. "/" .. filename
end

local floor = math.floor
local UIParent = UIParent
local CreateColor = CreateColorFromHexString

---@class BitForge.UI.Colors
---@field point colorRGBA
---@field hover colorRGBA
---@field danger colorRGBA
---@field bg colorRGBA
---@field bgDisabled colorRGBA
---@field surface colorRGBA
---@field disabled colorRGBA
---@field text colorRGBA
---@field textHover colorRGBA
---@field textDisabled colorRGBA
---@field edge colorRGBA
---@field edgeHover colorRGBA

-- Populated into the table, never assigned over it: a widget built by an
-- older minor holds a reference to the objects in here. A minor upgrade
-- must still update each object's RGBA in place, or a newer minor's
-- palette never reaches a widget an older minor already built.
local colors = lib.Colors

local function SetColor(key, hex)
    local incoming = CreateColor(hex)
    if colors[key] then
        colors[key]:SetRGBA(incoming:GetRGBA())
    else
        colors[key] = incoming
    end
end

SetColor("point", "FF45B7D1")
SetColor("hover", "FF4B5267")
-- The one warm token, and the suite's only red: a close affordance and a
-- refused save both have to read as "not the rest of this window", while
-- every other entry here is a surface, an edge or a shade of text. The
-- value is BitForge_EUI's own refusal red, promoted rather than invented.
SetColor("danger", "FFFF4D4D")
SetColor("bg", "FF121212")
SetColor("bgDisabled", "7F121212")
SetColor("surface", "FF1E1E1F")
SetColor("disabled", "FF181819")
SetColor("text", "FF888888")
SetColor("textHover", "FFFFFFFF")
SetColor("textDisabled", "FF4A4A4B")
SetColor("edge", "FF000000")
SetColor("edgeHover", "FF2A2A2B")

--- The size of `px` physical pixels in UI units, at UIParent's effective scale.
--- Use it wherever a pixel-perfect value is needed (edgeSize, SetHeight, etc.).
---@param px number?  Defaults to 1.
---@return number
function lib.GetPixel(px)
    return PixelUtil.GetNearestPixelSize(px or 1, UIParent:GetEffectiveScale(), 1)
end

function lib.CreateSeparatorTexture(parent)
    assert(parent and parent.IsObjectType and parent:IsObjectType("Frame"))
    local width = floor(parent:GetWidth() * .85)

    local line = parent:CreateTexture(nil, "ARTWORK")
    PixelUtil.SetSize(line, width, 1)
    line:SetPoint("CENTER")
    line:SetTexture("Interface/Common/UI-TooltipDivider-Transparent")
    local c = lib.Colors.point
    line:SetVertexColor(c.r, c.g, c.b, 0.5)

    return line
end

---@class BitForgeFontDef
---@field file   string|nil   Font file path (defaults to STANDARD_TEXT_FONT)
---@field size   number|nil   Point size
---@field flags  string|nil   Outline flags: "", "OUTLINE", or "THICKOUTLINE"
---@field shadow boolean|nil  True to render a 1-pixel drop shadow
---@field color  colorRGBA|nil  Text color (defaults to white)

---@class BitForgeFontVariants
---@field Small               Font
---@field Normal              Font
---@field Large               Font
---@field Huge                Font
---@field SmallOutline        Font
---@field NormalOutline       Font
---@field LargeOutline        Font
---@field HugeOutline         Font
---@field SmallShadow         Font
---@field NormalShadow        Font
---@field LargeShadow         Font
---@field HugeShadow          Font
---@field SmallOutlineShadow  Font
---@field NormalOutlineShadow Font
---@field LargeOutlineShadow  Font
---@field HugeOutlineShadow   Font

-- Populated into the table, never assigned over it: a widget holds a Font
-- object through SetFontObject, and a replaced object silently stops
-- tracking SetFonts.
local fonts = lib.Fonts

local FONT_SIZES = { Small = 10, Normal = 12, Large = 14, Huge = 20 }
-- CJK fonts generally need to be larger to be legible at the same point size
local isCJK = GetLocale() == "zhCN" or GetLocale() == "zhTW" or GetLocale() == "koKR"
if isCJK then
    for key, value in pairs(FONT_SIZES) do
        FONT_SIZES[key] = value + 1
    end
end

local FONT_COMBINATIONS = {
    { suffix = "",              flags = "",        shadow = false },
    { suffix = "Outline",       flags = "OUTLINE", shadow = false },
    { suffix = "Shadow",        flags = "",        shadow = true },
    { suffix = "OutlineShadow", flags = "OUTLINE", shadow = true },
}

local function CreateFontObject(name, size, flags, shadow)
    local font = CreateFont(name)
    font:SetFont(STANDARD_TEXT_FONT, size, flags)
    font:SetTextColor(1, 1, 1)
    if shadow then
        font:SetShadowOffset(1, -1)
        font:SetShadowColor(0, 0, 0, 1)
    end
    return font
end

for sizeName, sizeVal in pairs(FONT_SIZES) do
    for _, combo in ipairs(FONT_COMBINATIONS) do
        local key = combo.suffix == "" and sizeName or (sizeName .. combo.suffix)
        local font = fonts[key]
        if font then
            font:SetFont(STANDARD_TEXT_FONT, sizeVal, combo.flags)
        else
            fonts[key] = CreateFontObject("BitForgeFont" .. key, sizeVal, combo.flags, combo.shadow)
        end
    end
end

--- Override font settings on one or more variants.  Changes re-apply immediately
--- to existing Font objects.  Keys match BitForgeFontVariants field names.
---@param overrides table<string, BitForgeFontDef>
function lib:SetFonts(overrides)
    for key, def in pairs(overrides) do
        local font = self.Fonts[key]
        if font then
            local curFile, curSize, curFlags = font:GetFont()
            font:SetFont(def.file or curFile, def.size or curSize, def.flags or curFlags)
            local c = def.color
            if c then
                font:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
            end
            if def.shadow == true then
                font:SetShadowOffset(1, -1)
                font:SetShadowColor(0, 0, 0, 1)
            elseif def.shadow == false then
                font:SetShadowOffset(0, 0)
                font:SetShadowColor(0, 0, 0, 0)
            end
        end
    end
end
