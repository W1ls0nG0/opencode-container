#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    IMAGE="sbox"
}

# ─── Volume mounts ────────────────────────────────────────────────────────────

@test "auth volume mount point exists in container" {
    run docker run --rm -v "sbox-auth:/home/sandbox/.local/share/opencode" \
        --entrypoint sh "$IMAGE" -c "test -d /home/sandbox/.local/share/opencode"
    [ "$status" -eq 0 ]
}

@test "data volume mount point exists in container" {
    run docker run --rm -v "sbox-data:/home/sandbox/.local/state/opencode" \
        --entrypoint sh "$IMAGE" -c "test -d /home/sandbox/.local/state/opencode"
    [ "$status" -eq 0 ]
}

@test "project directory binds at /workspace" {
    run docker run --rm -v "$REPO_ROOT:/workspace" \
        --entrypoint sh "$IMAGE" -c "test -f /workspace/Dockerfile"
    [ "$status" -eq 0 ]
}

@test "project directory is writable by sandbox user" {
    run docker run --rm -v "$REPO_ROOT:/workspace" \
        --entrypoint sh "$IMAGE" -c "touch /workspace/.write-test && rm /workspace/.write-test"
    [ "$status" -eq 0 ]
}

# ─── Volume isolation ─────────────────────────────────────────────────────────

@test "host filesystem is not accessible from container" {
    run docker run --rm -v "$REPO_ROOT:/workspace" \
        --entrypoint sh "$IMAGE" -c "ls /root 2>&1"
    # Should either fail or be empty — no host home directory access
    [ "$status" -ne 0 ] || [ -z "$output" ]
}

@test "sbox-auth volume gets created by Docker" {
    docker run --rm -v "sbox-auth:/home/sandbox/.local/share/opencode" \
        --entrypoint true "$IMAGE"
    run docker volume inspect "sbox-auth"
    [ "$status" -eq 0 ]
}

@test "sbox-data volume gets created by Docker" {
    docker run --rm -v "sbox-data:/home/sandbox/.local/state/opencode" \
        --entrypoint true "$IMAGE"
    run docker volume inspect "sbox-data"
    [ "$status" -eq 0 ]
}
