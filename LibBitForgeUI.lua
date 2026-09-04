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
lib.Colors   = lib.Colors   or {}
lib.Fonts    = lib.Fonts    or {}
lib.Mixins   = lib.Mixins   or {}
lib.Skin     = lib.Skin     or {}
lib.Metrics  = lib.Metrics  or {}
lib.Minimums = lib.Minimums or {}

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
---@field success colorRGBA
---@field highlight colorRGBA
---@field bg colorRGBA
---@field bgDisabled colorRGBA
---@field surface colorRGBA
---@field raised colorRGBA
---@field disabled colorRGBA
---@field text colorRGBA
---@field textMuted colorRGBA
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
-- FF4D4D on the new `raised` measures 4.21:1, under the 4.5:1 AA floor --
-- and a refusal message inside an input row is exactly that pairing.
-- FF5F5F clears it at 4.63:1 with the hue intact.
SetColor("danger", "FFFF5F5F")
SetColor("success", "FF4ADE80")
SetColor("highlight", "FFFFC93C")
SetColor("bg", "FF0E0F12")
SetColor("bgDisabled", "7F0E0F12")
SetColor("surface", "FF1B1D23")
SetColor("raised", "FF2A2D35")
SetColor("disabled", "FF141519")
SetColor("text", "FFE4E6EB")
SetColor("textMuted", "FF9AA0AB")
SetColor("textHover", "FFFFFFFF")
SetColor("textDisabled", "FF5A5E68")
-- Inverts from darker-than-surface to lighter than it -- the single largest
-- visual change in the spec, and the whole point of the ladder: a border
-- reads as a lift, not a crack.
SetColor("edge", "FF32363F")
SetColor("edgeHover", "FF454A56")

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
        if not font then
            error(("LibBitForgeUI: unknown font variant '%s'"):format(tostring(key)), 2)
        end
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

---@class BitForge.UI.Metrics
--- The spacing scale.
---@field xs number            4
---@field sm number            8
---@field md number            12
---@field lg number            16
---@field xl number            24
---@field control number       32  Button, Dropdown, EditBox, title bar
---@field row number           28  CheckButton row, text-window link
---@field controlSmall number  24  CloseButton, Slider, icon-only CheckButton, footer button
--- Widget defaults and ornaments. Not spacing -- they are here because no
--- literal may reach a sizing call under Templates/, which tests/
--- test_metrics_discipline.lua enforces.
---@field defaultWidth number  200  Bar, Slider, EditBox, ScrollEditBox
---@field buttonWidth number   120  Button, text-window footer button
---@field dropdownWidth number 160
---@field scrollHeight number  120  ScrollEditBox
---@field windowWidth number   600  TextWindow
---@field windowHeight number  460  TextWindow
--- `icon` is the size a button's icon is BUILT at, not the size it keeps:
--- Buttons.lua's updateLayout re-derives it from the button's own shorter side
--- (min(w, h) - 2 * xs, so 24 on a default button) the first time the button is
--- laid out. Two places decide that region's size and this token is only one.
---@field icon number          16   a button icon at build time
---@field tick number          20   checkbutton tick texture
---@field arrow number         14   dropdown arrow
---@field thumbWidth number    6    slider thumb
---@field thumbHeight number   18   slider thumb

-- Assigned unconditionally, never `or`-defaulted. The table is reused across a
-- minor upgrade so an embedder's reference survives; the VALUES in it must not,
-- or a newer minor's scale never reaches anyone who loaded an older one.
local metrics = lib.Metrics
metrics.xs           = 4
metrics.sm           = 8
metrics.md           = 12
metrics.lg           = 16
metrics.xl           = 24
metrics.control      = 32
metrics.row          = 28
metrics.controlSmall = 24

metrics.defaultWidth  = 200
metrics.buttonWidth   = 120
metrics.dropdownWidth = 160
metrics.scrollHeight  = 120
metrics.windowWidth   = 600
metrics.windowHeight  = 460
metrics.icon          = 16
metrics.tick          = 20
metrics.arrow         = 14
metrics.thumbWidth    = 6
metrics.thumbHeight   = 18

--- Retune the scale. Every key must already exist -- a host that misspells one
--- gets an error rather than a silent no-op.
---@param overrides table<string, number>
function lib:SetMetrics(overrides)
    for key, value in pairs(overrides) do
        if self.Metrics[key] == nil then
            error(("LibBitForgeUI: unknown metric '%s'"):format(tostring(key)), 2)
        end
        self.Metrics[key] = value
    end
end

---@class BitForge.UI.Minimum
---@field minWidth number
---@field minHeight number

-- Keyed by mixin name, which is the factory name without its Create prefix.
-- tests/test_minimums.lua asserts that correspondence in both directions: a
-- widget added with no floor here, or a floor left behind by a widget that was
-- removed, is exactly the kind of hand-maintained list that goes wrong quietly.
--
-- Assigned unconditionally, for the reason lib.Metrics states.
local minimums = lib.Minimums
local function SetMinimum(key, minWidth, minHeight)
    local existing = minimums[key]
    if existing then
        existing.minWidth, existing.minHeight = minWidth, minHeight
    else
        minimums[key] = { minWidth = minWidth, minHeight = minHeight }
    end
end

SetMinimum("Bar",           40,  4)
SetMinimum("Button",        64, 24)
SetMinimum("CheckButton",   24, 24)
SetMinimum("CloseButton",   16, 16)
SetMinimum("Dropdown",      96, 24)
SetMinimum("EditBox",       80, 24)
SetMinimum("Frame",        160, 96)
SetMinimum("ScrollEditBox", 120, 48)
SetMinimum("Slider",        80, 20)
SetMinimum("TextWindow",   320, 240)

--- Raise `frame` to its widget's floor on whichever axis is under it.
---
--- Called by every factory AFTER it sizes its widget, which is what makes the
--- floor independent of lib.Metrics: a host that retunes the scale downward
--- still cannot punch through here.
---@param frame table   The widget being built.
---@param key string    A lib.Minimums key -- the mixin name.
function lib.ApplyMinimum(frame, key)
    -- Not named `floor`: that local already means math.floor at file scope,
    -- and wowlua_ls flags the shadow.
    local minimum = lib.Minimums[key]
    if not minimum then
        error(("LibBitForgeUI: no minimum registered for '%s'"):format(tostring(key)), 2)
    end

    local width, height = frame:GetWidth(), frame:GetHeight()
    if width < minimum.minWidth or height < minimum.minHeight then
        frame:SetSize(
            width  < minimum.minWidth  and minimum.minWidth  or width,
            height < minimum.minHeight and minimum.minHeight or height)
    end
end
