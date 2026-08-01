# pi-file-snapshots

Git-free file-state checkpoints for the [pi coding agent](https://pi.dev).

`pi-file-snapshots` watches the agent's `write` and `edit` tool calls and
silently keeps an independent record of your working-tree state at every
point in the conversation. You can then **revert the working tree to the
state it was in at any earlier message** — without the agent ever touching
git, and without you having to commit anything.

> Built for people who want to keep all the committing to themselves, but
> still miss opencode-style "restore to checkpoint" for the working tree.

## Features

- 📸 **Automatic capture** — every `write`/`edit` snapshots the file's
  on-disk contents *before* the change, keyed to the conversation entry.
- 🌳 **Conversation-aware** — snapshots are tied to session + entry ids, so
  each point in the tree remembers its own file state.
- ↩️ **One-command restore** — `/snapshots` lists every entry that changed
  files; pick one to roll the working tree back to that state.
- 🍴 **Auto on fork** — `/fork` offers to restore code state to the fork
  point, mirroring pi's `git-checkpoint` pattern.
- 🚫 **No git involved** — the store lives entirely outside your repo. The
  agent never runs `git`, never commits, never stashes.
- 🧪 **Fully tested** — pure store logic is unit-tested with `node:test`.

## Install

### As a pi package (recommended)

```bash
pi install npm:pi-file-snapshots
# or from git:
pi install git:github.com/earendil-works/pi-file-snapshots
```

### Local development

This package lives in pi's auto-discovered extensions directory during
development, so it loads automatically when you start pi:

```
~/.pi/agent/extensions/pi-file-snapshots/
├── index.ts
├── src/
└── test/
```

To try a checkout without installing it permanently:

```bash
pi -e ./path/to/pi-file-snapshots
```

## Usage

The extension has no configuration. Once loaded, it just works:

1. Have a conversation. Whenever the agent uses `write` or `edit`, the
   pre-change version of that file is snapshotted in the background.
2. Run `/snapshots` to open a picker of every conversation entry that
   changed files (newest first), each labeled with a snippet of the message
   and the number of files touched.
3. Pick an entry and confirm. The working tree is overwritten with the
   snapshot copies; files that did not exist at that point are deleted.
4. When you `/fork` from a previous user message, you'll be asked whether
   to restore files to that fork point before the fork proceeds.

### What gets captured

| Tool | Captured? |
|------|-----------|
| `write` | ✅ |
| `edit` | ✅ |
| `bash` | ❌ (by design) |
| `read`, `grep`, `find`, `ls` | n/a (read-only) |

Bash-driven changes (`sed`, `tee`, `> file`, etc.) are **not** snapshotted.
If the agent uses `bash` to modify files and you later restore to an earlier
point, those bash-made changes will not be reverted. Keep your own git
commits for that case, or open an issue if you'd like best-effort bash
capture.

### Storage layout

```
~/.pi/agent/file-snapshots/<sessionId>/<entryId>/
├── manifest.jsonl          # one JSON line per captured file
├── <encodedPath>           # on-disk contents at capture time
└── <encodedPath>.absent    # marker: file did NOT exist at that point
```

Override the store root with the `PI_FILE_SNAPSHOTS_DIR` environment variable.

### Reclaiming space

The store accumulates over a session. Clean it up any time:

```bash
rm -rf ~/.pi/agent/file-snapshots/<sessionId>   # one session
rm -rf ~/.pi/agent/file-snapshots                # everything
```

Deleting the store never affects your repo — it only removes the snapshot
history.

## How it works

Capture hooks pi's `tool_call` event for `write` and `edit`. For each call:

1. The on-disk version of the targeted file (resolved against `cwd`) is
   copied into the store *before* the tool executes.
2. If the file did not exist yet (a new file being created), an empty body
   plus an `.absent` marker is stored instead, so a restore knows to delete
   the file.
3. A `manifest.jsonl` line is appended for the entry, recording the path and
   its existence flag.

Restore reads an entry's directory, and for each captured file either
overwrites the live file with the snapshot copy, or deletes it if the
`.absent` marker is present.

The first capture for a given file within a given entry wins, so multiple
writes to the same file in one turn all snapshot against the same pre-change
state — exactly the "before" state you'd want to restore to.

## Commands

| Command | Description |
|---------|-------------|
| `/snapshots` | List entries that changed files and restore the working tree to one |

## Events used

| Event | Purpose |
|-------|---------|
| `tool_call` | Snapshot pre-edit state for `write`/`edit` |
| `session_before_fork` | Offer to restore files to the fork point |
| `session_shutdown` | Drop the in-memory manifest cache |

## Development

```bash
npm install            # dev dependencies (typescript, @types/node)
npm test               # run node:test suite
npm run typecheck      # tsc --noEmit
```

Tests are written with Node's built-in test runner and cover the pure
store logic (capture, restore, manifests, idempotency, path encoding) plus
the extension-layer helper functions. No live pi runtime is required to
run the suite.

## Project layout

```
pi-file-snapshots/
├── index.ts          # entry point (re-exports the factory)
├── src/
│   ├── extension.ts  # pi lifecycle wiring + /snapshots command
│   ├── store.ts      # capture / restore / manifest (pure, no ctx)
│   └── paths.ts      # path encoding + store location helpers
└── test/
    ├── paths.test.ts
    ├── store.test.ts
    └── extension.test.ts
```

## License

[MIT](./LICENSE)
