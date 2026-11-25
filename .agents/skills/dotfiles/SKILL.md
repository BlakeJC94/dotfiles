---
name: dotfiles
description: Manage Blake's home-directory dotfiles across machines with explicit bare-repository Git commands; triggers include dotfiles, syncing, or changing a tracked home config.
---

# Dotfiles workflow

## When to Use

Use for inspection and management of Blake's dotfiles repository at `~/.dotfiles`, whose worktree is `$HOME`.

## Required Git invocation

For every Git operation on the dotfiles worktree, use the explicit bare-repository and worktree paths:

```bash
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" <command> [args...]
```

Do not use shell aliases or wrappers for this repository. This applies to status, diff, staging, commit, restore, and push commands. For a separate repository under `$HOME`, use normal Git with `-C <repo-path>` instead.

## Bare checkout model

- `~/.dotfiles` stores Git metadata and the index; the worktree is `$HOME`.
- The local config sets `status.showUntrackedFiles=no`, so default status omits untracked files. Scope any `--untracked-files=all` search to the affected directory; never scan the whole home directory because caches and build trees can trigger huge scans or symlink errors.
- Changes under `$HOME` are worktree changes for this repository. Checkout, restore, and reset operations can overwrite them, so inspect the exact target and current diff first.
- Never stage the home-directory root (`~`, `$HOME`, or `.`). Stage only reviewed paths beneath it.

## Nested ignore-file audit

When adding or reviewing files, inspect the directory and its nested `.gitignore` files to exclude secrets, machine-local settings, generated artifacts, caches, build output, and runtime state. Use the explicit Git invocation, scoped to the affected directory:

```bash
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" ls-files -- <directory>
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" check-ignore -v -- <path>
```

When a nested `.gitignore` is needed, add narrow patterns for identified local or generated files; do not blanket-ignore a directory unless all of it is intentionally local. A `.gitignore` rule does not affect files already tracked. If a secret or state file is already tracked, report that separately; do not untrack it without authorization.

## Procedure

1. Inspect `status --short`, tracked paths, and relevant changes with `diff -- <path>`. For each changed path, inspect its parent directory for untracked files using a scoped search; compare candidates with `ls-files -- <directory>` and review their contents. Do not stage keep-worthy candidates without authorization.
2. Check nested ignore rules and review the exact staging scope. Preview additions before staging:
   ```bash
   git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" add --dry-run -v -- <subdirectory>
   ```
   After the user has authorized staging, use `add -- <subdirectory>`; never stage the home root. Inspect `diff --cached` and status afterward.
3. Commit only when explicitly requested. Review the staged diff, then use `commit -m "message"` with the explicit Git invocation.
4. Before restoring anything, confirm the exact path and explain whether the index, worktree, or both will change. Use `restore --staged -- <path>` to unstage or `restore --worktree -- <path>` to discard worktree changes only after authorization. Avoid broad resets.
5. Push only when explicitly requested. Use the explicit Git invocation with `push`; do not combine staging, committing, and pushing into one implicit workflow.

## Pitfalls

- Do not rely on default status to reveal untracked files; it is configured not to show them.
- Never stage or inspect every untracked file under `$HOME` at once.
- Do not run repo-wide staging, commit, restore, reset, or push operations unless explicitly requested.
- Do not stage secrets, runtime state, caches, or build output.

## Verification

- Confirm the target is the intended `$HOME` path and inspect status before and after changes.
- Before committing, verify the staged diff contains only the intended changes.
- After syncing or setting up another machine, verify status and inspect the relevant paths.
