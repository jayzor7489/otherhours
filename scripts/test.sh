#!/bin/bash
# swift test, plus the Swift Testing macro plugin path that the Command Line Tools build system
# sometimes fails to pass ("plugin for module 'TestingMacros' not found", seen 2026-10-14).
set -euo pipefail
cd "$(dirname "$0")/.."
export SDKROOT="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk}"   # see Global Constraints
exec swift test -Xswiftc -plugin-path -Xswiftc "$(xcode-select -p)/usr/lib/swift/host/plugins/testing" "$@"
