#!/usr/bin/env bats

setup() {
    load '../helpers/mocks'
    mock_docker_setup
    PATH="$_MOCK_DIR:$PATH"
    load_functions
}

teardown() {
    mock_docker_teardown
}

# ─── _sbox_build ──────────────────────────────────────────────────────────────

@test "_sbox_build returns 0 when image already exists" {
    mock_docker_inspect_ok
    run _sbox_build
    [ "$status" -eq 0 ]
}

@test "_sbox_build does not run docker build when image exists" {
    mock_docker_inspect_ok
    _sbox_build
    result="$(mock_docker_calls)"
    echo "$result" | grep -vq "build"
}

@test "_sbox_build runs docker build when image is missing" {
    mock_docker_inspect_fail
    run _sbox_build
    [ "$status" -eq 0 ]
    assert_docker_called_with "build"
}

@test "_sbox_build passes correct image tag to docker build" {
    mock_docker_inspect_fail
    _sbox_build
    assert_docker_called_with "-t $_SBOX_IMAGE"
}

@test "_sbox_build passes --no-cache to docker build" {
    mock_docker_inspect_fail
    _sbox_build
    assert_docker_called_with "--no-cache"
}

@test "_sbox_build fails gracefully when Dockerfile is missing" {
    mock_docker_inspect_fail
    local dockerfile_path="$BATS_TEST_DIRNAME/../../Dockerfile"
    mv "$dockerfile_path" "$dockerfile_path.bak"
    run _sbox_build
    mv "$dockerfile_path.bak" "$dockerfile_path"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "Dockerfile not found"
}

# ─── _sbox_vols ───────────────────────────────────────────────────────────────

@test "_sbox_vols outputs auth volume flag" {
    run _sbox_vols
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "sbox-auth"
}

@test "_sbox_vols outputs data volume flag" {
    run _sbox_vols
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "sbox-data"
}

@test "_sbox_vols maps auth to /home/sandbox/.local/share/opencode" {
    run _sbox_vols
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "/home/sandbox/.local/share/opencode"
}

@test "_sbox_vols maps data to /home/sandbox/.local/state/opencode" {
    run _sbox_vols
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "/home/sandbox/.local/state/opencode"
}

@test "_sbox_vols outputs two -v flags" {
    run _sbox_vols
    count=$(echo "$output" | grep -o "\-v" | wc -l)
    [ "$count" -eq 2 ]
}

# ─── _sbox_guard ──────────────────────────────────────────────────────────────

@test "_sbox_guard blocks when PWD is HOME" {
    local orig_home="$HOME"
    HOME="/tmp/test-home"
    PWD="$HOME"
    run _sbox_guard
    [ "$status" -eq 1 ]
    HOME="$orig_home"
}

@test "_sbox_guard prints error message when blocking" {
    local orig_home="$HOME"
    HOME="/tmp/test-home"
    PWD="$HOME"
    run _sbox_guard
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "Refusing"
    HOME="$orig_home"
}

@test "_sbox_guard allows non-HOME directories" {
    local orig_home="$HOME"
    HOME="/tmp/test-home"
    PWD="/tmp/test-project"
    run _sbox_guard
    [ "$status" -eq 0 ]
    HOME="$orig_home"
}
