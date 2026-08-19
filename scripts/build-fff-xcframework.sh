#!/usr/bin/env bash
set -euo pipefail

# Build the FFF C API as a framework-wrapped XCFramework for the local
# FFFSearch binary target.
#
# Defaults resolve to the latest stable upstream FFF release tag after fetching.
# Override FFF_REF or FFF_SOURCE_DIR for pinned/local experiments.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FFF_REPO_URL="${FFF_REPO_URL:-https://github.com/dmtrKovalenko/fff.git}"
FFF_REF="${FFF_REF:-}"
FFF_SOURCE_DIR="${FFF_SOURCE_DIR:-$ROOT_DIR/.build/fff-source}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.build/fff-xcframework}"
OUTPUT_DIR="$ROOT_DIR/Binary/CFFF.xcframework"

if [[ ! -d "$FFF_SOURCE_DIR/.git" ]]; then
  rm -rf "$FFF_SOURCE_DIR"
  git clone "$FFF_REPO_URL" "$FFF_SOURCE_DIR"
fi

git -C "$FFF_SOURCE_DIR" fetch --tags --force --prune --prune-tags origin

resolve_fff_ref() {
  if [[ -n "$FFF_REF" ]]; then
    printf '%s\n' "$FFF_REF"
    return
  fi

  git -C "$FFF_SOURCE_DIR" tag --list | python3 "$ROOT_DIR/scripts/select-latest-fff-release.py"
}

# If FFF_SOURCE_DIR was supplied explicitly, still check out the resolved ref
# unless FFF_SKIP_CHECKOUT=1 is set for local experiments.
if [[ "${FFF_SKIP_CHECKOUT:-0}" != "1" ]]; then
  FFF_RESOLVED_REF="$(resolve_fff_ref)"
  echo "==> Using FFF ref: $FFF_RESOLVED_REF"
  # Previous builds patch the FFF checkout before compiling; clean those edits
  # before switching release tags.
  git -C "$FFF_SOURCE_DIR" reset --hard HEAD
  git -C "$FFF_SOURCE_DIR" checkout "$FFF_RESOLVED_REF"
  git -C "$FFF_SOURCE_DIR" reset --hard "$FFF_RESOLVED_REF"
else
  FFF_RESOLVED_REF="$(git -C "$FFF_SOURCE_DIR" rev-parse --short HEAD)"
  echo "==> Using existing FFF checkout: $FFF_RESOLVED_REF"
fi

rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"

FFF_BUNDLE_VERSION="$(
  python3 - "$FFF_SOURCE_DIR/crates/fff-c/Cargo.toml" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
match = re.search(r'(?m)^version\s*=\s*"([^"]+)"', text)
if not match:
    raise SystemExit("Could not read fff-c package version")
print(match.group(1))
PY
)"
echo "==> FFF C API version: $FFF_BUNDLE_VERSION"

# Build dynamic frameworks for platforms that support Rust cdylibs and static
# frameworks for watchOS, where Rust does not support cdylib outputs. Keep
# DWARF in release builds so dsymutil can produce useful dSYMs for dynamic
# slices, and so static watchOS objects still carry debug info into the final
# app dSYM.
export CARGO_PROFILE_RELEASE_STRIP="${CARGO_PROFILE_RELEASE_STRIP:-false}"
export CARGO_PROFILE_RELEASE_DEBUG="${CARGO_PROFILE_RELEASE_DEBUG:-full}"
export CARGO_PROFILE_RELEASE_SPLIT_DEBUGINFO="${CARGO_PROFILE_RELEASE_SPLIT_DEBUGINFO:-packed}"

python3 - "$FFF_SOURCE_DIR/crates/fff-c/Cargo.toml" <<'PY'
from pathlib import Path
import re
import sys
path = Path(sys.argv[1])
text = path.read_text()
text = re.sub(r'crate-type = \[[^\]]+\]', 'crate-type = ["cdylib", "staticlib"]', text)
path.write_text(text)
PY

# libgit2's vendored C build compiles process-spawning code that references
# fork/execve. Those APIs are unavailable on tvOS and watchOS, even when the
# functions are unused by FFFSearch. Patch the vendored source so those targets
# compile and return a runtime error if process spawning is requested.
cargo fetch --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" >/dev/null
LIBGIT2_SYS_VERSION="$(
  python3 - "$FFF_SOURCE_DIR/Cargo.lock" <<'PY'
from pathlib import Path
import sys

lines = Path(sys.argv[1]).read_text().splitlines()
for index, line in enumerate(lines):
    if line == 'name = "libgit2-sys"':
        for candidate in lines[index + 1:index + 8]:
            if candidate.startswith('version = '):
                print(candidate.split('"', 2)[1])
                raise SystemExit
