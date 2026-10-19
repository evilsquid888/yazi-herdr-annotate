#!/usr/bin/env bash
# Open a file from Yazi in plannotator-tui (herdr-annotate) and deliver the
# review to an agent pane: the pane focused when Yazi opened, else one in the
# same tab, else one in the same workspace.
set -u
HERDR="${HERDR_BIN_PATH:-herdr}"
file="${1:-}"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/yazi/annotate-open.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "$(date "+%F %T") open: $file (pane ${HERDR_PANE_ID:-none})"

if [ -z "$file" ]; then
  echo "no file given; Yazi opener must pass %s1" >&2
  exit 2
fi

# Locate the annotate plugin's plannotator-tui (override with PLANNOTATOR_TUI).
TUI="${PLANNOTATOR_TUI:-}"
if [ -z "$TUI" ]; then
  TUI="$(ls -t "$HOME"/.config/herdr/plugins/github/annotate-*/bin/plannotator-tui.exe 2>/dev/null | head -n 1)"
fi
if [ ! -x "$TUI" ]; then
  echo "plannotator-tui not found; install the Full plugin: herdr plugin install plannotator/herdr-annotate" >&2
  exit 1
fi

# Yazi runs inside the ray.file-explorer plugin pane, so its HERDR_PLUGIN_*
# vars point at that plugin; plannotator-tui needs them to point at annotate.
ANNOTATE_ROOT="$(dirname "$(dirname "$TUI")")"
export HERDR_PLUGIN_ID=annotate HERDR_PLUGIN_ROOT="$ANNOTATE_ROOT"
export HERDR_PLUGIN_CONFIG_DIR="$HOME/.config/herdr/plugins/config/annotate"
export HERDR_PLUGIN_STATE_DIR="$HOME/.local/state/herdr/plugins/annotate"
unset HERDR_PLUGIN_ENTRYPOINT_ID

# Prefer the agent pane that was focused when Yazi was opened.
target="$(printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" | jq -r 'select(.focused_pane_agent != null) | .focused_pane_id // empty' 2>/dev/null)"
unset HERDR_PLUGIN_CONTEXT_JSON
if [ -z "$target" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
  panes="$("$HERDR" pane list 2>/dev/null)"
  tab="${HERDR_TAB_ID:-}"
  ws="${HERDR_WORKSPACE_ID:-}"
  target="$(printf '%s' "$panes" | jq -r --arg tab "$tab" --arg ws "$ws" --arg me "$HERDR_PANE_ID" '
    [.result.panes[] | select(.agent != null and .pane_id != $me)] as $a
    | (([$a[] | select(.tab_id == $tab)] + [$a[] | select(.workspace_id == $ws)])[0].pane_id) // empty')"
fi

if [ -n "$target" ]; then
  exec "$TUI" herdr open "$file" --deliver-to "$target"
else
  exec "$TUI" herdr open "$file"
fi
