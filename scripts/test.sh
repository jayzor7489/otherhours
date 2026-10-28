#!/bin/bash
# swift test, plus the Swift Testing macro plugin path that the Command Line Tools build system
# sometimes fails to pass ("plugin for module 'TestingMacros' not found", seen 2026-10-14).
set -euo pipefail
cd "$(dirname "$0")/.."
# The macOS 27 SDK needs Xcode for SwiftUI macros, so prefer 26.5 when it is installed;
# otherwise use whatever SDK the Command Line Tools provide.
PINNED_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
[ -z "${SDKROOT:-}" ] && [ -d "$PINNED_SDK" ] && export SDKROOT="$PINNED_SDK"
exec swift test -Xswiftc -plugin-path -Xswiftc "$(xcode-select -p)/usr/lib/swift/host/plugins/testing" "$@"
