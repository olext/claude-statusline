#!/bin/bash
# PostToolUse hook: flag flowchart MCP usage for statusline badge (per session).
sid=$(python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: print("")')
[ -n "$sid" ] || exit 0
d=/tmp/claude-flowchart-used
mkdir -p "$d"
touch "$d/$sid"
# prune flags older than 2 days
find "$d" -type f -mtime +2 -delete 2>/dev/null
exit 0
