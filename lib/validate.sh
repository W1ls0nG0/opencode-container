_sbox_validate_session_id() {
    if [[ -z "${1:-}" ]]; then
        return 0
    fi
    if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Invalid session ID: must be alphanumeric (dashes/underscores ok)" >&2
        return 1
    fi
}
