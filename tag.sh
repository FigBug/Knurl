#!/bin/bash -e
# Tags the version in VERSION and pushes the tag, which triggers the release workflow.
cd "$(dirname "$0")"
VER=$(cat VERSION)

if ! grep -q "^${VER}:*$" Changelist.txt; then
    echo "Error: Version $VER not found in Changelist.txt"
    exit 1
fi

echo "Tagging [$VER]"
git tag "$VER" && git push origin "$VER"
