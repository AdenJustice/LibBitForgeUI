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

### Changed

- `## Interface` declares 12.1.0 (`120100`) rather than 12.0.0. Nothing loads
  this `.toc` — it is packaging metadata — but it is the game version the
  release listing will show.
