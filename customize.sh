#!/system/bin/sh
# Box Proxy - KernelSU install script (核心内置版)
SKIPUNZIP=0
MODPATH="${0%/*}"

DATA=/data/adb/boxproxy
CONF_DIR="$DATA/configs"
RUN="$DATA/run"
CORE_DIR="$DATA/cores"

ui_print "*******************************"
ui_print "  Box Proxy  v1.1.0"
ui_print "  Shadowrocket-like for KSU"
ui_print "  (bundled mihomo core)"
ui_print "*******************************"

ARCH=$(getprop ro.product.cpu.abi)
ui_print "- device abi: $ARCH"

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh"   0 0 0755
set_perm "$MODPATH/action.sh"    0 0 0755
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
set_perm "$MODPATH/cores/mihomo" 0 0 0755

mkdir -p "$CONF_DIR" "$RUN" "$CORE_DIR" "$DATA/bin" "$DATA/reference"

# ---- 内置内核 ----
ui_print "- installing bundled core ..."
cp -af "$MODPATH/cores/mihomo" "$CORE_DIR/mihomo"
chmod 0755 "$CORE_DIR/mihomo"
[ -f "$MODPATH/cores/geoip.dat" ] && cp -af "$MODPATH/cores/geoip.dat" "$DATA/geoip.dat"

# ---- 脚本 ----
cp -af "$MODPATH/bin/." "$DATA/bin/"
chmod 0755 "$DATA/bin"/*.sh 2>/dev/null

# ---- 配置：仅保留 fanqie-lite（不覆盖用户已有同名文件） ----
for f in "$MODPATH"/configs/*; do
  [ -e "$f" ] || continue
  b=$(basename "$f")
  [ -f "$CONF_DIR/$b" ] || cp -af "$f" "$CONF_DIR/$b"
done
[ -f "$DATA/active" ] || echo "fanqie-lite.yaml" > "$DATA/active"

# ---- 参考原始文件 ----
[ -d "$MODPATH/reference" ] && cp -af "$MODPATH/reference/." "$DATA/reference/" 2>/dev/null

# ---- 默认开机自启 ----
touch "$DATA/autostart"

if [ -x "$CORE_DIR/mihomo" ]; then
  ui_print "- core: bundled & installed"
else
  ui_print "! core missing in package"
fi
ui_print "- install done. reboot & open WebUI."
