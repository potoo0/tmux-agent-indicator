#!/usr/bin/env bash
# Shared tmux helpers.

tmux_option_is_set() {
    local option="$1"
    local raw

    raw=$(tmux show-option -gq "$option" 2>/dev/null || true)
    [ -n "$raw" ]
}

tmux_get_option_or_default() {
    local option="$1"
    local default_value="$2"
    local value

    if tmux_option_is_set "$option"; then
        value=$(tmux show-option -gqv "$option")
        printf '%s\n' "$value"
    else
        printf '%s\n' "$default_value"
    fi
}

tmux_get_env() {
    local key="$1"

    tmux show-environment -g "$key" 2>/dev/null | sed 's/^[^=]*=//' || true
}

tmux_set_env() {
    tmux set-environment -g "$1" "$2"
}

tmux_unset_env() {
    tmux set-environment -gu "$1" 2>/dev/null || true
}
