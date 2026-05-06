#!/usr/bin/env bash
# source this once in your ~/.zshrc or ~/.bashrc
#
# Docker volumes used:
#   sbox-auth — credentials (auth.json), never touches your host
#   sbox-data — all sessions, plans, todos, stats (SQLite)
#
# Your project files are bind-mounted read/write from $(pwd).
# opencode may also create AGENTS.md and opencode.json in your project.
# Nothing outside $(pwd) is ever touched.

_SBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/config.sh
source "$_SBOX_DIR/lib/config.sh"
# shellcheck source=lib/helpers.sh
source "$_SBOX_DIR/lib/helpers.sh"
# shellcheck source=lib/validate.sh
source "$_SBOX_DIR/lib/validate.sh"
# shellcheck source=commands/launch.sh
source "$_SBOX_DIR/commands/launch.sh"
# shellcheck source=commands/query.sh
source "$_SBOX_DIR/commands/query.sh"
# shellcheck source=commands/manage.sh
source "$_SBOX_DIR/commands/manage.sh"
# shellcheck source=commands/help.sh
source "$_SBOX_DIR/commands/help.sh"
