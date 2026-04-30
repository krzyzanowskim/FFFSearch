#!/usr/bin/env bash
set -euo pipefail

# Build the FFF C API as a framework-wrapped XCFramework for the local
# FFFSearchPackage binary target.
#
# Defaults are pinned to the source revision used for the checked-in artifact.
# Override FFF_SOURCE_DIR to build from an existing checkout while developing.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FFF_REPO_URL="${FFF_REPO_URL:-https://github.com/dmtrKovalenko/fff.git}"
FFF_REF="${FFF_REF:-ca7bf03}"
FFF_SOURCE_DIR="${FFF_SOURCE_DIR:-$ROOT_DIR/.build/fff-source}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.build/fff-xcframework}"
OUTPUT_DIR="$ROOT_DIR/Binary/CFFF.xcframework"

if [[ ! -d "$FFF_SOURCE_DIR/.git" ]]; then
  rm -rf "$FFF_SOURCE_DIR"
  git clone "$FFF_REPO_URL" "$FFF_SOURCE_DIR"
fi

git -C "$FFF_SOURCE_DIR" fetch --tags origin
# If FFF_SOURCE_DIR was supplied explicitly, still check out the pinned ref unless
# FFF_SKIP_CHECKOUT=1 is set for local experiments.
if [[ "${FFF_SKIP_CHECKOUT:-0}" != "1" ]]; then
  git -C "$FFF_SOURCE_DIR" checkout "$FFF_REF"
fi

rustup target add aarch64-apple-darwin x86_64-apple-darwin >/dev/null

rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"

build_target() {
  local target="$1"
  cargo build --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" -p fff-c --release --target "$target"
  install_name_tool -id @rpath/CFFF.framework/Versions/A/CFFF "$FFF_SOURCE_DIR/target/$target/release/libfff_c.dylib"
}

build_target aarch64-apple-darwin
build_target x86_64-apple-darwin

framework="$BUILD_DIR/CFFF.framework"
mkdir -p \
  "$framework/Versions/A/Headers" \
  "$framework/Versions/A/Modules" \
  "$framework/Versions/A/Resources"

lipo -create \
  "$FFF_SOURCE_DIR/target/aarch64-apple-darwin/release/libfff_c.dylib" \
  "$FFF_SOURCE_DIR/target/x86_64-apple-darwin/release/libfff_c.dylib" \
  -output "$framework/Versions/A/CFFF"

cp "$FFF_SOURCE_DIR/crates/fff-c/include/fff.h" "$framework/Versions/A/Headers/fff.h"

cat > "$framework/Versions/A/Modules/module.modulemap" <<'MODULEMAP'
framework module CFFF {
  umbrella header "fff.h"
  export *
  module * { export * }
}
MODULEMAP

cat > "$framework/Versions/A/Resources/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CFFF</string>
  <key>CFBundleIdentifier</key>
  <string>dev.dmtrkovalenko.fff.CFFF</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>CFFF</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>0.6.4</string>
  <key>CFBundleVersion</key>
  <string>0.6.4</string>
</dict>
</plist>
PLIST

ln -s A "$framework/Versions/Current"
ln -s Versions/Current/CFFF "$framework/CFFF"
ln -s Versions/Current/Headers "$framework/Headers"
ln -s Versions/Current/Modules "$framework/Modules"
ln -s Versions/Current/Resources "$framework/Resources"

xcodebuild -create-xcframework \
  -framework "$framework" \
  -output "$OUTPUT_DIR"

plutil -p "$OUTPUT_DIR/Info.plist"
lipo -info "$OUTPUT_DIR/macos-arm64_x86_64/CFFF.framework/Versions/A/CFFF"
