_sbox_build() {
    docker image inspect "$_SBOX_IMAGE" >/dev/null 2>&1 && return 0
    local dockerfile
    dockerfile="$_SBOX_DIR/Dockerfile"
    if [ ! -f "$dockerfile" ]; then
        echo "Dockerfile not found at $dockerfile" >&2
        return 1
    fi
    echo "Building $_SBOX_IMAGE (first run only)..." >&2
    docker build --no-cache -t "$_SBOX_IMAGE" -f "$dockerfile" "$_SBOX_DIR"
}

_sbox_vols() {
    printf -- '-v %s:/home/sandbox/.local/share/opencode ' "$_SBOX_AUTH_VOL"
    printf -- '-v %s:/home/sandbox/.local/state/opencode ' "$_SBOX_DATA_VOL"
}

_sbox_guard() {
    if [ "$PWD" = "$HOME" ]; then
        echo "Refusing to run from \$HOME — cd into a project first." >&2
        return 1
    fi
}

# Usage: _sbox_run [-w] [-n] [-e CMD] [-- opencode args...]
#   -w      mount $PWD:/workspace
#   -n      no tty (stdin only, for piped output)
#   -e CMD  custom entrypoint
_sbox_run() {
    local tty_flag="-it" pwd_mount=() entrypoint=()
    while [[ "${1:-}" == -[wne] || "${1:-}" == -- ]]; do
        case "$1" in
            -w) pwd_mount=("-v" "$PWD:/workspace"); shift ;;
            -n) tty_flag="-i"; shift ;;
            -e) entrypoint=("--entrypoint" "$2"); shift 2 ;;
            --) shift; break ;;
        esac
    done
    docker run --rm "$tty_flag" $(_sbox_vols) \
        "${pwd_mount[@]}" "${entrypoint[@]}" "$_SBOX_IMAGE" "$@"
}
