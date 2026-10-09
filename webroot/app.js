#!/system/bin/sh
# Box Proxy v1.0.0 - KernelSU install script (内置内核)
SKIPUNZIP=0
MODPATH="${0%/*}"

DATA=/data/adb/boxproxy
CONF_DIR="$DATA/configs"
MOD_DIR="$DATA/modules"
NODE_DIR="$DATA/nodes"
RUN="$DATA/run"
CORE_DIR="$DATA/cores"

ui_print "*******************************"
ui_print "  Box Proxy  v1.0.0"
ui_print "  Shadowrocket-like for KSU"
ui_print "  bundled mihomo core"
ui_print "*******************************"

ARCH=$(getprop ro.product.cpu.abi)
ui_print "- device abi: $ARCH"

# ---- 权限 ----
set_perm_recursive "$MODPATH" 0 0 0755 0644
for s in service.sh action.sh customize.sh uninstall.sh; do set_perm "$MODPATH/$s" 0 0 0755; done
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
set_perm "$MODPATH/cores/mihomo" 0 0 0755

# ---- 目录（configs 默认留空，不预置任何配置）----
mkdir -p "$CONF_DIR" "$MOD_DIR" "$NODE_DIR" "$RUN" "$CORE_DIR" "$DATA/bin" "$DATA/templates" "$DATA/subscriptions" "$DATA/providers"

# ---- 内置内核 ----
ui_print "- installing bundled core ..."
cp -af "$MODPATH/cores/mihomo" "$CORE_DIR/mihomo"
chmod 0755 "$CORE_DIR/mihomo"
[ -f "$MODPATH/cores/geoip.dat" ] && cp -af "$MODPATH/cores/geoip.dat" "$DATA/geoip.dat"

# ---- 脚本 & 模板 ----
cp -af "$MODPATH/bin/." "$DATA/bin/"; chmod 0755 "$DATA/bin"/*.sh 2>/dev/null
[ -d "$MODPATH/templates" ] && cp -af "$MODPATH/templates/." "$DATA/templates/"

# ---- 默认开机自启 ----
touch "$DATA/autostart"

if [ -x "$CORE_DIR/mihomo" ]; then
  ui_print "- core: bundled & installed"
else
  ui_print "! core missing in package"
fi
ui_print "- configs dir left EMPTY (导入你自己的配置/节点)"
ui_print "- install done. reboot & open WebUI."
