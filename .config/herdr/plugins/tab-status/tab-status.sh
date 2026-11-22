#!/usr/bin/env bash
# Prefix tabs with an unseen finish (done) or a blocked agent with "* ".
# Viewing a tab turns done into idle and clears the prefix. Stateless and
# idempotent: a label is renamed only when it actually changes.
set -u

bin=${HERDR_BIN_PATH:-herdr}

if ! agents=$("$bin" agent list); then
  echo "tab-status: herdr agent list failed" >&2
  exit 0
fi

if ! tabs=$("$bin" tab list); then
  echo "tab-status: herdr tab list failed" >&2
  exit 0
fi

# Tab ids hosting at least one agent that needs attention (done or blocked).
attention=$(printf '%s' "$agents" | jq -c '
  [.result.agents[]?
   | select(.agent_status == "done" or .agent_status == "blocked")
   | .tab_id] | unique')
attention=${attention:-[]}

printf '%s' "$tabs" | jq -r --argjson attention "$attention" '
  .result.tabs[]?
  | . as $tab
  | ($tab.label | sub("^\\* "; "")) as $base
  | (if ($attention | index($tab.tab_id)) then "* " + $base else $base end) as $want
  | select($want != $tab.label)
  | "\($tab.tab_id)\t\($want)"
' | while IFS=$'\t' read -r tab_id label; do
    "$bin" tab rename "$tab_id" "$label" >/dev/null
  done

exit 0
