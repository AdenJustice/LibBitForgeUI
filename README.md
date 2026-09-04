# LibBitForgeUI

BitForge's UI toolkit, extracted so more than one addon can embed it: a shared
colour palette and font set, the skin primitives that paint them onto a frame,
and the widget factories built from both. LibStub major `LibBitForgeUI-1.0`.

**Embedding is the only way to use it.** There is no standalone install: the
library ships inside the addon that vendors it, resolves its media relative to
that addon, and expects that addon to have loaded `LibStub` already. A release
here is a zip and a tag an embedder can pin to, not something a player installs.

## Embedding

Vendor this repository as a submodule at `Libs/LibBitForgeUI` inside your
addon, and either point your `.toc` at `Libs\LibBitForgeUI\lib.xml`, or list
every file in `lib.xml`'s own order directly in your `.toc` (after your own
copy of `LibStub.lua`):

```
Libs\LibBitForgeUI\LibBitForgeUI.lua
Libs\LibBitForgeUI\Skin.lua
Libs\LibBitForgeUI\Templates\Frame.lua
Libs\LibBitForgeUI\Templates\Buttons.lua
Libs\LibBitForgeUI\Templates\CloseButton.lua
Libs\LibBitForgeUI\Templates\EditBox.lua
Libs\LibBitForgeUI\Templates\Dropdown.lua
Libs\LibBitForgeUI\Templates\Bar.lua
Libs\LibBitForgeUI\Templates\Slider.lua
Libs\LibBitForgeUI\Templates\TextWindow.lua
```

`LibBitForgeUI.lua` builds the palette, fonts and media path; `Skin.lua` is
the primitive layer the widgets below it build on; the eight
`Templates\*.lua` files are the widget factories themselves. Loading only
`LibBitForgeUI.lua` gets you the palette and fonts with no skin primitives,
no widgets and no bridge — see **Media paths** below for the one difference
between the `.toc` route and the `lib.xml` route.

Loading the library also creates sixteen global font objects named
`BitForgeFont<Variant>` (`BitForgeFontNormal`, `BitForgeFontLargeOutline`,
and so on). The `BitForgeFont` prefix is the original addon's name, kept
because call sites across the suite consume those names as strings rather
than as `lib.Fonts` table lookups.

### Which commit to pin

Pin the submodule to a commit on `main`, or to a `v*` tag. That is what a
release is.

The repository also has an `embed` branch. It carries exactly the same files
as `main` and exists so that a fix found while you are working inside your own
addon can be committed from the submodule checkout itself, rather than retyped
in a separate clone of this repository. If you want that, name the branch in
your `.gitmodules`:

```
[submodule "YourAddon/Libs/LibBitForgeUI"]
    path = YourAddon/Libs/LibBitForgeUI
    url = https://github.com/AdenJustice/LibBitForgeUI.git
    branch = embed
```

and move it with `git submodule update --remote`.

A submodule is checked out at a detached HEAD, and `--remote` leaves it that
way, so switch it onto the branch once before committing or pushing from it:

```sh
git -C YourAddon/Libs/LibBitForgeUI switch embed
```

Without that, `git push origin embed` from inside the submodule fails with
`src refspec embed does not match any`, or pushes a stale local branch.

`embed` is a working branch: at rest it is the same commit as `main`, and it
runs ahead only while a fix is in flight. Nothing is ever force-pushed to it,
so a commit you have pinned stays reachable — but a fix that has not landed on
`main` yet is a fix that has not been reviewed or released, so pin `main` or a
tag for anything you ship.

To go back to pinning `main`, drop the `branch = embed` line from
`.gitmodules`, detach the submodule onto the commit or tag you want
(`git -C YourAddon/Libs/LibBitForgeUI switch --detach v1.2.3`), and commit the
moved pointer in your addon. Either way, a fresh clone of your addon still
needs `git submodule update --init` before the library is there at all.

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
