---
name: split-stacked-prs
description: Split a large branch or existing GitHub PR into a docs-first PR0 staging branch and a reviewable stack of implementation PRs, then integrate the stack into PR0 for final sign-off. Preserve the original final code state and keep PR bases and train links correct.
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
    cherry-picking a noisy commit log. Prefer each branch to build and provide a
    useful result or a necessary, verifiable prerequisite. An intermediate
    branch may contain a temporary breaking change or fail to build when keeping
    it independently buildable would materially reduce reviewability. Keep the
    break as small as possible, explain how a later slice repairs it, and
    ensure the final branch contains the complete, coherent implementation.
    Only intermediate slices may carry temporary breaks; the final branch must
    not retain them and must pass its applicable checks. Preserve existing
    public and monitor-facing contracts in the final branch unless their change
    is explicitly in scope; a temporary intermediate break does not authorize
    an out-of-scope final contract change.
4. Make PR0 the documentation-only staging branch, based on `master`. Put all
    in-scope repository documentation changes from the final snapshot in PR0 so
    contracts and specs are reviewed before implementation; never include the
    private, untracked `PLAN.md`. Keep implementation PRs focused on code and
    tests. If implementation reveals a necessary docs change, update PR0 and
    propagate it through the stack for re-review. Name implementation branches
    and map each to its parent: `master -> PR0 -> PR1 -> PR2 -> ... -> PRN`.
    PR1 is based on PR0; each later PR is based on its immediate predecessor.
    Confirm the developer intends to repoint an existing PR before changing its
    base or rewriting its published head.

## Create the stack

* In this Canva checkout, inspect `../justfile` before using its recipes. The
    current `new branch_name` depends on `branch branch_name`, which runs
    `git branch --no-track <name> origin/master`, then checks out that branch.
    It uses the locally recorded `origin/master`; it does not fetch first. From
    `dev/`, use `just --justfile ../justfile new <pr0-branch>` (or
    `just new <pr0-branch>` from a directory where that justfile resolves).
    This creates PR0 from `master`; confirm the resulting snapshot contains
    only the planned docs. Check for an existing branch before invoking it.
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
* Review PR0 first for its contracts, specs, and documentation. Then create
    PR1 through PRN as a stack, with each PR based on its immediate parent.
    Review every implementation PR in detail before integration. After all are
    approved, merge from the deepest PR back toward PR0: PRN into PRN-1, then
    each updated parent into its parent, ending with PR1 into PR0. Keep PR0
    open. Review the complete PR0 diff once more for final sign-off; only then
    may PR0 merge to `master`.
* On PR1 through PRN, format as required by the repository, inspect that each
    diff contains only its intended slice, and commit. Skip per-slice build,
    test, CLI help, smoke, and other execution verification; intermediate
    branches do not need to build or pass tests. Record intentional temporary
    breaks clearly, but do not spend effort making an intermediate branch
    independently green. PR0's initial docs-only state does not need
    implementation tests. Run the full applicable validation once after the
    stack is integrated into PR0, resolve failures there, and require PR0 to
    pass before final sign-off. Each implementation PR should show only its
    slice when based on its parent.

## Preserve the original PR as PR0

* When splitting an existing PR, keep its URL and review history on PR0 by
    reusing its original branch. Save the original local and remote SHAs first.
    Reconstruct the PR0 head as the docs-only staging slice; this rewrites a
    published head and requires explicit developer authorization. Never rewrite
    it merely because the proposed stack sounds useful.
* Keep PR0 based on `master`. PR1 is based on PR0, and each later implementation
    PR is based on its immediate predecessor. After every implementation PR
    has been individually approved, integrate the stack back into PR0 in reverse
    order as described above. PR0 remains the aggregate PR and gets the final
    review; do not retarget it to PRN.
* Compare PR0's final tracked feature paths against the saved original SHA with
    `git diff --exit-code <saved-sha> HEAD -- <paths>`. Check for new files and
    deletions as well as modified files. When PR0 started from newer
    `origin/master`, do not compare whole repository trees and mistake unrelated
    upstream changes for feature changes.
