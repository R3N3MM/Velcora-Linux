#!/usr/bin/env python3
"""Render the boot-time VELCORA artwork from branding/logo/velcora-logo.svg.

The source logo is an animated 1920x1080 SVG (CSS hover plus SMIL rig
rotations).  Firmware boot menus and Plymouth cannot play SVG animation, so
this script samples the animation into PNG frames and composes the static
boot-menu splash.  The same rendered logo is used for the LightDM greeter,
Calamares and the installer launcher icon, so there is one source of truth.

Run inside a Debian container with python3 and librsvg2-bin:

    docker run --rm -v "$PWD:/work" -w /work debian:trixie \
        bash -c 'apt-get update && apt-get install -y python3 librsvg2-bin \
                 && python3 scripts/build/render-boot-branding.py'

Outputs (relative to --output, which defaults to build/generated):
  bootloaders/splash.svg
  includes.chroot/usr/share/plymouth/themes/velcora/
  includes.chroot/usr/share/velcora/logo/
  includes.chroot/etc/calamares/branding/velcora/velcora-logo.png
  includes.chroot/usr/share/icons/hicolor/256x256/apps/velcora-installer.png
  includes.chroot/usr/share/pixmaps/velcora-installer.png

The Plymouth theme description and script are source files in
boot/plymouth/velcora/; this script only renders their image frames.
"""

from __future__ import annotations

import argparse
import math
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

# Animation timing from the source SVG.
CYCLE_SECONDS = 9.0
FRAME_COUNT = 24

# CSS @keyframes whaleHover: transform-origin (0, 0); ease-in-out between
# keyframes.  Values are (translate-x, translate-y, scale, rotate-degrees).
HOVER_KEYFRAMES = [
    (0.00, 960.0, 520.0, 0.82, 0.0),
    (0.25, 966.0, 508.0, 0.83, -1.4),
    (0.50, 960.0, 520.0, 0.82, 0.0),
    (0.75, 954.0, 532.0, 0.81, 1.4),
    (1.00, 960.0, 520.0, 0.82, 0.0),
]

# 24 frames cover the 9 s cycle; the source artwork occupies 1024 units,
# scaled by 0.82 and centred at (960, 520) on the 1920x1080 canvas.
FRAME_VIEWBOX = (480.0, 40.0, 960.0, 960.0)
FRAME_PIXELS = 360


def log(message: str) -> None:
    print(f"==> {message}")


def read_source(repo: Path) -> tuple[str, str]:
    source = (repo / "branding" / "logo" / "velcora-logo.svg").read_text()
    defs = source[source.index("<defs>") + len("<defs>") : source.index("</defs>")]
    # The whale rig is the only drawing element outside <defs>; metadata is
    # trailing C2PA data and is not needed in the rendered artwork.
    rig = source[source.index('<g class="whale-rig">') : source.index("<metadata>")]
    return defs, rig


def bezier(progress: float, x1: float, y1: float, x2: float, y2: float) -> float:
    """Evaluate a CSS cubic-bezier easing curve at x=progress."""

    def curve(t: float, p1: float, p2: float) -> float:
        return 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t * t * p2 + t**3

    low, high = 0.0, 1.0
    for _ in range(48):
        mid = (low + high) / 2
        if curve(mid, x1, x2) < progress:
            low = mid
        else:
            high = mid
    return curve((low + high) / 2, y1, y2)


def hover_transform(seconds: float) -> str:
    cycle = seconds % CYCLE_SECONDS / CYCLE_SECONDS
    for index in range(len(HOVER_KEYFRAMES) - 1):
        start = HOVER_KEYFRAMES[index]
        end = HOVER_KEYFRAMES[index + 1]
        if start[0] <= cycle <= end[0]:
            span = end[0] - start[0]
            local = 0.0 if span == 0 else (cycle - start[0]) / span
            eased = bezier(local, 0.42, 0.0, 0.58, 1.0)
            values = [
                start[value] + (end[value] - start[value]) * eased
                for value in range(1, 5)
            ]
            break
    else:  # pragma: no cover - the keyframes always cover the cycle
        values = list(HOVER_KEYFRAMES[-1][1:])
    x, y, scale, rotate = values
    return f"translate({x:.4f},{y:.4f}) scale({scale:.5f}) rotate({rotate:.4f})"


def smil_angle(values: list[tuple[float, float, float]], seconds: float) -> tuple[float, float, float]:
    position = (seconds % CYCLE_SECONDS) / CYCLE_SECONDS * (len(values) - 1)
    index = min(int(position), len(values) - 2)
    fraction = position - index
    start, end = values[index], values[index + 1]
    angle = start[0] + (end[0] - start[0]) * fraction
    return angle, start[1], start[2]


def inline_rig(defs: str, rig: str, seconds: float, transform: str | None = None) -> str:
    """Return the whale rig with all animation resolved at ``seconds``."""

    defs = re.sub(r"<style>.*?</style>", "", defs, flags=re.S)
    rig = rig.replace(
        '<g transform="translate(-512, -512)" class="whale-shimmer">',
        '<g transform="translate(-512, -512)">',
    )
    rig = rig.replace(
        '<g class="whale-rig">',
        f'<g transform="{transform or hover_transform(seconds)}">',
    )

    pattern = re.compile(
        r"<g>\s*<animateTransform([^>]*)>.*?</animateTransform>\s*"
        r'(<g clip-path="url\(#(clip\w+)\)">)',
        re.S,
    )

    def replace(match: re.Match[str]) -> str:
        attributes = match.group(1)
        values_text = re.search(r'values="([^"]+)"', attributes)
        if not values_text:
            raise SystemExit("animateTransform without values")
        values = [
            tuple(float(part) for part in entry.split())
            for entry in values_text.group(1).split(";")
            if entry.strip()
        ]
        angle, cx, cy = smil_angle(values, seconds)
        return (
            f'<g transform="rotate({angle:.4f} {cx:g} {cy:g})">'
            + match.group(2)
        )

    rig, replacements = pattern.subn(replace, rig)
    if replacements != 3:
        raise SystemExit(f"expected 3 animateTransform groups, found {replacements}")
    rig = re.sub(r"<animateTransform[^>]*>.*?</animateTransform>", "", rig, flags=re.S)
    return f'<defs>{defs}</defs>\n{rig}'


