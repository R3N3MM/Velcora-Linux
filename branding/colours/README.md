# VELCORA colours

The official VELCORA palette. Eight colours, no tints or shades outside
this set; derive opacity variants where needed instead of introducing
new hues.

| Token | Hex | RGB | Role |
| --- | --- | --- | --- |
| Midnight | `#0B0F17` | 11, 15, 23 | Base background |
| Navy | `#0A1A33` | 10, 26, 51 | Elevated surfaces, deep panels |
| Slate | `#303B4D` | 48, 59, 77 | Borders, dividers, inactive controls |
| Muted | `#8B949E` | 139, 148, 158 | Muted and secondary text |
| Silver | `#C9D1DB` | 201, 209, 219 | Secondary text, icons |
| Snow | `#F0F6FC` | 240, 246, 252 | Primary text |
| Blue | `#1F6FEB` | 31, 111, 235 | Primary accent, focus, selection |
| Azure | `#58A6FF` | 88, 166, 255 | Accent hover, highlights, links |

Usage files:

- `palette.json` — tokens with hex, RGB and role for tooling.
- `palette.css` — CSS custom properties (`--velcora-*`).

Contrast ratios (WCAG 2.1):

| Pair | Ratio | Result |
| --- | --- | --- |
| Snow on Midnight | 17.6:1 | AAA |
| Snow on Navy | 16.0:1 | AAA |
| Silver on Midnight | 12.5:1 | AAA |
| Muted on Midnight | 6.2:1 | AA |
| Muted on Navy | 5.7:1 | AA |
| Midnight on Azure | 7.6:1 | AAA |
| Midnight on Blue | 4.1:1 | Large text and UI only |

Blue is a mid-tone: use it for fills with large or bold labels, and
prefer Azure with Midnight text where normal-size text sits on an
accent. Never set Snow on Azure (2.3:1).
