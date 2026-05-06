# sbox — run opencode in a container

A minimal Docker container for running [opencode](https://opencode.ai) from any project directory.

```
cd ~/my-project
sbox
```

---

## Why

opencode is an AI coding agent that can read, write, and execute code on your machine. Running it in a container gives it exactly what it needs — your current project — and nothing else.

No GitHub token. No host dotfiles. No surprises.

---

## Documentation

| Document | Contents |
|---|---|
| [docs/architecture.md](docs/architecture.md) | System capabilities, data flow, security model, design decisions |
| [docs/api.md](docs/api.md) | Internal function contracts, config variables, per-command reference |
| [docs/testing.md](docs/testing.md) | Mock framework API, writing tests, running tests |

---

## How it works

```
your shell
    │
    └── sbox.sh (entry point)
            │
            ├── lib/config.sh      — image name, volume names, version
            ├── lib/helpers.sh     — _sbox_build, _sbox_vols, _sbox_guard, _sbox_run
            ├── lib/validate.sh    — _sbox_validate_session_id
            ├── commands/launch.sh — sbox, sbox-resume
            ├── commands/query.sh  — sbox-sessions, sbox-todos, sbox-stats, sbox-export, sbox-db
            ├── commands/manage.sh — sbox-delete, sbox-reset-auth, sbox-reset-all, sbox-rebuild
            └── commands/help.sh   — sbox-help
```

Each command uses `_sbox_run` to assemble `docker run` calls consistently. The opencode binary is a native Bun-compiled executable — no Node.js runtime needed. The image is ~80MB.

---

## Setup

```bash
# 1. Clone or download this repo
cd sbox

# 2. Source the script (add this line to ~/.zshrc or ~/.bashrc)
source /path/to/sbox/sbox.sh

# 3. Go to any project and run
cd ~/my-project
sbox
```

First run builds the image (~30s). Every run after that is instant.

---

## First login

When opencode opens for the first time, run `/connect` inside the TUI and follow the prompts to authenticate with your provider (Anthropic, OpenAI, Google, etc.). Credentials are saved to the `sbox-auth` Docker volume and reused on every subsequent run.

---

## Commands

| Command | What it does |
|---|---|
| `sbox` | Launch opencode TUI in the current directory |
| `sbox-resume` | Continue the last session |
| `sbox-resume --session <id>` | Continue a specific session |
| `sbox-sessions` | List all sessions with IDs, titles, and dates |
| `sbox-todos [id]` | Show the agent's todo list from a session |
| `sbox-stats` | Token and cost breakdown by model and tool |
| `sbox-export [id]` | Export a full session to JSON |
| `sbox-db [sql]` | Query opencode's SQLite database directly |
| `sbox-delete <id>` | Delete a session |
| `sbox-rebuild` | Rebuild the image (picks up new opencode release) |
| `sbox-reset-auth` | Wipe credentials only, keep all sessions |
| `sbox-reset-all` | Wipe everything — auth and all sessions |
| `sbox-help` | Print this command list |

---

## What lives where

| Data | Location | On your host? |
|---|---|---|
| Your project files | bind mount from `$(pwd)` | Yes — intentional |
| `AGENTS.md`, `opencode.json` | written into your project by opencode | Yes — commit these |
| Credentials (`auth.json`) | Docker volume `sbox-auth` | No |
| Sessions, todos, stats | Docker volume `sbox-data` | No |
| opencode binary + tools | Docker image `sbox` | No |

Running `sbox` from `$HOME` is blocked — the agent would have access to your entire home directory.

---

## Inspecting sessions

Every conversation, plan, todo list, and token cost is stored in opencode's SQLite database inside the `sbox-data` volume. You can query it directly:

```bash
# List recent sessions
sbox-db "SELECT id, title, created_at FROM session ORDER BY created_at DESC LIMIT 10"

# See what the agent spent
sbox-db "SELECT model, SUM(input_tokens), SUM(output_tokens) FROM usage GROUP BY model"

# Export a session to JSON
sbox-export abc123
```

---

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core). One-time setup:

```bash
test/setup.sh
```

### Unit tests

Mock docker commands — no Docker daemon required, fast execution:

```bash
test/bats-core/bin/bats test/unit/
```

Run a single file:

```bash
test/bats-core/bin/bats test/unit/helpers.bats
test/bats-core/bin/bats test/unit/launch.bats
test/bats-core/bin/bats test/unit/query.bats
test/bats-core/bin/bats test/unit/manage.bats
```

### Integration tests

