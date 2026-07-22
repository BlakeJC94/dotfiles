---
name: just
description: Run tasks with just, a command runner. Use when running justfile recipes, listing available recipes, or working with branch-scoped justfiles (.$branch.just). Use ONLY when the project uses just or the user mentions just/justfile.
---

# Just - Command Runner

Use `just` to run tasks defined in justfiles. Prefer `just` over raw commands when a recipe exists for the task.

## Branch-Scoped Justfiles

This project uses branch-scoped justfiles via `git just`. Each branch gets its own justfile named `.<branch>.just` (lowercased, non-alphanumeric chars replaced with hyphens). Example: branch `feature/login` -> `.feature-login.just`.

### Workflow

1. `git just` with no args - opens the branch justfile in `$EDITOR` (creates it if missing)
2. `git just <recipe>` - runs a recipe from the branch justfile
3. `git just <recipe> <args...>` - runs a recipe with arguments

When starting work on a task:
- Check if a branch justfile exists: `ls .<branch>.just`
- If it exists, review its recipes: `just -f .<branch>.just --list`
- If it doesn't exist, create it and add recipes for the task

### Under the hood

`git just` resolves the justfile path as:

```
branch=$(git rev-parse --abbrev-ref HEAD)
branch=$(echo "$branch" | tr '[:upper:]' '[:lower:]')
branch=$(echo "$branch" | sed -E 's/[^a-zA-Z0-9-]+/-/g')
branch=$(echo "$branch" | sed -E 's/^-+//g')
branch=$(echo "$branch" | sed -E 's/-+$//g')
justfile=.$branch.just
```

Then runs: `just -f "$justfile" "$@"`

## Global Justfile

If a `justfile` or `Justfile` exists in the project root, it contains shared recipes available across all branches.

- List recipes: `just --list`
- Run a recipe: `just <recipe>`
- Run with args: `just <recipe> <args...>`

## When to Use

- Prefer `just` recipes over manual commands when a recipe exists
- For branch-specific work, use `git just` (which runs `just -f .<branch>.just`)
- For shared/project-wide tasks, use the global justfile
- When asked to "run tests", "build", "deploy", etc. - check justfiles first before running raw commands

## Discovery

Before running tasks, discover what's available:

```bash
just --list                           # global recipes
just -f .<branch>.just --list         # branch recipes
```

## Conventions

- Branch justfiles are gitignored (they are local working files)
- Put shared recipes in the global justfile; branch-specific ones in branch justfiles
- Recipes should be idempotent where possible
