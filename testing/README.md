# VELCORA testing

Everything here runs locally; nothing is uploaded and no tester data is
collected.

## Static and image checks

```sh
make lint        # shellcheck, Python syntax, build-config validation
make test        # lint + branding + ISO structure + checksum + package lists
make checksum    # only verify the ISO SHA-256
```

`make test` expects a built image at
`build/output/velcora-<VERSION>-amd64.iso` and its `.sha256` file. The ISO
checks use host `xorriso` when present and otherwise a disposable
`debian:trixie` container, so no live-build tools are needed on the host.

The package-list check resolves every entry in a trixie container with the
same pinned unstable/contrib source used by the build. It does not install
anything on the host.

## Headless boot smoke test

```sh
make test-boot
# or, with a specific image and timeout:
testing/boot/boot-test.sh --iso build/output/velcora-0.1.0-dev-amd64.iso --mode both --timeout 300
```

The script boots the ISO under BIOS and UEFI (OVMF), takes framebuffer
screenshots through the QEMU monitor, and waits for a login/desktop-looking
frame twice in a row. Screenshots are saved to
`build/output/boot-test-<mode>.ppm` (and `-fail.ppm` on timeout).

Requirements: `qemu-system-x86`, `python3`, and `ovmf` for the UEFI pass.
KVM is used when `/dev/kvm` is writable; otherwise QEMU falls back to slow
software emulation.

The marker is a heuristic (colour count, bright-pixel fraction, and bright
pixels near the top or bottom edge). Inspect the saved screenshot if a run
fails. Use `--keep` to preserve the QEMU logs and monitor socket.

## What is not covered yet

- Installer end-to-end disk installation (Calamares).
- Hardware compatibility and real-machine boot.
- Recovery and security scenarios.
