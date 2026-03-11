-- =========================================================
-- LibBitForgeUI
-- Material Design GUI widget library for WoW addons
-- =========================================================

---@class LibBitForgeUI
LibBitForgeUI = LibBitForgeUI or {}
LibBitForgeUI.Mixins = LibBitForgeUI.Mixins or {}

local MEDIA_PATH
do
    local src = debugstack(1, 1, 0):match("AddOns[\\/](.-)LibBitForgeUI")
    if src then
        MEDIA_PATH = "Interface/AddOns/" .. src:gsub("[\\/]", "/") .. "LibBitForgeUI/Media"
    end
end

--- Fetch a media asset from the library's embedded collection. Returns a valid path even if the library is embedded in an addon with no media folder.
--- @param filename string Relative path to the media file, e.g. "Textures/ButtonNormal"
--- @return string path Full path to the media file, or a fallback if the library is not
function LibBitForgeUI.GetMedia(filename)
    return MEDIA_PATH and (MEDIA_PATH .. "/" .. filename) or "Interface/Buttons/WHITE8X8"
end

-- =========================================================
-- Shared MD colour palette (module-level defaults)
-- Widgets copy from this table during OnLoad, so changes
-- made via SetPalette() before frame creation take effect.
-- =========================================================

---@type LibBitForgeUIColors
LibBitForgeUI.Colors = {
    bg           = { r = 0.118, g = 0.118, b = 0.118, a = 0.95 }, -- #1E1E1E 95%
    border       = { r = 0.298, g = 0.298, b = 0.298, a = 1.00 }, -- #4C4C4C
    primary      = { r = 0.251, g = 0.318, b = 0.710, a = 1.00 }, -- Indigo 500  #3F51B5
    primaryHover = { r = 0.361, g = 0.424, b = 0.788, a = 0.30 }, -- Indigo 300 overlay (ADD blend)
    primaryDark  = { r = 0.188, g = 0.247, b = 0.624, a = 1.00 }, -- Indigo 700  #303F9F
    disabled     = { r = 0.451, g = 0.451, b = 0.451, a = 0.60 }, -- Grey 60%
    text         = { r = 1.000, g = 1.000, b = 1.000, a = 1.00 }, -- White
}

--- Override one or more palette tokens. Changes apply to widgets created after this call.
--- Each value must be a table with r, g, b, a fields (partial tables are accepted).
---@param overrides table<string, BitForgeColor>
function LibBitForgeUI:SetPalette(overrides)
    for key, color in pairs(overrides) do
        local dest = self.Colors[key]
        if dest then
            if color.r ~= nil then dest.r = color.r end
            if color.g ~= nil then dest.g = color.g end
            if color.b ~= nil then dest.b = color.b end
            if color.a ~= nil then dest.a = color.a end
        end
    end
end
