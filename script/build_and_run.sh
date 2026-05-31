#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="GatewaySwitcher"
BUNDLE_ID="com.wenlanjun.GatewaySwitcher"
MIN_SYSTEM_VERSION="13.0"
INSTALL_APP_BUNDLE="/Applications/$APP_NAME.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
XCODE_PROJECT="$ROOT_DIR/GatewaySwitcher.xcodeproj"
XCODE_DERIVED_DATA="$ROOT_DIR/.xcode-derived"
XCODE_APP_BUNDLE="$XCODE_DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ -d "$XCODE_PROJECT" ]] && command -v xcodebuild >/dev/null 2>&1; then
  XCODEBUILD_ARGS=(
    -project "$XCODE_PROJECT"
    -scheme "$APP_NAME"
    -configuration Debug
    -derivedDataPath "$XCODE_DERIVED_DATA"
    build
  )

  if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
    XCODEBUILD_ARGS+=(
      -allowProvisioningUpdates
      CODE_SIGN_STYLE=Automatic
      DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
      CODE_SIGN_IDENTITY="Apple Development"
    )
  fi

  xcodebuild "${XCODEBUILD_ARGS[@]}"
  rm -rf "$APP_BUNDLE"
  mkdir -p "$DIST_DIR"
  /usr/bin/ditto "$XCODE_APP_BUNDLE" "$APP_BUNDLE"
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

register_app_bundle() {
  [[ -x "$LSREGISTER" ]] && "$LSREGISTER" -f -R -trusted "$APP_BUNDLE" >/dev/null 2>&1 || true

  local widget_extension="$APP_BUNDLE/Contents/PlugIns/GatewaySwitcherWidgetExtension.appex"
  if [[ -d "$widget_extension" ]] && command -v pluginkit >/dev/null 2>&1; then
    pluginkit -a "$widget_extension" >/dev/null 2>&1 || true
  fi
}

warn_unsigned_widget() {
  local widget_extension="$APP_BUNDLE/Contents/PlugIns/GatewaySwitcherWidgetExtension.appex"
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
