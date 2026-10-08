#!/system/bin/sh
# Box Proxy manager. Called by service.sh and WebUI.
DATA=/data/adb/boxproxy
CONF_DIR="$DATA/configs"
RUN="$DATA/run"
CORE="$DATA/cores/mihomo"
SUBS="$DATA/subscriptions"
mkdir -p "$CONF_DIR" "$RUN" "$SUBS"

die(){ echo "ERR: $*"; exit 1; }
active_name(){ [ -f "$DATA/active" ] && cat "$DATA/active"; }
dl() {
  url="$1"; out="$2"
  if command -v curl >/dev/null 2>&1; then curl -L --connect-timeout 15 -m 300 -o "$out" "$url"; return $?; fi
  if command -v wget >/dev/null 2>&1; then wget -q -O "$out" "$url"; return $?; fi
  busybox wget -q -O "$out" "$url"; return $?
}

cmd="$1"; shift 2>/dev/null

case "$cmd" in
  list)
    for f in "$CONF_DIR"/*; do
      [ -e "$f" ] || continue
      b=$(basename "$f")
      sz=$(( ( $(wc -c < "$f") + 1023 ) / 1024 ))
      mt=$(date -r "$f" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
      act=0; [ "$b" = "$(active_name)" ] && act=1
      echo "$b|${sz}K|$mt|$act"
    done
    ;;

  use) [ -n "$1" ] || die "usage: use <name>"; [ -f "$CONF_DIR/$1" ] || die "not exist"; echo "$1" > "$DATA/active"; echo "active=$1" ;;

  delete) [ -n "$1" ] || die "usage: delete <name>"; rm -f "$CONF_DIR/$1" "$SUBS/$1.url"; [ "$(active_name)" = "$1" ] && rm -f "$DATA/active"; echo "deleted=$1" ;;

  rename) [ -n "$1" ] && [ -n "$2" ] || die "usage: rename <old> <new>"; mv -f "$CONF_DIR/$1" "$CONF_DIR/$2" && echo "renamed" ;;

  # ---- 本地读写（供 WebUI 编辑器 / 本地导入）----
  read) [ -n "$1" ] || die "usage: read <name>"; [ -f "$CONF_DIR/$1" ] || die "not exist"; cat "$CONF_DIR/$1" ;;

  new)  [ -n "$1" ] || die "usage: new <name>"; : > "$CONF_DIR/$1"; echo "created=$1" ;;

  write-start) : > "$DATA/.wb64"; echo "ok" ;;
  write-append) [ -n "$1" ] || die "usage"; printf %s "$1" >> "$DATA/.wb64"; echo "ok" ;;
  write-commit)
    [ -n "$1" ] || die "usage: write-commit <name>"
    [ -f "$DATA/.wb64" ] || die "no buffer"
    if command -v base64 >/dev/null 2>&1; then
      base64 -d "$DATA/.wb64" > "$CONF_DIR/$1" 2>/dev/null || die "decode failed"
    else
      busybox base64 -d "$DATA/.wb64" > "$CONF_DIR/$1" || die "decode failed"
    fi
    rm -f "$DATA/.wb64"
    echo "saved=$1"
    ;;

  # ---- 在线导入 / 更新 ----
  import)
    url="$1"; name="$2"
    [ -n "$url" ] || die "usage: import <url> [name]"
    [ -n "$name" ] || name="sub_$(date +%Y%m%d_%H%M%S)"
    case "$name" in *.yaml|*.yml|*.conf|*.txt) ;; *) name="$name.yaml" ;; esac
    tmp="$CONF_DIR/.dl.$$"
    dl "$url" "$tmp" || die "download failed: $url"
    [ -s "$tmp" ] || die "empty file"
    mv -f "$tmp" "$CONF_DIR/$name"
    echo "$url" > "$SUBS/$name.url"
    echo "imported=$name"
    ;;

  update)
    name="$1"; [ -n "$name" ] || die "usage: update <name>"
    f="$SUBS/$name.url"; [ -f "$f" ] || die "no saved url for $name"
    url=$(cat "$f"); tmp="$CONF_DIR/.dl.$$"
    dl "$url" "$tmp" || die "download failed"
    mv -f "$tmp" "$CONF_DIR/$name"; echo "updated=$name"
    ;;

  update-all)
    for f in "$SUBS"/*.url; do
      [ -e "$f" ] || continue
      n=$(basename "$f" .url); url=$(cat "$f"); tmp="$CONF_DIR/.dl.$$"
      dl "$url" "$tmp" && mv -f "$tmp" "$CONF_DIR/$n" && echo "updated=$n"
    done
    ;;

  # ---- 服务控制 ----
  start)
    [ -x "$CORE" ] || die "core missing"
    n=$(active_name); [ -n "$n" ] || die "no active config"
    [ -f "$CONF_DIR/$n" ] || die "active config missing"
    sh "$0" stop >/dev/null 2>&1
    nohup "$CORE" -d "$DATA" -f "$CONF_DIR/$n" >"$RUN/mihomo.log" 2>&1 &
    echo $! > "$RUN/mihomo.pid"
    sleep 1
    if kill -0 $(cat "$RUN/mihomo.pid") 2>/dev/null; then
      echo "started pid=$(cat "$RUN/mihomo.pid") config=$n"
    else
      echo "ERR: core exited, see log"; tail -n 5 "$RUN/mihomo.log"
    fi
    ;;

  stop)
    if [ -f "$RUN/mihomo.pid" ]; then
      kill $(cat "$RUN/mihomo.pid") 2>/dev/null; sleep 1
      kill -9 $(cat "$RUN/mihomo.pid") 2>/dev/null; rm -f "$RUN/mihomo.pid"
    fi
    pkill -f "cores/mihomo" 2>/dev/null
    echo "stopped"
    ;;

  restart) sh "$0" stop >/dev/null 2>&1; sh "$0" start ;;
  toggle) [ "$(sh "$0" status)" = "running" ] && sh "$0" stop || sh "$0" start ;;

  status)
    if [ -f "$RUN/mihomo.pid" ] && kill -0 $(cat "$RUN/mihomo.pid") 2>/dev/null; then echo "running"; else echo "stopped"; fi
    ;;

  logs) tail -n "${1:-80}" "$RUN/mihomo.log" 2>/dev/null ;;

  core-version) [ -x "$CORE" ] && "$CORE" -v 2>/dev/null | head -n1 || echo "not installed" ;;
  core-install) sh "$DATA/bin/fetch_core.sh" ;;

  autostart)
    case "$1" in
      on)  touch "$DATA/autostart"; echo "autostart=on" ;;
      off) rm -f "$DATA/autostart"; echo "autostart=off" ;;
      *)   [ -f "$DATA/autostart" ] && echo "on" || echo "off" ;;
    esac
    ;;

  ip) curl -s --connect-timeout 10 https://api.ipify.org 2>/dev/null; echo ;;

  reset)
    sh "$0" stop >/dev/null 2>&1
    rm -rf "$CONF_DIR"; mkdir -p "$CONF_DIR"
    MOD=/data/adb/modules/box_proxy
    if [ -f "$MOD/configs/fanqie-lite.yaml" ]; then
      cp -f "$MOD/configs/fanqie-lite.yaml" "$CONF_DIR/fanqie-lite.yaml"
      echo "fanqie-lite.yaml" > "$DATA/active"
    fi
    echo "reset done"
    ;;

  *)
    echo "usage: manager.sh {list|use|delete|rename|read|new|write-start|write-append|write-commit|import|update|update-all|start|stop|restart|toggle|status|logs|core-version|core-install|autostart|ip|reset}"
    ;;
esac
