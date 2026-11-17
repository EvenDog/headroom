#!/usr/bin/env bash
# Publishes a Headroom build to GitHub: creates the release v<version> on main with the DMG and appcast.xml
# attached. Installed copies check that appcast (through releases/latest/download), so every release must
# carry one. Run script/release.sh for the same version first.
#
# Usage: script/publish_release.sh <version> <release-notes-file>
#   e.g. script/publish_release.sh 1.0.2 notes.md
set -euo pipefail

VERSION="${1:?usage: script/publish_release.sh <version> <release-notes-file>}"
NOTES_FILE="${2:?usage: script/publish_release.sh <version> <release-notes-file>}"
REPO="EvenDog/headroom"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG="$ROOT_DIR/dist/Headroom-$VERSION.dmg"
APPCAST="$ROOT_DIR/dist/appcast.xml"

[ -f "$DMG" ] || { echo "Missing $DMG. Run script/release.sh for $VERSION first." >&2; exit 1; }
[ -f "$APPCAST" ] || { echo "Missing $APPCAST. Run script/release.sh for $VERSION first." >&2; exit 1; }
[ -f "$NOTES_FILE" ] || { echo "Missing release notes file: $NOTES_FILE" >&2; exit 1; }
# The appcast must describe this exact version and DMG, or installed copies would be pointed at the wrong file.
grep -q "<sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>" "$APPCAST" \
  || { echo "$APPCAST is not for $VERSION. Run script/release.sh for $VERSION again." >&2; exit 1; }
grep -q "releases/download/v$VERSION/Headroom-$VERSION.dmg" "$APPCAST" \
  || { echo "$APPCAST points at a different download than Headroom-$VERSION.dmg." >&2; exit 1; }

echo "==> publishing Headroom $VERSION to github.com/$REPO"
gh release create "v$VERSION" "$DMG" "$APPCAST" \
  --repo "$REPO" --target main --title "Headroom $VERSION" --notes-file "$NOTES_FILE"
echo "==> done: https://github.com/$REPO/releases/tag/v$VERSION"
