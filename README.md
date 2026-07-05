# FFFSearch

SwiftPM wrapper for [FFF](https://github.com/dmtrKovalenko/fff).

FFF is Rust, so this package uses a prebuilt `CFFF.xcframework` from GitHub Releases. The binary is not committed here.

## Install

```swift
.package(url: "https://github.com/krzyzanowskim/FFFSearch.git", from: "0.9.6")
```

Depend on the `FFFSearch` product.

## Build

```bash
make
```

For local binary work:

```bash
make rebuild-binary
make binary-info
```

`make rebuild-binary` builds the latest stable upstream FFF release into ignored `Binary/CFFF.xcframework`. Use `FFF_REF` or `FFF_SOURCE_DIR` only when testing a specific upstream checkout.

## Release

```bash
make prepare-binary-release VERSION=0.9.6
git add Package.swift
git commit -m "Release 0.9.6"
git tag 0.9.6
git push origin main 0.9.6
make publish-binary-release VERSION=0.9.6
```

The prepare step builds the zip, computes the SwiftPM checksum, and updates `Package.swift`. The publish step uploads that zip to the matching GitHub release.

## License

MIT.