* Test PR0's final integrated state. Push a rewritten existing head with
    `git push --force-with-lease=<remote-ref>:<saved-remote-sha>`, never bare
    `--force`. Stop if the lease fails; inspect the remote before deciding what
    to do. Verify PR0 still has its original URL and its diff contains the
    complete intended feature plus the reviewed docs.

## Open and link draft PRs

* Use the `pr-create` skill's description guidance and probe
    `taz submit --dry-run --no-edit --title x --summary "" --test-plan ""` for
    required headings. Run `taz fmt` before committing. `taz submit` pushes and
    creates a draft by default; pass `--base-branch <parent>` for every child.
    Do not publish a PR ready for review unless requested.
* Give every PR a short scope-specific Summary and Test Plan. For PR1 through
    PRN, state that execution checks are deferred to the integrated PR0; do not
    claim intermediate tests or checks passed. Mark PR0's final validation as
    pending integration initially, then update its Test Plan with actual results
    before final sign-off. End each PR description with a blank line
    and `<sub>Agent-assisted</sub>` on its own final line, including
    descriptions updated later in the stack. Number PRs
    PR0 through PRN and add a zero-based `(i/N)` indicator to each title, where
    `i` is the PR number and `N` is the highest PR number (there are N+1 PRs).
    Replace rather than duplicate an old indicator when updating a train.
    Label PR0 `[STAGING BRANCH]` immediately after any ticket prefix in its title.
    For every implementation PR whose branch contains an intentional temporary
    break, add `BREAKING (INTERMEDIATE)` immediately after any ticket prefix.
    Put the position indicator at the end of each title. Preserve the existing
    title text apart from these required labels and indicator. Put a `Temporary
    intermediate break` summary item at the top of each affected PR description,
    stating what breaks, who or what is affected, why the cut improves
    reviewability, and which later PR repairs it. Remove the marker only from
    branches where the break is repaired. Put a numbered **PR train** under
    Summary: links to all PRs in order, including PR0, and identify the current
    one. If later PR numbers are not known yet, create drafts in stack order
    with branch placeholders, then replace all placeholders with URLs once
    every PR exists.
* For an existing PR, fetch its current body immediately before editing it.
    Preserve manual edits, evidence, and relevant `<details>` blocks. Keep each
    implementation PR's Summary scoped to its slice. PR0 starts with a docs-only
    Summary; after integration, update it to describe the complete aggregate
    state and final review. Remove stale test claims. Update bases without
    creating replacement PRs.
* Verify all PRs are drafts, PR0's title contains `[STAGING BRANCH]`, and
    every title has the correct zero-based `(i/N)` indicator. Every branch
    containing a temporary break must have the title marker and summary
    disclosure, and every disclosure must name its repair PR. Confirm no
    temporary break remains in PR0's final integrated state. PR0 must target
    `master`; each implementation PR must target its immediate predecessor.
    Every body must contain all train links and end with
    `<sub>Agent-assisted</sub>`. When preserving an existing PR, verify PR0 has
    its original URL. Check the worktree is clean and ignored scratch files
    remain untracked.

## Propagate subsequent changes

Inspect `~/.gitalias/train-merge` and `~/.gitalias/train-rebase` before use;
these aliases may change. Their current form takes `<base> <branch>...`,
updates each listed child in order, switches branches, and leaves the last
child checked out. They do not push. For a change committed to PR0, pass PR0 as
`<base>` and PR1 through PRN as the ordered child list. For a change committed
to PRi, pass PRi as `<base>` and PR(i+1) through PRN as the ordered child list.

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
* Push updated children and confirm PR bases and train links still match; do
    not add per-slice execution checks. If a change lands after stack
    integration, get affected implementation PRs reviewed again as needed,
    repeat the reverse-order integration into PR0, rerun the full applicable
    validation on PR0, and request final sign-off on the updated PR0 state.
