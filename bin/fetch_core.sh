#!/system/bin/sh
# 下载/更新 mihomo 内核（内置版默认已带；此脚本用于手动更新内核）
DATA=/data/adb/boxproxy
CORE_DIR="$DATA/cores"
mkdir -p "$CORE_DIR"

VER="${MIHOMO_VER:-v1.18.8}"
ABI=$(getprop ro.product.cpu.abi)
case "$ABI" in
  arm64-v8a)   A=arm64 ;;
  armeabi-v7a) A=armv7 ;;
  x86_64)      A=amd64 ;;
  x86)         A=386 ;;
  *)           A=arm64 ;;
esac

FILE="mihomo-linux-$A-$VER.gz"
BASE="https://github.com/MetaCubeX/mihomo/releases/download/$VER/$FILE"
MIRRORS="https://ghfast.top/ https://gh-proxy.com/ https://ghproxy.net/ https://mirror.ghproxy.com/ "

TMP="$CORE_DIR/.core.dl"; ok=0
try_dl() {
  if command -v curl >/dev/null 2>&1; then curl -L --connect-timeout 15 -m 300 -o "$TMP" "$1" && return 0; fi
  if command -v wget >/dev/null 2>&1; then wget -q -O "$TMP" "$1" && return 0; fi
  busybox wget -q -O "$TMP" "$1" && return 0
  return 1
}
for m in "" $MIRRORS; do
  u="${m}${BASE}"; echo "GET $u"
  if try_dl "$u" && [ -s "$TMP" ]; then ok=1; break; fi
done
[ "$ok" = "1" ] || { echo "ERR: all mirrors failed"; exit 1; }

if command -v gzip >/dev/null 2>&1; then gzip -dc "$TMP" > "$CORE_DIR/mihomo"; else busybox gzip -dc "$TMP" > "$CORE_DIR/mihomo"; fi
chmod 0755 "$CORE_DIR/mihomo"; rm -f "$TMP"
[ -x "$CORE_DIR/mihomo" ] && echo "OK: $($CORE_DIR/mihomo -v 2>/dev/null | head -n1)" || { echo "ERR: extract failed"; exit 1; }
