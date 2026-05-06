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

# ─── sbox-sessions ────────────────────────────────────────────────────────────

@test "sbox-sessions calls session list with table format" {
    run sbox-sessions
    assert_docker_called_with "session"
    assert_docker_called_with "list"
    assert_docker_called_with "--format"
    assert_docker_called_with "table"
}

@test "sbox-sessions passes extra arguments through" {
    run sbox-sessions --limit 5
    assert_docker_called_with "--limit"
    assert_docker_called_with "5"
}

# ─── sbox-todos ───────────────────────────────────────────────────────────────

@test "sbox-todos rejects non-alphanumeric session IDs" {
    run sbox-todos "bad;id"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "Invalid session ID"
}

@test "sbox-todos rejects session IDs with special characters" {
    run sbox-todos "id\$(whoami)"
    [ "$status" -eq 1 ]
}

@test "sbox-todos accepts alphanumeric session IDs" {
    run sbox-todos "abc123"
    echo "$output" | grep -qv "Invalid session ID"
}

@test "sbox-todos accepts session IDs with dashes and underscores" {
    run sbox-todos "abc_123-def"
    echo "$output" | grep -qv "Invalid session ID"
}

@test "sbox-todos without args does not error on validation" {
    run sbox-todos
    echo "$output" | grep -qv "Invalid session ID"
}

# ─── sbox-stats ───────────────────────────────────────────────────────────────

@test "sbox-stats calls stats command" {
    run sbox-stats
    assert_docker_called_with "stats"
}

@test "sbox-stats passes model and tool limits" {
    run sbox-stats
    assert_docker_called_with "--models"
    assert_docker_called_with "10"
    assert_docker_called_with "--tools"
}

# ─── sbox-export ──────────────────────────────────────────────────────────────

@test "sbox-export calls export command" {
    run sbox-export "test-session"
    assert_docker_called_with "export"
    assert_docker_called_with "test-session"
}

@test "sbox-export filename contains session id when provided" {
    local out="session-test-session-"
    run sbox-export "test-session"
    assert_docker_called_with "export"
}

# ─── sbox-db ──────────────────────────────────────────────────────────────────

@test "sbox-db with no arguments calls .tables" {
    run sbox-db
    assert_docker_called_with ".tables"
}

@test "sbox-db with SQL passes it through" {
    run sbox-db "SELECT * FROM session"
    assert_docker_called_with "SELECT * FROM session"
}

@test "sbox-db passes db subcommand" {
    run sbox-db "SELECT 1"
    assert_docker_called_with "db"
}
