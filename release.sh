#!/bin/bash -e
# Run by the release workflow on a tag push: creates the GitHub release with
# the notes for that version from Changelist.txt and attaches the zipped app.
cd "$(dirname "$0")"

VER="$GITHUB_REF_NAME"

NOTES=$(awk -v ver="$VER" '
    BEGIN { found=0; printing=0; pattern="^"ver":?$" }
    $0 ~ pattern { found=1; printing=1; next }
    printing && /^[0-9]+\.[0-9]+\.[0-9]+:?$/ { printing=0 }
    printing { print }
    END { if (!found) exit 1 }
' ./Changelist.txt) || true

if [ -z "$NOTES" ]; then
    echo "Error: Version $VER not found in Changelist.txt or has no content"
    exit 1
fi

echo "$NOTES" > /tmp/release_notes.txt
gh release create "$VER" --title "Knurl $VER" -F /tmp/release_notes.txt ./Binaries/*.zip
