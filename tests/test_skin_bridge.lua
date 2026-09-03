-- LibBitForgeUI's host-agnostic skin bridge -- lib.NewSkinBridge(). Ported
-- from BitForge's tests/test_core_skin_bridge.lua: the queueing and dispatch
-- assertions carry over unchanged. What that suite drove through a fake
-- host's registration callback, this one drives directly with
-- bridge.Deliver -- the library never learns which host, or whether there is
-- one.
local harness = dofile("tests/harness.lua")

harness.resetLibStub()
local lib = harness.loadLibrary("BitForge")
dofile("Skin.lua")

harness.assert(type(lib.NewSkinBridge) == "function", "lib.NewSkinBridge exists")

local bridge = lib.NewSkinBridge()

harness.assertEqual(bridge.GetSkin(), nil, "no facade is on offer until Deliver is called")

-- An early registrant: asked before the facade arrives.
local earlyGot, earlyRuns = nil, 0
bridge.OnSkin(function(facade) earlyGot, earlyRuns = facade, earlyRuns + 1 end)
harness.assertEqual(earlyGot, nil, "an early handler does not run before Deliver")

local FACADE = { apiVersion = 1 }
bridge.Deliver(FACADE)

harness.assertEqual(earlyGot, FACADE, "a handler registered before Deliver receives the facade")
harness.assertEqual(bridge.GetSkin(), FACADE, "GetSkin returns the facade after Deliver")

-- A late registrant: a lazily-built window, asking after the facade arrived.
-- This is the case a plain list of handlers silently drops.
local lateGot
bridge.OnSkin(function(facade) lateGot = facade end)
harness.assertEqual(lateGot, FACADE, "a handler registered after Deliver is called immediately")

-- Every handler is isolated, on the path a handler queued before Deliver
-- actually runs -- the drain loop, not the immediate-call branch below.
local queuedThrowBridge = lib.NewSkinBridge()
local queuedAfterThrower
queuedThrowBridge.OnSkin(function() error("queued handler blew up") end)
queuedThrowBridge.OnSkin(function(facade) queuedAfterThrower = facade end)
queuedThrowBridge.Deliver(FACADE)
harness.assertEqual(queuedAfterThrower, FACADE,
    "a throwing handler queued before Deliver does not stop the one queued after it")

-- The immediate-call branch isolates handlers the same way.
local afterThrower
bridge.OnSkin(function() error("handler blew up") end)
bridge.OnSkin(function(facade) afterThrower = facade end)
harness.assertEqual(afterThrower, FACADE,
    "a throwing handler does not stop the one registered after it")

-- A second Deliver, with a different facade, changes nothing -- first wins,
-- and a handler that already ran does not run again.
local OTHER_FACADE = { apiVersion = 2 }
bridge.Deliver(OTHER_FACADE)
harness.assertEqual(bridge.GetSkin(), FACADE,
    "a second Deliver with a different facade changes nothing")
harness.assertEqual(earlyRuns, 1,
    "a handler queued before the first Deliver does not run again on a second Deliver")

-- A handler registered from inside another handler, while Deliver drains the
-- queue built up before it ran: it must run exactly once, not twice.
local nestingBridge = lib.NewSkinBridge()
local nestedRuns = 0
nestingBridge.OnSkin(function()
    nestingBridge.OnSkin(function() nestedRuns = nestedRuns + 1 end)
end)
nestingBridge.Deliver(FACADE)
harness.assertEqual(nestedRuns, 1, "a handler registered during the drain runs exactly once")

-- Two bridges are independent: one addon's host handover must not satisfy
-- another's. NewSkinBridge has no counterpart at all in core, which only
-- ever had one bridge for the whole suite.
local bridgeA = lib.NewSkinBridge()
local bridgeB = lib.NewSkinBridge()
bridgeA.Deliver(FACADE)
harness.assertEqual(bridgeA.GetSkin(), FACADE, "bridge A holds the facade it was delivered")
harness.assertEqual(bridgeB.GetSkin(), nil, "bridge B is untouched by bridge A's Deliver")

harness.done()
