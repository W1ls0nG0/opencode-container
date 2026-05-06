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

# ─── sbox ──────────────────────────────────────────────────────────────────────

@test "sbox calls docker run with --rm flag" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox
    assert_docker_called_with "--rm"
}

@test "sbox calls docker run with -it flags" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox
    assert_docker_called_with "-it"
}

@test "sbox mounts current directory as /workspace" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox
    assert_docker_called_with "/tmp/test-project:/workspace"
}

@test "sbox passes extra arguments to the container" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox --version
    assert_docker_called_with "--version"
}

@test "sbox uses correct image name" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox
    assert_docker_called_with "$_SBOX_IMAGE"
}

@test "sbox refuses to run from HOME" {
    PWD="/tmp/test-home" HOME="/tmp/test-home" run sbox
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "Refusing"
}

@test "sbox does not call docker when run from HOME" {
    PWD="/tmp/test-home" HOME="/tmp/test-home" run sbox
    [ "$(mock_docker_call_count)" -eq 0 ]
}

# ─── sbox-resume ──────────────────────────────────────────────────────────────

@test "sbox-resume passes --continue flag to opencode" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox-resume
    assert_docker_called_with "--continue"
}

@test "sbox-resume forwards --session flag" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox-resume --session abc123
    assert_docker_called_with "--session"
    assert_docker_called_with "abc123"
}

@test "sbox-resume mounts project directory" {
    PWD="/tmp/test-project" HOME="/tmp/test-home" run sbox-resume
    assert_docker_called_with "/tmp/test-project:/workspace"
}

@test "sbox-resume refuses to run from HOME" {
    PWD="/tmp/test-home" HOME="/tmp/test-home" run sbox-resume
    [ "$status" -eq 1 ]
}