Requires Docker running. Tests image build, tool availability, user/permissions, and volume mounts:

```bash
test/bats-core/bin/bats test/integration/
```

### Run everything

```bash
test/bats-core/bin/bats test/
```

### Cleanup

Remove installed test dependencies and stale temp files:

```bash
test/cleanup.sh
```

To also remove Docker artifacts (image + volumes) created by integration tests:

```bash
test/cleanup.sh --docker
```

---

## Troubleshooting

### "Cannot connect to the Docker daemon"

Make sure Docker is running:

```bash
docker info
```

On Linux, you may need to add your user to the `docker` group or run with `sudo`.

### "permission denied while trying to connect"

Your user doesn't have Docker access. Add it to the `docker` group:

```bash
sudo usermod -aG docker "$USER"
```

Log out and back in for the change to take effect.

### "Dockerfile not found at ..."

The `sbox` function looks for `Dockerfile` relative to where `sbox.sh` lives on disk. If you moved the script without the Dockerfile, put them in the same directory.

### "Refusing to run from $HOME"

Running from your home directory would give the agent access to your entire home directory. `cd` into a specific project first.

### Build fails during `apk add`

Network issues downloading Alpine packages. Retry with:

```bash
sbox-rebuild
```

If it persists, check your Docker network / DNS settings.

### "no todos found"

Todos only exist if the agent used the `todowrite` tool during a session. Not every session will have them.

---

## Reference

### What's in the image

| Package | Why |
|---|---|
| `bash` | opencode's bash tool spawns `$SHELL` → `/bin/bash`; alpine ships ash only |
| `git` | opencode reads git context at startup; agent uses git via bash tool |
| `ripgrep` | grep and glob tools call `rg` directly; bash prompt instructs AI to always use `rg` |
| `python3` | agent writes and executes python scripts for data analysis, tests, scripting |
| `curl` | agent uses curl for API calls, endpoint testing, downloading files |
| `jq` | agent pipes almost all JSON through jq — git log, API responses, config files |
| `make` | most projects have a Makefile; agent will try `make test` / `make build` |
| `sqlite` | used by `sbox-db` to query opencode's session database directly |

### Pinning a version

The Dockerfile pins both the Alpine base image and the opencode version:

```dockerfile
FROM alpine:3.21
ARG OPENCODE_VERSION=2.0.1
```

To upgrade opencode, change the `OPENCODE_VERSION` build arg and run `sbox-rebuild`.

---

## Security

- **Filesystem isolation**: The container only sees your project directory (bind-mounted at `/workspace`). The rest of your host filesystem is inaccessible.
- **No host credentials**: No GitHub tokens, SSH keys, or dotfiles are passed into the container.
- **Credential storage**: opencode auth tokens are stored in the `sbox-auth` Docker volume — they never touch your host filesystem.
- **Non-root execution**: The container runs as user `sandbox` (uid 1000), not root.
- **No privilege escalation**: The container runs without `--privileged` or any capabilities beyond defaults.
- **HOME guard**: `sbox` refuses to run from `$HOME` to prevent accidental exposure of your entire home directory.
- **Session ID validation**: all commands that accept session IDs (`sbox-todos`, `sbox-delete`, `sbox-export`) validate them as alphanumeric to prevent SQL injection.

---

## Contributing

1. Fork the repository
2. Make your changes
3. Run the test suite: `test/bats-core/bin/bats test/unit/`
4. Open a pull request

Code style: match the existing conventions. Shell scripts use 4-space indentation. Functions are `snake_case`. Public commands are `sbox-*`, internal helpers are `_sbox_*`.

### Project structure

```
sbox.sh                  Entry point — sources all modules
lib/
  config.sh              Configuration variables
  helpers.sh             _sbox_build, _sbox_vols, _sbox_guard, _sbox_run
  validate.sh            _sbox_validate_session_id
commands/
  launch.sh              sbox, sbox-resume
  query.sh               sbox-sessions, sbox-todos, sbox-stats, sbox-export, sbox-db
  manage.sh              sbox-delete, sbox-reset-auth, sbox-reset-all, sbox-rebuild
  help.sh                sbox-help
docs/
  architecture.md        System capabilities, data flow, design decisions
  api.md                 Internal function contracts
  testing.md             Test framework and writing tests
```

### Linting

```bash
shellcheck sbox.sh lib/*.sh commands/*.sh
```

---

## Changelog

See [changelog.md](changelog.md) for version history.

---

## Requirements

- Docker (running)
- bash or zsh
