#!/bin/bash
# Brainstack — one-time backfill of your existing local AI chats.
# Finds your past Claude Code, Cowork and Codex sessions on THIS machine and
# sends each to Brainstack via the installed plugin's binary. Safe to re-run
# (the server skips anything it already has). Run AFTER you've signed in once.
set -euo pipefail

# Locate the installed vgb binary (from the brainstack plugin) + its config.
VGB="$(ls -t "$HOME"/.claude/plugins/*/*/brainstack/*/runtime/vgb "$HOME"/.claude/plugins/*/brainstack*/plugins/brainstack/runtime/vgb 2>/dev/null | head -1 || true)"
ROOT="$(dirname "$(dirname "${VGB:-}")" 2>/dev/null || true)"
if [ -z "${VGB:-}" ] || [ ! -x "$VGB" ]; then
  echo "Couldn't find the Brainstack plugin binary. Install the plugin and sign in first."; exit 1
fi
export CLAUDE_PLUGIN_ROOT="$ROOT"
sent=0

send() { # session_id  transcript_path
  printf '{"session_id":"%s","transcript_path":"%s","hook_event_name":"SessionEnd","cwd":"%s"}' "$1" "$2" "$HOME" \
    | "$VGB" hook session-end >/dev/null 2>&1 && sent=$((sent+1)) && printf '.'
}

echo "Scanning your machine for past chats…"
# Claude Code: ~/.claude/projects/<proj>/<uuid>.jsonl  (id = filename)
while IFS= read -r f; do
  [ -s "$f" ] && send "$(basename "$f" .jsonl)" "$f"
done < <(find "$HOME/.claude/projects" -name '*.jsonl' 2>/dev/null)
# Cowork: …/local-agent-mode-sessions/**/local_<uuid>/audit.jsonl  (id = uuid)
while IFS= read -r f; do
  d="$(basename "$(dirname "$f")")"; [ -s "$f" ] && send "${d#local_}" "$f"
done < <(find "$HOME/Library/Application Support/Claude/local-agent-mode-sessions" -name 'audit.jsonl' 2>/dev/null)
# Codex: ~/.codex/sessions|archived_sessions/**/rollout-*-<uuid>.jsonl (id = trailing uuid)
while IFS= read -r f; do
  id="$(basename "$f" .jsonl | grep -oE '[0-9a-fA-F-]{36}$' || true)"; [ -n "$id" ] && [ -s "$f" ] && send "$id" "$f"
done < <(find "$HOME/.codex/sessions" "$HOME/.codex/archived_sessions" -name 'rollout-*.jsonl' 2>/dev/null)

echo ""
echo "Done. Sent $sent past session(s) to Brainstack. They'll turn into notes in the background over the next little while."
