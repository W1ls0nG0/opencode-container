#!/usr/bin/env bash

_MOCK_DIR="$(mktemp -d)"
_MOCK_DOCKER_LOG="$_MOCK_DIR/docker_calls"
_MOCK_DOCKER_EXIT="$_MOCK_DIR/docker_exit"
_MOCK_DOCKER_STDOUT="$_MOCK_DIR/docker_stdout"

mock_docker_setup() {
    echo "0" > "$_MOCK_DOCKER_EXIT"
    echo "" > "$_MOCK_DOCKER_STDOUT"
    : > "$_MOCK_DOCKER_LOG"

    cat > "$_MOCK_DIR/docker" <<'MOCK'
#!/usr/bin/env bash
echo "$@" >> "$(dirname "$0")/docker_calls"
cat "$(dirname "$0")/docker_stdout"
exit "$(cat "$(dirname "$0")/docker_exit")"
MOCK
    chmod +x "$_MOCK_DIR/docker"
}

mock_docker_teardown() {
    rm -rf "$_MOCK_DIR"
}

mock_docker_set_exit() {
    echo "$1" > "$_MOCK_DOCKER_EXIT"
}

mock_docker_set_stdout() {
    echo "$1" > "$_MOCK_DOCKER_STDOUT"
}

mock_docker_calls() {
    cat "$_MOCK_DOCKER_LOG"
}

mock_docker_last_call() {
    tail -1 "$_MOCK_DOCKER_LOG"
}

mock_docker_call_count() {
    wc -l < "$_MOCK_DOCKER_LOG" | tr -d ' '
}

assert_docker_called_with() {
    local expected="$1"
    local calls
    calls="$(mock_docker_calls)"
    if ! echo "$calls" | grep -qF -- "$expected"; then
        echo "FAIL: expected docker call containing: $expected" >&2
        echo "Actual calls:" >&2
        echo "$calls" >&2
        return 1
    fi
}

assert_docker_not_called_with() {
    local expected="$1"
    local calls
    calls="$(mock_docker_calls)"
    if echo "$calls" | grep -qF -- "$expected"; then
        echo "FAIL: expected docker call NOT containing: $expected" >&2
        echo "Actual calls:" >&2
        echo "$calls" >&2
        return 1
    fi
}

mock_docker_inspect_ok() {
    mock_docker_set_stdout ""
    mock_docker_set_exit 0
    _mock_docker_behaviors
}

mock_docker_inspect_fail() {
    mock_docker_set_stdout ""
    mock_docker_set_exit 1
    _mock_docker_behaviors
}

_mock_docker_behaviors() {
    local state_file="$_MOCK_DIR/docker_state"
    echo "" > "$state_file"

    cat > "$_MOCK_DIR/docker" <<MOCK
#!/usr/bin/env bash
LOG="\$(dirname "\$0")/docker_calls"
STATE="\$(dirname "\$0")/docker_state"
EXIT="\$(cat "\$(dirname "\$0")/docker_exit")"
echo "\$@" >> "\$LOG"

case "\$1" in
    rmi)
        echo "removed" > "\$STATE"
        exit 0
        ;;
    image)
        if [ "\$2" = "inspect" ]; then
            if grep -q "removed" "\$STATE" 2>/dev/null; then
                exit 1
            fi
            exit "\$EXIT"
        fi
        ;;
    volume)
        if [ "\$2" = "rm" ]; then
            exit 0
        fi
        ;;
esac

cat "\$(dirname "\$0")/docker_stdout"
exit 0
MOCK
    chmod +x "$_MOCK_DIR/docker"
}

load_functions() {
    local mocks_dir
    mocks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_root
    repo_root="$(cd "$mocks_dir/../.." && pwd)"
    # shellcheck source=/dev/null
    source "$repo_root/sbox.sh"
}
