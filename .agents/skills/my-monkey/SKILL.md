---
name: my-monkey
description: Probe code for likely bugs and uncovered edge cases without changing code or tests. Use when asked to try to break an implementation, stress its assumptions, or find and verify missed failure paths.
---

# My monkey

Find plausible correctness issues, then try to reproduce them. This is a focused adversarial investigation, not a style review or an implementation task.

## Scope and safety

- Work in the current worktree. Use the files, diff, feature, or behavior named by the user; if none is clear, ask for a target before probing.
- Do not edit or create files, including tests, reports, fixtures, or snapshots. Do not install dependencies, change branches, or run commands that modify the repository. Leave code and tests untouched even when a fix seems obvious.
- Run only targeted, non-destructive checks in a local or isolated environment. Do not exercise production services, send real requests, use live credentials, delete data, or trigger expensive jobs. If verification requires one of these, stop and ask; otherwise report the limitation.
- Follow repository instructions and existing test conventions. If a test command would update snapshots or files, do not run it.

## Investigation

1. Read the relevant implementation, its callers, contracts, and nearby tests. Identify intended behavior before claiming a violation. Do not infer coverage from test names alone; inspect assertions.
2. Map the risky paths: empty and malformed inputs, boundaries, ordering, duplicate operations, state transitions, failures and retries, concurrency, and interactions with external systems. Focus on cases reachable in this code and likely to matter, not a generic checklist.
3. Form a small number of concrete hypotheses. For each, trace the path through the code and check whether a test actually covers it.
4. Try to falsify the strongest hypotheses using existing targeted tests or safe, read-only invocations. Record the exact command, input, result, and relevant environment. A failed test is evidence only after checking whether it fails for the suspected reason. Do not claim a reproduction from static reasoning alone.
5. Report only actionable findings. Separate reproduced failures from plausible, unverified risks; state why verification was not possible. Do not call a case "uncovered" unless the relevant tests were inspected; otherwise say coverage is unknown.

## Output

- List findings by impact. For each: severity, file and line, triggering case, expected versus observed behavior (or the precise predicted failure), evidence or reproduction steps, coverage gap, and the smallest suggested fix or test to consider. Suggest tests for meaningful behavior states, not coverage percentages; each suggested case should read simply as setup, action, and observable outcome. Suggestions are for the developer to implement, not changes to make.
- State which checks ran and their results, plus any verification limits. If no credible issue remains, say so; do not invent findings.
- Return findings in chat only. Do not write an artifact or modify the worktree.
