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
