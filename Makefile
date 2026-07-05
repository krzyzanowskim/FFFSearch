.PHONY: all help build release test describe rebuild-binary binary-info prepare-binary-release publish-binary-release clean

all: build test

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make                Build and test the Swift package' \
		'  make build          Build the Swift package' \
		'  make release        Build the Swift package in release mode' \
		'  make test           Run Swift package tests when present' \
		'  make describe       Print SwiftPM package description' \
		'  make rebuild-binary Rebuild local ignored Binary/CFFF.xcframework from FFF source' \
		'  make binary-info    Print local XCFramework and Mach-O slice info' \
		'  make prepare-binary-release VERSION=X.Y.Z' \
		'                      Build, zip, checksum, and update Package.swift' \
		'  make publish-binary-release VERSION=X.Y.Z' \
		'                      Upload the prepared zip to the GitHub release' \
		'  make clean          Clean SwiftPM build artifacts'

build:
	swift build

release:
	swift build -c release

test:
	@if [ -d Tests ]; then \
		swift test; \
	else \
		echo "No Tests directory; skipping swift test."; \
	fi

describe:
	swift package describe

rebuild-binary:
	scripts/build-fff-xcframework.sh

binary-info:
	@if [ ! -d Binary/CFFF.xcframework ]; then \
		echo "Binary/CFFF.xcframework is not present; run make rebuild-binary first."; \
		exit 1; \
	fi
	plutil -p Binary/CFFF.xcframework/Info.plist
	@find Binary/CFFF.xcframework -path '*/CFFF.framework/CFFF' -type f | sort | while IFS= read -r binary; do \
		echo "==> $$binary"; \
		lipo -info "$$binary"; \
	done
	@find Binary/CFFF.xcframework -name '*.dSYM' -type d | sort | while IFS= read -r dsym; do \
		echo "==> $$dsym"; \
		dwarfdump --uuid "$$dsym" || true; \
	done

prepare-binary-release:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is required, for example: make prepare-binary-release VERSION=0.9.6"; \
		exit 2; \
	fi
	scripts/release-cfff-binary.sh prepare "$(VERSION)"

publish-binary-release:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is required, for example: make publish-binary-release VERSION=0.9.6"; \
		exit 2; \
	fi
	scripts/release-cfff-binary.sh publish "$(VERSION)"

clean:
	swift package clean
