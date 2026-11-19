#!/usr/bin/env bash
## Headless QEMU smoke test for the VELCORA live ISO.
##
## Boots the ISO under BIOS, UEFI (OVMF) or both, takes screenshots through
## the QEMU monitor and waits until a frame looks like the LightDM login
## screen or the Xfce desktop. Fails on timeout.
##
## Usage: testing/boot/boot-test.sh [--iso PATH] [--mode bios|uefi|both]
##                                  [--timeout SECONDS] [--keep]
##
## Defaults: build/output/velcora-<VERSION>-live-amd64.iso, mode both;
##           300 s with KVM, 900 s with software emulation.
## Screenshots are written to build/output/boot-test-<mode>.ppm.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
ISO="$REPO_ROOT/build/output/velcora-$VERSION-live-amd64.iso"
MODE="both"
TIMEOUT=""
KEEP=0
HELPER="$REPO_ROOT/testing/boot/qemu-screen.py"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
	sed -n '2,14p' "$0" | sed 's/^## \{0,1\}//'
}

while (( $# > 0 )); do
	case "$1" in
		--iso) ISO="${2:?--iso needs a path}"; shift 2 ;;
		--mode) MODE="${2:?--mode needs bios, uefi or both}"; shift 2 ;;
		--timeout) TIMEOUT="${2:?--timeout needs seconds}"; shift 2 ;;
		--keep) KEEP=1; shift ;;
		-h|--help) usage; exit 0 ;;
		*) die "unknown argument: $1" ;;
	esac
done

case "$MODE" in
	bios|uefi|both) ;;
	*) die "--mode must be bios, uefi or both" ;;
esac
if [[ -n "$TIMEOUT" && ! "$TIMEOUT" =~ ^[0-9]+$ ]]; then
	die "--timeout must be a number of seconds"
fi
if [[ -z "$TIMEOUT" ]]; then
	if [[ -r /dev/kvm && -w /dev/kvm ]]; then
		TIMEOUT=300
	else
		TIMEOUT=900
	fi
fi

[[ -f "$ISO" ]] || die "ISO not found: $ISO (run 'make iso' first)"
command -v qemu-system-x86_64 >/dev/null 2>&1 \
	|| die "qemu-system-x86_64 is required (sudo apt install qemu-system-x86)"
command -v python3 >/dev/null 2>&1 || die "python3 is required"
[[ -f "$HELPER" ]] || die "missing helper: $HELPER"

find_first() {
	local candidate
	for candidate in "$@"; do
		if [[ -f "$candidate" ]]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done
	return 1
}

OVMF_CODE="${OVMF_CODE:-$(find_first \
	/usr/share/OVMF/OVMF_CODE_4M.fd \
	/usr/share/OVMF/OVMF_CODE.fd \
	/usr/share/qemu/OVMF.fd || true)}"
OVMF_VARS="${OVMF_VARS:-$(find_first \
	/usr/share/OVMF/OVMF_VARS_4M.fd \
	/usr/share/OVMF/OVMF_VARS.fd || true)}"

if [[ "$MODE" == "uefi" || "$MODE" == "both" ]]; then
	[[ -n "$OVMF_CODE" && -f "$OVMF_CODE" ]] \
		|| die "OVMF firmware not found (sudo apt install ovmf)"
	[[ -n "$OVMF_VARS" && -f "$OVMF_VARS" ]] \
		|| die "OVMF variable store not found (sudo apt install ovmf)"
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/velcora-boot.XXXXXX")"
qemu_pid=""

cleanup() {
	if [[ -n "$qemu_pid" ]] && kill -0 "$qemu_pid" 2>/dev/null; then
		kill "$qemu_pid" 2>/dev/null || true
		wait "$qemu_pid" 2>/dev/null || true
	fi
	if (( KEEP == 0 )); then
		rm -rf "$WORK"
	else
		log "kept work directory: $WORK"
	fi
}
trap cleanup EXIT

run_mode() {
	local mode="$1"
	local run="$WORK/$mode"
	local sock="$run/monitor.sock"
	local serial="$run/serial.log"
	local passes=0
	local deadline
	local metrics=""
	local -a qemu_args

	mkdir -p "$run"
	log "booting $mode (timeout ${TIMEOUT}s)"

	qemu_args=(
		-boot d
		-display none -vga std -no-reboot
		-monitor "unix:$sock,server,nowait"
		-serial "file:$serial"
		-drive "file=$ISO,media=cdrom,readonly=on"
	)
	if [[ -r /dev/kvm && -w /dev/kvm ]]; then
		qemu_args+=(-m 4096 -smp 2 -enable-kvm -cpu host)
	else
		qemu_args+=(-m 6144 -smp 4 -accel "tcg,thread=multi")
		log "KVM is unavailable; using multithreaded software emulation (up to ${TIMEOUT}s)"
	fi
	if [[ "$mode" == "uefi" ]]; then
		cp "$OVMF_VARS" "$run/OVMF_VARS.fd"
		qemu_args+=(
			-drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
			-drive "if=pflash,format=raw,file=$run/OVMF_VARS.fd"
		)
	fi

	qemu-system-x86_64 "${qemu_args[@]}" >"$run/qemu.log" 2>&1 &
	qemu_pid=$!

	for _ in {1..20}; do
		[[ -S "$sock" ]] && break
		sleep 1
	done
	if [[ ! -S "$sock" ]]; then
		tail -n 20 "$run/qemu.log" 2>/dev/null || true
		die "$mode: QEMU monitor socket did not appear"
	fi

	deadline=$((SECONDS + TIMEOUT))
	while (( SECONDS < deadline )); do
		sleep 5
		if ! kill -0 "$qemu_pid" 2>/dev/null; then
			wait "$qemu_pid" 2>/dev/null || true
			qemu_pid=""
			tail -n 20 "$run/qemu.log" 2>/dev/null || true
			die "$mode: QEMU exited before the login/desktop marker"
		fi

		rm -f "$run/screen.ppm"
		if ! python3 "$HELPER" dump "$sock" "$run/screen.ppm" >/dev/null 2>&1; then
			continue
		fi
		if metrics="$(python3 "$HELPER" check "$run/screen.ppm" 2>&1)"; then
			passes=$((passes + 1))
			log "  $metrics (${passes}/2)"
		else
			passes=0
		fi
		if (( passes >= 2 )); then
			mkdir -p "$REPO_ROOT/build/output"
			cp "$run/screen.ppm" "$REPO_ROOT/build/output/boot-test-$mode.ppm" 2>/dev/null || true
			break
		fi
	done

	if (( passes < 2 )); then
		mkdir -p "$REPO_ROOT/build/output"
		cp "$run/screen.ppm" "$REPO_ROOT/build/output/boot-test-$mode-fail.ppm" 2>/dev/null || true
		tail -n 20 "$serial" 2>/dev/null || true
		die "$mode: no login/desktop marker within ${TIMEOUT}s"
	fi

	kill "$qemu_pid" 2>/dev/null || true
	wait "$qemu_pid" 2>/dev/null || true
	qemu_pid=""
	log "$mode boot reached the marker"
}

case "$MODE" in
	bios) run_mode bios ;;
	uefi) run_mode uefi ;;
	both) run_mode bios; run_mode uefi ;;
esac

printf 'OK — %s boot smoke test passed\n' "$MODE"
