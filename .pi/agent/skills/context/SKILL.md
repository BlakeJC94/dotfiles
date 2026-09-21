---
name: context
description: Load the current branch PLAN and its ancestor plans when the user invokes /skill:context. Use only when explicitly invoked.
---

# Plan Context

Load the plan context only for this request. Do not automatically inspect or load PLAN files in other work.

1. Run `git plan` from the project root to obtain the current PLAN path.
2. If no readable PLAN is available, state that concisely and stop.
3. Read the current PLAN and its existing ancestor plans, ordered from oldest ancestor to current.
   - Plans are named `<repository>-<full-branch-name>.<extension>`.
   - An ancestor has the same repository prefix and a hyphen-prefix of the current branch name.
   - Do not read descendant plans. List their paths when relevant.
4. Treat the loaded content as the source of truth for the current work.

Plan headings:

- `## Context` is append-only project context.
- `## TODO` is the developer's personal TODO list. Do not edit it.
- `## Agent notes` is the only section agents may edit. Re-read it after the developer says it changed.

If the project has a `justfile`, use `git just` for its documented operations.
