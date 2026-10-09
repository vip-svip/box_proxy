#!/system/bin/sh
# Box Proxy v1.0.0 manager  (Shadowrocket-like for KernelSU)
DATA=/data/adb/boxproxy
CONF_DIR="$DATA/configs"
MOD_DIR="$DATA/modules"
NODE_DIR="$DATA/nodes"
RUN="$DATA/run"
CORE="$DATA/cores/mihomo"
SUBS="$DATA/subscriptions"
TPL="$DATA/templates"
API="http://127.0.0.1:9090"
EXT="http://www.gstatic.com/generate_204"
mkdir -p "$CONF_DIR" "$MOD_DIR" "$NODE_DIR" "$RUN" "$SUBS" "$TPL"

die(){ echo "ERR: $*"; exit 1; }
active_name(){ [ -f "$DATA/active" ] && cat "$DATA/active"; }
is_running(){ [ -f "$RUN/mihomo.pid" ] && kill -0 "$(cat "$RUN/mihomo.pid")" 2>/dev/null; }

dl(){
  if command -v curl >/dev/null 2>&1; then curl -fL --connect-timeout 15 -m 300 -o "$2" "$1"; return $?; fi
  if command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"; return $?; fi
  busybox wget -q -O "$2" "$1"; return $?
}
http_get(){
  t="${2:-15}"
  if command -v curl >/dev/null 2>&1; then curl -s --max-time "$t" "$1"; return; fi
  if command -v wget >/dev/null 2>&1; then wget -q -O - "$1"; return; fi
  busybox wget -q -O - "$1"
}
rotate_log(){
  f="$RUN/mihomo.log"; [ -f "$f" ] || return 0
  sz=$(wc -c < "$f" 2>/dev/null || echo 0)
  if [ "$sz" -gt 1048576 ] 2>/dev/null; then tail -n 300 "$f" > "$f.tmp" 2>/dev/null && mv -f "$f.tmp" "$f"; fi
}
have_conf(){ ls "$CONF_DIR"/*.yaml "$CONF_DIR"/*.yml >/dev/null 2>&1; }

# 确保存在可用配置（修复 active config missing）
ensure(){
  if ! have_conf; then
    if [ -f "$TPL/base.yaml" ]; then cp -f "$TPL/base.yaml" "$CONF_DIR/default.yaml"
    else printf 'mixed-port: 7890\nmode: rule\nrules:\n  - MATCH,DIRECT\n' > "$CONF_DIR/default.yaml"; fi
    echo "default.yaml" > "$DATA/active"
  fi
  a=$(active_name)
  if [ -z "$a" ] || [ ! -f "$CONF_DIR/$a" ]; then
    a=$(ls "$CONF_DIR"/*.yaml "$CONF_DIR"/*.yml 2>/dev/null | head -n1 | xargs -r basename)
    [ -n "$a" ] && echo "$a" > "$DATA/active"
  fi
}

cmd="$1"; shift 2>/dev/null

case "$cmd" in
  version) grep '^version=' /data/adb/modules/box_proxy/module.prop 2>/dev/null | cut -d= -f2 ;;

  list)
    for f in "$CONF_DIR"/*.yaml "$CONF_DIR"/*.yml; do
      [ -e "$f" ] || continue
      b=$(basename "$f")
      sz=$(( ( $(wc -c < "$f") + 1023 ) / 1024 ))
      mt=$(date -r "$f" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
      act=0; [ "$b" = "$(active_name)" ] && act=1
      echo "$b|${sz}K|$mt|$act"
    done ;;

  use) [ -n "$1" ] || die "usage: use <name>"; [ -f "$CONF_DIR/$1" ] || die "not exist"; echo "$1" > "$DATA/active"; echo "active=$1" ;;
  delete) [ -n "$1" ] || die "usage: delete <name>"; rm -f "$CONF_DIR/$1" "$SUBS/$1.url"; [ "$(active_name)" = "$1" ] && rm -f "$DATA/active"; ensure; echo "deleted=$1" ;;
  rename) [ -n "$1" ] && [ -n "$2" ] || die "usage: rename <old> <new>"; mv -f "$CONF_DIR/$1" "$CONF_DIR/$2" && echo "renamed" ;;

  read) [ -n "$1" ] || die "usage: read <name>"; [ -f "$CONF_DIR/$1" ] || die "not exist"; cat "$CONF_DIR/$1" ;;
  new)  [ -n "$1" ] || die "usage: new <name>"; cp -f "$TPL/base.yaml" "$CONF_DIR/$1" 2>/dev/null || : > "$CONF_DIR/$1"; echo "created=$1" ;;

  # WebUI 写入缓冲（base64 分块）
  write-start) : > "$DATA/.wb64"; echo "ok" ;;
  write-append) printf %s "$1" >> "$DATA/.wb64"; echo "ok" ;;
  write-commit)
    [ -n "$1" ] || die "usage: write-commit <abs-target>"
    [ -f "$DATA/.wb64" ] || die "no buffer"
    mkdir -p "$(dirname "$1")"
    if command -v base64 >/dev/null 2>&1; then
      base64 -d "$DATA/.wb64" > "$1" 2>/dev/null || base64 -D "$DATA/.wb64" > "$1" 2>/dev/null || die "decode failed"
    else busybox base64 -d "$DATA/.wb64" > "$1" || die "decode failed"; fi
    rm -f "$DATA/.wb64"; echo "saved=$1" ;;

  import)
    url="$1"; name="$2"; [ -n "$url" ] || die "usage: import <url> [name]"
    [ -n "$name" ] || name="sub_$(date +%Y%m%d_%H%M%S)"
    case "$name" in *.yaml|*.yml|*.conf|*.txt) ;; *) name="$name.yaml" ;; esac
    tmp="$CONF_DIR/.dl.$$"; dl "$url" "$tmp" || die "download failed"
    [ -s "$tmp" ] || die "empty file"; mv -f "$tmp" "$CONF_DIR/$name"; echo "$url" > "$SUBS/$name.url"
    echo "imported=$name" ;;

  update)
    name="$1"; [ -n "$name" ] || die "usage: update <name>"; f="$SUBS/$name.url"; [ -f "$f" ] || die "no saved url"
    url=$(cat "$f"); tmp="$CONF_DIR/.dl.$$"; dl "$url" "$tmp" || die "download failed"; mv -f "$tmp" "$CONF_DIR/$name"; echo "updated=$name" ;;

  update-all)
    for f in "$SUBS"/*.url; do [ -e "$f" ] || continue; n=$(basename "$f" .url); url=$(cat "$f"); tmp="$CONF_DIR/.dl.$$"
      dl "$url" "$tmp" && mv -f "$tmp" "$CONF_DIR/$n" && echo "updated=$n"; done ;;

  ensure) ensure; echo "active=$(active_name)" ;;

  start)
    ensure
    [ -x "$CORE" ] || die "core missing"
    n=$(active_name); [ -n "$n" ] || die "no active config"
    [ -f "$CONF_DIR/$n" ] || die "active config missing"
    sh "$0" stop >/dev/null 2>&1
    rotate_log
    if command -v setsid >/dev/null 2>&1; then
      setsid "$CORE" -d "$DATA" -f "$CONF_DIR/$n" >>"$RUN/mihomo.log" 2>&1 &
    else
      nohup "$CORE" -d "$DATA" -f "$CONF_DIR/$n" >>"$RUN/mihomo.log" 2>&1 &
    fi
    echo $! > "$RUN/mihomo.pid"; sleep 2
    if is_running; then echo "started pid=$(cat "$RUN/mihomo.pid") config=$n"
    else echo "ERR: core exited, see log"; tail -n 12 "$RUN/mihomo.log"; fi ;;

  stop)
    if [ -f "$RUN/mihomo.pid" ]; then kill "$(cat "$RUN/mihomo.pid")" 2>/dev/null; sleep 1; kill -9 "$(cat "$RUN/mihomo.pid")" 2>/dev/null; rm -f "$RUN/mihomo.pid"; fi
    pkill -f "boxproxy/cores/mihomo" 2>/dev/null; echo "stopped" ;;

  restart) sh "$0" stop >/dev/null 2>&1; sh "$0" start ;;
  toggle) is_running && sh "$0" stop || sh "$0" start ;;
  status) if is_running; then echo "running"; else echo "stopped"; fi ;;
  logs) tail -n "${1:-80}" "$RUN/mihomo.log" 2>/dev/null ;;

  check) [ -x "$CORE" ] || die "core missing"; n=$(active_name); [ -n "$n" ] || die "no active config"
    "$CORE" -d "$DATA" -f "$CONF_DIR/$n" -t 2>&1 | tail -n 20 ;;

  core-version) [ -x "$CORE" ] && "$CORE" -v 2>/dev/null | head -n1 || echo "not installed" ;;
  core-install) sh "$DATA/bin/fetch_core.sh" ;;

  stats)
    if ! is_running; then echo "0|0|0|0"; exit 0; fi
    body=$(http_get "$API/connections" 3 2>/dev/null)
    dl=$(printf '%s' "$body" | grep -o '"downloadTotal":[0-9]*' | head -n1 | cut -d: -f2)
    ul=$(printf '%s' "$body" | grep -o '"uploadTotal":[0-9]*' | head -n1 | cut -d: -f2)
    mm=$(printf '%s' "$body" | grep -o '"memory":[0-9]*' | head -n1 | cut -d: -f2)
    cc=$(printf '%s' "$body" | grep -o '"metadata":' | wc -l)
    echo "${dl:-0}|${ul:-0}|${mm:-0}|${cc:-0}" ;;

  proxies) http_get "$API/proxies" 4 ;;
  select)
    n="$1"; g="${2:-PROXY}"; [ -n "$n" ] || die "usage: select <name> [group]"
    command -v curl >/dev/null 2>&1 || die "curl required for select"
    curl -s -X PUT -H 'Content-Type: application/json' --data "{\"name\":\"$n\"}" "$API/proxies/$g" >/dev/null 2>&1 && echo "selected=$n" || echo "ERR: select failed" ;;
  delay) http_get "$API/group/${1:-PROXY}/delay?timeout=5000&url=$EXT" 20 ;;

  backup)
    out="$DATA/boxproxy-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    if command -v tar >/dev/null 2>&1; then tar czf "$out" -C "$DATA" configs modules subscriptions state.json active 2>/dev/null
    else busybox tar czf "$out" -C "$DATA" configs modules subscriptions state.json active 2>/dev/null; fi
    [ -s "$out" ] && echo "$out" || echo "ERR: backup failed" ;;
  restore)
    f="$1"; [ -f "$f" ] || die "usage: restore <file.tar.gz>"
    sh "$0" stop >/dev/null 2>&1
    if command -v tar >/dev/null 2>&1; then tar xzf "$f" -C "$DATA" 2>/dev/null; else busybox tar xzf "$f" -C "$DATA" 2>/dev/null; fi
    ensure; echo "restored" ;;

  autostart) case "$1" in on) touch "$DATA/autostart"; echo "on";; off) rm -f "$DATA/autostart"; echo "off";; *) [ -f "$DATA/autostart" ] && echo "on" || echo "off";; esac ;;
  ip) http_get "https://api.ipify.org" 10; echo ;;

  reset)
    sh "$0" stop >/dev/null 2>&1
    rm -f "$CONF_DIR"/*.yaml "$CONF_DIR"/*.yml "$SUBS"/*.url "$DATA/state.json" 2>/dev/null
    rm -f "$MOD_DIR"/*.yaml 2>/dev/null
    ensure; echo "reset done" ;;

  *) echo "usage: manager.sh {version|list|use|delete|rename|read|new|write-start|write-append|write-commit|import|update|update-all|ensure|start|stop|restart|toggle|status|logs|check|stats|proxies|select|delay|backup|restore|core-version|core-install|autostart|ip|reset}" ;;
esac
