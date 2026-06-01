#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="GatewaySwitcher"
WIDGET_NAME="GatewaySwitcherWidgetExtension"
BUNDLE_ID="com.wenlanjun.GatewaySwitcher"
MIN_SYSTEM_VERSION="13.0"
INSTALL_APP_BUNDLE="/Applications/$APP_NAME.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if ! swift build; then
  echo "SwiftPM build failed" >&2
  exit 1
fi

BUILD_DIR="$(swift build --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"

cp "$BUILD_DIR/$APP_NAME" "$APP_BINARY"
chmod +x "$APP_BINARY"

# Bundle assets
if [[ -d "Sources/GatewaySwitcherApp/Resources/Assets.xcassets" ]]; then
  cp -R Sources/GatewaySwitcherApp/Resources/Assets.xcassets "$APP_RESOURCES/Assets.xcassets"
fi

cp "$ROOT_DIR/script/install_passwordless_helper.sh" "$APP_RESOURCES/install_passwordless_helper.sh"
chmod +x "$APP_RESOURCES/install_passwordless_helper.sh"

# Bundle widget extension if built
WIDGET_BINARY="$BUILD_DIR/$WIDGET_NAME"
if [[ -x "$WIDGET_BINARY" ]]; then
  WIDGET_PLUGINS="$APP_CONTENTS/PlugIns"
  WIDGET_APPEX="$WIDGET_PLUGINS/$WIDGET_NAME.appex"
  mkdir -p "$WIDGET_PLUGINS/$WIDGET_NAME.appex/Contents/MacOS"
  mkdir -p "$WIDGET_PLUGINS/$WIDGET_NAME.appex/Contents/Resources"
  cp "$WIDGET_BINARY" "$WIDGET_PLUGINS/$WIDGET_NAME.appex/Contents/MacOS/$WIDGET_NAME"
  chmod +x "$WIDGET_PLUGINS/$WIDGET_NAME.appex/Contents/MacOS/$WIDGET_NAME"

  if [[ -f "Config/Widget/Info.plist" ]]; then
    cp Config/Widget/Info.plist "$WIDGET_APPEX/Contents/Info.plist"
  fi
fi

# Generate app Info.plist
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
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>$BUNDLE_ID</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>gatewayswitcher</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

register_app_bundle() {
  [[ -x "$LSREGISTER" ]] && "$LSREGISTER" -f -R -trusted "$APP_BUNDLE" >/dev/null 2>&1 || true

  local widget_extension="$APP_BUNDLE/Contents/PlugIns/$WIDGET_NAME.appex"
  if [[ -d "$widget_extension" ]] && command -v pluginkit >/dev/null 2>&1; then
    pluginkit -a "$widget_extension" >/dev/null 2>&1 || true
  fi
}

warn_unsigned_widget() {
  local widget_extension="$APP_BUNDLE/Contents/PlugIns/$WIDGET_NAME.appex"
  [[ -d "$widget_extension" ]] || return

  local signing_info
  signing_info="$(/usr/bin/codesign -dv "$widget_extension" 2>&1 || true)"
  if ! /usr/bin/grep -q "TeamIdentifier=" <<<"$signing_info" || /usr/bin/grep -q "TeamIdentifier=not set" <<<"$signing_info"; then
    cat >&2 <<EOF
warning: Widget extension is ad-hoc signed. macOS usually will not show ad-hoc signed widgets in the desktop widget gallery.
Set DEVELOPMENT_TEAM=<your Apple Developer Team ID> and run '$0 --install' to build with Apple Development signing and install to /Applications.
EOF
  fi
}

install_app() {
  rm -rf "$INSTALL_APP_BUNDLE"
  /usr/bin/ditto "$APP_BUNDLE" "$INSTALL_APP_BUNDLE"
  APP_BUNDLE="$INSTALL_APP_BUNDLE"
  APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
}

open_app() {
  warn_unsigned_widget
  register_app_bundle
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --install|install)
    install_app
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
    echo "usage: $0 [run|--install|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac