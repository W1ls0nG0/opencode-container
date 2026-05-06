sbox-delete() {
    if [ -z "${1:-}" ]; then
        echo "Usage: sbox-delete <sessionID>  (run sbox-sessions to see IDs)" >&2
        return 1
    fi
    _sbox_validate_session_id "$1" || return 1
    _sbox_build || return 1
    _sbox_run session delete "$1"
}

sbox-rebuild() {
    docker rmi "$_SBOX_IMAGE" 2>/dev/null
    _sbox_build
}

sbox-reset-auth() {
    docker volume rm "$_SBOX_AUTH_VOL" 2>/dev/null \
        && echo "Auth wiped. Next 'sbox' will prompt for login." >&2
}

sbox-reset-all() {
    read -r -p "Delete ALL sessions, todos, plans and auth? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || return 0
    docker volume rm "$_SBOX_AUTH_VOL" "$_SBOX_DATA_VOL" 2>/dev/null
    echo "Done." >&2
}
