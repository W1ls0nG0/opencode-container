sbox-help() {
    cat >&2 <<'HELP'
Launch
  sbox                    Open TUI in current directory
  sbox-resume             Continue last session (--session <id> for a specific one)

Visibility
  sbox-sessions           List all sessions (ID, title, date)
  sbox-todos [id]         Show todos the agent wrote during a session
  sbox-stats              Token + cost breakdown by model and tool
  sbox-export [id]        Export full session (messages, tool calls) to JSON
  sbox-db [sql]           Query opencode's SQLite db directly

Manage
  sbox-delete <id>        Delete a session
  sbox-reset-auth         Wipe credentials only (keep sessions)
  sbox-reset-all          Wipe everything

Maintenance
  sbox-rebuild            Rebuild image (picks up new opencode release)

What lives where
  Your project files      bind-mounted from $(pwd) — agent can read/write here
  auth.json               Docker volume 'sbox-auth' — never on your host
  sessions/todos/stats    Docker volume 'sbox-data' — never on your host
  AGENTS.md, opencode.json  written into your project by opencode (commit these)
HELP
}
