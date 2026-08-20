#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-prepare}"
VERSION="${2:-${VERSION:-}}"
REPO="${GITHUB_REPOSITORY:-}"
ASSET_NAME="${ASSET_NAME:-CFFF.xcframework.zip}"
XCFRAMEWORK_PATH="${XCFRAMEWORK_PATH:-$ROOT_DIR/Binary/CFFF.xcframework}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/release-cfff-binary.sh prepare [VERSION]
  scripts/release-cfff-binary.sh publish [VERSION]
  scripts/release-cfff-binary.sh release [VERSION]

Modes:
  prepare   Build CFFF.xcframework, zip it for SwiftPM, compute the checksum,
            and update Package.swift with the GitHub release URL.
  publish   Upload the prepared zip to an existing pushed GitHub tag release.
  release   Prepare, commit Package.swift, tag VERSION, push the current branch
            and tag, then publish the GitHub release artifact.

When VERSION is omitted, the latest stable upstream FFF C API version is used.

Environment:
  REPO=owner/name               Override GitHub repository detection.
  ASSET_NAME=name.zip           Override release asset name.
  XCFRAMEWORK_PATH=/path        Override local XCFramework path.
  FFF_REF=vX.Y.Z                Forwarded to build-fff-xcframework.sh.
USAGE
}

if [[ "$MODE" == "-h" || "$MODE" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "$REPO" ]]; then
  if command -v gh >/dev/null; then
    REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
  fi
fi

if [[ -z "$REPO" ]]; then
  remote_url="$(git -C "$ROOT_DIR" remote get-url origin)"
  REPO="$(
    python3 - "$remote_url" <<'PY'
import re
import sys

remote = sys.argv[1]
patterns = [
    r"^git@github\.com:([^/]+/[^/]+?)(?:\.git)?$",
    r"^https://github\.com/([^/]+/[^/]+?)(?:\.git)?$",
]
for pattern in patterns:
    match = re.match(pattern, remote)
    if match:
        print(match.group(1))
        raise SystemExit(0)
raise SystemExit(1)
PY
  )"
fi

resolve_latest_fff_version() {
  local fff_repo_url="${FFF_REPO_URL:-https://github.com/dmtrKovalenko/fff.git}"
  local fff_source_dir="${FFF_SOURCE_DIR:-$ROOT_DIR/.build/fff-source}"
  local fff_ref="${FFF_REF:-}"

  if [[ ! -d "$fff_source_dir/.git" ]]; then
    rm -rf "$fff_source_dir"
    git clone "$fff_repo_url" "$fff_source_dir" >/dev/null
  fi

  git -C "$fff_source_dir" fetch --tags --force --prune --prune-tags origin >/dev/null

  if [[ -z "$fff_ref" ]]; then
    fff_ref="$(git -C "$fff_source_dir" tag --list | python3 "$ROOT_DIR/scripts/select-latest-fff-release.py")"
  fi

  git -C "$fff_source_dir" reset --hard HEAD >/dev/null
  git -C "$fff_source_dir" checkout "$fff_ref" >/dev/null
  git -C "$fff_source_dir" reset --hard "$fff_ref" >/dev/null

  python3 - "$fff_source_dir/crates/fff-c/Cargo.toml" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
match = re.search(r'(?m)^version\s*=\s*"([^"]+)"', text)
if not match:
    raise SystemExit("Could not read fff-c package version")
print(match.group(1))
PY
}

if [[ -z "$VERSION" ]]; then
  VERSION="$(resolve_latest_fff_version)"
fi

if [[ -z "$VERSION" ]]; then
  usage
  exit 64
fi

echo "==> Release version: $VERSION"

ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT_DIR/.build/artifacts/$VERSION}"
ARCHIVE_PATH="$ARTIFACT_DIR/$ASSET_NAME"
RELEASE_URL="https://github.com/$REPO/releases/download/$VERSION/$ASSET_NAME"

