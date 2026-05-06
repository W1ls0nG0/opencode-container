sbox-sessions() {
    _sbox_build || return 1
    _sbox_run session list --format table "$@"
}

sbox-todos() {
    _sbox_build || return 1
    local filter=""
    if [ -n "${1:-}" ]; then
        _sbox_validate_session_id "$1" || return 1
        filter="WHERE session_id = '$1'"
    fi
    local db_path
    db_path="$(docker run --rm -i $(_sbox_vols) \
        --entrypoint opencode "$_SBOX_IMAGE" db path 2>/dev/null)"
    docker run --rm -i $(_sbox_vols) \
        --entrypoint sqlite3 \
        "$_SBOX_IMAGE" \
        "$db_path" \
        "SELECT s.title, t.content, t.status, t.priority
         FROM todo t
         JOIN session s ON s.id = t.session_id
         $filter
         ORDER BY t.session_id, t.priority;" \
        2>/dev/null \
        || echo "(no todos found — they only exist if the agent used the todowrite tool)" >&2
}

sbox-stats() {
    _sbox_build || return 1
    _sbox_run stats --models 10 --tools 10 "$@"
}

sbox-export() {
    _sbox_build || return 1
    _sbox_validate_session_id "${1:-}" || return 1
    local out="session-${1:-latest}-$(date +%Y%m%d-%H%M%S).json"
    _sbox_run export "$1" > "$out"
    echo "Saved: $out" >&2
}

sbox-db() {
    _sbox_build || return 1
    if [ -z "${1:-}" ]; then
        _sbox_run db ".tables"
    else
        _sbox_run db "$1"
    fi
}
