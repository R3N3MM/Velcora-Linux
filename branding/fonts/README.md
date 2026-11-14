# VELCORA fonts

The two typefaces used across the VELCORA identity:

| Family | Version | Upstream | Licence |
| --- | --- | --- | --- |
| Inter | 4.1 | https://github.com/rsms/inter | SIL OFL 1.1 (`inter/LICENSE.txt`) |
| JetBrains Mono | 2.304 | https://github.com/JetBrains/JetBrainsMono | SIL OFL 1.1 (`jetbrains-mono/OFL.txt`) |

Inter is the UI and display face. JetBrains Mono is the terminal,
code and monospaced data face.

## Layout

- `inter/` — variable TTFs, static TTFs in `static/`, and WOFF2 web
  fonts with `inter.css` in `web/`.
- `jetbrains-mono/` — static TTFs in `ttf/`, variable TTFs in
  `variable/`, and WOFF2 web fonts in `webfonts/`.

## Installing system-wide

Copy the TTF files into the system font directory and refresh the cache:

```sh
sudo install -m 644 inter/*.ttf inter/static/*.ttf /usr/share/fonts/truetype/inter/
sudo install -m 644 jetbrains-mono/ttf/*.ttf jetbrains-mono/variable/*.ttf \
  /usr/share/fonts/truetype/jetbrains-mono/
sudo fc-cache -f
```

For a single user, use `~/.local/share/fonts/` instead and run
`fc-cache -f` without `sudo`.

## Refreshing from upstream

Download the release archives from the upstream links above, then:

```sh
unzip Inter-4.1.zip
cp InterVariable*.ttf inter/
cp extras/ttf/Inter-*.ttf inter/static/
rm inter/static/InterDisplay-*.ttf
cp web/*.woff2 web/inter.css inter/web/

unzip JetBrainsMono-2.304.zip
cp fonts/ttf/*.ttf jetbrains-mono/ttf/
cp fonts/variable/*.ttf jetbrains-mono/variable/
cp fonts/webfonts/*.woff2 jetbrains-mono/webfonts/
```

Update the version table above when bumping either family.
