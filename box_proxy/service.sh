#!/system/bin/sh
MODDIR="${0%/*}"
DATA=/data/adb/boxproxy

# wait for boot
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 120 ]; do
  sleep 2; i=$((i+1))
done
sleep 5

# make sure helper scripts exist
[ -d "$DATA/bin" ] || { mkdir -p "$DATA/bin"; cp -af "$MODDIR/bin/." "$DATA/bin/"; chmod 0755 "$DATA/bin"/*.sh; }

# auto start if enabled
if [ -f "$DATA/autostart" ]; then
  sh "$DATA/bin/manager.sh" start >> "$DATA/run/service.log" 2>&1
fi
