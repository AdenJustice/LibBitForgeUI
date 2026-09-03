-- Headless test harness for LibBitForgeUI. A reduced copy of BitForge's own
-- tests/harness.lua -- the widget object model and the assertion helpers,
-- and a LibStub stand-in for the entry point's own registration semantics.
-- Everything about a database, events, locales, slash commands and module
-- loading is BitForge core's concern, not a library's, and stays behind.
local harness = {}

local failures = 0
local checks = 0

-- The client's pixel-to-UI-unit factor at the reference resolution
-- (Blizzard_SharedXML/PixelUtil.lua: 768 / physical screen height), and also
-- UIParent's effective scale at the default UI scale -- the pairing that makes
-- one UI unit exactly one physical pixel. Both readings are wanted, and they
-- are the same number, so it is written once.
local UI_UNIT_FACTOR = 768 / 1080

harness.stub = {}

function harness.resetStubs()
    -- What a FontString answers from GetHeight, keyed by the text it holds.
    -- Headless Lua measures no glyphs, so a wrapped region is one line tall
    -- here however long its sentence is -- see harness.installFontStringBehaviour.
    harness.stub.fontStringHeights = {}
    -- What GetLocale() answers. A default only: nothing here varies it, but
    -- a font table built at file-load time (the CJK size bump) reads it.
    harness.stub.locale = "enUS"
end

--- A LibStub stand-in. The real one is 30 lines and does exactly this; a copy
--- here keeps the suite from depending on a checkout of it.
local libs, minors = {}, {}
_G.LibStub = setmetatable({
    NewLibrary = function(_, major, minor)
        if minors[major] and minors[major] >= minor then return nil end
        minors[major] = minor
        libs[major] = libs[major] or {}
        return libs[major], minors[major]
    end,
    GetLibrary = function(_, major) return libs[major] end,
}, { __call = function(self, major) return libs[major] end })

--- Forget every registration, so a test can load the library twice.
function harness.resetLibStub() libs, minors = {}, {} end

-- Mirrors the MAJOR literal in LibBitForgeUI.lua. Nothing compares the two --
-- a mismatch here would just make every load answer "did not register".
local MAJOR = "LibBitForgeUI-1.0"
local LIBRARY_FILE = "LibBitForgeUI.lua"

-- The hostName a caller last loaded with, so a re-load driven by minor alone
-- (harness.loadLibraryAgain) still passes SetMediaPath the addon identity a
-- real reload would keep -- a real embedder never changes its own name
-- between one load of a file and the next.
local lastHostName

--- Runs LibBitForgeUI.lua with `hostName` as its addon-name vararg, and
--- answers what LibStub now holds for MAJOR -- nil if this run's MINOR was
--- not newer than what a previous run already registered, exactly as
--- LibStub:NewLibrary itself answers nil for that case.
local function runLibraryChunk(hostName)
    local before = minors[MAJOR]
    local chunk = assert(loadfile(LIBRARY_FILE))
    chunk(hostName)
    if minors[MAJOR] == before then return nil end
    return LibStub:GetLibrary(MAJOR)
end

function harness.loadLibrary(hostName)
    lastHostName = hostName
    return runLibraryChunk(hostName)
end

--- Re-runs the library file with MINOR forced to `minor`, through the global
--- override the library file reads as `_G.__LibBitForgeUI_TEST_MINOR` --
--- present for this suite alone; a real embedder never re-loads its own file
--- with a chosen minor.
function harness.loadLibraryAgain(minor)
    _G.__LibBitForgeUI_TEST_MINOR = minor
    local result = runLibraryChunk(lastHostName)
    _G.__LibBitForgeUI_TEST_MINOR = nil
    return result
end

-- Enough of the widget layer to load a UI factory file headlessly and inspect
-- what it built. Not a reimplementation: a frame records and hands back a
-- stub, and only what factory code reasons about rather than merely calls is
-- modelled faithfully -- the MODELLED_* tables below.

local frameMeta = {}

