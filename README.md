# FFFSearchPackage

SwiftPM wrapper for FFF file search used by Commander.

## Contents

- `Binary/CFFF.xcframework` — framework-wrapped universal macOS build of FFF's `fff-c` library.
- `Sources/FFFSearch` — Swift wrapper around the C API.
- `scripts/build-fff-xcframework.sh` — rebuilds the binary artifact from FFF source.

## Rebuild binary artifact

```bash
scripts/build-fff-xcframework.sh
```

The script pins FFF to commit `ca7bf03` by default and builds both `aarch64-apple-darwin` and `x86_64-apple-darwin` slices. Override `FFF_REF` or `FFF_SOURCE_DIR` for local experiments.

## Commander integration

Commander expects this package as a sibling checkout:

```text
~/Devel/Commander
~/Devel/FFFSearchPackage
```
