#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="GatewaySwitcher"
BUNDLE_ID="com.wenlanjun.GatewaySwitcher"
MIN_SYSTEM_VERSION="13.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
XCODE_PROJECT="$ROOT_DIR/GatewaySwitcher.xcodeproj"
XCODE_DERIVED_DATA="$ROOT_DIR/.xcode-derived"
XCODE_APP_BUNDLE="$XCODE_DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ -d "$XCODE_PROJECT" ]] && command -v xcodebuild >/dev/null 2>&1; then
  xcodebuild -project "$XCODE_PROJECT" -scheme "$APP_NAME" -configuration Debug -derivedDataPath "$XCODE_DERIVED_DATA" build
  APP_BUNDLE="$XCODE_APP_BUNDLE"
  APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
else
  if swift build; then
    BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
  else
    echo "SwiftPM build failed; falling back to direct swiftc build." >&2
    MANUAL_BUILD_DIR="$ROOT_DIR/.build/manual"
    mkdir -p "$MANUAL_BUILD_DIR"
    swiftc Sources/GatewayKit/*.swift Sources/GatewaySwitcherApp/*.swift -o "$MANUAL_BUILD_DIR/$APP_NAME"
    BUILD_BINARY="$MANUAL_BUILD_DIR/$APP_NAME"
  fi

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS" "$APP_RESOURCES"
  cp "$BUILD_BINARY" "$APP_BINARY"
  chmod +x "$APP_BINARY"
  cp "$ROOT_DIR/script/install_passwordless_helper.sh" "$APP_RESOURCES/install_passwordless_helper.sh"
  chmod +x "$APP_RESOURCES/install_passwordless_helper.sh"

  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>切换网关</string>
  <key>CFBundleDisplayName</key>
  <string>切换网关</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
