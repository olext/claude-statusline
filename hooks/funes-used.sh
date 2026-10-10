#!/bin/bash
# PostToolUse hook: count funes MCP calls per session for statusline badge.
sid=$(python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: print("")')
[ -n "$sid" ] || exit 0
d=/tmp/claude-funes-used
mkdir -p "$d"
n=$(cat "$d/$sid" 2>/dev/null || echo 0)
echo $((n + 1)) > "$d/$sid"
# prune counters older than 2 days
find "$d" -type f -mtime +2 -delete 2>/dev/null
exit 0
