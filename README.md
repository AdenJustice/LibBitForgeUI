# LibBitForgeUI

BitForge's UI toolkit, extracted so more than one addon can embed it: a shared
colour palette and font set, the skin primitives that paint them onto a frame,
and the widget factories built from both. LibStub major `LibBitForgeUI-1.0`.

## Embedding

Vendor this repository as a submodule at `Libs/LibBitForgeUI` inside your
addon, and list its files in your `.toc` (after your own copy of
`LibStub.lua`):

```
Libs\LibBitForgeUI\LibBitForgeUI.lua
```

or, if you prefer the XML route, `Libs\LibBitForgeUI\lib.xml` — see
**Media paths** below for the one difference between the two.

## Media paths

The library resolves texture paths under
`Interface/AddOns/<YourAddonName>/Libs/LibBitForgeUI/Media` by default, taken
from the addon name the client hands the library's first file at load time.
That only works when the file is listed directly in your `.toc`: whether the
same vararg is populated for a file reached through a `<Script file="...">`
tag inside an XML your `.toc` loads is not confirmed (see below). If you embed
elsewhere, or load through `lib.xml`, or the default is otherwise wrong for
your layout, call `lib:SetMediaPath("Interface/AddOns/YourAddon/Wherever")`
before building any widget.

**Known limitation:** it is not established here whether WoW populates a
loaded file's `...` vararg with the addon name when that file is reached via
`<Script file="...">` in an XML the `.toc` lists, as opposed to being listed
in the `.toc` directly. Listing `LibBitForgeUI.lua` directly in your `.toc` is
the certain path; if you load through `lib.xml` instead and media paths come
back wrong, call `SetMediaPath` explicitly.

## Tests

Headless, no WoW client required:

```sh
tests/run.sh
```
