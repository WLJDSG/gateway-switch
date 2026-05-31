#!/usr/bin/env bash
set -euo pipefail

HELPER_PATH="/usr/local/bin/gateway-switcher-helper"
SUDOERS_PATH="/etc/sudoers.d/gateway-switcher"
CONSOLE_USER="$(/usr/bin/stat -f %Su /dev/console)"

if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" ]]; then
  echo "Cannot determine the logged-in user." >&2
  exit 1
fi

/bin/mkdir -p /usr/local/bin

/bin/cat >"$HELPER_PATH" <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail

NETWORKSETUP="/usr/sbin/networksetup"
ROUTE="/sbin/route"
DSCACHEUTIL="/usr/bin/dscacheutil"
KILLALL="/usr/bin/killall"

is_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r a b c d <<<"$ip"
  for octet in "$a" "$b" "$c" "$d"; do
    [[ "$octet" =~ ^[0-9]+$ ]] || return 1
    (( octet >= 0 && octet <= 255 )) || return 1
  done
}

if [[ "${1:-}" == "--check" ]]; then
  exit 0
fi

SERVICE=""
IP=""
SUBNET=""
ROUTER=""
DNS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service)
      SERVICE="${2:-}"
      shift 2
      ;;
    --ip)
      IP="${2:-}"
      shift 2
      ;;
    --subnet)
      SUBNET="${2:-}"
      shift 2
      ;;
    --router)
      ROUTER="${2:-}"
      shift 2
      ;;
    --dns)
      DNS="${2:-}"
      shift 2
      ;;
    *)
      echo "Unsupported argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SERVICE" || -z "$IP" || -z "$SUBNET" || -z "$ROUTER" || -z "$DNS" ]]; then
  echo "Missing required network configuration." >&2
  exit 2
fi

if [[ "$ROUTER" != "192.168.31.1" && "$ROUTER" != "192.168.31.3" ]]; then
  echo "Router is not allowed: $ROUTER" >&2
  exit 2
fi

if [[ "$DNS" != "192.168.31.1" && "$DNS" != "192.168.31.3" ]]; then
  echo "DNS is not allowed: $DNS" >&2
  exit 2
fi

if [[ "$SERVICE" == *"/"* || "$SERVICE" == *$'\n'* || "$SERVICE" == *$'\r'* ]]; then
  echo "Service name is not allowed." >&2
  exit 2
fi

is_ipv4 "$IP" || { echo "Invalid IP: $IP" >&2; exit 2; }
is_ipv4 "$SUBNET" || { echo "Invalid subnet: $SUBNET" >&2; exit 2; }

"$NETWORKSETUP" -setmanual "$SERVICE" "$IP" "$SUBNET" "$ROUTER"
"$NETWORKSETUP" -setdnsservers "$SERVICE" "$DNS"
"$ROUTE" -n change default "$ROUTER" >/dev/null 2>&1 || "$ROUTE" -n add default "$ROUTER"
"$DSCACHEUTIL" -flushcache
"$KILLALL" -HUP mDNSResponder >/dev/null 2>&1 || true
HELPER

/bin/chmod 755 "$HELPER_PATH"
/usr/sbin/chown root:wheel "$HELPER_PATH"

TMP_SUDOERS="$(/usr/bin/mktemp /tmp/gateway-switcher-sudoers.XXXXXX)"
/bin/cat >"$TMP_SUDOERS" <<SUDOERS
$CONSOLE_USER ALL=(root) NOPASSWD: $HELPER_PATH
SUDOERS

/usr/sbin/visudo -cf "$TMP_SUDOERS" >/dev/null
/bin/mv "$TMP_SUDOERS" "$SUDOERS_PATH"
/bin/chmod 440 "$SUDOERS_PATH"
/usr/sbin/chown root:wheel "$SUDOERS_PATH"

echo "Installed passwordless helper for $CONSOLE_USER."
