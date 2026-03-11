---@meta _

---@class BitForgeColor
---@field r number
---@field g number
---@field b number
---@field a number

--- Shared MD colour palette. Widgets read from this table during OnLoad.
--- Modify via LibBitForgeUI:SetPalette() before creating frames.
---@class LibBitForgeUIColors
---@field bg          BitForgeColor  -- Backdrop background (#1E1E1E 95%)
---@field border      BitForgeColor  -- Backdrop border idle (#4C4C4C)
---@field primary     BitForgeColor  -- Primary accent: button normal, focused border (Indigo 500 #3F51B5)
---@field primaryHover BitForgeColor -- Primary hover overlay: button highlight, row hover (Indigo 300 ADD blend)
---@field primaryDark BitForgeColor  -- Primary dark: button pushed (Indigo 700 #303F9F)
---@field disabled    BitForgeColor  -- Disabled state tint (Grey 60%)
---@field text        BitForgeColor  -- Input / label text (white)
