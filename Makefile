# VELCORA Linux build targets.
# The ISO is built in a container; no build tools are required on the host
# beyond Docker, make and bash.

SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help validate lint test test-boot checksum iso iso-live iso-installer publish clean distclean

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: ## Check scripts and live-build configuration
	./scripts/build/validate-config.sh

lint: validate ## Shellcheck and Python syntax checks
	./scripts/validation/lint.sh

test: lint ## Verify branding, ISO, checksum and package lists
	./scripts/validation/check-branding.sh
	./scripts/validation/check-iso.sh
	./scripts/validation/check-installer-iso.sh
	./scripts/validation/checksum.sh "build/output/velcora-$$(tr -d '[:space:]' < VERSION)-live-amd64.iso"
	./scripts/validation/checksum.sh "build/output/velcora-$$(tr -d '[:space:]' < VERSION)-installer-amd64.iso"
	./scripts/validation/check-packages.sh

test-boot: ## Headless QEMU smoke test (BIOS and UEFI)
	./testing/boot/boot-test.sh

checksum: ## Verify the ISO SHA-256 checksum
	./scripts/validation/checksum.sh

iso: iso-live iso-installer ## Build both VELCORA Live and Installer ISOs

iso-live: validate ## Build the Velcora Live desktop ISO
	./scripts/build/build-iso.sh

iso-installer: validate ## Build the dedicated Debian Installer ISO
	./scripts/build/build-installer-iso.sh

publish: ## Publish the built ISO as GitHub release assets
	./scripts/release/publish-iso.sh

clean: ## Remove the build workspace and ISO output
	rm -rf build/work build/output

distclean: clean ## Also remove in-tree live-build leftovers
	rm -rf build/live-build/chroot build/live-build/binary build/live-build/.build \
		build/live-build/cache
	rm -f build/live-build/*.iso build/live-build/*.contents build/live-build/*.files \
		build/live-build/*.packages build/live-build/*.size build/live-build/*.manifest
