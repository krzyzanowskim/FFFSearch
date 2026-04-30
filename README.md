# FFFSearch

Standalone SwiftPM package that exposes [FFF](https://github.com/dmtrKovalenko/fff) file search to Swift.

The package intentionally ships FFF as a binary XCFramework. Upstream FFF is a Rust project, and SwiftPM cannot compile Rust sources as ordinary package targets. The included build script provides a reproducible source rebuild path for the binary artifact.

## Contents

- `Binary/CFFF.xcframework` — framework-wrapped universal macOS build of FFF's `fff-c` library.
- `Sources/FFFSearch` — Swift wrapper around the C API.
- `scripts/build-fff-xcframework.sh` — rebuilds the binary artifact from FFF source.
- `Makefile` — convenience targets for full rebuilds and package checks.

## Requirements

- macOS 13 or newer.
- SwiftPM / Xcode command line tools.
- Rust and `rustup` when rebuilding `Binary/CFFF.xcframework`.

## Usage

Add the package as a dependency and depend on the `FFFSearch` product:

```swift
.package(url: "<package-url>", from: "0.1.0")
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

The rebuild script pins FFF to commit `ca7bf03` by default and builds both `aarch64-apple-darwin` and `x86_64-apple-darwin` slices. Override `FFF_REF` or `FFF_SOURCE_DIR` for local experiments:

```bash
FFF_REF=<commit> make rebuild-binary
FFF_SOURCE_DIR=/path/to/fff FFF_SKIP_CHECKOUT=1 make rebuild-binary
```
