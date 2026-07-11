#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/lib/tmux-test-lib.sh"

trap cleanup_test_server EXIT

setup_test_server "state-transitions"

run_state running
assert_non_empty "$(get_pane_option "$PANE" "@agent_state")" "pane @agent_state should be set after running"
[ "$(get_pane_option "$PANE" "@agent_state")" = "running" ] || fail "pane @agent_state should be running"
[ "$(get_pane_option "$PANE" "@agent_name")" = "claude" ] || fail "pane @agent_name should be claude"
[ "$(get_window_option "$WIN" "@agent_state")" = "running" ] || fail "window @agent_state should be running"
[ "$(get_window_option "$WIN" "@agent_name")" = "claude" ] || fail "window @agent_name should be claude"

run_state needs-input
[ "$(get_pane_option "$PANE" "@agent_state")" = "needs-input" ] || fail "pane @agent_state should be needs-input"
[ "$(get_window_option "$WIN" "@agent_state")" = "needs-input" ] || fail "window @agent_state should be needs-input"

run_state "done"
[ "$(get_pane_option "$PANE" "@agent_state")" = "done" ] || fail "pane @agent_state should be done"
[ "$(get_window_option "$WIN" "@agent_state")" = "done" ] || fail "window @agent_state should be done"

run_state off

state_after="$(get_env "TMUX_AGENT_PANE_${PANE}_STATE")"
assert_empty "$state_after" "pane state should be cleared after off"
assert_empty "$(get_pane_option "$PANE" "@agent_state")" "pane @agent_state should be cleared after off"
assert_empty "$(get_pane_option "$PANE" "@agent_name")" "pane @agent_name should be cleared after off"
assert_empty "$(get_window_option "$WIN" "@agent_state")" "window @agent_state should be cleared after off"
assert_empty "$(get_window_option "$WIN" "@agent_name")" "window @agent_name should be cleared after off"

indicator_after="$(run_indicator_capture "$PANE")"
assert_empty "$indicator_after" "indicator should be empty after off"

pass "state transitions running -> needs-input -> done -> off"
