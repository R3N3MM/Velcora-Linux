# VELCORA icons

64x64 icons in SVG (source) and PNG. Regenerate with
`python3 scripts/build/generate-icons.py` (needs python3-cairosvg).

- `taskbar/`: terminal, browser, application, workspaces, launcher,
  text-editor, store, settings. Dark rounded tile, chrome-silver glyph.
- `panel/`: accessibility, workspace, volume, bluetooth, wifi, battery,
  notifications, power. Symbolic silver glyph on a transparent background.

Edit the glyph definitions in the generator rather than the SVGs, so the
set stays consistent (3.4px stroke on tiles, 4px on panel icons, round caps).
