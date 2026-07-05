#!/usr/bin/env python3
import re
import sys


STABLE_RELEASE_TAG = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")


def latest_release_tag(tags: list[str]) -> str:
    candidates: list[tuple[tuple[int, int, int, bool], str]] = []

    for raw_tag in tags:
        tag = raw_tag.strip()
        match = STABLE_RELEASE_TAG.fullmatch(tag)
        if not match:
            continue

        major, minor, patch = (int(part) for part in match.groups())
        candidates.append(((major, minor, patch, tag.startswith("v")), tag))

    if not candidates:
        raise ValueError("No stable FFF release tags found")

    return max(candidates)[1]


def main() -> int:
    try:
        print(latest_release_tag(sys.stdin.readlines()))
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
