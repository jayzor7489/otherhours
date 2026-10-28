#!/bin/bash
# Builds Otherhours.app and zips it for a GitHub release: build/Otherhours-<version>.zip.
# The app is ad-hoc signed, not notarized; the README tells downloaders how to open it.
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/build.sh --no-install
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/App-Info.plist)"
ZIP="build/Otherhours-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent build/Otherhours.app "$ZIP"   # ditto keeps the signature intact; plain zip can break it
shasum -a 256 "$ZIP"
echo "==> $ZIP"
