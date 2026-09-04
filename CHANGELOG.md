# Changelog

Every release of LibBitForgeUI is recorded here. The reader is an addon author
embedding this library, not a player: an entry names what moved in the surface
an embedder touches — a factory, a palette key, a font object, a media path,
the skin bridge — and what embedding code has to change because of it. How any
of it was implemented belongs in the commit.

## [Unreleased]

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
- `raised`, a fourth ground colour above `bg`, `surface` and `disabled` on the
  palette's elevation ladder — the plane an interactive control like the
  dropdown's closed box or the edit box now sits on, instead of the window's
  own background.

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
- Default and minimum sizes changed on several widgets: `Button` drops from
  36 to 32 tall (matching `Dropdown` and `EditBox`, which it commonly shares
  a row with); `CheckButton` rises from 24 to 28 tall; the default
  `TextWindow` grows from 560×440 to 600×460, with its internal padding
  going from 12 to 16. A widget built smaller than its new floor is grown to
  the floor rather than left at the requested size.
