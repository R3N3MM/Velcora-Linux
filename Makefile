# VELCORA Linux build targets.
# The ISO is built in a container; no build tools are required on the host
# beyond Docker, make and bash.

SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help validate iso publish clean distclean

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: ## Check scripts and live-build configuration
	./scripts/build/validate-config.sh

iso: validate ## Build the VELCORA live ISO (Docker required)
	./scripts/build/build-iso.sh

publish: ## Publish the built ISO as GitHub release assets (split)
	./scripts/release/publish-iso.sh

clean: ## Remove the build workspace and ISO output
	rm -rf build/work build/output

distclean: clean ## Also remove in-tree live-build leftovers
	rm -rf build/live-build/chroot build/live-build/binary build/live-build/.build \
		build/live-build/cache
	rm -f build/live-build/*.iso build/live-build/*.contents build/live-build/*.files \
		build/live-build/*.packages build/live-build/*.size build/live-build/*.manifest
