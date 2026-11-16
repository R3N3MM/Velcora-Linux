#!/usr/bin/env python3
"""QEMU monitor helper for the VELCORA headless boot smoke test.

Two subcommands:

  dump  <monitor.sock> <screen.ppm>   ask QEMU for a framebuffer screenshot
  check <screen.ppm>                  print metrics and exit 0 if the frame
                                      looks like a login/desktop screen

The check is deliberately a heuristic: it looks for a colourful framebuffer
with a meaningful number of distinct colours, enough non-dark pixels, and
bright pixels near the top or bottom edge (panel, greeter bar, taskbar).
Black GRUB screens and the mostly-black Plymouth splash do not match.
"""

from __future__ import annotations

import socket
import sys

PROMPT = b"(qemu)"


def _read_until_prompt(sock: socket.socket) -> bytes:
    data = b""
    while PROMPT not in data:
        chunk = sock.recv(4096)
        if not chunk:
            break
        data += chunk
    return data


def dump(sock_path: str, out_path: str) -> int:
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(15)
    try:
        sock.connect(sock_path)
        _read_until_prompt(sock)
        sock.sendall(b'screendump "' + out_path.encode("utf-8") + b'"\n')
        response = _read_until_prompt(sock)
    finally:
        sock.close()
    if b"error" in response.lower():
        sys.stderr.write(response.decode("utf-8", "replace"))
        return 1
    return 0


def read_ppm(path: str) -> tuple[int, int, bytes]:
    with open(path, "rb") as handle:
        data = handle.read()
    if not data.startswith(b"P6"):
        raise ValueError("not a binary PPM (P6) image")

    position = 2
    values: list[int] = []
    while len(values) < 3:
        while position < len(data) and data[position : position + 1].isspace():
            position += 1
        if data[position : position + 1] == b"#":
            while position < len(data) and data[position : position + 1] not in b"\r\n":
                position += 1
            continue
        start = position
        while position < len(data) and not data[position : position + 1].isspace():
            position += 1
        values.append(int(data[start:position]))

    width, height, maxval = values
    if maxval > 255:
        raise ValueError("16-bit PPM is not supported")

    if data[position : position + 2] == b"\r\n":
        position += 2
    elif data[position : position + 1] in b" \t\r\n":
        position += 1

    need = width * height * 3
    pixels = data[position : position + need]
    if len(pixels) != need:
        raise ValueError("truncated PPM pixel data")
    return width, height, pixels


def check(path: str) -> int:
    width, height, pixels = read_ppm(path)
    total = width * height
    top_rows = max(1, height // 10)
    bottom_start = height - max(1, height // 8)

    buckets: set[tuple[int, int, int]] = set()
    bright = 0
    top_bright = 0
    bottom_bright = 0
    top_total = top_rows * width
    bottom_total = (height - bottom_start) * width

    for y in range(height):
        row = y * width * 3
        top_row = y < top_rows
        bottom_row = y >= bottom_start
        for x in range(width):
            index = row + x * 3
            red, green, blue = pixels[index], pixels[index + 1], pixels[index + 2]
            buckets.add((red >> 4, green >> 4, blue >> 4))
            if max(red, green, blue) > 48:
                bright += 1
                if top_row:
                    top_bright += 1
                if bottom_row:
                    bottom_bright += 1

    bright_fraction = bright / total
    top_fraction = top_bright / top_total
    bottom_fraction = bottom_bright / bottom_total

    print(
        f"colours={len(buckets)} bright={bright_fraction:.3f} "
        f"top={top_fraction:.3f} bottom={bottom_fraction:.3f}"
    )

    marker = (
        len(buckets) >= 64
        and bright_fraction >= 0.025
        and (top_fraction >= 0.015 or bottom_fraction >= 0.015)
    )
    return 0 if marker else 1


def main(argv: list[str]) -> int:
    if len(argv) == 4 and argv[1] == "dump":
        return dump(argv[2], argv[3])
    if len(argv) == 3 and argv[1] == "check":
        try:
            return check(argv[2])
        except (OSError, ValueError) as exc:
            print(f"check: {exc}", file=sys.stderr)
            return 1
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
