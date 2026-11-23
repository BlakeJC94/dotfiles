#!/usr/bin/env bash
set -u

herdr=${HERDR_BIN_PATH:-herdr}
export PATH="$(dirname "$herdr"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin${PATH:+:$PATH}"
workspace=${HERDR_RELOAD_WORKSPACE_ID:-}

pause() {
  printf '\nPress Enter to close.'
  read -r _
}

if [ -z "$workspace" ]; then
  printf 'Cannot determine the Herdr workspace for this action.\n'
  pause
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  printf 'Missing required command: jq\n'
  pause
  exit 1
fi

if ! agents=$("$herdr" agent list); then
  printf 'Could not list active Herdr agents.\n'
  pause
  exit 1
fi

eligible=$(printf '%s' "$agents" | jq -r --arg workspace "$workspace" '
  .result.agents[]?
  | select(.agent == "pi" and .workspace_id == $workspace and (.agent_status == "idle" or .agent_status == "done"))
  | select((.pane_id | type) == "string")
  | [.pane_id, (.name // .terminal_title // .pane_id | tostring | gsub("[\\t\\r\\n]"; " ")), .agent_status]
  | @tsv
') || {
  printf 'Herdr returned an invalid agent list.\n'
  pause
  exit 1
}
skipped=$(printf '%s' "$agents" | jq -r --arg workspace "$workspace" '
  .result.agents[]?
  | select(.agent == "pi" and .workspace_id == $workspace and (.agent_status != "idle" and .agent_status != "done"))
  | select((.pane_id | type) == "string")
  | [.pane_id, (.name // .terminal_title // .pane_id | tostring | gsub("[\\t\\r\\n]"; " ")), (.agent_status // "unknown")]
  | @tsv
') || {
  printf 'Herdr returned an invalid agent list.\n'
  pause
  exit 1
}

eligible_count=$(printf '%s' "$agents" | jq --arg workspace "$workspace" '[.result.agents[]? | select(.agent == "pi" and .workspace_id == $workspace and (.agent_status == "idle" or .agent_status == "done") and (.pane_id | type) == "string")] | length') || {
  printf 'Could not count reloadable Pi sessions.\n'
  pause
  exit 1
}

printf 'Herdr workspace %s\n\n' "$workspace"
printf 'Pi sessions to reload (idle/done):\n'
if [ -n "$eligible" ]; then
  while IFS=$'\t' read -r pane label status; do
    [ -n "$pane" ] && printf '  - %s (%s, %s)\n' "$label" "$status" "$pane"
  done <<< "$eligible"
else
  printf '  (none)\n'
fi
if [ -n "$skipped" ]; then
  printf '\nSkipped (not idle/done):\n'
  while IFS=$'\t' read -r pane label status; do
    [ -n "$pane" ] && printf '  - %s (%s, %s)\n' "$label" "$status" "$pane"
  done <<< "$skipped"
fi

if [ "$eligible_count" -eq 0 ]; then
  printf '\nNothing to reload.\n'
  pause
  exit 0
fi

printf '\nSubmit /reload to these sessions? [y/N] '
answer=''
read -r answer
case "$answer" in
  y|Y|yes|YES) ;;
  *) printf 'Cancelled.\n'; pause; exit 0 ;;
esac

sent=0
changed=0
failed=0
while IFS=$'\t' read -r pane label _status; do
  [ -n "$pane" ] || continue
  if ! latest=$("$herdr" agent list); then
    printf 'Could not refresh session state for %s; not sending.\n' "$pane"
    failed=$((failed + 1))
    continue
  fi
  if ! printf '%s' "$latest" | jq -e --arg workspace "$workspace" --arg pane "$pane" '
    [.result.agents[]? | select(.agent == "pi" and .workspace_id == $workspace and .pane_id == $pane and (.agent_status == "idle" or .agent_status == "done"))] | length > 0
  ' >/dev/null; then
    printf 'Skipped %s; it is no longer an idle/done Pi session in this workspace.\n' "$pane"
    changed=$((changed + 1))
    continue
  fi
  if "$herdr" agent prompt "$pane" "/reload" >/dev/null; then
    printf 'Submitted /reload to %s (%s).\n' "$label" "$pane"
    sent=$((sent + 1))
  else
    printf 'Could not confirm delivery to %s (%s); delivery may be uncertain.\n' "$label" "$pane"
    failed=$((failed + 1))
  fi
done <<< "$eligible"

printf '\nReload requests submitted: %s; skipped after state change: %s; failed or uncertain: %s.\n' "$sent" "$changed" "$failed"
pause
