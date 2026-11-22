---
name: session-transfer
description: Fork a pi session to another saved Herdr machine and continue it there - new workspace, new tab, or split pane. Use when asked to transfer, send, move, migrate, or continue this session/conversation on another machine or workspace, or to run it on a machine label such as local-server.
---

# Session transfer

Copy the current pi session to a saved Herdr machine and fork it there with
`pi --fork`. This is a fork, not a live move: the remote gets the transcript up
to a snapshot, and this local session remains as the frozen origin.

Engine: `~/.config/herdr/plugins/session-transfer/transfer.sh`
(linked Herdr plugin `blake.session-transfer`). The skill passes the machine and
destination; the script does the copy, destination creation, fork, and prompt.

## Preconditions - verify, do not assume

```bash
test "${HERDR_ENV:-}" = 1 || { echo "not inside Herdr"; exit 1; }
herdr machine list --json          # enabled profiles and their ssh targets
ssh -o BatchMode=yes <target> true # must succeed without a password prompt
```

The source agent's shell is non-interactive: `git push` and `scp` must not
prompt. Use key-based SSH only.

## Procedure

Gather the choices with `planning_questionnaire` when it is available,
otherwise ask in chat. Batch them into one stop where possible.

1. **Source.** Read the current pane and session:
   ```bash
   herdr pane get "$HERDR_PANE_ID"   # .result.pane.cwd, .agent_session.value
   ```
   Confirm the pane has a pi session and note its cwd.

2. **Local git (only what the user asks).** If `git -C <src-cwd> rev-parse
   --is-inside-work-tree` succeeds, check status and branch. Ask whether to
   commit and push. Run only the git commands the user requests; committing
   everything can include secrets, so confirm the message and scope first. The
   engine never touches the local repo.

3. **Machine.** List enabled profiles from `herdr machine list --json`
   (`label`, `target`, `enabled`). Ask which. Use the **label** with herdr and
   let the script map it to the ssh target.

4. **Remote cwd.** Default: source cwd with `$HOME` replaced by the remote
   `$HOME` (for example `/Users/blake/x` -> `/home/blake/x`). Confirm with the
   user, or ask for an explicit absolute path. Most repos differ, so do not
   guess silently.

5. **Destination.** Ask which kind, then collect the rest:
   - `workspace` - a new remote workspace (optionally `--label`).
   - `tab` - a new tab in an existing remote workspace. List them with
     `herdr --machine <label> workspace list`, then ask which (`--workspace`).
   - `split` - a split pane in an existing remote workspace. List panes with
     `herdr --machine <label> pane list --workspace <id>`, then ask which
     (`--anchor-pane`), and `--direction right|down`.

6. **Remote git.** Default is `git pull --ff-only` on the remote cwd. Also ask
   whether to switch the remote to the local branch first (`--remote-branch
   <ref>`), or to skip git (`--no-remote-git`). A dirty or diverged remote tree
   makes the pull fail; the script stops rather than clobbering it.

7. **Confirm, then run.** Summarize machine, remote cwd, destination, git mode,
   and the re-anchor prompt. Then:
   ```bash
   ~/.config/herdr/plugins/session-transfer/transfer.sh \
     --machine <label> --dest workspace|tab|split --remote-cwd /abs/remote/path \
     [--workspace <id>] [--anchor-pane <id>] [--direction right|down] \
     [--label <text>] [--remote-branch <ref>] [--no-remote-git] \
     [--prompt "<one line>"] [--no-prompt] [--no-wait]
   ```
   Keep `--prompt` to a single line. It prints a JSON summary on stdout with
   `pane`, `agent`, `remote_session`, and `source_session`.

8. **Report.** Give the remote pane, agent name, and session path. Tell the user
   that (a) the local session is now the origin and does not track the remote,
   and (b) the fork stops at the pre-transfer snapshot, so this final exchange
   is not in the remote transcript.

## Pitfalls

- Arguments to herdr agent commands must follow `--`; without it herdr parses
  flags such as `--fork` as its own and fails.
- The remote agent name must be unique among live agents and match
  `[a-z][a-z0-9_-]{0,31}`; the script generates one.
- Remote `pi` may not be on the non-interactive SSH `PATH` (version managers
  such as mise). Launching through a herdr-created pane avoids this; do not
  `ssh <target> pi ...` directly.
- Provider credentials, models, extensions, and skills are per-machine. If the
  session's last model is unavailable remotely, the fork starts but the first
  turn fails; pass a model or fix the remote config first.
- Do not commit on the user's behalf without approval.
- If the remote cwd is not a git repo, the pull is skipped with a notice; the
  fork still runs.

## Verification

```bash
herdr --machine <label> agent get <name>                 # agent_status idle
herdr --machine <label> agent read <name> --source recent-unwrapped --lines 40
```

The forked session should confirm continuity in its first reply.
