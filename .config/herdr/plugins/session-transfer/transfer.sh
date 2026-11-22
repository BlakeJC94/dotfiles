#!/usr/bin/env bash
# Fork a pi session to a saved Herdr machine and start it in a chosen destination.
# Engine for the session-transfer skill: ~/.agents/skills/session-transfer/SKILL.md
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
# Herdr runs plugin commands with a minimal PATH; restore the usual locations.
export PATH="$(dirname "$herdr"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin${PATH:+:$PATH}"

log() { printf '%s\n' "$*" >&2; }
die() { printf 'transfer: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

pane=${HERDR_PANE_ID:-}
session="" machine="" dest="" remote_cwd="" workspace=""
label="" anchor="" direction=right prompt="" do_prompt=1
name="" remote_git=1 remote_branch="" wait_settle=1 dry=0

usage() {
  cat <<'EOF'
usage: transfer.sh --machine LABEL --dest workspace|tab|split [options]

required
  --machine LABEL         enabled Herdr machine label
  --dest KIND             workspace | tab | split

source
  --pane ID               source pane (default $HERDR_PANE_ID)
  --session PATH          source session file (default from --pane)
  --name NAME             remote agent name (default transfer-<id>-<rand>)
  --prompt TEXT           re-anchor prompt (default generated, single line)
  --no-prompt             open the fork idle instead of prompting it
  --no-wait               do not wait for the prompted turn to settle

destination
  --remote-cwd PATH       remote working directory (default: source cwd, home remapped)
  --workspace ID          target workspace for --dest tab
  --anchor-pane ID        anchor pane for --dest split
  --direction right|down  split direction (default right)
  --label TEXT            workspace or tab label

code
  --no-remote-git         skip git on the remote
  --remote-branch REF     git checkout REF on the remote before pulling

  --dry-run               print the plan, mutate nothing
  -h, --help              this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --pane) pane=$2; shift 2;;
    --session) session=$2; shift 2;;
    --machine) machine=$2; shift 2;;
    --dest) dest=$2; shift 2;;
    --remote-cwd) remote_cwd=$2; shift 2;;
    --workspace) workspace=$2; shift 2;;
    --anchor-pane) anchor=$2; shift 2;;
    --direction) direction=$2; shift 2;;
    --label) label=$2; shift 2;;
    --prompt) prompt=$2; shift 2;;
    --no-prompt) do_prompt=0; shift;;
    --name) name=$2; shift 2;;
    --no-remote-git) remote_git=0; shift;;
    --remote-branch) remote_branch=$2; shift 2;;
    --no-wait) wait_settle=0; shift;;
    --dry-run) dry=1; shift;;
    -h|--help) usage; exit 0;;
    *) die "unknown option: $1 (try --help)";;
  esac
done

[ -n "$machine" ] || { usage >&2; die "--machine is required"; }
case "$dest" in workspace|tab|split) ;; *) die "--dest must be workspace, tab, or split";; esac
[ "$dest" = tab ] && [ -z "$workspace" ] && die "--dest tab needs --workspace"
[ "$dest" = split ] && [ -z "$anchor" ] && die "--dest split needs --anchor-pane"

need "$herdr"; need ssh; need scp; need jq

# --- source ---
if [ -z "$session" ]; then
  [ -n "$pane" ] || die "need --pane or --session"
  session=$("$herdr" pane get "$pane" | jq -r '.result.pane.agent_session.value // empty')
  [ -n "$session" ] || die "pane $pane has no pi session"
fi
[ -f "$session" ] || die "session file not found: $session"
head -1 "$session" | jq -e 'select(.type=="session")' >/dev/null 2>&1 \
  || die "not a pi session file: $session"
sid=$(head -1 "$session" | jq -r '.id')

src_cwd=""
[ -n "$pane" ] && src_cwd=$("$herdr" pane get "$pane" | jq -r '.result.pane.cwd // empty')

# --- machine ---
row=$("$herdr" machine list --json \
  | jq -r --arg m "$machine" '([.[] | select(.label==$m or .id==$m)][0]) // {} | "\(.target // "")\t\(.enabled // false)"')
