---
name: split-stacked-prs
description: Split a large branch or existing GitHub PR into a reviewable stack of branches and draft PRs, preserve the original final code state, and keep PR bases and train links correct. Use for Canva stacked PRs, especially when the first branch must use `just new` and later changes may need `git train-merge` or `git train-rebase`.
---

# Split a branch into stacked PRs

Use this when the developer asks to split an existing branch or PR. If they
only ask how to split it, propose cuts and wait. Apply repository policies and
load the `just` and `pr-create` skills when using those workflows.

## Establish the snapshot and cuts

1. Check `git status --porcelain=v1`, the current branch, its upstream, the
    original PR's base/head/draft state, and `git diff <base>...HEAD --stat`.
    Read the relevant code. Do not include unrelated, untracked, ignored, or
    local scratch files.
2. Record the original HEAD SHA and the remote head SHA before rewriting
    anything. The original commit remains a recovery point after a local reset.
    Check whether `origin/master` and the original PR's merge base differ;
    compare the changed paths across those bases. New master commits must not
    become part of a slice's PR diff.
3. Choose cuts by independently reviewable behaviour and dependencies, not by
    cherry-picking a noisy commit log. Each branch must build and provide a
    useful result or a necessary, verifiable prerequisite. Keep existing public
    and monitor-facing contracts unchanged unless their change is explicitly in
    scope.
4. Name the branches and map each to its parent:
    `master -> slice-1 -> slice-2 -> ... -> existing-final-branch`. Confirm the
    developer intends to repoint an existing PR before changing its base or
    rewriting its published head.

## Create the stack

* In this Canva checkout, inspect `../justfile` before using its recipes. The
    current `new branch_name` depends on `branch branch_name`, which runs
    `git branch --no-track <name> origin/master`, then checks out that branch.
    It uses the locally recorded `origin/master`; it does not fetch first. From
    `dev/`, use `just --justfile ../justfile new <first-branch>` (or
    `just new <first-branch>` from a directory where that justfile resolves).
    Check for an existing branch before invoking it.
* Create later branches from their immediate parent with
    `git switch -c <child>`. Do **not** use `just new` for a child: that recipe
    always starts from `origin/master`.
* Reconstruct each slice from the original final snapshot and the previous
    slice. Bring over only the files or hunks needed for that slice. If
    restoring a whole file from the snapshot, remove later-slice code before
    committing; check imports, Bazel dependencies, exports, docs, and CLI
    registration. Do not add placeholder commands merely to make an early slice
    compile. Follow repository instructions before editing any file, including
    test-file restrictions.
* After each slice: format as required by the repository, run focused
    build/tests and CLI help or smoke checks where appropriate, inspect
    `git diff <parent>...HEAD --stat` and `git diff --check`, then commit. If a
    check fails, report its exit code and relevant stderr; fix before
    continuing. Each child PR should show only that slice when based on its
    parent.

## Preserve or move an existing final PR

* Keep its URL and review history by using its original branch as the last
    branch. Save its old SHA first. Once all lower slices are committed,
    reconstruct only the remaining diff on top of the last new branch. A
    reset/rebase and force-push of a published branch requires explicit
    authorisation; never do it merely because a proposed stack sounds useful.
* Compare the new final branch's tracked feature paths against the saved
    original SHA with `git diff --exit-code <saved-sha> HEAD -- <paths>`. Check
    for new files and deletions as well as modified files. When the new first
    branch started from newer `origin/master`, do not compare whole repository
    trees and mistake unrelated upstream changes for feature changes.
* Test the resulting final branch. Push a rewritten existing head with
    `git push --force-with-lease=<remote-ref>:<saved-remote-sha>`, never bare
    `--force`. Stop if the lease fails; inspect the remote before deciding what
    to do. Retarget the existing PR to the last new branch and verify its diff
    is the intended final slice.

## Open and link draft PRs

* Use the `pr-create` skill's description guidance and probe
    `taz submit --dry-run --no-edit --title x --summary "" --test-plan ""` for
    required headings. Run `taz fmt` before committing. `taz submit` pushes and
    creates a draft by default; pass `--base-branch <parent>` for every child.
    Do not publish a PR ready for review unless requested.
* Give every PR a short scope-specific Summary and Test Plan. End each PR
    description with a blank line and `<sub>Agent-assisted</sub>` on its own
    final line, including descriptions updated later in the stack. Add a `(n/N)`
    indicator to each title, where `n` is its 1-based position and `N` is the
    total number of PRs. Place it after any ticket prefix, preserve the rest of
    an existing title, and replace rather than duplicate an old indicator when
    updating a train. Put a numbered **PR train** under Summary: links to all
    PRs in order, including itself, and identify the current one. If later PR
    numbers are not known yet, create drafts in stack order with branch
    placeholders, then replace all placeholders with URLs once every PR exists.
* For an existing PR, fetch its current body immediately before editing it.
    Preserve manual edits, evidence, and relevant `<details>` blocks while
    narrowing its Summary to its actual slice. Remove stale test claims. Update
    its base without creating a replacement PR.
* Verify all PRs are drafts, each title has the correct `(n/N)` indicator,
    each base points to the preceding head (the first points to `master`), every
    body contains all train links and ends with `<sub>Agent-assisted</sub>`,
    and the final PR has its original URL. Check
    the worktree is clean and ignored scratch files remain untracked.

## Propagate subsequent changes

Inspect `~/.gitalias/train-merge` and `~/.gitalias/train-rebase` before use;
these aliases may change. Their current form takes `<base> <branch>...`,
updates each listed child in order, switches branches, and leaves the last
child checked out. They do not push. For a change committed to slice 1, pass
slice 1 as `<base>` and slices 2 through N as the ordered child list.

* `git train-merge <changed-parent> <child-1> <child-2> ...` uses
    `git merge --no-squash --no-ff --no-edit` on each child. It preserves
    commit IDs already reviewed, but adds merge commits. Usually push the
    updated children normally.
* `git train-rebase <changed-parent> <child-1> <child-2> ...` uses
    `git rebase <base> <branch>` on each child. It gives linear history, but
    rewrites published child SHAs and may flatten merge commits. Record
    expected remote SHAs and use force-with-lease for each rewritten branch,
    with developer authorisation.
* Before either alias, check staged, unstaged, and untracked work yourself and
    inspect `git worktree list --porcelain`. Their built-in dirty check covers
    **unstaged changes only**; they reject children checked out in another
    worktree. On a conflict, stop and follow the alias's printed continuation
    instructions; do not push a partial train.
* Re-run each affected slice's checks, compare the final feature state, push
    the updated children, and confirm PR bases and train links still match.
