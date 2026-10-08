#!/system/bin/sh
# stop service and clean runtime on uninstall
sh /data/adb/boxproxy/bin/manager.sh stop >/dev/null 2>&1
rm -rf /data/adb/boxproxy
