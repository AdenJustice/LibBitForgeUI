# Changelog

Every release of LibBitForgeUI is recorded here. The reader is an addon author
embedding this library, not a player: an entry names what moved in the surface
an embedder touches — a factory, a palette key, a font object, a media path,
the skin bridge — and what embedding code has to change because of it. How any
of it was implemented belongs in the commit.

## [Unreleased]

### Added

- `lib.CreateScrollList(parent, options)`, a scroll list built from a `WowScrollBoxList`, a `MinimalScrollBar` and one of the client's two list-view constructors — **and the bar comes back already styled**, which is the reason it exists: nine surfaces across the suite that vendors this library built the trio by hand and seven of them reached the screen unstyled, because `Skin.StyleScrollBar` was a separate call. Size the returned frame; the split between box and bar is internal. `options.tree` picks the tree view over the linear one, `options.initializer` is required, and `elementType`, `extent`, `indent`, `padding` and `spacing` default to `"Button"` and the matching `lib.Metrics` tokens. It publishes `lib.Mixins.ScrollList` and `lib.Minimums.ScrollList` (120 × 48).

- `Templates\ScrollList.lua` in `lib.xml`, last. **An embedder that lists the files in its own `.toc` instead of loading `lib.xml` has to add this line**; one pointing at `lib.xml` needs no change.

- `lib.Colors.selection` — the accent at a quarter alpha, for a selected row's fill. Three embedders had each invented one and no two agreed. The palette now has seventeen entries.

### Changed

- **`lib.Colors.bg` now carries an alpha of its own (`F20E0F12`), and this is the one change that can reach your code.** It is the window ground's opacity, which used to be a private `0.5` inside `lib.CreateFrame` — so every contrast value this palette was chosen for was computed against a ground that never appeared on screen, and over a bright scene the muted text token measured 1.37:1. **A call site that wants `bg` as a solid colour must now read `GetRGB` rather than `GetRGBA`**: three components, no alpha. A call site painting a window ground wants `GetRGBA` and is already right.

- **`lib.Colors.point` moves from `#45B7D1` to `#22D3EE`** — the same hue five degrees over, with the chroma and lightness raised (L\* 69.3 → 77.9, C\* 32.8 → 40.8). Nothing about how it is used changes; every widget drawing with it follows the value.

- **A titled `lib.CreateFrame` draws its title dark on the accent instead of white on it.** White on the old accent measured 2.35:1 against a 4.5:1 floor and would have measured 1.81:1 on the new one — a brighter accent makes white worse, not better. The title text is now `lib.Colors.bg`, at 10.61:1.

- **`lib.Skin.BuildWindowShell`'s default header height is `lib.Metrics.control` (32), where it was a hard-coded 30.** A caller passing an explicit `options.headerHeight` is unaffected; one relying on the default gets a header two pixels taller. The 30 was the last copy of a value moved to 32 everywhere else one release ago.

## [v12.1.0.1] — 2026-09-04

### Added

- `LibBitForgeUI-1.0`, a LibStub library carrying BitForge's UI toolkit: the
  colour palette, the font set, the skin primitives that paint them onto a
  frame, and the widget factories built from both.
- Sixteen global font objects named `BitForgeFont<Variant>`, created at load,
  for call sites that consume font objects by name rather than through
  `lib.Fonts`.
- `lib:SetMediaPath(path)`, for an embedder that vendors the library somewhere
  other than `Libs/LibBitForgeUI` or reaches it through `lib.xml`.
- A per-addon skin bridge, so a host can drive the primitives without either
  side naming the other.
- Packaged releases. A tag on this repository now produces a zip and a GitHub
  release an embedder can pin to instead of pinning a bare commit. The package
  holds this repository's files and nothing else — embedding remains the only
  way to use the library, and the addon that vendors it still supplies LibStub.
- `lib.Metrics`, a named spacing scale (nineteen keys — eight layout tokens
  such as `md` and `control`, plus widget defaults like `defaultWidth`), and
  `lib:SetMetrics(overrides)` to retune it. Every factory now sizes its
  widget from this scale rather than from a number written into the widget
  itself.
- `lib.Minimums` and `lib.ApplyMinimum(frame, key)`: a minimum width and
  height per widget (keyed by mixin name — `Button`, `Dropdown`, `Frame`, and
  so on for all ten factories), enforced after every construction and after
  any later resize a factory performs. A caller asking for a smaller widget
  than the floor now gets the floor instead. `UI.CreateFrame` additionally
  puts the same floor under the user's drag-resize handle.
- An icon set in `Media/`, reachable by name through `lib.GetMedia`:
  `arrow_up`, `arrow_down`, `ban`, `checked`, `unchecked`, `coins`, `gear`,
  `sliders`, `trash`, `xmark`, `square-xmark` and `square-xmark-outline`. Each
  is a white 256×256 TGA, so a consumer tints it with `SetVertexColor` from a
  palette token rather than shipping one file per colour. The four that
  previously shipped as `.blp` — the arrows and the two check boxes — are now
  TGA under the same media names, so nothing that reads them has to change.
- `raised`, a fourth ground colour above `bg`, `surface` and `disabled` on the
  palette's elevation ladder — the plane an interactive control like the
  dropdown's closed box or the edit box now sits on, instead of the window's
  own background.
- An `embed` branch to vendor from. It carries exactly the same files as
  `main` — nothing is filtered out of it — and exists so that a fix you find
  while working inside your own addon can be committed from the submodule
  checkout itself rather than retyped in a separate clone. Name it with
  `branch = embed` in your `.gitmodules` and move it with `git submodule
  update --remote`. Pin `main` or a `v*` tag for anything you ship: `embed`
  runs ahead of `main` only while a fix is in flight, and a commit on it that
  has not landed is one that has not been reviewed or released. Nothing is
  ever force-pushed to it, so a commit you have pinned stays reachable.

### Changed

- `## Interface` declares 12.1.0 (`120100`) rather than 12.0.0. Nothing loads
  this `.toc` — it is packaging metadata — but it is the game version the
  release listing will show.
- The colour palette is sixteen tokens, up from twelve, and several existing
  values moved. `text` is now near-white rather than mid-grey — code that
  wants secondary/dimmed text should read the new `textMuted` token instead.
  `edge` is now lighter than the surface it outlines rather than darker.
  `disabled` and `danger` also moved; `point`, `hover` and `textHover` did
  not. `lib:SetFonts` now raises on an unknown font variant name instead of
  silently doing nothing — an embedder relying on that silence to no-op a
  misspelled call will now see an error.
- The close button's glyph is `square-xmark-outline` — an X inside a square
  outline — rather than the loose strokes of `close_x.tga`, which no longer
  ships. An embedder that reached for `lib.GetMedia("close_x")` on its own
  account has to name an icon that exists; the button itself is unchanged in
  size, hit area, colours and narration. The mark now covers 0.656 of the
  button's edge rather than the 0.44 the bare X did, so a boxed glyph reads at
  16 as well as at 24.
- Default and minimum sizes changed on several widgets: `Button` drops from
  36 to 32 tall (matching `Dropdown` and `EditBox`, which it commonly shares
  a row with); `CheckButton` rises from 24 to 28 tall; the default
  `TextWindow` grows from 560×440 to 600×460, with its internal padding
  going from 12 to 16. A widget built smaller than its new floor is grown to
  the floor rather than left at the requested size.
