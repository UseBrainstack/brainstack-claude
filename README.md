# Brainstack — universal plugin (macOS + Windows)

One Claude Code plugin, one native binary, both OSes. It provides the **Brainstack
MCP connector** so your AI can save durable takeaways to your brain and search it
back — no Node required.

## Install

```
claude plugin marketplace add UseBrainstack/brainstack-claude
claude plugin install brainstack@brainstack-claude
```

Restart Claude Code and sign in to usebrainstack.com when prompted (secret-less
OAuth; token stored at `~/.brainstack/token.json`). That's the whole setup — **no
hooks to approve, nothing installed system-wide.**

## Capture is MCP-driven (no local hooks)

There are no local capture hooks. Capture happens over the connector: your AI
files durable takeaways when you ask ("save this to the brain") and at the end of
a substantive session. **Everything lands private by default** — you decide, in
the moment or later in the web app, what to share and with whom. Deterministic
auto-capture is a Compliance-API (Enterprise) feature.

## Backfill your old chats (optional, one-time)

To pull your existing local history (Claude Code / Cowork / Codex) into your brain
in one shot:

```
curl -fsSL "https://raw.githubusercontent.com/UseBrainstack/brainstack-chatgpt/main/import-old-chats.sh?cb=$RANDOM" | bash
```

Windows (PowerShell):

```
irm "https://raw.githubusercontent.com/UseBrainstack/brainstack-chatgpt/main/import-old-chats.ps1?cb=$(Get-Random)" | iex
```

It signs you in, scans your local transcripts, lets you choose how many to bring
in, uploads them, and deletes itself. Nothing is installed.
