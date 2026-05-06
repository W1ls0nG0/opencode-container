sbox() {
    _sbox_guard || return 1
    _sbox_build || return 1
    _sbox_run -w "$@"
}

sbox-resume() {
    _sbox_guard || return 1
    _sbox_build || return 1
    _sbox_run -w --continue "$@"
}
