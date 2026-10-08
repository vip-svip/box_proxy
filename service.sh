#!/system/bin/sh
MODDIR="${0%/*}"
DATA=/data/adb/boxproxy

i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 120 ]; do sleep 2; i=$((i+1)); done
sleep 5

# ensure helper scripts
[ -d "$DATA/bin" ] || { mkdir -p "$DATA/bin"; cp -af "$MODDIR/bin/." "$DATA/bin/"; chmod 0755 "$DATA/bin"/*.sh; }

# ensure bundled core present
[ -x "$DATA/cores/mihomo" ] || { mkdir -p "$DATA/cores"; cp -af "$MODDIR/cores/mihomo" "$DATA/cores/mihomo"; chmod 0755 "$DATA/cores/mihomo"; }

# autostart
if [ -f "$DATA/autostart" ]; then
  sh "$DATA/bin/manager.sh" start >> "$DATA/run/service.log" 2>&1
fi