raise SystemExit('Could not read libgit2-sys version from Cargo.lock')
PY
)"
LIBGIT2_SYS_SOURCE="$(find "${CARGO_HOME:-$HOME/.cargo}/registry/src" -path "*/libgit2-sys-${LIBGIT2_SYS_VERSION}" -type d | head -n 1)"
if [[ -z "$LIBGIT2_SYS_SOURCE" ]]; then
  echo "Could not locate libgit2-sys ${LIBGIT2_SYS_VERSION} source in Cargo registry" >&2
  exit 1
fi
PATCHED_LIBGIT2_SYS="$BUILD_DIR/libgit2-sys-patched"
cp -R "$LIBGIT2_SYS_SOURCE" "$PATCHED_LIBGIT2_SYS"
python3 - "$PATCHED_LIBGIT2_SYS/libgit2/src/util/unix/process.c" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
if '#include <TargetConditionals.h>' not in text:
    text = text.replace(
        '#ifdef __APPLE__\n\t#include <crt_externs.h>',
        '#ifdef __APPLE__\n\t#include <TargetConditionals.h>\n\t#include <crt_externs.h>'
    )
start = 'int git_process_start(git_process *process)\n{\n'
if 'process spawning is unavailable on this Apple platform' not in text:
    text = text.replace(
        start,
        start + '#if defined(__APPLE__) && ((defined(TARGET_OS_TV) && TARGET_OS_TV) || (defined(TARGET_OS_WATCH) && TARGET_OS_WATCH))\n'
                '\t(void)process;\n'
                '\tgit_error_set(GIT_ERROR_OS, "process spawning is unavailable on this Apple platform");\n'
                '\treturn -1;\n'
                '#else\n',
        1
    )
    end = 'on_error:\n\tCLOSE_FD(in[0]);     CLOSE_FD(in[1]);\n\tCLOSE_FD(out[0]);    CLOSE_FD(out[1]);\n\tCLOSE_FD(err[0]);    CLOSE_FD(err[1]);\n\tCLOSE_FD(status[0]); CLOSE_FD(status[1]);\n\treturn -1;\n}\n\nint git_process_id'
    repl = 'on_error:\n\tCLOSE_FD(in[0]);     CLOSE_FD(in[1]);\n\tCLOSE_FD(out[0]);    CLOSE_FD(out[1]);\n\tCLOSE_FD(err[0]);    CLOSE_FD(err[1]);\n\tCLOSE_FD(status[0]); CLOSE_FD(status[1]);\n\treturn -1;\n#endif\n}\n\nint git_process_id'
    if end not in text:
        raise SystemExit('could not find git_process_start end marker')
    text = text.replace(end, repl, 1)
path.write_text(text)
PY
python3 - "$FFF_SOURCE_DIR/Cargo.toml" "$PATCHED_LIBGIT2_SYS" <<'PY'
from pathlib import Path
import sys
manifest = Path(sys.argv[1])
patch_path = Path(sys.argv[2]).resolve()
text = manifest.read_text()
line = f'libgit2-sys = {{ path = "{patch_path}" }}'
lines = [l for l in text.splitlines() if not l.startswith('libgit2-sys = { path = ')]
text = '\n'.join(lines).rstrip() + '\n'
if '[patch.crates-io]' in text:
    text = text.replace('[patch.crates-io]\n', f'[patch.crates-io]\n{line}\n', 1)
else:
    text += f'\n[patch.crates-io]\n{line}\n'
manifest.write_text(text)
PY

required_targets=(
  aarch64-apple-darwin
  x86_64-apple-darwin
  aarch64-apple-ios
  aarch64-apple-ios-sim
  aarch64-apple-tvos
  aarch64-apple-tvos-sim
  aarch64-apple-visionos
  aarch64-apple-visionos-sim
  aarch64-apple-watchos
  aarch64-apple-watchos-sim
)

optional_targets=(
  # Rust currently ships this simulator target, but not every Apple simulator
  # or watch device target has prebuilt standard libraries on every toolchain.
  x86_64-apple-ios
  x86_64-apple-tvos
  x86_64-apple-watchos-sim
  arm64_32-apple-watchos
  armv7k-apple-watchos
)

for target in "${required_targets[@]}"; do
  rustup target add "$target" >/dev/null
done

available_optional_targets=()
for target in "${optional_targets[@]}"; do
  if rustup target add "$target" >/dev/null 2>&1; then
    available_optional_targets+=("$target")
  else
    echo "Skipping optional Rust target without prebuilt std: $target"
  fi
done

has_optional_target() {
  local needle="$1"
  local target
  for target in "${available_optional_targets[@]}"; do
    [[ "$target" == "$needle" ]] && return 0
  done
  return 1
}

