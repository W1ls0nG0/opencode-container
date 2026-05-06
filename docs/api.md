# Internal API Reference

This document covers every variable and function in sbox's internal modules. Public commands are documented first, then internal helpers, then config variables.

For the architectural rationale behind these interfaces, see [architecture.md](architecture.md).

---

## Config Variables

Defined in `lib/config.sh`. All variables are private (underscore-prefixed) and used throughout the codebase.

| Variable | Value | Purpose |
|---|---|---|
| `_SBOX_IMAGE` | `"sbox"` | Docker image name used in all `docker` commands |
| `_SBOX_AUTH_VOL` | `"sbox-auth"` | Named volume for credentials (`auth.json`) |
| `_SBOX_DATA_VOL` | `"sbox-data"` | Named volume for session data (SQLite DB) |
| `_SBOX_VERSION` | `"1.0.0"` | Current sbox version |
| `_SBOX_DIR` | *(computed)* | Absolute path to the directory containing `sbox.sh` — used to locate the Dockerfile and all sourced modules |

`_SBOX_DIR` is computed at the top of `sbox.sh`:
```bash
_SBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

---

## Internal Helpers

### `_sbox_build`

**Source:** `lib/helpers.sh`

**Signature:**
```
_sbox_build
```

**Behavior:**
1. Checks if the image `$_SBOX_IMAGE` already exists (`docker image inspect`)
2. If it exists, returns 0 immediately (no output)
3. If it doesn't exist, builds from `$_SBOX_DIR/Dockerfile` with `--no-cache`
4. Prints "Building sbox (first run only)..." to stderr before building

**Returns:**
| Code | Condition |
|---|---|
| `0` | Image already exists, or build succeeded |
| `1` | Dockerfile not found at expected path |

**Side effects:** Calls `docker image inspect` and potentially `docker build`.

**Used by:** Every command that needs a running container (`sbox`, `sbox-resume`, `sbox-sessions`, `sbox-todos`, `sbox-stats`, `sbox-export`, `sbox-db`, `sbox-delete`). Not used by `sbox-reset-auth`, `sbox-reset-all`.

---

### `_sbox_vols`

**Source:** `lib/helpers.sh`

**Signature:**
```
_sbox_vols
```

**Behavior:**
Outputs two Docker volume flags to stdout (space-separated, trailing space after each):
```
-v sbox-auth:/home/sandbox/.local/share/opencode -v sbox-data:/home/sandbox/.local/state/opencode 
```

**Returns:** Always `0`.

**Side effects:** None. Pure output — no docker calls.

**Consumed by:** `_sbox_run` (via `"$(_sbox_vols)"` expansion) and `sbox-todos` (raw docker calls).

---

### `_sbox_guard`

**Source:** `lib/helpers.sh`

**Signature:**
```
_sbox_guard
```

**Behavior:**
Compares `$PWD` to `$HOME`. If they match, prints an error to stderr and returns 1.

**Returns:**
| Code | Condition |
|---|---|
| `0` | `$PWD` != `$HOME` |
| `1` | `$PWD` == `$HOME` |

**Stderr on failure:**
```
Refusing to run from $HOME — cd into a project first.
```

**Used by:** `sbox`, `sbox-resume`.

---

### `_sbox_run`

**Source:** `lib/helpers.sh`

**Signature:**
```
_sbox_run [-w] [-n] [-e CMD] [-- opencode_args...]
```

**Flags:**

| Flag | Effect | Example |
|---|---|---|
| `-w` | Bind-mount `$PWD` as `/workspace` | `sbox`, `sbox-resume` |
| `-n` | Use `-i` instead of `-it` (no TTY allocation) | query commands piped to stdout |
| `-e CMD` | Override entrypoint to `CMD` | `sbox-todos` uses `--entrypoint sqlite3` |
| `--` | Pass all remaining args to the container | `--continue`, `--session abc123` |

**Behavior:**
Assembles and executes a `docker run` command:
```
docker run --rm <$tty_flag> $(_sbox_vols) [$PWD mount] [--entrypoint CMD] $_SBOX_IMAGE [opencode_args]
```

Where:
- `$tty_flag` is `-it` (default) or `-i` (with `-n`)
- `$PWD mount` is `-v $PWD:/workspace` (with `-w`)
- `$(_sbox_vols)` provides auth + data volume flags

**Returns:** The exit code of `docker run`.

**Side effects:** Runs a Docker container. The container is removed on exit (`--rm`). Volumes persist.

**Used by:** `sbox`, `sbox-resume`, `sbox-sessions`, `sbox-stats`, `sbox-export`, `sbox-db`, `sbox-delete`.

---

### `_sbox_validate_session_id`

**Source:** `lib/validate.sh`

**Signature:**
```
_sbox_validate_session_id <id>
```

**Behavior:**
- If `$1` is empty or unset, returns 0 (validation skipped — session ID is optional)
- If `$1` is non-empty, checks it against `^[a-zA-Z0-9_-]+$`
- On mismatch, prints error to stderr and returns 1

**Returns:**
| Code | Condition |
|---|---|
| `0` | Empty string, or matches `^[a-zA-Z0-9_-]+$` |
| `1` | Non-empty and contains characters outside the allowed set |

**Stderr on failure:**
```
Invalid session ID: must be alphanumeric (dashes/underscores ok)
```

**Used by:** `sbox-todos` (optional), `sbox-export` (optional), `sbox-delete` (required — validated before `_sbox_build`).

---

## Public Commands

### `sbox`

**Source:** `commands/launch.sh`

**Usage:** `sbox [opencode_args...]`

**Flow:** `_sbox_guard` → `_sbox_build` → `_sbox_run -w "$@"`

Opens the opencode TUI in the current directory. The project is bind-mounted at `/workspace`. Extra arguments are passed to the opencode binary.

**Returns:** Exit code of `docker run`, or `1` if guard/build fails.

---

### `sbox-resume`

**Source:** `commands/launch.sh`

**Usage:** `sbox-resume [--session <id>]`

**Flow:** `_sbox_guard` → `_sbox_build` → `_sbox_run -w --continue "$@"`

Same as `sbox` but passes `--continue` to opencode to resume the last session. Use `--session <id>` to resume a specific session.

**Returns:** Exit code of `docker run`, or `1` if guard/build fails.

---

### `sbox-sessions`

**Source:** `commands/query.sh`

**Usage:** `sbox-sessions [opencode_args...]`

**Flow:** `_sbox_build` → `_sbox_run session list --format table "$@"`

Lists all sessions in a table format. Extra arguments (e.g., `--limit 5`) are passed through.

---

### `sbox-todos`

**Source:** `commands/query.sh`

**Usage:** `sbox-todos [session_id]`

**Flow:**
1. `_sbox_build`
2. If `$1` provided: `_sbox_validate_session_id "$1"` → filter by `WHERE session_id = '$1'`
3. Resolve DB path: `docker run --rm -i $(_sbox_vols) --entrypoint opencode "$_SBOX_IMAGE" db path`
4. Query: `docker run --rm -i $(_sbox_vols) --entrypoint sqlite3 "$_SBOX_IMAGE" "$db_path" "SELECT ..."`

This command does **not** use `_sbox_run` because it needs a custom entrypoint (`sqlite3`) and queries the SQLite database directly.

**Output:** Columns: `title`, `content`, `status`, `priority` from the `todo` table joined with `session`. On failure, prints `(no todos found — they only exist if the agent used the todowrite tool)`.

---

### `sbox-stats`

**Source:** `commands/query.sh`

**Usage:** `sbox-stats [opencode_args...]`

**Flow:** `_sbox_build` → `_sbox_run stats --models 10 --tools 10 "$@"`

Token usage and cost breakdown, limited to top 10 models and top 10 tools.

---

### `sbox-export`

**Source:** `commands/query.sh`

**Usage:** `sbox-export [session_id]`

**Flow:** `_sbox_build` → `_sbox_validate_session_id` → `_sbox_run export "$1"`

Exports a session to a JSON file. Output filename: `session-<id>-<timestamp>.json` (or `session-latest-<timestamp>.json` if no ID provided). The JSON is written to the **current working directory on the host** (stdout redirect).

---

### `sbox-db`

**Source:** `commands/query.sh`

**Usage:** `sbox-db [sql]`

**Flow:** `_sbox_build` → `_sbox_run db "$1"`

Direct SQL access to opencode's SQLite database. With no arguments, runs `.tables` to list all tables. Otherwise passes the SQL string to `opencode db`.

---

### `sbox-delete`

**Source:** `commands/manage.sh`

**Usage:** `sbox-delete <session_id>`

**Flow:**
1. Require `$1` (print usage if missing)
2. `_sbox_validate_session_id "$1"`
3. `_sbox_build`
4. `_sbox_run session delete "$1"`

**Stderr on missing arg:**
```
Usage: sbox-delete <sessionID>  (run sbox-sessions to see IDs)
```

---

### `sbox-rebuild`

**Source:** `commands/manage.sh`

**Usage:** `sbox-rebuild`

**Flow:** `docker rmi "$_SBOX_IMAGE"` → `_sbox_build`

Removes the existing image (ignoring errors if it doesn't exist) then rebuilds from the Dockerfile. Use this to pick up a new opencode version after changing `OPENCODE_VERSION` in the Dockerfile.

---

### `sbox-reset-auth`

**Source:** `commands/manage.sh`

**Usage:** `sbox-reset-auth`

**Flow:** `docker volume rm "$_SBOX_AUTH_VOL"`

Removes only the auth volume. Sessions and data are preserved. Next `sbox` run will prompt for authentication.

**Stdout on success:**
```
Auth wiped. Next 'sbox' will prompt for login.
```

---

### `sbox-reset-all`

**Source:** `commands/manage.sh`

**Usage:** `sbox-reset-all`

**Flow:** Interactive confirmation → `docker volume rm "$_SBOX_AUTH_VOL" "$_SBOX_DATA_VOL"`

Prompts with `Delete ALL sessions, todos, plans and auth? [y/N]`. Only removes volumes if the user types `y` or `Y`.

---

### `sbox-help`

**Source:** `commands/help.sh`

**Usage:** `sbox-help`

Prints a formatted command reference to stderr. Lists all commands grouped by category (Launch, Visibility, Manage, Maintenance) and a "What lives where" data location reference.
