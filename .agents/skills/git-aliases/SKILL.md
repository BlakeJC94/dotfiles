---
name: git-aliases
description: Use when helping Blake with Git commands or repository workflows where a personal ~/.gitconfig alias may already handle the task. Covers the most useful configured aliases and their effects.
---

# Git aliases

Check `~/.gitconfig` when a requested Git workflow may match an alias below. These aliases are personal shortcuts, not standard Git commands, and some rely on tools such as `sk` or scripts under `~/.gitalias/`.

## Everyday status, history, and diffs

- `git st` - short status, including branch tracking and stash count.
- `git lg [log-args...]` - compact one-line history; shows the latest 8 commits by default, or passes supplied arguments to `git log --oneline`.
- `git lgs [log-args...]` - like `lg`, with per-commit file status.
- `git hist [log-args...]` - graph history using the configured `concise` format.
- `git last` - latest commit with per-file stats.
- `git dif` - summary of unstaged changes.
- `git difs` - summary of staged changes.
- `git diffs` - full staged diff.
- `git diff-branch [diff-args...]` - diff from the merge-base with `master` to `HEAD`; it assumes a local `master` ref exists.

## Staging and committing

- `git a` - interactively select unstaged tracked changes with `sk` and stage them.
- `git af` - interactively select tracked changes since `HEAD`, including staged and unstaged changes, and stage the selected files.
- `git ad` - stage all tracked-file changes; untracked files are excluded.
- `git unstage <path>...` - unstage paths without changing their contents.
- `git cm "message"` - commit staged changes with a message.
- `git cma "message" [path]...` - stage the given paths and commit; this delegates to `~/.gitalias/cma`.
- `git uncommit` - undo the last commit while keeping its changes staged.

## Branches and restoring files

- `git co` - interactively choose and check out a local branch using `sk`.
- `git b` - switch back to the previously checked-out branch.
- `git prime` - print the default branch advertised by `origin`.
- `git get <ref> <path>...` - restore paths from a ref without moving `HEAD`.
- `git up` - set the current branch's upstream through `~/.gitalias/up`.

## Destructive or publish operations

Check the target and working-tree state before using these aliases:

- `git forget` - with no paths, hard-resets tracked files to `HEAD`; with paths, restores those paths from `HEAD` in both the index and working tree.
- `git purge` - removes untracked files and directories (`git clean -fd`).
- `git cleanup` - fetches with pruning, then force-deletes local branches whose upstream is gone.
- `git ca` / `git ce` - amend the previous commit, respectively editing or retaining its message.
- `git sync [message]` - stages tracked changes and commits them, using a timestamped message by default.
- `git yeet [message]` - runs `git sync` and then pushes. This creates a commit and publishes it; inspect the staged scope and destination first.

## Guidance

- Prefer aliases when they match the requested workflow, but explain their effects before recommending destructive or publishing operations.
- Do not assume external helpers are installed: aliases such as `cma`, `up`, `chip`, and `rb` invoke scripts in `~/.gitalias/`; interactive aliases require `sk`.
- For exact or less common behavior, inspect the current `~/.gitconfig` rather than relying on this summary, since the config can change.
