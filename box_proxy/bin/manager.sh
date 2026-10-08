#!/system/bin/sh
# Box Proxy manager. Called by service.sh and WebUI.
DATA=/data/adb/boxproxy
CONF_DIR="$DATA/configs"
RUN="$DATA/run"
CORE="$DATA/cores/mihomo"
SUBS="$DATA/subscriptions"
mkdir -p "$CONF_DIR" "$RUN" "$SUBS"

die(){ echo "ERR: $*"; exit 1; }
have(){ [ -x "$1" ]; }

active_name(){ [ -f "$DATA/active" ] && cat "$DATA/active"; }

dl() { # dl <url> <outfile>
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

  delete) [ -n "$1" ] || die "usage: delete <name>"; rm -f "$CONF_DIR/$1"; [ "$(active_name)" = "$1" ] && rm -f "$DATA/active"; echo "deleted=$1" ;;

  rename) [ -n "$1" ] && [ -n "$2" ] || die "usage: rename <old> <new>"; mv -f "$CONF_DIR/$1" "$CONF_DIR/$2" && echo "renamed" ;;

  import) # import <url> [name]
    url="$1"; name="$2"
    [ -n "$url" ] || die "usage: import <url> [name]"
    [ -n "$name" ] || name="sub_$(date +%Y%m%d_%H%M%S)"
    case "$name" in *.yaml|*.yml|*.conf) ;; *) name="$name.yaml" ;; esac
    tmp="$CONF_DIR/.dl.$$"
    dl "$url" "$tmp" || die "download failed: $url"
    [ -s "$tmp" ] || die "empty file"
    mv -f "$tmp" "$CONF_DIR/$name"
    echo "$url" > "$SUBS/$name.url"
    echo "imported=$name"
    ;;

  update) # update subscription by stored url
    name="$1"; [ -n "$name" ] || die "usage: update <name>"
    f="$SUBS/$name.url"
    [ -f "$f" ] || die "no saved url for $name"
    url=$(cat "$f")
    tmp="$CONF_DIR/.dl.$$"
    dl "$url" "$tmp" || die "download failed"
    mv -f "$tmp" "$CONF_DIR/$name"
    echo "updated=$name"
    ;;

  update-all)
    for f in "$SUBS"/*.url; do
      [ -e "$f" ] || continue
      n=$(basename "$f" .url)
      url=$(cat "$f")
      tmp="$CONF_DIR/.dl.$$"
      dl "$url" "$tmp" && mv -f "$tmp" "$CONF_DIR/$n" && echo "updated=$n"
    done
    ;;

  start)
    have "$CORE" || die "core missing, download it in WebUI settings"
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
      kill $(cat "$RUN/mihomo.pid") 2>/dev/null
      sleep 1
      kill -9 $(cat "$RUN/mihomo.pid") 2>/dev/null
      rm -f "$RUN/mihomo.pid"
    fi
    pkill -f "cores/mihomo" 2>/dev/null
    echo "stopped"
    ;;

  restart) sh "$0" stop >/dev/null 2>&1; sh "$0" start ;;
  toggle) [ "$(sh "$0" status)" = "running" ] && sh "$0" stop || sh "$0" start ;;

  status)
    if [ -f "$RUN/mihomo.pid" ] && kill -0 $(cat "$RUN/mihomo.pid") 2>/dev/null; then
      echo "running"
    else
      echo "stopped"
    fi
    ;;

  logs) tail -n "${1:-80}" "$RUN/mihomo.log" 2>/dev/null ;;

  core-version) have "$CORE" && "$CORE" -v 2>/dev/null | head -n1 || echo "not installed" ;;

  core-install) sh "$DATA/bin/fetch_core.sh" ;;

  autostart) # autostart on|off
    case "$1" in
      on)  touch "$DATA/autostart"; echo "autostart=on" ;;
      off) rm -f "$DATA/autostart"; echo "autostart=off" ;;
      *)   [ -f "$DATA/autostart" ] && echo "on" || echo "off" ;;
    esac
    ;;

  ip) # proxy ip / connectivity check
    curl -s --connect-timeout 10 https://api.ipify.org 2>/dev/null; echo
    ;;

  reset)
    sh "$0" stop >/dev/null 2>&1
    rm -rf "$CONF_DIR" "$SUBS"
    mkdir -p "$CONF_DIR" "$SUBS"
    if [ -f /data/adb/modules/box_proxy/template.yaml ]; then
      cp -f /data/adb/modules/box_proxy/template.yaml "$CONF_DIR/default.yaml"
      echo "default.yaml" > "$DATA/active"
    fi
    echo "reset done"
    ;;

  *)
    echo "usage: manager.sh {list|use|delete|rename|import|update|update-all|start|stop|restart|toggle|status|logs|core-version|core-install|autostart|ip|reset}"
    ;;
esac
