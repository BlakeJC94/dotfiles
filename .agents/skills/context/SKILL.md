---
name: context
description: Load the current branch PLAN and its explicitly linked related plans when the user invokes /skill:context. Use only when explicitly invoked.
---

# Plan Context

Load the plan context only for this request. Do not automatically inspect or load PLAN files in other work.

1. Run `git plan` from the project root to obtain the current PLAN path.
2. If no readable PLAN is available, state that concisely and stop.
3. Read the current PLAN first.
4. Read every local Markdown document linked under the current PLAN's `## Related plans` heading, in listed order.
   - This heading must appear near the top of the PLAN.
   - Do not infer relationships from branch names or filenames.
   - Do not read linked documents outside this section.
   - If a listed local document is unreadable, state that concisely and continue with the readable plans.
5. Treat the loaded content as the source of truth for the current work.

Plan headings:

- `## Related plans` lists local Markdown links to plans that `/skill:context` must load after the current PLAN.
- `## Context` is append-only project context.
- `## TODO` is the developer's personal TODO list. Do not edit it.
- `## Agent notes` is the only section agents may edit. Re-read it after the developer says it changed.
