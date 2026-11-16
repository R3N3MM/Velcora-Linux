#!/usr/bin/env python3
"""Stage VELCORA wallpapers and the Velcora icon theme from branding/.

The build stages branding/ (the source of truth) into the image.  This
script is the one-way sync from branding/ into the generated asset tree,
which scripts/build/stage-live-config.sh then copies into live-build:

    python3 scripts/build/sync-branding-assets.py --output build/generated/includes.chroot

It replaces the generated usr/share/icons/Velcora theme and the
usr/share/backgrounds/velcora/velcora_wallpaper_*.jpg files.  Nothing else
is touched.
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

# (source under branding/icons, freedesktop context, canonical name, aliases)
ICONS = [
    # --- application / taskbar icons -------------------------------------
    (
        "taskbar/terminal",
        "apps",
        "velcora-terminal",
        ["utilities-terminal", "xfce4-terminal", "org.xfce.terminal"],
    ),
    (
        "taskbar/text-editor",
        "apps",
        "velcora-text-editor",
        ["accessories-text-editor", "mousepad", "org.xfce.mousepad"],
    ),
    (
        "taskbar/browser",
        "apps",
        "velcora-browser",
        ["web-browser", "firefox", "firefox-esr", "org.mozilla.firefox"],
    ),
    (
        "taskbar/folder",
        "apps",
        "velcora-folder",
        ["system-file-manager", "thunar", "org.xfce.thunar", "Thunar"],
    ),
    (
        "taskbar/settings",
        "apps",
        "velcora-settings",
        [
            "preferences-system",
            "xfce4-settings-manager",
            "xfce-settings-manager",
            "org.xfce.settings.manager",
        ],
    ),
    (
        "taskbar/store",
        "apps",
        "velcora-store",
        ["system-software-install", "org.gnome.Software", "gnome-software"],
    ),
    (
        "taskbar/application",
        "apps",
        "velcora-application",
        ["applications-other", "application-x-executable"],
    ),
    (
        "taskbar/launcher",
        "apps",
        "velcora-launcher",
        [
            "start-here",
            "xfce4-panel-menu",
            "applications-system",
            "xfce4-appfinder",
            "org.xfce.appfinder",
        ],
    ),
    (
        "taskbar/workspaces",
        "actions",
        "velcora-workspaces",
        ["workspace-switcher", "preferences-system-windows"],
    ),
    # --- panel status and action icons -----------------------------------
    (
        "panel/accessibility",
        "apps",
        "velcora-accessibility",
        [
            "preferences-desktop-accessibility",
            "preferences-desktop-accessibility-symbolic",
        ],
    ),
    (
        "panel/airplane-mode",
        "status",
        "velcora-airplane-mode",
        ["airplane-mode", "airplane-mode-symbolic"],
    ),
    (
        "panel/battery-100",
        "status",
        "velcora-battery-100",
        [
            "battery-full",
            "battery-full-charged",
            "battery-full-symbolic",
            "battery-full-charged-symbolic",
        ],
    ),
    (
        "panel/battery-75",
        "status",
        "velcora-battery-75",
        ["battery-good", "battery-good-symbolic"],
    ),
    (
        "panel/battery-50",
        "status",
        "velcora-battery-50",
        ["battery-low", "battery-low-symbolic"],
    ),
    (
        "panel/battery-25",
        "status",
        "velcora-battery-25",
        ["battery-caution", "battery-caution-symbolic"],
    ),
    (
        "panel/battery-empty",
        "status",
        "velcora-battery-empty",
        ["battery-empty", "battery-empty-symbolic"],
    ),
    (
        "panel/battery-charging",
        "status",
        "velcora-battery-charging",
        [
            "battery-charging",
            "battery-full-charging",
            "battery-good-charging",
            "battery-low-charging",
            "battery-caution-charging",
            "battery-empty-charging",
            "battery-charging-symbolic",
            "battery-full-charging-symbolic",
            "battery-good-charging-symbolic",
            "battery-low-charging-symbolic",
            "battery-caution-charging-symbolic",
            "battery-empty-charging-symbolic",
        ],
    ),
    (
        "panel/bluetooth",
        "status",
        "velcora-bluetooth",
        ["bluetooth", "bluetooth-active", "bluetooth-active-symbolic"],
    ),
    (
        "panel/bluetooth-off",
        "status",
        "velcora-bluetooth-off",
        ["bluetooth-off", "bluetooth-disabled", "bluetooth-disabled-symbolic"],
    ),
    (
        "panel/do-not-disturb",
        "status",
        "velcora-do-not-disturb",
        [
            "notifications-disabled",
            "notifications-disabled-symbolic",
            "do-not-disturb",
        ],
    ),
    (
        "panel/ethernet",
        "status",
        "velcora-ethernet",
        ["network-wired", "network-wired-connected", "network-wired-symbolic"],
    ),
    (
        "panel/ethernet-off",
        "status",
        "velcora-ethernet-off",
        [
            "network-wired-disconnected",
            "network-wired-disconnected-symbolic",
            "network-offline",
        ],
    ),
    (
        "panel/lock",
        "actions",
        "velcora-lock",
        ["system-lock-screen", "system-lock-screen-symbolic"],
    ),
    (
        "panel/logout",
        "actions",
        "velcora-logout",
        ["system-log-out", "system-log-out-symbolic"],
    ),
    (
        "panel/mic",
        "status",
        "velcora-mic",
        ["audio-input-microphone", "audio-input-microphone-symbolic"],
    ),
    (
        "panel/mic-100",
        "status",
        "velcora-mic-100",
        ["microphone-sensitivity-high", "microphone-sensitivity-high-symbolic"],
    ),
    (
        "panel/mic-75",
        "status",
        "velcora-mic-75",
        ["microphone-sensitivity-medium", "microphone-sensitivity-medium-symbolic"],
    ),
    (
        "panel/mic-50",
        "status",
        "velcora-mic-50",
        ["microphone-sensitivity-low", "microphone-sensitivity-low-symbolic"],
    ),
    (
        "panel/mic-25",
        "status",
        "velcora-mic-25",
        [
            "microphone-sensitivity-very-low",
            "microphone-sensitivity-very-low-symbolic",
        ],
    ),
    (
        "panel/mic-muted",
        "status",
        "velcora-mic-muted",
        [
            "microphone-sensitivity-muted",
            "microphone-sensitivity-muted-symbolic",
        ],
    ),
    (
        "panel/notifications",
        "status",
        "velcora-notifications",
        ["notifications", "notification-active", "notifications-symbolic"],
    ),
    (
        "panel/notifications-new",
        "status",
        "velcora-notifications-new",
        ["notification-new", "notifications-new", "notification-new-symbolic"],
    ),
    (
        "panel/power-off",
        "actions",
        "velcora-power-off",
        ["system-shutdown", "system-shutdown-symbolic"],
    ),
    (
        "panel/restart",
        "actions",
        "velcora-restart",
        ["system-reboot", "system-reboot-symbolic"],
    ),
    (
        "panel/sleep",
        "actions",
        "velcora-sleep",
        ["system-suspend", "system-suspend-symbolic"],
    ),
    (
        "panel/volume-high",
        "status",
        "velcora-volume-high",
        ["audio-volume-high", "audio-volume-high-symbolic"],
    ),
    (
        "panel/volume-medium",
        "status",
        "velcora-volume-medium",
        ["audio-volume-medium", "audio-volume-medium-symbolic"],
    ),
    (
        "panel/volume-low",
        "status",
        "velcora-volume-low",
        ["audio-volume-low", "audio-volume-low-symbolic"],
    ),
    (
        "panel/volume-muted",
        "status",
        "velcora-volume-muted",
        ["audio-volume-muted", "audio-volume-muted-symbolic"],
    ),
    (
        "panel/wifi",
        "status",
        "velcora-wifi",
        [
            "network-wireless",
            "network-wireless-connected",
            "network-wireless-signal-excellent",
            "network-wireless-signal-excellent-symbolic",
        ],
    ),
    (
        "panel/wifi-2",
        "status",
        "velcora-wifi-2",
        ["network-wireless-signal-good", "network-wireless-signal-good-symbolic"],
    ),
    (
        "panel/wifi-1",
        "status",
        "velcora-wifi-1",
        ["network-wireless-signal-ok", "network-wireless-signal-ok-symbolic"],
    ),
    (
        "panel/wifi-0",
        "status",
        "velcora-wifi-0",
        ["network-wireless-signal-weak", "network-wireless-signal-weak-symbolic"],
    ),
    (
        "panel/wifi-off",
        "status",
        "velcora-wifi-off",
        [
            "network-wireless-offline",
            "network-wireless-disconnected",
            "network-wireless-signal-none",
            "network-wireless-signal-none-symbolic",
        ],
    ),
    ("panel/workspace", "actions", "velcora-workspace", []),
]

CONTEXTS = {
    "apps": "Applications",
    "status": "Status",
    "actions": "Actions",
}

DEFAULT_WALLPAPER = "velcora_wallpaper_datacenter_core.jpg"


def log(message: str) -> None:
    print(f"==> {message}")


def sync_wallpapers(repo: Path, includes: Path) -> None:
    source = repo / "branding" / "wallpapers"
    target = includes / "usr" / "share" / "backgrounds" / "velcora"
    target.mkdir(parents=True, exist_ok=True)

    for stale in target.glob("velcora_wallpaper_*.jpg"):
        stale.unlink()

    wallpapers = sorted(
        path for path in source.glob("*.jpg") if " (" not in path.name
    )
    for wallpaper in wallpapers:
        shutil.copy2(wallpaper, target / wallpaper.name)

    default = target / "velcora-default.jpg"
    if default.exists() or default.is_symlink():
        default.unlink()
    default.symlink_to(DEFAULT_WALLPAPER)
    log(f"staged {len(wallpapers)} wallpapers in {target}")


def make_icon_theme(repo: Path, includes: Path) -> None:
    source = repo / "branding" / "icons"
    target = includes / "usr" / "share" / "icons" / "Velcora"
    if target.exists():
        shutil.rmtree(target)

    for context in CONTEXTS:
        (target / "scalable" / context).mkdir(parents=True)
        (target / "64x64" / context).mkdir(parents=True)

    for asset, context, canonical, aliases in ICONS:
        for suffix in ("svg", "png"):
            origin = source / f"{asset}.{suffix}"
            if not origin.is_file():
                raise SystemExit(f"missing icon source: {origin}")
            directory = target / ("scalable" if suffix == "svg" else "64x64") / context
            destination = directory / f"{canonical}.{suffix}"
            shutil.copy2(origin, destination)
            for alias in aliases:
                link = directory / f"{alias}.{suffix}"
                if link.exists() or link.is_symlink():
                    link.unlink()
                link.symlink_to(destination.name)

    directories = [
        f"{size}/{context}" for size in ("64x64", "scalable") for context in CONTEXTS
    ]
    lines = [
        "[Icon Theme]",
        "Name=Velcora",
        "Comment=VELCORA icon theme",
        "Inherits=Adwaita,hicolor",
        f"Directories={','.join(directories)}",
        "",
    ]
    for size in ("64x64", "scalable"):
        for context, label in CONTEXTS.items():
            lines.extend(
                [
                    f"[{size}/{context}]",
                    "Size=64",
                    "Context=" + label,
                    "Type=" + ("Fixed" if size == "64x64" else "Scalable"),
                ]
            )
            if size == "scalable":
                lines.extend(["MinSize=16", "MaxSize=512"])
            lines.append("")
    (target / "index.theme").write_text("\n".join(lines))
    log(f"built icon theme {target} ({len(ICONS)} source icons)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument(
        "--output",
        type=Path,
        help="generated includes.chroot root (default: <repo>/build/generated/includes.chroot)",
    )
    arguments = parser.parse_args()

    repo = arguments.repo.resolve()
    includes = (
        arguments.output or repo / "build" / "generated" / "includes.chroot"
    ).resolve()
    sync_wallpapers(repo, includes)
    make_icon_theme(repo, includes)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