[ -n "$row" ] || die "unknown machine: $machine"
target=${row%%$'\t'*}
enabled=${row##*$'\t'}
[ -n "$target" ] || die "machine '$machine' has no ssh target"
[ "$enabled" = true ] || die "machine '$machine' is disabled"

# --- remote cwd (absolute) ---
target_home=$(ssh -o BatchMode=yes -o ConnectTimeout=10 "$target" 'printf %s "$HOME"') \
  || die "ssh to $target failed (key-based auth required)"
[ -n "$target_home" ] || die "could not read remote HOME on $target"
if [ -z "$remote_cwd" ]; then
  case "$src_cwd" in
    "$HOME") remote_cwd=$target_home;;
    "$HOME"/*) remote_cwd="$target_home/${src_cwd#"$HOME"/}";;
    *) die "cannot map source cwd '$src_cwd' to the remote; pass --remote-cwd";;
  esac
fi
case "$remote_cwd" in /*) ;; *) die "--remote-cwd must be absolute: $remote_cwd";; esac

name=${name:-transfer-${sid:0:6}-$(printf '%04x' $((RANDOM % 65536)))}
name=$(printf '%s' "$name" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9_-' '-')
name=${name:0:32}

if [ -z "$prompt" ] && [ "$do_prompt" = 1 ]; then
  prompt="You were transferred from machine '$(hostname -s)' to '$machine'. Your working directory was $src_cwd and is now $remote_cwd. Re-resolve all paths before acting and ignore the old location. Continue the task from where it left off. First confirm continuity in one short paragraph: the last topic and the next step."
fi

remote_file="/tmp/pi-transfer-${sid:0:8}-$(date +%s).jsonl"
rq() { printf %q "$1"; }  # shell-quote a local value for a remote sh -c string

# --- plan ---
log "source session : $session"
log "source cwd     : $src_cwd"
log "machine        : $machine ($target)"
log "remote cwd     : $remote_cwd"
log "destination    : $dest${workspace:+ workspace=$workspace}${anchor:+ anchor=$anchor}${direction:+ ($direction)}"
log "remote agent   : $name"

if [ "$dry" = 1 ]; then
  log "(dry run, no changes)"
  [ "$remote_git" = 1 ] && log "  ssh $target 'git -C $(rq "$remote_cwd") pull --ff-only'"
  log "  scp $session $target:$remote_file"
  log "  $herdr --machine $machine $dest create ... --cwd $remote_cwd --no-focus"
  log "  $herdr --machine $machine agent start $name --kind pi --pane <new> -- --fork $remote_file --name $name"
  [ "$do_prompt" = 1 ] && log "  $herdr --machine $machine agent prompt $name <re-anchor prompt> --wait"
  exit 0
fi

# --- readiness ---
ssh -o BatchMode=yes "$target" "test -d $(rq "$remote_cwd")" \
  || die "remote directory does not exist: $remote_cwd"

# --- remote git ---
if [ "$remote_git" = 1 ]; then
  # A .git file (dotfiles-style bare repo) reports is-inside-work-tree=false with exit 0.
  if [ "$(ssh -o BatchMode=yes "$target" "git -C $(rq "$remote_cwd") rev-parse --is-inside-work-tree 2>/dev/null")" = true ]; then
    if [ -n "$remote_branch" ]; then
      log "remote git: checkout $remote_branch"
      ssh -o BatchMode=yes "$target" "git -C $(rq "$remote_cwd") checkout $(rq "$remote_branch")" \
        || die "remote git checkout failed"
    fi
    log "remote git: pull --ff-only"
    ssh -o BatchMode=yes "$target" "git -C $(rq "$remote_cwd") pull --ff-only" \
      || die "remote git pull failed (tree may be dirty or diverged); resolve it and retry"
  else
    log "remote git: not a repo at $remote_cwd, skipping"
  fi
fi

# --- copy session ---
log "copying session to $target:$remote_file"
scp -q -o BatchMode=yes "$session" "$target:$remote_file" \
  || die "scp to $target failed"

# --- destination ---
case "$dest" in
  workspace)
    args=(--machine "$machine" workspace create --cwd "$remote_cwd" --no-focus)
    [ -n "$label" ] && args+=(--label "$label")
    ;;
  tab)
    args=(--machine "$machine" tab create --workspace "$workspace" --cwd "$remote_cwd" --no-focus)
    [ -n "$label" ] && args+=(--label "$label")
    ;;
  split)
    args=(--machine "$machine" pane split "$anchor" --direction "$direction" --cwd "$remote_cwd" --no-focus)
    ;;
esac
result=$("$herdr" "${args[@]}") || die "$dest create failed"
new_pane=$(printf '%s' "$result" | jq -r '(.result.root_pane // .result.pane) | if type=="object" then .pane_id else . end')
[ -n "$new_pane" ] && [ "$new_pane" != null ] || die "no new pane id in: $result"
log "new pane: $new_pane"

# --- launch ---
started=$("$herdr" --machine "$machine" agent start "$name" --kind pi --pane "$new_pane" \
  -- --fork "$remote_file" --name "$name") || die "agent start failed"
remote_session=$(printf '%s' "$started" | jq -r '.result.agent.agent_session.value // empty')
log "started $name in $new_pane (session: ${remote_session:-unknown})"

# --- prompt ---
if [ "$do_prompt" = 1 ]; then
  waits=()
  [ "$wait_settle" = 1 ] && waits=(--wait --timeout 600000)
  "$herdr" --machine "$machine" agent prompt "$name" "$prompt" ${waits[@]+"${waits[@]}"} >/dev/null \
    || die "prompting $name failed"
  [ "$wait_settle" = 1 ] && log "prompted $name and waited for it to settle"
fi

printf '{"machine":"%s","pane":"%s","agent":"%s","remote_session":"%s","source_session":"%s"}\n' \
  "$machine" "$new_pane" "$name" "$remote_session" "$session"
