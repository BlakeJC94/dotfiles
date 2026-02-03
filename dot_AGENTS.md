# Project conventions

> **purpose** – This file is the onboarding manual for every human and every AI
> assistant (Claude, Cursor, GPT, Aider, etc.) who edits this repository. It
> encodes our coding standards, guard-rails, and workflow tricks so the *human
> 30 %* (architecture, tests, domain judgment) stays in human hands.

______________________________________________________________________

**Golden rule**: When unsure about implementation details or requirements,
ALWAYS consult the developer rather than making assumptions.

## What AI Must NEVER Do

1. **Never modify test files** - Always get human approval with the intended
   changes to test cases
2. **Never change API contracts** - Breaks real applications
3. **Never add dependencies** - Always ask
4. **Never refactor large modules without guidance** - Always plan and ask
5. **Never assume business logic** - Always ask
6. **Never stray from the current task** - Inform the dev if it'd be better to
   start afresh.
7. **Never remove AIDEV- comments** - They're there for a reason

Remember: We optimize for maintainability over cleverness. When in doubt,
choose the boring solution.


## Anchor comments

Add specially formatted comments throughout the codebase, where appropriate,
for yourself as inline knowledge that can be easily `grep`ped for.

### Guidelines:

- Use `AIDEV-NOTE:`, `AIDEV-TODO:`, or `AIDEV-QUESTION:` (all-caps prefix) for
  comments aimed at AI and developers.
- Keep them concise (≤ 120 chars).
- **Important:** Before scanning files, always first try to **locate existing
  anchors** `AIDEV-*` in relevant subdirectories.
- **Update relevant anchors** when modifying associated code.
- Make sure to add relevant anchor comments, whenever a file or piece of code
  is:
  - too long, or
  - too complex, or
  - very important, or
  - confusing, or
  - could have a bug unrelated to the task you are currently working on.

Example:

```python
# AIDEV-NOTE: perf-hot-path; avoid extra allocations
async def render_feed(...):
    ...
```
