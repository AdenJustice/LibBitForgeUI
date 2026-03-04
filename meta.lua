---@meta _

---@class LibBitForgeUI
---@field Colors                     LibBitForgeUIColors
---@field SetPalette                 fun(self: LibBitForgeUI, overrides: table<string, BitForgeColor>)
---@field FrameMixin                 LibBitForgeUI.FrameMixin
---@field TitledFrameMixin           LibBitForgeUI.TitledFrameMixin
---@field ButtonMixin                LibBitForgeUI.ButtonMixin
---@field CheckboxMixin              LibBitForgeUI.CheckboxMixin
---@field ScrollElementAsButtonMixin LibBitForgeUI.ScrollElementAsButtonMixin
---@field ScrollElementAsCheckMixin  LibBitForgeUI.ScrollElementAsCheckMixin
---@field EditBoxBaseMixin           LibBitForgeUI.EditBoxBaseMixin
---@field EditBoxMixin               LibBitForgeUI.EditBoxMixin
---@field MultiLineEditBoxMixin      LibBitForgeUI.MultiLineEditBoxMixin
---@field DropdownMixin              LibBitForgeUI.DropdownMixin
---@field TabButtonMixin             LibBitForgeUI.TabButtonMixin
---@field TabBarMixin                LibBitForgeUI.TabBarMixin
---@field SliderMixin                LibBitForgeUI.SliderMixin

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

---@class LibBitForgeUI.FrameMixin: Frame, BackdropTemplateMixin

---@class LibBitForgeUI.TitledFrameMixin: LibBitForgeUI.FrameMixin
---@field SetTitle fun(self: LibBitForgeUI.TitledFrameMixin, text: string)

---@class LibBitForgeUI.ButtonMixin: Button, LibBitForgeUI.FrameMixin

---@class LibBitForgeUI.CheckboxMixin: CheckButton
---@field OnLoad fun(self: LibBitForgeUI.CheckboxMixin)
---@field SyncColor fun(self: LibBitForgeUI.CheckboxMixin)

---@class LibBitForgeUI.ScrollElementAsButtonMixin: LibBitForgeUI.ButtonMixin
---@field Init fun(self: LibBitForgeUI.ScrollElementAsButtonMixin, data: any)

---@class LibBitForgeUI.ScrollElementAsCheckMixin: LibBitForgeUI.CheckboxMixin
---@field Init fun(self: LibBitForgeUI.ScrollElementAsCheckMixin, data: any)

---@class LibBitForgeUI.EditBoxBaseMixin: BackdropTemplateMixin

---@class LibBitForgeUI.EditBoxMixin: EditBox, LibBitForgeUI.EditBoxBaseMixin
---@field SetBorderColor fun(self: LibBitForgeUI.EditBoxMixin, r: number, g: number, b: number, a?: number)
---@field SetFocusBorderColor fun(self: LibBitForgeUI.EditBoxMixin, r: number, g: number, b: number, a?: number)
---@field SetInputTextColor fun(self: LibBitForgeUI.EditBoxMixin, r: number, g: number, b: number, a?: number)

---@class LibBitForgeUI.MultiLineEditBoxMixin: Frame, BackdropTemplateMixin, LibBitForgeUI.EditBoxBaseMixin
---@field ScrollFrame ScrollFrame
---@field EditBox     EditBox

---@class BitForgeDropdownHeader: Button, BackdropTemplateMixin
---@field Text    FontString
---@field Chevron FontString

---@class BitForgeDropdownList: Frame, BackdropTemplateMixin

---@class LibBitForgeUI.DropdownMixin: Frame, BackdropTemplateMixin
---@field Header BitForgeDropdownHeader
---@field List   BitForgeDropdownList
---@field SetItems fun(self: LibBitForgeUI.DropdownMixin, items: { value: any, label: string }[])
---@field SetPlaceholder fun(self: LibBitForgeUI.DropdownMixin, text: string)
---@field GetValue fun(self: LibBitForgeUI.DropdownMixin): any
---@field SetValue fun(self: LibBitForgeUI.DropdownMixin, value: any)
---@field SetOnChange fun(self: LibBitForgeUI.DropdownMixin, fn: fun(value: any))

---@class BitForgeTabButton: CheckButton
---@field Bg            Texture
---@field BorderTop     Texture
---@field BorderBottom  Texture
---@field BorderLeft    Texture
---@field BorderRight   Texture
---@field Indicator     Texture
---@field Label         FontString

---@class LibBitForgeUI.TabButtonMixin: CheckButton
---@field Bg           Texture
---@field BorderTop    Texture
---@field BorderBottom Texture
---@field BorderLeft   Texture
---@field BorderRight  Texture
---@field Indicator    Texture
---@field Label        FontString
---@field SetTabPosition fun(self: LibBitForgeUI.TabButtonMixin, pos: "bottom"|"top"|"left"|"right")

---@class LibBitForgeUI.TabBarMixin: Frame
---@field AddTab fun(self: LibBitForgeUI.TabBarMixin, id: any, label: string): BitForgeTabButton
---@field SetPosition fun(self: LibBitForgeUI.TabBarMixin, pos: "bottom"|"top"|"left"|"right")
---@field SetSelectedTab fun(self: LibBitForgeUI.TabBarMixin, id: any)
---@field SetOnChange fun(self: LibBitForgeUI.TabBarMixin, fn: fun(id: any))
---@field SetTabSize fun(self: LibBitForgeUI.TabBarMixin, w: number, h: number)

---@class LibBitForgeUI.SliderMixin: Slider
---@field Track   Texture  -- Thin grey track bar
---@field Fill    Texture  -- Primary-coloured fill (left portion)
---@field Thumb   Texture  -- Tall-rectangle thumb
---@field private _thumbMinW  number
---@field private _thumbRatio number
---@field private _thumbW     number
---@field private _onChange   fun(value: number)?
---@field SetOnChange fun(self: LibBitForgeUI.SliderMixin, fn: fun(value: number))
---@field SetThumbMinWidth fun(self: LibBitForgeUI.SliderMixin, minW: number)
---@field SetThumbRatio fun(self: LibBitForgeUI.SliderMixin, ratio: number)
