# VELCORA icons

64x64 icons in SVG (source) and PNG.  The build installs them as the
`Velcora` icon theme through `scripts/build/sync-branding-assets.py`, which
creates the freedesktop aliases and the theme index.

- `taskbar/`: terminal, browser, application, workspaces, launcher,
  text-editor, store, settings, folder. Dark rounded tile, chrome-silver
  glyph.
- `panel/`: accessibility, workspace, volume, bluetooth, wifi, battery,
  notifications, power. Symbolic silver glyph on a transparent background.

Edit the glyph definitions in the generator rather than the SVGs, so the
set stays consistent (3.4px stroke on tiles, 4px on panel icons, round caps).