update_package_manifest() {
  local release_url="$1"
  local checksum="$2"

  python3 - "$ROOT_DIR/Package.swift" "$release_url" "$checksum" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
release_url = sys.argv[2]
checksum = sys.argv[3]
text = path.read_text()

pattern = re.compile(
    r'\.binaryTarget\(\s*name:\s*"CFFF",\s*'
    r'(?:(?:path:\s*"[^"]+")|(?:url:\s*"[^"]+",\s*checksum:\s*"[^"]+"))\s*\)',
    re.MULTILINE,
)
replacement = (
    '.binaryTarget(\n'
    '            name: "CFFF",\n'
    f'            url: "{release_url}",\n'
    f'            checksum: "{checksum}"\n'
    '        )'
)
updated, count = pattern.subn(replacement, text)
if count != 1:
    raise SystemExit(f"Expected to update one CFFF binaryTarget, updated {count}")
path.write_text(updated)
PY
}

require_clean_tracked_worktree() {
  if ! git -C "$ROOT_DIR" diff --quiet || ! git -C "$ROOT_DIR" diff --cached --quiet; then
    echo "Working tree has tracked changes; commit or stash them before release." >&2
    exit 1
  fi
}

prepare() {
  "$ROOT_DIR/scripts/build-fff-xcframework.sh"

  if [[ ! -d "$XCFRAMEWORK_PATH" ]]; then
    echo "Missing XCFramework at $XCFRAMEWORK_PATH" >&2
    exit 1
  fi

  rm -rf "$ARTIFACT_DIR"
  mkdir -p "$ARTIFACT_DIR"
  ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_PATH" "$ARCHIVE_PATH"

  checksum="$(swift package compute-checksum "$ARCHIVE_PATH")"

  update_package_manifest "$RELEASE_URL" "$checksum"

  echo "Archive: $ARCHIVE_PATH"
  echo "URL: $RELEASE_URL"
  echo "Checksum: $checksum"
}

publish() {
  if ! command -v gh >/dev/null; then
    echo "GitHub CLI is required for publish mode." >&2
    exit 1
  fi

  if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "Missing archive at $ARCHIVE_PATH; run prepare first." >&2
    exit 1
  fi

  if ! git ls-remote --exit-code --tags origin "refs/tags/$VERSION" >/dev/null; then
    echo "Remote tag $VERSION does not exist on origin." >&2
    echo "Commit Package.swift, tag the release commit, and push the tag before publishing." >&2
    exit 1
  fi

  if gh release view "$VERSION" --repo "$REPO" >/dev/null 2>&1; then
    gh release upload "$VERSION" "$ARCHIVE_PATH" --repo "$REPO" --clobber
  else
    gh release create "$VERSION" "$ARCHIVE_PATH" \
      --repo "$REPO" \
      --title "$VERSION" \
      --notes "CFFF binary artifact for FFFSearch $VERSION."
  fi
}

release() {
  if ! command -v gh >/dev/null; then
    echo "GitHub CLI is required for release mode." >&2
    exit 1
  fi

  branch="$(git -C "$ROOT_DIR" branch --show-current)"
  if [[ -z "$branch" ]]; then
    echo "Cannot release from detached HEAD." >&2
    exit 1
  fi

  require_clean_tracked_worktree

  if git -C "$ROOT_DIR" rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
    echo "Local tag $VERSION already exists." >&2
    exit 1
  fi

  if git -C "$ROOT_DIR" ls-remote --exit-code --tags origin "refs/tags/$VERSION" >/dev/null 2>&1; then
    echo "Remote tag $VERSION already exists on origin." >&2
    exit 1
  fi

  prepare

  git -C "$ROOT_DIR" add Package.swift
  if git -C "$ROOT_DIR" diff --cached --quiet -- Package.swift; then
    echo "Package.swift did not change; refusing to create an empty release commit." >&2
    exit 1
  fi

  git -C "$ROOT_DIR" commit -m "Release $VERSION"
  git -C "$ROOT_DIR" tag "$VERSION"
  git -C "$ROOT_DIR" push origin "$branch" "$VERSION"
  publish
}

case "$MODE" in
  prepare)
    prepare
    ;;
  publish)
    publish
    ;;
  release)
    release
    ;;
  *)
    usage
    exit 64
    ;;
esac
