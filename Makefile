.PHONY: all help build release test describe rebuild-binary binary-info clean

all: rebuild-binary binary-info build test

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make                Rebuild binary artifact, show binary info, build, and test' \
		'  make build          Build the Swift package' \
		'  make release        Build the Swift package in release mode' \
		'  make test           Run Swift package tests when present' \
		'  make describe       Print SwiftPM package description' \
		'  make rebuild-binary Rebuild Binary/CFFF.xcframework from FFF source' \
		'  make binary-info    Print XCFramework and Mach-O slice info' \
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
	plutil -p Binary/CFFF.xcframework/Info.plist
	@find Binary/CFFF.xcframework -path '*/CFFF.framework/CFFF' -type f | sort | while IFS= read -r binary; do \
		echo "==> $$binary"; \
		lipo -info "$$binary"; \
	done
	@find Binary/CFFF.xcframework -name '*.dSYM' -type d | sort | while IFS= read -r dsym; do \
		echo "==> $$dsym"; \
		dwarfdump --uuid "$$dsym" || true; \
	done

clean:
	swift package clean
