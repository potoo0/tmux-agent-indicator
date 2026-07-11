#!/usr/bin/env bash
# Shared tmux user-option helpers for exposing agent state to tmux formats.

agent_set_pane_options() {
    local pane_id="$1"
    local state="$2"
    local agent="$3"

    tmux set-option -qpt "$pane_id" @agent_state "$state" || true
    tmux set-option -qpt "$pane_id" @agent_name "$agent" || true
}

agent_clear_pane_options() {
    local pane_id="$1"

    tmux set-option -qpt "$pane_id" -u @agent_state 2>/dev/null || true
    tmux set-option -qpt "$pane_id" -u @agent_name 2>/dev/null || true
}

agent_set_window_options() {
    local window_id="$1"
    local state="$2"
    local agent="$3"

    tmux set-window-option -qt "$window_id" @agent_state "$state" || true
    tmux set-window-option -qt "$window_id" @agent_name "$agent" || true
}

agent_clear_window_options() {
    local window_id="$1"

    tmux set-window-option -qt "$window_id" -u @agent_state 2>/dev/null || true
    tmux set-window-option -qt "$window_id" -u @agent_name 2>/dev/null || true
}

agent_state_priority() {
    case "$1" in
        needs-input) printf '3\n' ;;
        running) printf '2\n' ;;
        done) printf '1\n' ;;
        *) printf '0\n' ;;
    esac
}

agent_refresh_window_options() {
    local window_id="$1"
    local best_state=""
    local best_agent=""
    local best_priority=0
    local pane_id state priority

    while IFS= read -r pane_id; do
        [ -n "$pane_id" ] || continue
        state=$(tmux_get_env "TMUX_AGENT_PANE_${pane_id}_STATE")
        case "$state" in
            running|needs-input|done) ;;
            *) continue ;;
        esac
        priority=$(agent_state_priority "$state")
        if [ "$priority" -gt "$best_priority" ]; then
            best_state="$state"
            best_agent=$(tmux_get_env "TMUX_AGENT_PANE_${pane_id}_AGENT")
            best_priority="$priority"
        fi
    done < <(tmux list-panes -t "$window_id" -F '#{pane_id}' 2>/dev/null || true)

    if [ -n "$best_state" ]; then
        agent_set_window_options "$window_id" "$best_state" "$best_agent"
    else
        agent_clear_window_options "$window_id"
    fi
}
