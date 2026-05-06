#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    IMAGE="sbox"
}

# ─── Build ─────────────────────────────────────────────────────────────────────

@test "Docker image builds successfully" {
    run docker build -t "$IMAGE" "$REPO_ROOT"
    [ "$status" -eq 0 ]
}

# ─── Tools installed ──────────────────────────────────────────────────────────

@test "bash is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v bash"
    [ "$status" -eq 0 ]
}

@test "git is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v git"
    [ "$status" -eq 0 ]
}

@test "ripgrep is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v rg"
    [ "$status" -eq 0 ]
}

@test "python3 is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v python3"
    [ "$status" -eq 0 ]
}

@test "curl is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v curl"
    [ "$status" -eq 0 ]
}

@test "jq is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v jq"
    [ "$status" -eq 0 ]
}

@test "make is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v make"
    [ "$status" -eq 0 ]
}

@test "sqlite3 is installed" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v sqlite3"
    [ "$status" -eq 0 ]
}

# ─── opencode binary ──────────────────────────────────────────────────────────

@test "opencode binary is on PATH" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "command -v opencode"
    [ "$status" -eq 0 ]
}

@test "opencode binary is executable" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "test -x \$(command -v opencode)"
    [ "$status" -eq 0 ]
}

# ─── User and working directory ───────────────────────────────────────────────

@test "container runs as sandbox user" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "whoami"
    [ "$status" -eq 0 ]
    [ "$output" = "sandbox" ]
}

@test "sandbox user has uid 1000" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "id -u"
    [ "$status" -eq 0 ]
    [ "$output" = "1000" ]
}

@test "working directory is /workspace" {
    run docker run --rm --entrypoint sh "$IMAGE" -c "pwd"
    [ "$status" -eq 0 ]
    [ "$output" = "/workspace" ]
}

# ─── Image size ───────────────────────────────────────────────────────────────

@test "image size is reasonable (under 300MB)" {
    size=$(docker image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null)
    # Size is in bytes; 300MB = 314572800
    [ "$size" -lt 314572800 ]
}
