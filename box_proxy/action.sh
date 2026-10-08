#!/system/bin/sh
# KernelSU action button: toggle proxy on/off
DATA=/data/adb/boxproxy
MG="$DATA/bin/manager.sh"
[ -x "$MG" ] || MG="/data/adb/modules/box_proxy/bin/manager.sh"
S=$(sh "$MG" status)
if [ "$S" = "running" ]; then
  sh "$MG" stop
  echo "Box Proxy: stopped"
else
  sh "$MG" start
  echo "Box Proxy: started"
fi
