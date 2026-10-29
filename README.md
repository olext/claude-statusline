# claude-statusline

A compact status line for [Claude Code](https://claude.com/claude-code):

```
[Opus 5.5] 5h ▓▓▓░░░░░░░ 30% 7d ▓▓▓▓▓▓▓░░░ 70% | ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░… 42% 86k/200k
```

- Model name
- 5-hour and 7-day rate-limit usage bars (shown first so narrow terminals keep them)
- 60-char context-window bar with percent and used/total tokens
- Bars colored green (<60%), yellow (<85%), red (≥85%)
- Optional badges: flowchart MCP used this session, funes memory index status, [context-mode](https://github.com/mksglu/context-mode) savings, and any extra badges from `~/.claude/hooks/caveman-statusline.sh`

Requires `bash` and `python3`.

## Install

```bash
git clone https://github.com/olext/claude-statusline.git
cp claude-statusline/statusline.sh ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

## Optional badges

The flowchart and funes badges rely on PostToolUse hooks that flag MCP usage per session. Copy `hooks/*.sh` to `~/.claude/hooks/` and add:

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "mcp__flowchart__.*", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/flowchart-used.sh", "async": true }] },
      { "matcher": "mcp__funes__.*",     "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/funes-used.sh",     "async": true }] }
    ]
  }
}
```

The context-mode badge needs no hook. It shows `[CTXM]` when the `context-mode@context-mode` plugin is enabled in `~/.claude/settings.json`, and `[CTXM:N%]` once the current session has kept output out of context. N is `bytes_avoided / (bytes_avoided + bytes_returned)` summed over this session's events in `~/.claude/context-mode/sessions/*.db`.

Badges stay hidden when the related tool or hook is absent.

## License

MIT
