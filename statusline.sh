#!/bin/bash
# Status line: [Model] 60-char context bar + tokens + 5h/7d usage bars + plugin badges.
input=$(cat)
printf '%s' "$input" > "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.statusline-last.json"

read -r MODEL PCT USED SIZE P5H P7D SID < <(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
cw = d.get("context_window") or {}
rl = d.get("rate_limits") or {}
model = (d.get("model") or {}).get("display_name") or "?"
pct = cw.get("used_percentage") or 0
used = (cw.get("total_input_tokens") or 0) + (cw.get("total_output_tokens") or 0)
size = cw.get("context_window_size") or 0
def fmt(n):
    if n >= 1_000_000: return f"{n/1_000_000:.1f}m".replace(".0m", "m")
    if n >= 1_000: return f"{round(n/1000)}k"
    return str(n)
def rlpct(key):
    v = (rl.get(key) or {}).get("used_percentage")
    return "-" if v is None else str(int(v))
print(model.replace(" ", "_"), int(pct), fmt(used), fmt(size), rlpct("five_hour"), rlpct("seven_day"), d.get("session_id") or "-")
')
MODEL=${MODEL//_/ }
[ -z "$PCT" ] && PCT=0

# bar WIDTH PCT -> BAR (▓ filled / ░ empty)
bar() {
  local w=$1 p=$2 f e FILL PAD
  f=$((p * w / 100)); [ "$p" -gt 0 ] && [ "$f" -eq 0 ] && f=1; [ "$f" -gt "$w" ] && f=$w
  e=$((w - f)); BAR=""
  [ "$f" -gt 0 ] && printf -v FILL "%${f}s" && BAR="${FILL// /▓}"
  [ "$e" -gt 0 ] && printf -v PAD "%${e}s" && BAR="${BAR}${PAD// /░}"
}

# color PCT -> C (green <60, yellow <85, red >=85)
color() {
  if [ "$1" -ge 85 ]; then C='\033[31m'; elif [ "$1" -ge 60 ]; then C='\033[33m'; else C='\033[32m'; fi
}

printf '[%s]' "$MODEL"

# Rate-limit usage bars first — narrow terminals truncate the tail, keep these visible.
if [ "$P5H" != "-" ]; then
  bar 10 "$P5H"; color "$P5H"
  printf ' 5h %b%s\033[0m %s%%' "$C" "$BAR" "$P5H"
fi
if [ "$P7D" != "-" ]; then
  bar 10 "$P7D"; color "$P7D"
  printf ' 7d %b%s\033[0m %s%%' "$C" "$BAR" "$P7D"
fi

bar 60 "$PCT"; color "$PCT"
printf ' | %b%s\033[0m %s%% %s/%s' "$C" "$BAR" "$PCT" "$USED" "$SIZE"

# flowchart MCP badge: shown once the flowchart server was used this session (flag set by PostToolUse hook).
[ -n "$SID" ] && [ "$SID" != "-" ] && [ -f "/tmp/claude-flowchart-used/$SID" ] && printf ' \033[36m⛁ flowchart\033[0m'

# funes badge: ◉chunks ⧗embed-queue ⟳indexing ×recalls-this-session.
# `funes status` takes ~2s, so it refreshes in the background into a cache at most once a minute.
if command -v funes >/dev/null 2>&1; then
  FC=/tmp/claude-funes-status.txt
  if [ ! -f "$FC" ] || [ -n "$(find "$FC" -mmin +1 2>/dev/null)" ]; then
    if mkdir /tmp/claude-funes-status.lock 2>/dev/null; then
      ( funes status >"$FC.new" 2>/dev/null && mv -f "$FC.new" "$FC"; rmdir /tmp/claude-funes-status.lock ) </dev/null >/dev/null 2>&1 &
    fi
  fi
  k() { local n=$1; [ "$n" -ge 1000 ] && echo "$(( (n + 500) / 1000 ))k" || echo "$n"; }
  FCHUNKS=$(sed -n 's/^chunks: \([0-9]*\).*/\1/p' "$FC" 2>/dev/null)
  FQUEUE=$(sed -n 's/^\([0-9]*\) chunks awaiting embedding.*/\1/p' "$FC" 2>/dev/null)
  printf ' \033[35m[funes ◉'
  [ -n "$FCHUNKS" ] && printf ' %s' "$(k "$FCHUNKS")"
  [ -n "$FQUEUE" ] && [ "$FQUEUE" -gt 0 ] && printf ' ⧗ %s' "$(k "$FQUEUE")"
  pgrep -f '^([^ ]*/)?funes index' >/dev/null 2>&1 && printf ' ⟳ '
  if [ -n "$SID" ] && [ "$SID" != "-" ] && [ -f "/tmp/claude-funes-used/$SID" ]; then
    printf ' ×%s' "$(cat "/tmp/claude-funes-used/$SID")"
  fi
  printf ']\033[0m'
fi

# Plugin badges from previous status line script, if still present.
BADGES_SCRIPT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/caveman-statusline.sh"
if [ -f "$BADGES_SCRIPT" ]; then
  BADGES=$(bash "$BADGES_SCRIPT" </dev/null)
  [ -n "$BADGES" ] && printf ' %s' "$BADGES"
fi

echo
exit 0