build_target() {
  local target="$1"
  echo "==> Building $target"

  case "$target" in
    *-apple-darwin)
      MACOSX_DEPLOYMENT_TARGET=13.0 \
        cargo build --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" -p fff-c --release --target "$target"
      ;;
    *-apple-ios|*-apple-ios-sim)
      IPHONEOS_DEPLOYMENT_TARGET=13.0 \
        cargo build --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" -p fff-c --release --target "$target"
      ;;
    *-apple-tvos|*-apple-tvos-sim)
      TVOS_DEPLOYMENT_TARGET=13.0 \
        cargo build --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" -p fff-c --release --target "$target"
      ;;
    *-apple-visionos|*-apple-visionos-sim)
      XROS_DEPLOYMENT_TARGET=1.0 \
        cargo build --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" -p fff-c --release --target "$target"
      ;;
    *-apple-watchos|*-apple-watchos-sim)
      WATCHOS_DEPLOYMENT_TARGET=9.0 \
        cargo build --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" -p fff-c --release --target "$target"
      ;;
    *)
      cargo build --manifest-path "$FFF_SOURCE_DIR/Cargo.toml" -p fff-c --release --target "$target"
      ;;
  esac
}

make_info_plist() {
  local plist="$1"
  cat > "$plist" <<PLIST
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
  <string>${FFF_BUNDLE_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${FFF_BUNDLE_VERSION}</string>
</dict>
</plist>
PLIST
}

make_modulemap() {
  local modulemap="$1"
  cat > "$modulemap" <<'MODULEMAP'
framework module CFFF {
  umbrella header "fff.h"
  export *
  module * { export * }
}
MODULEMAP
}

install_framework_metadata() {
  local headers_dir="$1"
  local modules_dir="$2"
  local plist="$3"
  mkdir -p "$headers_dir" "$modules_dir" "$(dirname "$plist")"
  cp "$FFF_SOURCE_DIR/crates/fff-c/include/fff.h" "$headers_dir/fff.h"
  make_modulemap "$modules_dir/module.modulemap"
  make_info_plist "$plist"
}

finish_shallow_framework_bundle() {
  local framework="$1"
  install_framework_metadata "$framework/Headers" "$framework/Modules" "$framework/Info.plist"
}

finish_versioned_framework_bundle() {
  local framework="$1"
  install_framework_metadata \
    "$framework/Versions/A/Headers" \
    "$framework/Versions/A/Modules" \
    "$framework/Versions/A/Resources/Info.plist"

  ln -s A "$framework/Versions/Current"
  ln -s Versions/Current/CFFF "$framework/CFFF"
  ln -s Versions/Current/Headers "$framework/Headers"
  ln -s Versions/Current/Modules "$framework/Modules"
  ln -s Versions/Current/Resources "$framework/Resources"
}

make_dsym_info_plist() {
  local plist="$1"
  cat > "$plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>English</string>
  <key>CFBundleIdentifier</key>
  <string>com.apple.xcode.dsym.CFFF</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundlePackageType</key>
  <string>dSYM</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
PLIST
}

make_dsym_from_rust_outputs() {
  local identifier="$1"
  shift
  local targets=("$@")
  local dsym="$BUILD_DIR/$identifier/CFFF.framework.dSYM"

  mkdir -p "$dsym/Contents/Resources/DWARF"
  make_dsym_info_plist "$dsym/Contents/Info.plist"

  local dwarf_inputs=()
  local target
  for target in "${targets[@]}"; do
    local source_dsym="$FFF_SOURCE_DIR/target/$target/release/libfff_c.dylib.dSYM"
    local source_dwarf="$source_dsym/Contents/Resources/DWARF/libfff_c.dylib"
    if [[ ! -f "$source_dwarf" ]]; then
      echo "Missing Rust-generated dSYM DWARF: $source_dwarf" >&2
      exit 1
    fi
    dwarf_inputs+=("$source_dwarf")
    if [[ -d "$source_dsym/Contents/Resources/Relocations" ]]; then
      mkdir -p "$dsym/Contents/Resources/Relocations"
      cp -R "$source_dsym/Contents/Resources/Relocations/." "$dsym/Contents/Resources/Relocations/"
    fi
  done

  if [[ "${#dwarf_inputs[@]}" -eq 1 ]]; then
    cp "${dwarf_inputs[0]}" "$dsym/Contents/Resources/DWARF/CFFF"
  else
    lipo -create "${dwarf_inputs[@]}" -output "$dsym/Contents/Resources/DWARF/CFFF"
  fi
}

make_dynamic_framework() {
  local identifier="$1"
  shift
  local targets=("$@")
  local framework="$BUILD_DIR/$identifier/CFFF.framework"
  local binary="$framework/CFFF"
  local install_name="@rpath/CFFF.framework/CFFF"

  if [[ "$identifier" == "macos" ]]; then
    mkdir -p "$framework/Versions/A"
    binary="$framework/Versions/A/CFFF"
    install_name="@rpath/CFFF.framework/Versions/A/CFFF"
  else
    mkdir -p "$framework/Headers" "$framework/Modules"
  fi

  local inputs=()
  local target
  for target in "${targets[@]}"; do
    inputs+=("$FFF_SOURCE_DIR/target/$target/release/libfff_c.dylib")
  done

  echo "==> Packaging dynamic $identifier (${targets[*]})"
  if [[ "${#inputs[@]}" -eq 1 ]]; then
    cp "${inputs[0]}" "$binary"
  else
    lipo -create "${inputs[@]}" -output "$binary"
  fi

  install_name_tool -id "$install_name" "$binary"
  if [[ "$identifier" == "macos" ]]; then
    finish_versioned_framework_bundle "$framework"
  else
    finish_shallow_framework_bundle "$framework"
  fi

  echo "==> Packaging dSYM for $identifier"
  make_dsym_from_rust_outputs "$identifier" "${targets[@]}"
}

make_static_framework() {
  local identifier="$1"
  shift
  local targets=("$@")
  local framework="$BUILD_DIR/$identifier/CFFF.framework"

  mkdir -p "$framework/Headers" "$framework/Modules"

  local inputs=()
  local target
  for target in "${targets[@]}"; do
    inputs+=("$FFF_SOURCE_DIR/target/$target/release/libfff_c.a")
  done

  echo "==> Packaging static $identifier (${targets[*]})"
  if [[ "${#inputs[@]}" -eq 1 ]]; then
    cp "${inputs[0]}" "$framework/CFFF"
  else
    lipo -create "${inputs[@]}" -output "$framework/CFFF"
  fi

  finish_shallow_framework_bundle "$framework"
}

all_build_targets=("${required_targets[@]}" "${available_optional_targets[@]}")
for target in "${all_build_targets[@]}"; do
  build_target "$target"
done

macos_targets=(aarch64-apple-darwin x86_64-apple-darwin)
ios_simulator_targets=(aarch64-apple-ios-sim)
tvos_simulator_targets=(aarch64-apple-tvos-sim)
watchos_device_targets=(aarch64-apple-watchos)
watchos_simulator_targets=(aarch64-apple-watchos-sim)

has_optional_target x86_64-apple-ios && ios_simulator_targets+=(x86_64-apple-ios)
has_optional_target x86_64-apple-tvos && tvos_simulator_targets+=(x86_64-apple-tvos)
has_optional_target arm64_32-apple-watchos && watchos_device_targets+=(arm64_32-apple-watchos)
has_optional_target armv7k-apple-watchos && watchos_device_targets+=(armv7k-apple-watchos)
has_optional_target x86_64-apple-watchos-sim && watchos_simulator_targets+=(x86_64-apple-watchos-sim)

make_dynamic_framework macos "${macos_targets[@]}"
make_dynamic_framework ios aarch64-apple-ios
make_dynamic_framework ios-simulator "${ios_simulator_targets[@]}"
make_dynamic_framework tvos aarch64-apple-tvos
make_dynamic_framework tvos-simulator "${tvos_simulator_targets[@]}"
make_dynamic_framework visionos aarch64-apple-visionos
make_dynamic_framework visionos-simulator aarch64-apple-visionos-sim
make_static_framework watchos "${watchos_device_targets[@]}"
make_static_framework watchos-simulator "${watchos_simulator_targets[@]}"

xcframework_args=()
while IFS= read -r -d '' framework; do
  xcframework_args+=("-framework" "$framework")
  dsym="$(dirname "$framework")/CFFF.framework.dSYM"
  if [[ -d "$dsym" ]]; then
    xcframework_args+=("-debug-symbols" "$(cd "$(dirname "$dsym")" && pwd)/$(basename "$dsym")")
  fi
done < <(find "$BUILD_DIR" -maxdepth 3 -name CFFF.framework -type d -print0 | sort -z)

xcodebuild -create-xcframework \
  "${xcframework_args[@]}" \
  -output "$OUTPUT_DIR"

plutil -p "$OUTPUT_DIR/Info.plist"
find "$OUTPUT_DIR" -path '*/CFFF.framework/CFFF' -print0 | sort -z | while IFS= read -r -d '' binary; do
  echo "==> $binary"
  lipo -info "$binary"
done
find "$OUTPUT_DIR" -name '*.dSYM' -type d -print0 | sort -z | while IFS= read -r -d '' dsym; do
  echo "==> $dsym"
  dwarfdump --uuid "$dsym" || true
done
