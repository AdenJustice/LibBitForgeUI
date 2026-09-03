local ipairs = ipairs
local tinsert = table.insert

local PixelUtil = PixelUtil

local MAJOR = "LibBitForgeUI-1.0"
local lib = LibStub and LibStub:GetLibrary(MAJOR, true)
if not lib then return end

local UI = lib
---@type BitForge.UI.Colors
local colors = UI.Colors

local DEFAULT_WIDTH = 560
local DEFAULT_HEIGHT = 440
local TITLE_HEIGHT = 32
local PADDING = 12
local LINK_HEIGHT = 26
local BUTTON_HEIGHT = 24
local BUTTON_WIDTH = 120

---@class BitForge.TextWindowMixin : BitForge.FrameMixin
---@field Body      BitForge.ScrollEditBoxMixin
---@field Buttons   BitForge.ButtonMixin[]
---@field Lead      FontString?
---@field Link      BitForge.EditBoxMixin?
---@field Footnote  FontString?
local TextWindowMixin = {}

---@param text string
function TextWindowMixin:SetText(text)
    self.Body:SetText(text or "")
end

--- Replaces the line under the box.
---
--- Errors rather than no-ops when the window was created without one: the
--- layout left no room for it, so drawing nothing would be a silent loss of
--- whatever the caller meant to say.
---@param text string
function TextWindowMixin:SetFootnote(text)
    if not self.Footnote then
        error("Attempted to set a footnote on a window created without one.", 2)
    end
    self.Footnote:SetText(text)
end

--- Focuses the box and selects all of it.
---
--- As far as any copy affordance in WoW can go: the game cannot write to the
--- clipboard, so this selects and the player presses Ctrl+C. A caller that
--- labels a button for this must name the selection, not the copy.
function TextWindowMixin:SelectAll()
    self.Body:SetFocus()
    self.Body:GetEditBox():HighlightText()
end

--- Shows the window. Focus-and-select on top of that is opt-in
--- (options.selectOnOpen): right for a report a player is about to copy out of,
--- wrong for a window that can open on its own at login and would otherwise
--- steal focus and swallow keybinds.
function TextWindowMixin:Open()
    self:Show()
    if self.selectOnOpen then
        self:SelectAll()
    end
end

UI.Mixins.TextWindow = TextWindowMixin

---@class BitForge.TextWindowOptions
---@field title         string    window title
---@field lead          string?   one line above the text box
---@field link          string?   a selectable single-line URL under the lead
---@field footnote      string?   one line under the text box
---@field width         number?   defaults to 560
---@field height        number?   defaults to 440
---@field name          string?   global frame name, so UISpecialFrames closes it on Escape
---@field buttons       table?    array of { text = string, onClick = fun(window) }
---@field selectOnOpen  boolean?  select the body's text on Open(); defaults to false

