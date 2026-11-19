---
name: dotfiles
description: Help Blake inspect and manage the home-directory dotfiles repository across machines using `git dotfiles`; triggers include dotfiles, git dotfiles, syncing dotfiles, or changing a tracked home config.
---

# Dotfiles workflow

## When to Use

Use for everyday inspection and management of Blake's dotfiles repository. `git dotfiles` runs Git with `~/.dotfiles` as the Git directory and `$HOME` as the worktree. This is not a regular repository rooted in the current directory.

## Bare checkout model

- `~/.dotfiles` is a bare Git repository: it stores Git metadata and the index, not a checked-out directory tree.
- The worktree is `$HOME`. `git dotfiles` supplies `--git-dir="$HOME/.dotfiles/"` and `--work-tree="$HOME"` to each Git command, so tracked paths correspond directly to files under the home directory. There is no `.git` directory in `$HOME` for this repo.
- The local config has `status.showUntrackedFiles=no`, so status omits untracked home-directory files. `git dotfiles sync` also stages tracked changes only (`git add -uv .`); track new dotfiles by re-adding their affected subdirectory after reviewing its nested `.gitignore` rules. Never run `git dotfiles add` at the home-directory root (`~`, `$HOME`, or `.` from this worktree).
- Changes made in the home directory are the worktree changes for this repo. Checkout, restore, and reset operations can overwrite those files, so inspect the exact target and current diff first.
- Keep status and untracked-file searches scoped. Do not run `git dotfiles status --untracked-files=all` across the whole home directory: caches and build trees can trigger huge scans or symlink errors. First list tracked changed paths, identify their parent directories, then check for untracked files only in those directories and inspect candidates individually.

## Nested ignore-file audit

When adding or reviewing files, rely on nested `.gitignore` files to exclude secrets, machine-local settings, generated artifacts, caches, build output, and state that should not be committed. Use `git dotfiles ls-files` to see the tracked dotfiles; scope it to an affected directory with `git dotfiles ls-files -- <directory>` when useful. Inspect the directory contents and existing ignore rules too; base patterns on files actually present rather than guessing.

When a nested `.gitignore` is needed, create it in the specific directory and add narrow patterns that ignore the identified secrets and state while preserving files that belong in version control. Do not apply a blanket ignore to a directory unless its contents are intentionally all local. Never stage secret or state files. Stage additions by re-adding the affected subdirectory with `git dotfiles add -- <subdirectory>` after reviewing the ignore rules and dry-run output. Never run `git dotfiles add` at the home-directory root (`~`, `$HOME`, or `.` from this worktree).

A `.gitignore` rule does not affect files already tracked by Git. If a secret or state file is already tracked, report that separately; do not imply the new rule protects it or untrack it without authorization. Verify new rules against representative untracked paths with `git check-ignore -v -- <path>` (use `git dotfiles check-ignore` for the dotfiles worktree), then inspect status and the staged diff.

## Procedure

1. Start with `git dotfiles status`, then use `git dotfiles ls-files` to see the tracked dotfiles and inspect relevant changes with `git dotfiles diff -- <path>`. For each changed path, inspect its parent directory for untracked files using a search scoped to that directory; compare candidates with `git dotfiles ls-files -- <directory>`, review their contents, and decide whether each is a useful dotfile to keep or local/generated/secret state to leave out. Report keep-worthy candidates and do not stage them without authorization. Never scan the entire home directory for untracked files.
2. Once the nested ignore rules and candidate files are reviewed, re-add the affected subdirectory with `git dotfiles add -- <subdirectory>` to track intended new files; never run `git dotfiles add` at the home-directory root (`~`, `$HOME`, or `.` from this worktree). Inspect the staged result with `git dotfiles diff --cached`.
3. Commit reviewed changes with `git dotfiles cm "message"`. For explicit paths, `git dotfiles cma "message" <path>...` stages those paths and commits them; inspect its helper if its exact behavior matters.
4. Before restoring anything, confirm the exact path and explain that `git dotfiles forget <path>` discards its staged and unstaged changes. Without a path, `git dotfiles forget` hard-resets all tracked changes.
5. Treat `git dotfiles sync` as a repo-wide operation: it stages tracked changes and commits them. Treat `git dotfiles yeet` as publishing: it syncs and pushes. Do not run either unless Blake explicitly requests it.
6. The `~/.gitalias/dotfiles` wrapper guards directory-wide mutations. For `git dotfiles add <subdirectory>`, it warns, runs `git add --dry-run -v` for that target, then prompts `Proceed? [y/N]`; declining stops the command. Review the scope and dry-run output and honor the prompt - do not bypass it. Never run add at the home-directory root (`~`, `$HOME`, or `.` from this worktree).

## Pitfalls

- Do not run ordinary `git` commands expecting them to target the dotfiles repo; use `git dotfiles`.
- Never run `git dotfiles add` at the home-directory root (`~`, `$HOME`, or `.` from this worktree). Re-add only the affected subdirectory after checking its nested `.gitignore` rules and reviewing the wrapper's dry-run; it still asks before performing the real add.
- Do not assume untracked files are included by `git dotfiles sync`; its configured command uses `git add -uv .`, which stages tracked-file changes only.
- `git dotfiles forget` without a path is destructive. `git dotfiles yeet` pushes to the configured remote.
- Guidance first for dotfiles changes generally. The nested-ignore audit above explicitly authorizes agents to create and stage a narrowly scoped nested `.gitignore` when needed; do not stage the protected secret or state files.

## Verification

- Confirm the target is the intended `$HOME` path and inspect `git dotfiles status` before and after changes.
- Before committing, verify `git dotfiles diff --cached` contains only the intended changes.
- After syncing or setting up another machine, verify with `git dotfiles status` and inspect the relevant file paths.
