# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-05-06

### Launch commands

- **sbox** — Launch the opencode TUI in the current directory. First run builds
  the Docker image (~30 s); subsequent runs are instant. Refuses to run from
  `$HOME` to prevent accidental exposure of the entire home directory.
- **sbox-resume** — Continue the last session. Accepts `--session <id>` to
  resume a specific session by its identifier.

### Query commands

- **sbox-sessions** — List all sessions with IDs, titles, and creation dates in
  a table format.
- **sbox-todos [id]** — Show the agent's todo list from a session. Queries the
  SQLite database for todo items with session title, content, status, and
  priority. When no session ID is given, lists todos across all sessions.
- **sbox-stats** — Display token and cost breakdown by model and tool (top 10
  each).
- **sbox-export [id]** — Export a full session (messages, tool calls) to a
  timestamped JSON file in the current directory.
- **sbox-db [sql]** — Query opencode's SQLite database directly. Without
  arguments, lists all tables. Accepts arbitrary SQL for ad-hoc queries.

### Manage commands

- **sbox-delete <id>** — Delete a session by ID. Validates the session ID format
  before attempting deletion.
- **sbox-rebuild** — Remove the existing image and rebuild from scratch. Use this
  to pick up a new opencode release or recover from a corrupted build.
- **sbox-reset-auth** — Remove the `sbox-auth` Docker volume, wiping credentials
  while keeping all session data intact.
- **sbox-reset-all** — Interactive confirmation prompt, then removes both the
  `sbox-auth` and `sbox-data` Docker volumes, wiping credentials and all session
  history.
- **sbox-help** — Print the full command reference to stderr.

### Internal library

- **lib/config.sh** — Central configuration: image name (`sbox`), volume names
  (`sbox-auth`, `sbox-data`), and project version (`1.0.0`).
- **lib/helpers.sh** — Core runtime helpers:
  - `_sbox_build` — Lazy image build on first invocation; skips if the image
    already exists.
  - `_sbox_vols` — Assembles Docker volume flags for auth and data persistence.
  - `_sbox_guard` — Blocks execution from `$HOME`.
  - `_sbox_run` — Unified `docker run` wrapper with optional pwd mount (`-w`),
    no-tty mode (`-n`), and custom entrypoint (`-e`).
- **lib/validate.sh** — `_sbox_validate_session_id` — validates session IDs as
  alphanumeric (dashes and underscores allowed) to prevent SQL injection.

### Docker image

- Alpine 3.21 base image with packages: bash, git, ripgrep, python3, curl, jq,
  make, sqlite.
- opencode v1.14.39 installed as a standalone binary (Bun-compiled, no Node.js
  runtime required).
- Runs as non-root user `sandbox` (uid 1000).
- Working directory set to `/workspace` for project bind mounts.
- Image size approximately 80 MB.

### Security

- Filesystem isolation: the container only sees the bind-mounted project
  directory.
- No host credentials, SSH keys, or dotfiles are passed into the container.
- Auth tokens are stored in a Docker volume — they never touch the host
  filesystem.
- `$HOME` guard prevents accidental exposure of the entire home directory.
- Session ID validation prevents SQL injection in query and manage commands.
- No `--privileged` flag or extra capabilities.

### Testing

- Unit tests with bats-core using mock docker commands — no Docker daemon
  required.
  - `test/unit/helpers.bats` — covers `_sbox_build`, `_sbox_vols`, `_sbox_guard`,
    `_sbox_run`.
  - `test/unit/launch.bats` — covers `sbox` and `sbox-resume`.
  - `test/unit/query.bats` — covers `sbox-sessions`, `sbox-todos`, `sbox-stats`,
    `sbox-export`, `sbox-db`.
  - `test/unit/manage.bats` — covers `sbox-delete`, `sbox-reset-auth`,
    `sbox-reset-all`, `sbox-rebuild`.
- Integration tests requiring a running Docker daemon:
  - `test/integration/runtime.bats` — tool availability, user/permissions.
  - `test/integration/dockerfile.bats` — image build, volume mounts.
- Test infrastructure: `test/setup.sh` (installs bats-core), `test/cleanup.sh`
  (removes dependencies and optionally Docker artifacts), `test/helpers/mocks.bash`
  (mock framework).
- ShellCheck linting: `shellcheck sbox.sh lib/*.sh commands/*.sh`.

### Documentation

- **README.md** — Full user guide: setup, commands, data locations, session
  inspection, troubleshooting, contributing guidelines, and security model.
- **docs/architecture.md** — System capabilities, data flow, security model, and
  design decisions.
- **docs/api.md** — Internal function contracts, config variables, and
  per-command reference.
- **docs/testing.md** — Mock framework API, writing tests, and running tests.
