#!/bin/bash
# Builds World Clock.app with its widget extension using only the Command Line Tools,
# signs it ad-hoc, installs it to ~/Applications and registers the widget.
#
#     scripts/build.sh            build, check, install, open
#     scripts/build.sh --no-install   build and check only
set -euo pipefail
cd "$(dirname "$0")/.."

export SDKROOT="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk}"   # macOS 27 SDK needs Xcode for SwiftUI macros
INSTALL_DIR="~/Applications"   # absolute: $HOME differs in Claude's sandboxed sessions
VERSION="$(date +%Y%m%d%H%M)"   # bump every build, or chronod keeps the old extension
APP="build/World Clock.app"
APPEX="$APP/Contents/PlugIns/WorldClockWidget.appex"
EXT_BIN="$APPEX/Contents/MacOS/WorldClockWidget"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

fail() { echo "    FAIL: $*" >&2; exit 1; }
# Checks pipe into plain `grep >/dev/null`, never `grep -q`: with pipefail, -q exits at the
# first match, the writer dies of SIGPIPE (141) and a present symbol reads as missing.

echo "==> swift build (release)"
swift build -c release --product WorldClock
swift build -c release --product WorldClockExtension
BIN="$(swift build -c release --show-bin-path)"

echo "==> Assemble $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APPEX/Contents/MacOS" "$APPEX/Contents/Resources"
cp "$BIN/WorldClock" "$APP/Contents/MacOS/WorldClock"
cp "$BIN/WorldClockExtension" "$EXT_BIN"
cp Resources/App-Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"   # drawn by scripts/make_icon.swift
cp Resources/Widget-Info.plist "$APPEX/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APPEX/Contents/Info.plist"
cp Resources/cities.tsv Resources/regions.tsv Resources/abbreviations.tsv "$APPEX/Contents/Resources/"   # the app reads these copies too

echo "==> Checks"
nm -u "$EXT_BIN" | grep "_NSExtensionMain" >/dev/null || fail "extension does not start in _NSExtensionMain"
echo "    ok: entry point _NSExtensionMain"
plutil -lint "$APP/Contents/Info.plist" "$APPEX/Contents/Info.plist" >/dev/null || fail "Info.plist invalid"

echo "==> Sign (ad-hoc): extension first with its sandbox, then the app"
codesign --force --sign - --timestamp=none --entitlements Resources/Widget.entitlements "$APPEX"
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP" || fail "signature does not verify"
codesign -d --entitlements - "$APPEX" 2>/dev/null | grep app-sandbox >/dev/null || fail "extension lost its sandbox entitlement"
codesign -d --entitlements - "$APPEX" 2>/dev/null | grep shared-preference.read-only >/dev/null \
    || fail "extension cannot read the app's settings (shared-preference exception missing)"
echo "    ok: signed, sandbox kept, reads the app's settings"

[ "${1:-}" = "--no-install" ] && { echo "==> Built $APP (not installed)"; exit 0; }

echo "==> Install to $INSTALL_DIR"
killall WorldClockWidget 2>/dev/null || true   # a running extension keeps the old code loaded
killall WorldClock 2>/dev/null || true         # so does the menu bar app, which stays running
for _ in $(seq 50); do pgrep -x WorldClock >/dev/null || break; sleep 0.1; done   # `open` fails (-600) while it quits
mkdir -p "$INSTALL_DIR"
INSTALLED="$INSTALL_DIR/World Clock.app"
rm -rf "$INSTALLED"
cp -R "$APP" "$INSTALLED"
"$LSREGISTER" -f "$INSTALLED"
pluginkit -a "$INSTALLED/Contents/PlugIns/WorldClockWidget.appex"
pluginkit -m -p com.apple.widgetkit-extension -i com.jasonaldemita.worldclock.widget -v | sed 's/^/    /'
open "$INSTALLED"
echo "==> Installed $INSTALLED (version $VERSION)"
