# FFFSearch

SwiftPM wrapper for [FFF](https://github.com/dmtrKovalenko/fff).

FFF is written in Rust, so this package uses a prebuilt `CFFF.xcframework` from GitHub Releases. The binary is not committed to the repo.

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
make update
make binary-info
```

`make update` fetches the latest stable upstream FFF release and rebuilds ignored `Binary/CFFF.xcframework`. Use `FFF_REF` or `FFF_SOURCE_DIR` only when testing a specific upstream checkout.

## Release

```bash
make release
```

`make release` uses the latest stable upstream FFF C API version by default. It rebuilds `CFFF.xcframework`, zips it, computes the SwiftPM checksum, updates `Package.swift`, commits the change, tags the release, pushes the current branch and tag, then creates or updates the GitHub release asset.

To override the release version:

```bash
make release VERSION=0.9.6
```

For manual release steps:

```bash
make prepare-binary-release VERSION=0.9.6
git add Package.swift
git commit -m "Release 0.9.6"
git tag 0.9.6
git push origin main 0.9.6
make publish-binary-release VERSION=0.9.6
```

## License

MIT.