--- A titled window holding a lead line, an optional selectable link, a
--- scrolling text box, an optional footnote and a row of buttons.
---
--- Everything past the title is optional and absent parts occupy no space, so
--- one widget serves a report window with a URL and a footnote and a release-
--- notes window with neither.
---@param options BitForge.TextWindowOptions
---@return BitForge.TextWindowMixin
function UI.CreateTextWindow(options)
    local frame = UI.CreateFrame(UIParent, options.title, options.name)
    Mixin(frame, TextWindowMixin)
    frame.selectOnOpen = options.selectOnOpen and true or false

    frame:SetSize(options.width or DEFAULT_WIDTH, options.height or DEFAULT_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    UI.ApplyShadow(frame)

    -- CreateCloseButton ships no OnClick deliberately, so every window says what
    -- its X does.
    local close = UI.CreateCloseButton(frame)
    PixelUtil.SetPoint(close, "TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Escape closes a plain frame only if the client knows its name. Guarded
    -- against a second CreateTextWindow naming the same frame: UISpecialFrames
    -- has no dedupe of its own, and a duplicate entry is a duplicate close.
    if options.name then
        local alreadyRegistered = false
        for _, name in ipairs(UISpecialFrames) do
            if name == options.name then
                alreadyRegistered = true
                break
            end
        end
        if not alreadyRegistered then
            tinsert(UISpecialFrames, options.name)
        end
    end

    -- anchorX carries the horizontal inset for whichever point `anchor` is:
    -- PADDING off the frame itself, or 0 once anchored to a lead/link that is
    -- already inset by PADDING -- reusing PADDING there would double it.
    local anchor, anchorPoint, anchorX, anchorY =
        frame, "TOPLEFT", PADDING, -(TITLE_HEIGHT + PADDING)

    if options.lead then
        local lead = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalShadow")
        lead:SetJustifyH("LEFT")
        -- No fixed height: SetWordWrap(true) only wraps into space the
        -- FontString is free to grow into, and a height pinned to one line
        -- would clip the second.
        lead:SetWordWrap(true)
        lead:SetTextColor(colors.text:GetRGB())
        lead:SetText(options.lead)
        PixelUtil.SetPoint(lead, "TOPLEFT", anchor, anchorPoint, anchorX, anchorY)
        PixelUtil.SetPoint(lead, "TOPRIGHT", frame, "TOPRIGHT", -PADDING, anchorY)
        frame.Lead = lead
        anchor, anchorPoint, anchorX, anchorY = lead, "BOTTOMLEFT", 0, -4
    end

    if options.link then
        local link = UI.CreateEditBox(frame)
        link:SetHeight(LINK_HEIGHT)
        link:SetText(options.link)
        link:SetCursorPosition(0)
        PixelUtil.SetPoint(link, "TOPLEFT", anchor, anchorPoint, anchorX, anchorY)
        PixelUtil.SetPoint(link, "TOPRIGHT", frame, "TOPRIGHT", -PADDING, anchorY)
        frame.Link = link
        anchor, anchorPoint, anchorX, anchorY = link, "BOTTOMLEFT", 0, -PADDING
    end

    frame.Buttons = {}
    -- A BOTTOM* anchor's y grows inward, toward the frame's centre, so the
    -- no-buttons case starts at the same positive PADDING the buttons branch
    -- below computes for itself -- a negative value here draws outside the
    -- frame.
    local bottom = PADDING
    if options.buttons and #options.buttons > 0 then
        local previous
        for _, spec in ipairs(options.buttons) do
            local button = UI.CreateButton(nil, frame, nil, spec.text)
            button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
            button:SetScript("OnClick", function() spec.onClick(frame) end)
            if previous then
                PixelUtil.SetPoint(button, "RIGHT", previous, "LEFT", -PADDING, 0)
            else
                PixelUtil.SetPoint(button, "BOTTOMRIGHT", frame, "BOTTOMRIGHT",
                    -PADDING, PADDING)
            end
            previous = button
            frame.Buttons[#frame.Buttons + 1] = button
        end
        bottom = PADDING + BUTTON_HEIGHT + PADDING
    end

    -- The mirror of the top chain, and bottomX carries the same horizontal
    -- inset rule: PADDING off the frame itself, 0 once anchored to a footnote
    -- already inset by PADDING.
    local bottomAnchor, bottomPoint, bottomX, bottomY = frame, "BOTTOMLEFT", PADDING, bottom

    if options.footnote then
        local footnote = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalShadow")
        footnote:SetJustifyH("LEFT")
        -- No fixed height, for the same reason the lead has none -- and the
        -- body's bottom chains off this region's own top rather than off a
        -- reserved constant. A BOTTOM*-anchored FontString grows UPWARD as it
        -- wraps, so a constant that guesses one line's worth leaves the rest of
        -- the sentence behind the body's opaque backdrop rather than pushing
        -- the body up. Every privacy sentence this window carries runs to two
        -- lines or more.
        footnote:SetWordWrap(true)
        footnote:SetTextColor(colors.text:GetRGB())
        footnote:SetText(options.footnote)
        PixelUtil.SetPoint(footnote, "BOTTOMLEFT", frame, "BOTTOMLEFT", PADDING, bottom)
        PixelUtil.SetPoint(footnote, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, bottom)
        frame.Footnote = footnote
        bottomAnchor, bottomPoint, bottomX, bottomY = footnote, "TOPLEFT", 0, PADDING
    end

    local body = UI.CreateScrollEditBox(frame)
    PixelUtil.SetPoint(body, "TOPLEFT", anchor, anchorPoint, anchorX, anchorY)
    PixelUtil.SetPoint(body, "TOPRIGHT", frame, "TOPRIGHT", -PADDING, anchorY)
    PixelUtil.SetPoint(body, "BOTTOMLEFT", bottomAnchor, bottomPoint, bottomX, bottomY)
    frame.Body = body

    return frame
end