-- The frame state a widget factory branches on, modelled rather than merely
-- recorded. A control asking `if frame:IsShown()` before deciding whether to
-- open or close is a shape this suite's windows take, and a stub answering a
-- truthy method to either sends that branch the wrong way, silently.
--
-- GetParent is here for the same reason one step removed: a script handler
-- passed the region the mouse is over often reaches an ancestor through it,
-- and against a fresh stub that reads nil the handler early-returns.
local MODELLED_STATE = {
    Show       = function(frame) frame.shown = true end,
    Hide       = function(frame) frame.shown = false end,
    SetShown   = function(frame, shown) frame.shown = shown and true or false end,
    IsShown    = function(frame) return frame.shown end,
    IsVisible  = function(frame) return frame.shown end,
    SetMovable = function(frame, movable) frame.movable = movable and true or false end,
    IsMovable  = function(frame) return frame.movable end,
    GetParent  = function(frame) return frame.frameParent end,
    -- The name CreateFrame was given, exactly as the client answers it -- nil
    -- for the anonymous frames most widgets build.
    GetName = function(frame) return frame.frameName end,
    -- The handler SetScript/HookScript filed under frame.scripts, so a test
    -- can drive a click the same way the client would invoke it -- the
    -- generic fallback would hand back a fresh recording stub instead of the
    -- function that was wired up.
    GetScript = function(frame, script) return frame.scripts[script] end,
    -- Every SetPoint call a region has ever received, in call order --
    -- calls.SetPoint above is last-call-wins, which loses every earlier
    -- corner a multi-anchor layout sets (three SetPoint calls fully
    -- constrain a rectangle without a fourth). A text-window layout is the
    -- first to need more than the most recent call: pinning a mismatched
    -- inset between two of a region's own anchors means seeing both of them.
    SetPoint = function(frame, ...)
        frame.points = frame.points or {}
        local point = { ... }
        point.n = select("#", ...)
        frame.points[#frame.points + 1] = point
    end,
    -- The arguments of the most recent SetPoint call, echoed back exactly as
    -- given. A real GetPoint always answers the five-value form (defaulting
    -- relativeTo to the parent and relativePoint to point), but nothing under
    -- test drives a short-form SetPoint and then reads a defaulted value
    -- back, so reproducing that defaulting here would be complexity nothing
    -- exercises.
    GetPoint = function(frame)
        local last = frame.points and frame.points[#frame.points]
        if not last then return nil end
        return last[1], last[2], last[3], last[4], last[5]
    end,
    -- Recorded rather than left to the generic stub: a window reads its own
    -- strata straight back to prove it did not inherit the wrong one, and the
    -- generic fallback would hand back a fresh frame table instead of the
    -- string that was set.
    SetFrameStrata = function(frame, strata) frame.frameStrata = strata end,
    GetFrameStrata = function(frame) return frame.frameStrata end,
    -- Modelled for the same reason: pixel-arithmetic helpers do arithmetic on
    -- the result (frame:GetFrameLevel() - 1), which a fresh recording stub
    -- cannot take part in.
    SetFrameLevel = function(frame, level) frame.frameLevel = level end,
    GetFrameLevel = function(frame) return frame.frameLevel or 0 end,
    -- Modelled rather than recorded because a check button's state is read
    -- back by the code under test -- a GetChecked answering the default frame
    -- stub would be truthy whatever was last set, so an unchecked box would
    -- test as checked and a stale one would test as fresh.
    SetChecked = function(frame, checked) frame.checked = checked and true or false end,
    GetChecked = function(frame) return frame.checked end,
    -- Modelled for the same reason, and the reason bites harder: a recorded
    -- IsEnabled answers a FRESH FRAME TABLE, which is truthy whatever was
    -- last set -- so every assertion that a dependent control greys out would
    -- pass against a widget that never called SetEnabled at all. The
    -- recorder still files calls.SetEnabled before dispatching here, so a
    -- test reading back the argument keeps working.
    SetEnabled = function(frame, enabled) frame.enabled = enabled and true or false end,
    IsEnabled  = function(frame) return frame.enabled end,
    -- Every frame answers a number here, measured or not: pixel-perfect
    -- sizing divides by UIParent's effective scale, and a widget sizing a
    -- stroke from the result would be multiplying the recorder's fresh stub
    -- instead. An unmeasured frame answers the client's own default rather
    -- than a contrived 1, so a test reads the pixel arithmetic the game
    -- would run. A frame given geometry answers what the fixture set, exactly
    -- as GEOMETRY_GETTERS does.
    GetEffectiveScale = function(frame)
        local geometry = frame.geometry
        return geometry and (geometry.scale or 1) or UI_UNIT_FACTOR
    end,
    -- A real client measures rendered glyphs; headless Lua cannot, so a
    -- button label answers zero-width text rather than a fresh recording
    -- stub -- a button that sizes its own width off the label's rendered
    -- width cannot take part in that arithmetic through a table.
    GetStringWidth = function() return 0 end,
    GetUnboundedStringWidth = function() return 0 end,
    -- The native Button/CheckButton text pair. A button mixin's SetText
    -- writes through a Label region directly and defines no GetText of its
    -- own, so a caller reading a button's label back relies on the widget's
    -- built-in GetText, which the real client answers from whatever
    -- SetFontString registered.
    SetFontString = function(frame, fontString) frame.fontString = fontString end,
    GetText = function(frame)
        return frame.fontString and frame.fontString:GetText() or nil
    end,
}

-- StatusBar, which owns state of its own rather than merely recording what it
-- was handed. Kept off MODELLED_STATE and reached only by a frame whose type
-- is "StatusBar", because a plain Frame has no SetValue in the client and a
-- stub that answered one would let a typo through.
--
-- SetValue clamps into the range, as the real widget does. That is not
-- guesswork: Blizzard_SharedXML/SmoothStatusBar.lua clamps its lerp target
-- into the bar's own range before interpolating toward it, which is only
-- necessary because GetValue can never answer outside that range -- an
-- unclamped target would otherwise never satisfy its IsCloseEnough check and
-- the bar would interpolate forever. A stub that stored the raw value would
-- let a bar fed past its maximum pass a test the client would fail.
--
-- Both setters take numbers the client documents Nilable = false, so a nil
-- raises here as it does there. A stub that quietly substituted zero would
-- let a widget forget to guard a maximum it has not learned yet and still
-- pass.
local MODELLED_STATUS_BAR = {
    SetMinMaxValues = function(frame, minimum, maximum)
        assert(type(minimum) == "number" and type(maximum) == "number",
            "Usage: StatusBar:SetMinMaxValues(minValue, maxValue)")
        frame.minValue = minimum
        frame.maxValue = maximum
        frame.value = math.max(minimum, math.min(maximum, frame.value or 0))
    end,
    GetMinMaxValues = function(frame)
        return frame.minValue or 0, frame.maxValue or 1
    end,
    SetValue = function(frame, value)
        assert(type(value) == "number", "Usage: StatusBar:SetValue(value)")
        frame.value = math.max(frame.minValue or 0, math.min(frame.maxValue or 1, value))
    end,
    GetValue = function(frame)
        return frame.value or 0
    end,
    -- The bar's own texture, and the same object on every call -- the client
    -- hands back one region, and a widget that captured it once in OnLoad
    -- would otherwise be holding something no later assertion can reach.
    SetStatusBarTexture = function(frame, asset)
        if type(asset) == "table" then
            frame.statusBarTexture = asset
        else
            frame.statusBarTexture = frame.statusBarTexture or harness.newFrame("Texture")
            frame.statusBarTexture:SetTexture(asset)
        end
        return true
    end,
    GetStatusBarTexture = function(frame)
        frame.statusBarTexture = frame.statusBarTexture or harness.newFrame("Texture")
        return frame.statusBarTexture
    end,
}

-- Real numeric answers for the handful of getters pixel-accurate math
-- actually reads. Left unset, a frame answers the old way: every uppercase
-- call records itself and returns a fresh stub, which is what a test that
-- never looks at real geometry wants. Width/height derive from the same
-- rectangle rather than being stored separately, so the two can never
-- disagree with left/right/top/bottom the way two independent fields could.
local GEOMETRY_GETTERS = {
    GetLeft            = function(geometry) return geometry.left end,
    GetRight           = function(geometry) return geometry.right end,
    GetTop             = function(geometry) return geometry.top end,
    GetBottom          = function(geometry) return geometry.bottom end,
    GetWidth           = function(geometry) return geometry.right - geometry.left end,
    GetHeight          = function(geometry) return geometry.top - geometry.bottom end,
    GetEffectiveScale  = function(geometry) return geometry.scale or 1 end,
}

--- Gives a frame stub a real rectangle, so the getters in GEOMETRY_GETTERS
--- answer real numbers instead of a fresh recording stub. WoW's own
--- convention: right > left, top > bottom.
---@param frame table  a harness.newFrame() stub
---@param geometry table  { left, right, top, bottom, scale }
function harness.setFrameGeometry(frame, geometry)
    frame.geometry = geometry
end

-- Sub-widget references a mixin creates lazily and probes with
-- "if self.Icon then self.Icon:Method() end" before ever assigning one. The
-- generic phantom method below is truthy for any capitalized key, so that
-- check would always pass and then crash indexing a function value -- these
-- read as a genuine nil until the module that owns them assigns a real child.
-- NineSlice/Border/Bg/BG join the set for the same reason: Skin.lua's
-- StripFrameTextures probes each the same way ("if frame.NineSlice then
-- frame.NineSlice:SetAlpha(0) end") before a template has necessarily built
-- one. GetRegions is the same problem one level up -- StripFrameTextures
-- feature-detects it with "not frameObject.GetRegions" before ever calling
-- it, and the phantom method is truthy for any capitalized key, so that
-- check would never see it as absent without landing here too.
local OPTIONAL_WIDGET_FIELDS = {
    Icon = true, Accent = true, Lead = true, Link = true, Footnote = true,
    NineSlice = true, Border = true, Bg = true, BG = true, GetRegions = true,
}

--- A stand-in for a WoW frame or region.
---
--- Any field whose name begins with an uppercase letter resolves to a
--- recording no-op method; every other field reads as nil, exactly as on a
--- bare table. Widget API names are uniformly PascalCase and the state a
--- factory parks on a frame is not, which is what makes the split safe.
---
--- Each call lands in `frame.calls[methodName]` as its argument list, last
--- call wins, and returns a fresh stub parented to the frame it was called
--- on -- so `CreateFontString` yields a region distinct from its parent that
--- still answers GetParent, and a setter chain still loads. SetScript and
--- HookScript additionally file the handler under `frame.scripts[scriptName]`,
--- which is how a test drives a click the same way a real click would.
function harness.newFrame(frameType, frameName, frameParent, frameTemplate)
    local frame = setmetatable({
        frameType     = frameType,
        frameName     = frameName,
        frameParent   = frameParent,
        frameTemplate = frameTemplate,
        calls         = {},
        scripts       = {},
        -- CreateFrame hands back a shown frame; a template marked hidden
        -- calls Hide during its own load, exactly as this stub's callers do.
        shown         = true,
        -- And an immovable one, until something calls SetMovable.
        movable       = false,
        -- An unchecked one, matching a CheckButton fresh from CreateFrame.
        checked       = false,
        -- And an enabled one: every widget type that has the pair starts live.
        enabled       = true,
        -- No rectangle by default: GetLeft/GetRight/GetTop/GetBottom/GetWidth/
        -- GetHeight/GetEffectiveScale fall through to the generic recording
        -- stub below until harness.setFrameGeometry gives this frame real
        -- numbers. See GEOMETRY_GETTERS.
        geometry      = nil,
    }, frameMeta)
    -- A real client resolves CreateFrame's (and any wrapper's) name argument
    -- to a global of the same name; mirror that so a caller can rely on
    -- _G[name] rather than scanning harness.frames.
    if frameName then _G[frameName] = frame end

    -- "EditBox" is modelled here rather than left to the generic recording
    -- fallback: three things about a real one decide what a caller writes and
    -- to which key -- see the doc on harness.installEditBoxBehaviour, which
    -- this frameType check subsumes so that CreateFrame("EditBox", ...) is
    -- modelled exactly the same way whether real widget code calls it or a
    -- stub does.
    if frameType == "EditBox" then
        harness.installEditBoxBehaviour(frame)
    end

    -- Two spellings reach a FontString stub: self:CreateFontString(...)
    -- auto-vivifies through the generic recording fallback below under
    -- "CreateFontString" (the method name that built it), and a fixture that
    -- builds one directly names it "FontString". Both would otherwise hand
    -- SetText/GetText back as unrelated fresh stubs -- a title, a lead line
    -- or a footnote read back with GetText is exactly what a text-window
    -- factory's own test asserts on, and the direct spelling deserves the
    -- same real state.
    if frameType == "CreateFontString" or frameType == "FontString" then
        harness.installFontStringBehaviour(frame)
    end

    -- ScrollingEditBoxTemplate's real OnLoad immediately dereferences
    -- self.ScrollBox.EditBox, and this stub records a template name without
    -- honouring it -- so a bare CreateFrame call naming this template, real
    -- or stubbed, would hand that OnLoad a nil. harness.newFrame exists by
    -- the time this runs: every load happens after the whole harness file,
    -- including this branch, is chunked.
    if frameTemplate == "ScrollingEditBoxTemplate" then
        local editBox = harness.newFrame("EditBox", nil, frame)
        frame.ScrollBox = harness.newFrame("Frame", nil, frame)
        frame.ScrollBox.EditBox = editBox
        function frame:GetEditBox() return editBox end
        function frame:SetText(text) editBox:SetText(text) end
        function frame:GetText() return editBox:GetText() end
        function frame:SetFocus() editBox:SetFocus() end
        function frame:ClearText() editBox:SetText("") end
    end

    return frame
end

frameMeta.__index = function(self, key)
    if type(key) ~= "string" or not key:find("^%u") then return nil end
    if OPTIONAL_WIDGET_FIELDS[key] then return nil end

    local geometryGetter = self.geometry and GEOMETRY_GETTERS[key]
    if geometryGetter then
        return function(frame) return geometryGetter(frame.geometry) end
    end

    local method = function(_, ...)
        local args = { ... }
        args.n = select("#", ...)
        self.calls[key] = args

        if key == "SetScript" and type(args[1]) == "string" then
            -- Replaces the whole chain, hooks included.
            self.scripts[args[1]] = args[2]
        elseif key == "HookScript" and type(args[1]) == "string" then
            -- CHAINS, and the EXISTING handler runs FIRST. Order is not a
            -- detail here: a widget library that hooks OnEscapePressed to
            -- clear focus, and a caller that hooks the same script to
            -- restore a value, produce opposite results depending on which
            -- runs first -- and a stub that let the last hook win would
            -- agree with whichever ordering the caller assumed.
            local existing, hook = self.scripts[args[1]], args[2]
            if existing then
                self.scripts[args[1]] = function(...)
                    existing(...)
                    return hook(...)
                end
            else
                self.scripts[args[1]] = hook
            end
        end

        local modelled = MODELLED_STATE[key]
            or (self.frameType == "StatusBar" and MODELLED_STATUS_BAR[key] or nil)
        if modelled then return modelled(self, ...) end

        return harness.newFrame(key, nil, self)
    end
    rawset(self, key, method)
    return method
end

--- A plain FontString's SetText/GetText, modelled for the same reason as
--- harness.installEditBoxBehaviour: a caller that reads a title, a lead line
--- or a footnote back with GetText would otherwise be handed an unrelated
--- fresh recording stub. Every other FontString call -- SetTextColor,
--- SetJustifyH, SetWordWrap -- is left to the generic recorder.
---
--- Height is the second piece of state, and the one the client measures
--- rather than the one a caller set: a wrapped FontString's rendered height
--- decides where anything anchored to its top edge lands. It reads from
--- harness.stub.fontStringHeights, keyed by the text, and REFUSES text it has
--- no height for rather than answering 0 -- a fixture that forgets to
--- register one would otherwise compute an edge from a height nobody
--- measured and pass silently. SetHeight is deliberately left to the generic
--- recorder, so a test can still assert that a wrapping region was never
--- pinned to a fixed height.
---@param fontString table  a harness.newFrame(...) stub
function harness.installFontStringBehaviour(fontString)
    local text = ""
    fontString.SetText = function(_, value)
        fontString.calls.SetText = { value, n = 1 }
        text = value ~= nil and tostring(value) or ""
    end
    fontString.GetText = function() return text end
    fontString.GetHeight = function()
        -- A field stands in FRONT of frameMeta.__index, so GEOMETRY_GETTERS
        -- never gets the chance to answer here. Dispatch to it by hand: a
        -- font string given harness.setFrameGeometry would otherwise take
        -- GetWidth and GetLeft from the rectangle and its height from
        -- somewhere else, and the whole point of deriving every edge from
        -- one rectangle is that no two of them can disagree.
        if fontString.geometry then
            return GEOMETRY_GETTERS.GetHeight(fontString.geometry)
        end
        local height = harness.stub.fontStringHeights[text]
        if height then return height end
        -- Empty text really is nothing tall. Text without a registered
        -- height is a fixture that never took the measurement, and 0 is a
        -- plausible enough answer to pass an assertion while meaning nothing.
        if text ~= "" then
            error(("no rendered height registered for the FontString text %q --"
                .. " set harness.stub.fontStringHeights for it before a layout"
                .. " reads its edges"):format(text), 2)
        end
        return 0
    end
end

--- A widget factory's EditBoxMixin:OnLoad, modelled rather than stubbed.
--- Three things about a real edit box decide what a caller writes and to
--- which key, and none of them is visible in a recording no-op:
---
---   * OnLoad HookScripts OnEnterPressed and OnEscapePressed to ClearFocus,
---     and a hook runs AFTER the handler already installed -- so a caller's
---     own hook on those scripts runs once focus is already gone;
---   * clearing focus fires OnEditFocusLost, which is where a form commits;
---   * a box hidden or disabled while focused loses focus the same way,
---     which is how a commit can arrive after the pane has moved on.
---
--- Text is real state: a caller that reads GetText back off a frame stub
--- would be handed a table. Programmatic SetText firing OnTextChanged is
--- deliberately NOT modelled -- modelling it would fire a search box's
--- refresh from its own repaint.
---
--- Applied by harness.newFrame itself whenever frameType is "EditBox", so a
--- real factory's own CreateFrame("EditBox", ...) call is modelled the same
--- way a stub-table-built one is.
---@param editBox table  a harness.newFrame("EditBox", ...) stub
function harness.installEditBoxBehaviour(editBox)
    local text = ""
    local focused = false

    -- The overrides below stand in front of the recording metatable, so each
    -- files its own call the way that metatable would; a test asserting on
    -- SetEnabled or SetShown must not stop seeing it.
    local function record(name, ...)
        local args = { ... }
        args.n = select("#", ...)
        editBox.calls[name] = args
    end

    local function fire(script)
        local handler = editBox.scripts[script]
        if handler then handler(editBox) end
    end

    local function loseFocus()
        if not focused then return end
        focused = false
        fire("OnEditFocusLost")
    end

    editBox.SetText = function(_, value)
        record("SetText", value)
        text = value ~= nil and tostring(value) or ""
    end
    editBox.GetText = function() return text end
    editBox.HasFocus = function() return focused end

    editBox.SetFocus = function()
        record("SetFocus")
        if focused then return end
        focused = true
        fire("OnEditFocusGained")
    end

    editBox.ClearFocus = function()
        record("ClearFocus")
        loseFocus()
    end

    editBox.Hide = function()
        record("Hide")
        editBox.shown = false
        loseFocus()
    end

    editBox.SetShown = function(_, shown)
        record("SetShown", shown)
        editBox.shown = shown and true or false
        if not editBox.shown then loseFocus() end
    end

    editBox.SetEnabled = function(_, enabled)
        record("SetEnabled", enabled)
        editBox.enabled = enabled and true or false
        if not enabled then loseFocus() end
    end

    -- Installed exactly as a real EditBox mixin installs them, so a caller's
    -- own hooks chain behind these rather than in front of them. The two
    -- focus handlers only repaint a border; they are here for their place in
    -- the chain, not for the colour.
    editBox:HookScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor() end)
    editBox:HookScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor() end)
    editBox:HookScript("OnEnterPressed", function(self) self:ClearFocus() end)
    editBox:HookScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- SetScript, and with the mixin's own empty default: a caller overriding
    -- OnTextChanged as a plain field would never be seen, which is why
    -- widget code in this suite uses SetScript for it instead.
    editBox:SetScript("OnTextChanged", function() end)