def background() -> str:
    return """
  <defs>
    <linearGradient id="background" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#070A10"/>
      <stop offset="0.55" stop-color="#0B0F17"/>
      <stop offset="1" stop-color="#06090F"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="38%" r="58%">
      <stop offset="0" stop-color="#1F6FEB" stop-opacity="0.26"/>
      <stop offset="0.55" stop-color="#1F6FEB" stop-opacity="0.06"/>
      <stop offset="1" stop-color="#0B0F17" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="100%" height="100%" fill="url(#background)"/>
  <rect width="100%" height="100%" fill="url(#glow)"/>
"""


def write_svg(path: Path, body: str, width: int, height: int, viewbox: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="{viewbox}">\n{body}\n</svg>\n'
    )


def render(svg: Path, png: Path, width: int, height: int | None = None) -> None:
    png.parent.mkdir(parents=True, exist_ok=True)
    command = ["rsvg-convert", "--format", "png", "--width", str(width)]
    if height is not None:
        command.extend(["--height", str(height)])
    command.extend([str(svg), "--output", str(png)])
    subprocess.run(command, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument(
        "--output",
        type=Path,
        help="generated asset root (default: <repo>/build/generated)",
    )
    arguments = parser.parse_args()

    repo = arguments.repo.resolve()
    generated = (arguments.output or repo / "build" / "generated").resolve()
    includes = generated / "includes.chroot"
    bootloaders = generated / "bootloaders"
    theme_source = repo / "boot" / "plymouth" / "velcora"
    for name in ("velcora.plymouth", "velcora.script"):
        if not (theme_source / name).is_file():
            raise SystemExit(f"missing Plymouth theme source: {theme_source / name}")
    defs, rig = read_source(repo)

    if shutil.which("rsvg-convert") is None:
        raise SystemExit("rsvg-convert is required (install librsvg2-bin)")

    with tempfile.TemporaryDirectory(prefix="velcora-branding-") as temporary:
        work = Path(temporary)

        # Boot menu splash: 800x600 source, live-build renders 640x480 for
        # isolinux and 800x600 for GRUB.  270 px whale centred above the menu.
        splash_rig = inline_rig(
            defs, rig, 0.0, transform="translate(400,165) scale(0.2930) rotate(0)"
        )
        write_svg(
            bootloaders / "splash.svg",
            background() + f'<g class="whale-rig">{splash_rig}</g>',
            800,
            600,
            "0 0 800 600",
        )
        log(f"wrote {bootloaders / 'splash.svg'}")

        # Plymouth background and animation frames.  Frames are cropped to
        # the whale's bounding box so the script can position and scale them
        # independently of the display resolution.
        write_svg(
            work / "background.svg",
            background(),
            1920,
            1080,
            "0 0 1920 1080",
        )
        theme = includes / "usr" / "share" / "plymouth" / "themes" / "velcora"
        theme.mkdir(parents=True, exist_ok=True)
        for stale in list(theme.glob("logo-*.png")) + [theme / "background.png"]:
            if stale.exists():
                stale.unlink()
        render(work / "background.svg", theme / "background.png", 1920, 1080)

        viewbox = " ".join(f"{value:g}" for value in FRAME_VIEWBOX)
        for index in range(FRAME_COUNT):
            seconds = CYCLE_SECONDS * index / FRAME_COUNT
            body = inline_rig(defs, rig, seconds)
            write_svg(work / f"frame-{index}.svg", body, FRAME_PIXELS, FRAME_PIXELS, viewbox)
            render(work / f"frame-{index}.svg", theme / f"logo-{index}.png", FRAME_PIXELS, FRAME_PIXELS)
        log(f"wrote {FRAME_COUNT} Plymouth frames to {theme}")

        # Static logo for the greeter, Calamares and desktop icons.
        splash_logo = includes / "usr" / "share" / "velcora" / "logo"
        splash_logo.mkdir(parents=True, exist_ok=True)
        shutil.copy2(repo / "branding" / "logo" / "velcora-logo.svg", splash_logo / "velcora-logo.svg")
        body = inline_rig(defs, rig, 0.0)
        write_svg(work / "logo.svg", body, 512, 512, viewbox)
        render(work / "logo.svg", splash_logo / "velcora-logo.png", 512, 512)
        render(
            work / "logo.svg",
            includes / "etc" / "calamares" / "branding" / "velcora" / "velcora-logo.png",
            512,
            512,
        )
        for target in (
            includes / "usr" / "share" / "icons" / "hicolor" / "256x256" / "apps" / "velcora-installer.png",
            includes / "usr" / "share" / "pixmaps" / "velcora-installer.png",
        ):
            render(work / "logo.svg", target, 256, 256)
        log(f"wrote static logo to {splash_logo} and installer/Calamares assets")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
