#!/bin/bash
# Brainstack — one-time backfill of your existing local AI chats.
# Drives the Brainstack plugin's own binary (vgb) to send your past Claude Code,
# Cowork and Codex sessions to Brainstack. Run AFTER installing the plugin and
# signing in once. Safe to re-run (the server skips anything it already has).
set -uo pipefail

# Locate the vgb binary: local plugin copy first, then an installed plugin.
VGB=""
for c in \
  "/Users/LiamVG/brainstack-universal/plugins/brainstack/runtime/vgb" \
  $(ls -t "$HOME"/.claude/plugins/*/*/brainstack*/*/runtime/vgb 2>/dev/null) \
  $(ls -t "$HOME"/.claude/plugins/marketplaces/*/plugins/brainstack/runtime/vgb 2>/dev/null); do
  [ -x "$c" ] && VGB="$c" && break
done
[ -n "$VGB" ] || { echo "Couldn't find the Brainstack plugin binary. Install the plugin + sign in first."; exit 1; }
export CLAUDE_PLUGIN_ROOT="$(dirname "$(dirname "$VGB")")"

sent=0
send() { # session_id  transcript_path
  printf '{"session_id":"%s","transcript_path":"%s","hook_event_name":"SessionEnd","cwd":"%s"}' "$1" "$2" "$HOME" \
    | "$VGB" hook session-end >/dev/null 2>&1 && sent=$((sent+1)) && printf '.'
}

echo "Uploading your past chats through the Brainstack plugin..."
# Claude Code: ~/.claude/projects/<proj>/<uuid>.jsonl  (id = filename)
while IFS= read -r f; do [ -s "$f" ] && send "$(basename "$f" .jsonl)" "$f"; done \
  < <(find "$HOME/.claude/projects" -name '*.jsonl' 2>/dev/null)
# Cowork: .../local-agent-mode-sessions/**/local_<uuid>/audit.jsonl  (id = uuid)
while IFS= read -r f; do d="$(basename "$(dirname "$f")")"; [ -s "$f" ] && send "${d#local_}" "$f"; done \
  < <(find "$HOME/Library/Application Support/Claude/local-agent-mode-sessions" -name 'audit.jsonl' 2>/dev/null)
# Codex: ~/.codex/sessions|archived_sessions/**/rollout-*-<uuid>.jsonl  (id = trailing uuid)
while IFS= read -r f; do
  id="$(basename "$f" .jsonl | grep -oE '[0-9a-fA-F-]{36}$' || true)"
  [ -n "$id" ] && [ -s "$f" ] && send "$id" "$f"
done < <(find "$HOME/.codex/sessions" "$HOME/.codex/archived_sessions" -name 'rollout-*.jsonl' 2>/dev/null)

echo ""
echo "Done -- sent $sent past session(s) to Brainstack. They'll turn into notes in the background over the next little while."
