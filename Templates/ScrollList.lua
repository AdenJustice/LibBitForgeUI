local PixelUtil = PixelUtil

local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
local metrics = UI.Metrics
local skin = UI.Skin

---@class BitForge.ScrollListOptions
---@field initializer fun(frame: any, data: any)  Fills one row. Required.
---@field tree        boolean?  Tree view rather than linear. Default false.
---@field elementType string?   Frame type each row is built from. Default "Button".
---@field extent      number?   Row height. Default Metrics.row.
---@field indent      number?   Tree indent per depth. Default Metrics.md.
---@field padding     number?   View padding on all four sides. Default Metrics.xs.
---@field spacing     number?   Gap between rows. Default Metrics.xs.

---@class BitForge.ScrollListMixin : Frame
---@field ScrollBox Frame
---@field ScrollBar Frame
---@field View      table
local ScrollListMixin = {}

---@param options BitForge.ScrollListOptions
function ScrollListMixin:OnLoad(options)
    -- A list with no initializer builds rows nothing ever fills: it renders
    -- as empty rows, forever, with no error. Refused here rather than found
    -- in game.
    if type(options.initializer) ~= "function" then
        error("LibBitForgeUI: CreateScrollList needs an options.initializer function", 3)
    end

    local extent  = options.extent  or metrics.row
    local padding = options.padding or metrics.xs
    local spacing = options.spacing or metrics.xs

    local scrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
    -- MinimalScrollBar is an EventFrame, not a Frame (MinimalScrollBar.xml).
    local scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")

    -- The bar keeps its own width, from its template, and the box takes what
    -- is left. This is the split every hand-rolled call site was doing with
    -- a gutter constant of its own.
    PixelUtil.SetPoint(scrollBar, "TOPRIGHT", self, "TOPRIGHT", 0, 0)
    PixelUtil.SetPoint(scrollBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
    PixelUtil.SetPoint(scrollBox, "TOPLEFT", self, "TOPLEFT", 0, 0)
    PixelUtil.SetPoint(scrollBox, "BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -metrics.xs, 0)

    local view
    if options.tree then
        view = CreateScrollBoxListTreeListView(
            options.indent or metrics.md, padding, padding, padding, padding, spacing)
    else
        view = CreateScrollBoxListLinearView(padding, padding, padding, padding, spacing)
    end

    -- Mandatory for a bare frame type: with no template there is no
    -- C_XMLUtil.GetTemplateInfo to measure a row with, and Init raises
    -- (Blizzard_SharedXML/Scroll/ScrollBoxListView.lua).
    view:SetElementExtent(extent)
    view:SetElementInitializer(options.elementType or "Button", options.initializer)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
    -- The reason this factory exists: six of the nine hand-rolled scroll
    -- lists in the suite that vendors this library reached the screen with
    -- an unstyled bar, because styling it was a separate call.
    skin.StyleScrollBar(scrollBar)

    self.ScrollBox, self.ScrollBar, self.View = scrollBox, scrollBar, view

    UI.ApplyMinimum(self, "ScrollList")
end

UI.Mixins.ScrollList = ScrollListMixin

---@param parent  any
---@param options BitForge.ScrollListOptions
---@return BitForge.ScrollListMixin
function UI.CreateScrollList(parent, options)
    ---@class BitForge.ScrollListMixin
    local frame = CreateFrame("Frame", nil, parent)
    Mixin(frame, ScrollListMixin)
    frame:OnLoad(options or {})
    return frame
end
