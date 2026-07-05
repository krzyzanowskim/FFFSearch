# FFFSearch

Standalone SwiftPM package that exposes [FFF](https://github.com/dmtrKovalenko/fff) file search to Swift.

The package intentionally ships FFF as a binary XCFramework. Upstream FFF is a Rust project, and SwiftPM cannot compile Rust sources as ordinary package targets. The included build script provides a source rebuild path for the binary artifact; set `FFF_REF` when you need to pin a specific upstream release.

## Contents

- `Binary/CFFF.xcframework` — framework-wrapped Apple platform builds of FFF's `fff-c` library (dynamic with dSYMs for macOS, iOS, tvOS, and visionOS; static for watchOS, where Rust does not support `cdylib`).
- `Sources/FFFSearch` — Swift wrapper around the C API.
- `scripts/build-fff-xcframework.sh` — rebuilds the binary artifact from FFF source.
- `Makefile` — convenience targets for full rebuilds and package checks.

## Requirements

- macOS 13, iOS 13, tvOS 13, visionOS 1, or watchOS 9 or newer.
- SwiftPM / Xcode command line tools.
- Rust and `rustup` when rebuilding `Binary/CFFF.xcframework`.

## Usage

Add the package as a dependency and depend on the `FFFSearch` product:

```swift
.package(url: "git@github.com:krzyzanowskim/FFFSearch.git", from: "0.1.0")
```

For local development:

```swift
.package(path: "../FFFSearch")
```

## Development

```bash
make
```

Running `make` rebuilds the binary artifact, prints binary metadata, builds the Swift package, and runs tests when a `Tests` directory exists.

Common narrower targets:

```bash
make build
make rebuild-binary
make binary-info
```

The rebuild script fetches upstream tags, resolves the latest stable FFF release tag matching `vMAJOR.MINOR.PATCH`, and builds Apple platform slices for macOS, iOS, tvOS, visionOS, and watchOS. It keeps release debug information, emits dSYMs for dynamic framework slices, and leaves watchOS static object debug info available for the consuming app's final dSYM. Some Intel simulator/watch device Rust targets may be unavailable on a given Rust toolchain; the script includes them when `rustup` provides prebuilt standard libraries and skips them otherwise. Override `FFF_REF` or `FFF_SOURCE_DIR` for pinned/local experiments:

```bash
FFF_REF=vX.Y.Z make rebuild-binary
FFF_SOURCE_DIR=/path/to/fff FFF_SKIP_CHECKOUT=1 make rebuild-binary
```
