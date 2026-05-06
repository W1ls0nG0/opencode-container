#!/usr/bin/env bats

setup() {
    load '../helpers/mocks'
    mock_docker_setup
    mock_docker_inspect_ok
    PATH="$_MOCK_DIR:$PATH"
    load_functions
}

teardown() {
    mock_docker_teardown
}

# ─── sbox-delete ──────────────────────────────────────────────────────────────

@test "sbox-delete requires an argument" {
    run sbox-delete
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "Usage"
}

@test "sbox-delete calls session delete with the given ID" {
    run sbox-delete "abc123"
    assert_docker_called_with "session"
    assert_docker_called_with "delete"
    assert_docker_called_with "abc123"
}

# ─── sbox-rebuild ─────────────────────────────────────────────────────────────

@test "sbox-rebuild removes existing image" {
    run sbox-rebuild
    assert_docker_called_with "rmi"
    assert_docker_called_with "$_SBOX_IMAGE"
}

@test "sbox-rebuild triggers a rebuild" {
    run sbox-rebuild
    assert_docker_called_with "build"
}

# ─── sbox-reset-auth ──────────────────────────────────────────────────────────

@test "sbox-reset-auth removes the auth volume" {
    run sbox-reset-auth
    assert_docker_called_with "volume"
    assert_docker_called_with "rm"
    assert_docker_called_with "$_SBOX_AUTH_VOL"
}

# ─── sbox-reset-all ───────────────────────────────────────────────────────────

@test "sbox-reset-all removes both volumes when confirmed" {
    echo "y" | run sbox-reset-all
    assert_docker_called_with "volume"
    assert_docker_called_with "rm"
    assert_docker_called_with "$_SBOX_AUTH_VOL"
    assert_docker_called_with "$_SBOX_DATA_VOL"
}

@test "sbox-reset-all aborts when not confirmed" {
    local stdin_file
    stdin_file="$(mktemp)"
    echo "n" > "$stdin_file"
    run sbox-reset-all < "$stdin_file"
    rm -f "$stdin_file"
    [ "$status" -eq 0 ]
    assert_docker_not_called_with "volume"
}

# ─── sbox-help ────────────────────────────────────────────────────────────────

@test "sbox-help lists the sbox command" {
    run sbox-help
    echo "$output" | grep -q "sbox"
}

@test "sbox-help lists sbox-resume command" {
    run sbox-help
    echo "$output" | grep -q "sbox-resume"
}

@test "sbox-help lists sbox-sessions command" {
    run sbox-help
    echo "$output" | grep -q "sbox-sessions"
}

@test "sbox-help lists sbox-todos command" {
    run sbox-help
    echo "$output" | grep -q "sbox-todos"
}

@test "sbox-help lists sbox-stats command" {
    run sbox-help
    echo "$output" | grep -q "sbox-stats"
}

@test "sbox-help lists sbox-export command" {
    run sbox-help
    echo "$output" | grep -q "sbox-export"
}

@test "sbox-help lists sbox-db command" {
    run sbox-help
    echo "$output" | grep -q "sbox-db"
}

@test "sbox-help lists sbox-delete command" {
    run sbox-help
    echo "$output" | grep -q "sbox-delete"
}

@test "sbox-help lists sbox-reset-auth command" {
    run sbox-help
    echo "$output" | grep -q "sbox-reset-auth"
}

@test "sbox-help lists sbox-reset-all command" {
    run sbox-help
    echo "$output" | grep -q "sbox-reset-all"
}

@test "sbox-help lists sbox-rebuild command" {
    run sbox-help
    echo "$output" | grep -q "sbox-rebuild"
}

@test "sbox-help describes volume locations" {
    run sbox-help
    echo "$output" | grep -q "sbox-auth"
    echo "$output" | grep -q "sbox-data"
}
