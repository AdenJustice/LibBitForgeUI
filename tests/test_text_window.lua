-- The shared text window: a titled frame holding a lead line, an optional
-- selectable link, a scrolling text box, an optional footnote and a button row.
--
-- Two things open one: the item report (#256) and the release notes (#275). It
-- is a widget rather than either of those, so it knows nothing about items,
-- versions or URLs -- everything it shows arrives as an option.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")
dofile("Templates/Frame.lua")
dofile("Templates/Buttons.lua")
dofile("Templates/CloseButton.lua")
dofile("Templates/EditBox.lua")
dofile("Templates/TextWindow.lua")

local UI = lib

local clicked = 0
local window = UI.CreateTextWindow({
    title    = "Report an Item",
    lead     = "Select All, then Ctrl+C.",
    link     = "https://example.invalid/issues",
    footnote = "a privacy sentence",
    name     = "BitForgeTestTextWindow",
    buttons  = { { text = "Select All", onClick = function() clicked = clicked + 1 end } },
})

harness.assertEqual(window.Title:GetText(), "Report an Item", "the title bar carries the title")
harness.assertEqual(window.Lead:GetText(), "Select All, then Ctrl+C.")
harness.assertEqual(window.Link:GetText(), "https://example.invalid/issues",
    "the link sits in an edit box so it can be selected and copied")
harness.assertEqual(window.Footnote:GetText(), "a privacy sentence")

window:SetText("one\ntwo")
harness.assertEqual(window.Body:GetText(), "one\ntwo")

window:SetFootnote("a different sentence")
harness.assertEqual(window.Footnote:GetText(), "a different sentence")

window.Buttons[1]:GetScript("OnClick")(window.Buttons[1])
harness.assertEqual(clicked, 1, "the button row runs the handler it was given")

-- Escape has to close it, and UISpecialFrames is how a plain frame gets that.
local registered = false
for _, name in ipairs(UISpecialFrames) do
    if name == "BitForgeTestTextWindow" then registered = true end
end
harness.assertEqual(registered, true, "a named window is registered with UISpecialFrames")

-- Everything past the title is optional, and a window created without a part
-- must not draw a stub of it.
local bare = UI.CreateTextWindow({ title = "Bare" })
harness.assertEqual(bare.Lead, nil)
harness.assertEqual(bare.Link, nil)
harness.assertEqual(bare.Footnote, nil)
harness.assertEqual(#bare.Buttons, 0)

local ok = pcall(function() bare:SetFootnote("nowhere to put this") end)
harness.assertEqual(ok, false,
    "setting a footnote on a window that has none errors rather than drawing nothing")

-- Geometry: harness.lua's modelled SetPoint keeps every anchor call a region
-- receives, in order, so a mismatch between two of a region's own corners
-- (or a wrong sign on one) is something a test can see rather than something
-- only the client's own renderer would catch.
local function pointNamed(region, name)
    for _, point in ipairs(region.points) do
        if point[1] == name then return point end
    end
    error(("%s has no %s point recorded"):format(tostring(region), name))
end

-- A region's own LEFT edge is the same point whether TOP* or BOTTOM* names
-- it -- a lead line only ever calls SetPoint("TOPLEFT", ...), never
-- "BOTTOMLEFT", so resolving what body anchors "BOTTOMLEFT" against has to
-- fall back to whichever corner shares that horizontal word. The exact name
-- is tried first: a region (like the body itself) that set BOTH corners
-- explicitly must resolve each to its OWN recorded offset, not to whichever
-- of the two happens to come first in call order.
local function horizontalWord(pointName)
    if pointName:find("LEFT$") then return "LEFT" end
    if pointName:find("RIGHT$") then return "RIGHT" end
    error("point name has no horizontal component: " .. pointName)
end

local function findPoint(region, pointName)
    for _, point in ipairs(region.points) do
        if point[1] == pointName then return point end
    end
    local horizontal = horizontalWord(pointName)
    for _, point in ipairs(region.points) do
        if horizontalWord(point[1]) == horizontal then return point end
    end
    error(("%s has no point on its %s edge"):format(tostring(region), horizontal))
end

-- Horizontal position never depends on an element's rendered height (only
-- vertical does, and a wrapped lead line's real height is exactly what a
-- headless test cannot know), so walking the anchor chain to an absolute x
-- is exact for every point this layout sets, wrapped lead included.
local function resolveX(topWindow, region, pointName)
    local point = findPoint(region, pointName)
    local relativeTo, relativePoint, x = point[2], point[3], point[4]
    if relativeTo == topWindow then return x end
    return x + resolveX(topWindow, relativeTo, relativePoint)
end

-- Vertical needs one thing horizontal never did: a rendered height. The body's
-- bottom is anchored to the footnote's TOP, and a footnote only ever sets its
-- own BOTTOM corners -- so reading its top means crossing however tall the text
-- wrapped to. That is the measurement a headless run cannot take, which is why
-- harness.stub.fontStringHeights exists and why this defect survived five
-- reviews. A y offset is always ADDED to the reference point, whichever corner
-- names either end, so nothing here flips a sign.
local function verticalWord(pointName)
    if pointName:find("^TOP") then return "TOP" end
    if pointName:find("^BOTTOM") then return "BOTTOM" end
    error("point name has no vertical component: " .. pointName)
end

--- Where a region's TOP or BOTTOM edge sits, in units above the window's own
--- bottom edge.
local function edgeAbove(topWindow, region, edge)
    if region == topWindow then
        return edge == "BOTTOM" and 0 or topWindow.calls.SetSize[2]
    end

    for _, point in ipairs(region.points) do
        if verticalWord(point[1]) == edge then
            return point[5] + edgeAbove(topWindow, point[2], verticalWord(point[3]))
        end
    end

    -- Only the opposite edge is anchored, so cross the region's own height.
    local opposite = edge == "TOP" and "BOTTOM" or "TOP"
    local base = edgeAbove(topWindow, region, opposite)
    local height = region:GetHeight()
    if edge == "TOP" then return base + height end
    return base - height
end

-- Critical: with nothing below the title bar, the body's own anchors must
-- land inside the frame -- not overhanging the bottom edge (the sign this
-- round fixed), and not disagreeing with itself on the left edge (the
-- double-defined offset this round also fixed).
harness.assertEqual(resolveX(bare, bare.Body, "TOPLEFT"), resolveX(bare, bare.Body, "BOTTOMLEFT"),
    "the body's left edge agrees whether read from its top or its bottom anchor")
harness.assertEqual(pointNamed(bare.Body, "BOTTOMLEFT")[5], 16,
    "the body's bottom sits inside the frame, not past it")
harness.assertEqual(pointNamed(bare.Body, "TOPRIGHT")[4], -16,
    "the body's right edge is inset from the frame, not flush with it")

-- One rendered line, in the UI units every height below is counted in.
local LINE = 18

-- The harness's side of that measurement, pinned here because this is the file
-- that reads it. Both halves were blind spots in their own right: a height
-- nobody registered used to answer 0, and a FontString's GetHeight used to
-- bypass the rectangle that answers its every other edge.
local measured = harness.newFrame("FontString")
measured:SetText("a font string given a rectangle")
harness.setFrameGeometry(measured, { left = 0, right = 100, top = 50, bottom = 20 })
harness.assertEqual(measured:GetHeight(), 30,
    "a font string with a rectangle takes its height from it, as it does its width")
harness.assertEqual(measured:GetWidth(), 100, "which is the same rectangle")

local unmeasured = harness.newFrame("FontString")
unmeasured:SetText("text whose rendered height nobody registered")
harness.assertEqual(pcall(unmeasured.GetHeight, unmeasured), false,
    "an unregistered height on text that renders is refused, not answered as 0")
harness.assertEqual(harness.newFrame("FontString"):GetHeight(), 0,
    "and empty text really is nothing tall")

-- The exact configuration that shipped the Critical bug, and the one spec
-- #279's release-notes window will use: a footnote with no buttons.
-- Its height is registered like every other one here: an unregistered
-- FontString height is a harness error, and a silent 0 would have let the
-- assertion below read the footnote's BOTTOM edge while claiming its TOP.
local SHORT_FOOTNOTE = "a footnote"
harness.stub.fontStringHeights[SHORT_FOOTNOTE] = LINE
local footnoteOnly = UI.CreateTextWindow({ title = "Footnote only", footnote = SHORT_FOOTNOTE })
local footnoteBottom = pointNamed(footnoteOnly.Footnote, "BOTTOMLEFT")[5]
harness.assertEqual(footnoteBottom, 16, "the footnote sits inside the frame with no buttons present")
harness.assertEqual(edgeAbove(footnoteOnly, footnoteOnly.Body, "BOTTOM")
    > edgeAbove(footnoteOnly, footnoteOnly.Footnote, "TOP"), true,
    "the body's bottom edge sits above the footnote it shares the frame with")

-- Critical: every privacy sentence this window was built for wraps -- the
-- shortest shipped one runs to two lines and the longest to five -- and a
-- BOTTOM*-anchored FontString with no height grows UPWARD into whatever is
-- above it. Reserving one line's worth for it put the rest of the sentence
-- behind the body's opaque backdrop, on the one surface whose whole purpose is
-- informed consent. So the body's bottom chains off the footnote's real top,
-- and the harness is told how tall this one renders.
local FOUR_LINE_FOOTNOTE = "a privacy sentence that wraps to four rendered lines"
harness.stub.fontStringHeights[FOUR_LINE_FOOTNOTE] = 4 * LINE

local tall = UI.CreateTextWindow({
    title    = "Report an Item",
    footnote = FOUR_LINE_FOOTNOTE,
    buttons  = { { text = "Select All", onClick = function() end } },
})
harness.assertEqual(tall.Footnote.calls.SetHeight, nil,
    "a wrapping footnote is no more pinned to one line's height than the lead is")
harness.assertEqual(edgeAbove(tall, tall.Footnote, "TOP"), 16 + 24 + 16 + 4 * LINE,
    "the footnote's top rises with the text it wraps, clear of the button row")
harness.assertEqual(edgeAbove(tall, tall.Body, "BOTTOM")
    >= edgeAbove(tall, tall.Footnote, "TOP"), true,
    "the body's bottom clears the footnote's real wrapped height, not one line of it")

-- And it tracks that height rather than any constant: the same window with a
-- one-line footnote puts its body exactly three lines lower.
local ONE_LINE_FOOTNOTE = "a privacy sentence that fits on one line"
harness.stub.fontStringHeights[ONE_LINE_FOOTNOTE] = LINE
local short = UI.CreateTextWindow({
    title    = "Report an Item",
    footnote = ONE_LINE_FOOTNOTE,
    buttons  = { { text = "Select All", onClick = function() end } },
})
harness.assertEqual(edgeAbove(tall, tall.Body, "BOTTOM")
    - edgeAbove(short, short.Body, "BOTTOM"), 3 * LINE,
    "the body's bottom follows the footnote's height rather than a fixed reservation")

-- With a lead alone, the left edge still agrees with itself once chained
-- through it, and the lead itself is free to grow rather than pinned to one
-- line's height.
local leadOnly = UI.CreateTextWindow({ title = "Lead only", lead = "a line that might wrap" })
harness.assertEqual(leadOnly.Lead.calls.SetHeight, nil,
    "a wrapping lead line is not pinned to one line's height")
harness.assertEqual(resolveX(leadOnly, leadOnly.Body, "TOPLEFT"),
    resolveX(leadOnly, leadOnly.Body, "BOTTOMLEFT"),
    "the body's left edge agrees with itself when chained through a lead alone")

-- With a lead and a link both present (the "window" built at the top of this
-- file), the left edge still agrees with itself chained through both.
harness.assertEqual(resolveX(window, window.Body, "TOPLEFT"),
    resolveX(window, window.Body, "BOTTOMLEFT"),
    "the body's left edge agrees with itself when chained through a lead and a link")

-- selectOnOpen defaults to false: a window that can open on its own (release
-- notes, at login) must not steal focus and swallow keybinds.
local quiet = UI.CreateTextWindow({ title = "Quiet" })
quiet:Open()
harness.assertEqual(quiet.Body:GetEditBox().calls.SetFocus, nil,
    "Open() does not focus the body unless selectOnOpen was requested")

local reportWindow = UI.CreateTextWindow({ title = "Report", selectOnOpen = true })
reportWindow:Open()
harness.assertEqual(reportWindow.Body:GetEditBox().calls.SetFocus ~= nil, true,
    "selectOnOpen = true focuses the body on Open()")

local function countRegistrations(name)
    local count = 0
    for _, registeredName in ipairs(UISpecialFrames) do
        if registeredName == name then count = count + 1 end
    end
    return count
end
local before = countRegistrations("BitForgeTestTextWindow")
UI.CreateTextWindow({ title = "Report an Item", name = "BitForgeTestTextWindow" })
harness.assertEqual(countRegistrations("BitForgeTestTextWindow"), before,
    "a second window sharing a name does not double-register with UISpecialFrames")

-- The floor: a default-sized window already clears it, and a squashed one is
-- grown back up to it on both axes.
local floorWindow = UI.CreateTextWindow({ title = "Floors" })
harness.assertEqual(floorWindow:GetWidth(), 600, "the window's default width grew with its padding")
harness.assertEqual(floorWindow:GetHeight(), 460, "and so did its height")

-- SetSize is modelled by the harness, so calling it directly is the same
-- geometry change a real SetSize-driven resize would produce -- see
-- harness.lua's MODELLED_STATE.SetSize.
floorWindow:SetSize(10, 10)
UI.ApplyMinimum(floorWindow, "TextWindow")
harness.assertEqual(floorWindow:GetWidth(), 320, "a squashed window is grown to its floor")
harness.assertEqual(floorWindow:GetHeight(), 240, "on both axes")

-- And the drag path stops at the SAME floor. UI.CreateFrame already called
-- SetResizeBounds with Minimums.Frame -- 160x96, the floor this widget
-- inherits rather than the one it has -- so the last call wins and it has to
-- be this window's own, or a dragged corner takes it half the size a
-- programmatic resize can reach.
local bounds = floorWindow.calls.SetResizeBounds
harness.assertEqual(bounds and bounds[1], lib.Minimums.TextWindow.minWidth,
    "the drag floor is the window's own, not the plain frame's it inherits")
harness.assertEqual(bounds and bounds[2], lib.Minimums.TextWindow.minHeight,
    "on both axes")

harness.report()
