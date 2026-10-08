#!/system/bin/sh
# Box Proxy - KernelSU install script
SKIPUNZIP=0
MODPATH="${0%/*}"

DATA=/data/adb/boxproxy
CONF_DIR="$DATA/configs"
RUN="$DATA/run"
CORE_DIR="$DATA/cores"
BIN_DIR="$DATA/bin"

ui_print "*******************************"
ui_print "  Box Proxy  v1.0.0"
ui_print "  Shadowrocket-like for KSU"
ui_print "*******************************"

ARCH=$(getprop ro.product.cpu.abi)
ui_print "- device abi: $ARCH"

# ---- permissions ----
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh"   0 0 0755
set_perm "$MODPATH/action.sh"    0 0 0755
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644

# ---- runtime dirs ----
mkdir -p "$CONF_DIR" "$RUN" "$CORE_DIR" "$BIN_DIR"
cp -af "$MODPATH/bin/." "$BIN_DIR/" 2>/dev/null
chmod 0755 "$BIN_DIR"/*.sh 2>/dev/null

# ---- seed default config ----
if [ ! -f "$MODPATH/configs/default.yaml" ]; then :; fi
[ -f "$MODPATH/template.yaml" ] && cp -af "$MODPATH/template.yaml" "$CONF_DIR/default.yaml"
[ -f "$CONF_DIR/default.yaml" ] && [ ! -f "$DATA/active" ] && echo "default.yaml" > "$DATA/active"

# ---- try to download core (non-fatal) ----
ui_print "- fetching mihomo core ..."
sh "$MODPATH/bin/fetch_core.sh" >/dev/null 2>&1
if [ -x "$CORE_DIR/mihomo" ]; then
  ui_print "- core installed: $(sh "$MODPATH/bin/manager.sh" core-version 2>/dev/null)"
else
  ui_print "! core not downloaded (no network / mirror down)"
  ui_print "! open module WebUI -> 设置 -> 下载/更新内核"
fi

ui_print "- install done. reboot & open WebUI."