end

function harness.installGlobals()
    -- Every frame CreateFrame hands out, in creation order -- for
    -- descendant-walking helpers a later task may add, the way BitForge's own
    -- harness.descendantsOf reads this same table.
    harness.frames = {}
    _G.CreateFrame = function(frameType, frameName, frameParent, frameTemplate)
        local frame = harness.newFrame(frameType, frameName, frameParent, frameTemplate)
        harness.frames[#harness.frames + 1] = frame
        return frame
    end
    _G.UIParent = harness.newFrame("Frame", "UIParent")

    -- PixelUtil's setters take the region as their first argument and snap
    -- the result to whole pixels. The stub forwards to the region's own
    -- method and skips the snapping, so a region anchored through PixelUtil
    -- records the call on itself exactly as a bare SetPoint would.
    --
    -- GetNearestPixelSize is the exception and is
    -- Blizzard_SharedXML/PixelUtil.lua verbatim: it takes numbers rather than
    -- a region, so the forwarder below answers nil for it, and a caller
    -- multiplying that nil raises.
    _G.PixelUtil = setmetatable({
        GetPixelToUIUnitFactor = function() return UI_UNIT_FACTOR end,
        GetNearestPixelSize = function(uiUnitSize, layoutScale, minPixels)
            if uiUnitSize == 0 and (not minPixels or minPixels == 0) then
                return 0
            end

            local numPixels = math.floor((uiUnitSize * layoutScale) / UI_UNIT_FACTOR + 0.5)
            if minPixels then
                if uiUnitSize < 0.0 then
                    if numPixels > -minPixels then numPixels = -minPixels end
                elseif numPixels < minPixels then
                    numPixels = minPixels
                end
            end

            return numPixels * UI_UNIT_FACTOR / layoutScale
        end,
    }, {
        __index = function(_, key)
            if type(key) ~= "string" or not key:find("^%u") then return nil end

            return function(region, ...)
                if type(region) == "table" then
                    return region[key](region, ...)
                end
            end
        end,
    })

    -- Blizzard_SharedXMLBase/Mixin.lua.
    _G.Mixin = function(object, ...)
        for index = 1, select("#", ...) do
            for key, value in pairs((select(index, ...))) do
                object[key] = value
            end
        end
        return object
    end

    -- Blizzard_SharedXMLBase/Mixin.lua's CreateFromMixins: a fresh table
    -- built from one or more mixins, rather than copying onto an existing
    -- frame the way Mixin above does.
    _G.CreateFromMixins = function(...)
        local object = {}
        for index = 1, select("#", ...) do
            for key, value in pairs((select(index, ...))) do
                object[key] = value
            end
        end
        return object
    end

    -- A default only. A font table built at file-load time (the CJK size
    -- bump) is the only reader; nothing here varies it yet.
    _G.GetLocale = function() return harness.stub.locale end

    -- Font objects are built at file-read time, so these have to answer for
    -- a widget factory file to load at all. The object is a recording stub
    -- like any other frame region.
    _G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    _G.CreateFont = function(name) return harness.newFrame("Font", name) end

    -- ColorMixin, trimmed to the three methods this suite's widgets actually
    -- call: SetRGBA builds it, GetRGB/GetRGBA read it back. The real mixin
    -- also carries hex-generating and text-wrapping methods; nothing under
    -- test reaches them, so they and the C_ColorUtil they delegate to are
    -- left out rather than carried unused.
    local ColorMixin = {}

    function ColorMixin:SetRGBA(r, g, b, a)
        self.r, self.g, self.b = r, g, b
        self.a = a or 1
    end

    function ColorMixin:GetRGB() return self.r, self.g, self.b end

    function ColorMixin:GetRGBA() return self.r, self.g, self.b, self.a end

    _G.CreateColor = function(r, g, b, a)
        local color = {}
        for key, value in pairs(ColorMixin) do color[key] = value end
        color:SetRGBA(r, g, b, a)
        return color
    end

    -- ColorUtil.lua. "AARRGGBB", alpha first -- a palette built from hex
    -- literals at file-read time cannot load headlessly without it.
    _G.CreateColorFromHexString = function(hexString)
        local a = tonumber(hexString:sub(1, 2), 16) / 255
        local r = tonumber(hexString:sub(3, 4), 16) / 255
        local g = tonumber(hexString:sub(5, 6), 16) / 255
        local b = tonumber(hexString:sub(7, 8), 16) / 255
        return _G.CreateColor(r, g, b, a)
    end

    -- Blizzard_SharedXML/Backdrop.lua. A scrolling edit box's mixin is the
    -- only caller, and only for OnBackdropLoaded -- which the real mixin
    -- itself no-ops whenever backdropInfo is still nil, exactly the state
    -- the inner edit box is in at that call site.
    _G.BackdropTemplateMixin = {
        OnBackdropLoaded = function() end,
    }

    -- Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua, verbatim. A
    -- close button borrows this one part of Blizzard's own close button: a
    -- screen reader announces the button through it, and a copy of the
    -- method would answer a string that had drifted from the client's.
    _G.NARRATION_OBJECT_CLOSE_BUTTON = "Close"
    _G.UIPanelCloseButtonNarrationMixin = {
        NarrationGetName = function()
            return _G.NARRATION_OBJECT_CLOSE_BUTTON
        end,
    }

    -- Blizzard_Menu/DropdownButton.lua, as much of it as a dropdown widget
    -- needs to load and be driven. self.menu is the field the real mixin
    -- sets on open and clears on close, and IsMenuOpen is the only thing a
    -- dropdown's own scripts read it through, so those three move together
    -- here as they do there.
    _G.DropdownButtonMixin = {
        OnLoad_Intrinsic = function(self)
            self:EnableMouseWheel(false)
            self:RegisterForMouse("LeftButtonDown", "LeftButtonUp")
        end,
        OnMouseDown_Intrinsic = function() end,
        OnMouseWheel_Intrinsic = function() end,
        OnMenuOpened = function(self, menu) self.menu = menu end,
        OnMenuClosed = function(self) self.menu = nil end,
        IsMenuOpen = function(self) return self.menu ~= nil end,
        SetupMenu = function(self, generator) self.menuGenerator = generator end,
        GenerateMenu = function() end,
        GetMenuDescription = function(self) return self.menuDescription end,
        -- What the real CollectSelectionData answers for a dropdown that has
        -- no menu description yet, which is every dropdown at OnLoad.
        CollectSelectionData = function() return nil, nil, {} end,
    }

    -- UIParentPanelManager.lua:20. A list of frame NAMES, which is why a
    -- frame that wants Escape-to-close needs a global one.
    _G.UISpecialFrames = {}
end

function harness.newNamespace()
    return { enum = {}, locale = {}, model = {}, view = {}, control = {} }
end

--- Loads a widget-factory file with the varargs a .toc-listed file receives:
--- (addonName, ns). addonName is required: no host is common enough to
--- default to, and a default misnames every file loaded without one, silently.
function harness.loadModule(path, ns, addonName)
    local chunk = assert(loadfile(path))
    return chunk(assert(addonName, "harness.loadModule: addonName is required"), ns)
end

local function fail(label, detail)
    failures = failures + 1
    io.write(("  FAIL  %s\n        %s\n"):format(label, detail))
end

function harness.assert(condition, label)
    checks = checks + 1
    if not condition then
        fail(label, "expected a truthy value")
    end
end

function harness.assertEqual(actual, expected, label)
    checks = checks + 1
    if actual ~= expected then
        fail(label, ("expected %s, got %s"):format(tostring(expected), tostring(actual)))
    end
end

function harness.assertDeepEqual(actual, expected, label)
    checks = checks + 1
    local function deep(a, b)
        if a == b then return true end
        if type(a) ~= "table" or type(b) ~= "table" then return false end
        for key, value in pairs(a) do
            if not deep(value, b[key]) then return false end
        end
        for key in pairs(b) do
            if a[key] == nil then return false end
        end
        return true
    end
    if not deep(actual, expected) then
        fail(label, "tables differ")
    end
end

function harness.report()
    io.write(("\n%d checks, %d failures\n"):format(checks, failures))
    os.exit(failures == 0 and 0 or 1)
end

--- Alias for harness.report -- this library's own suite (test_library.lua)
--- uses this name, while a widget test inherited from BitForge in a later
--- task calls harness.report() instead. Both finish the same run.
harness.done = harness.report

harness.resetStubs()
harness.installGlobals()

return harness
