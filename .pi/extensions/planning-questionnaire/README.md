# pi-planning-questionnaire

A [pi](https://pi.dev) extension that helps an agent gather multiple clarifying
answers in a single interactive widget, plus a `/clarify` command that drives a
read-only planning phase around it.

## What it adds

### `planning_questionnaire` tool

An interactive tool the agent calls to ask a **batch** of clarifying questions in
one widget instead of one question per turn. Each question supports:

- Multiple-choice options (single or multi-select)
- An optional free-form "Type something." answer
- A final confirm screen reviewing every answer before returning

The tool returns a structured summary of answers to the agent, or a cancelled
result if the user presses `Esc`.

### `/clarify` command

Kicks off a read-only planning phase: it sends the agent a prompt to generate
3–6 context-aware clarifying questions and call `planning_questionnaire`.
While the phase is active, mutating tools (`edit`, `write`, `bash`) are blocked
until the agent settles, and a `clarify: read-only` status is shown. This keeps
planning strictly read-only.

## Install

```bash
pi install npm:pi-planning-questionnaire
# or from git
pi install git:github.com/<owner>/pi-planning-questionnaire
```

Or drop this directory under `~/.pi/agent/extensions/planning-questionnaire/`
for auto-discovery (hot-reloadable with `/reload`).

## Usage

Ask the agent to clarify before planning:

```
/clarify
```

The agent will call `planning_questionnaire` automatically. You can also ask
it directly ("ask me clarifying questions before planning") and it will use the
tool.

### Keybindings (question screen)

| Key | Action |
| --- | --- |
| `Up` / `Down` | Navigate options |
| `Enter` | Select (single) / continue (multi) |
| `Space` | Toggle option (multi-select) |
| `Left` / `Shift+Tab` | Previous question |
| `Right` / `Tab` | Next (single-select once answered) |
| `Esc` | Cancel the whole questionnaire |

### Confirm screen

| Key | Action |
| --- | --- |
| `Enter` | Submit answers |
| `Shift+Tab` | Edit previous question |
| `Esc` | Cancel |

## Testing

The suite uses Node's built-in test runner and assert — no test dependencies.
After installing peer packages (`npm install` resolves the `peerDependencies`),
run:

```bash
npm test
# equivalently:
node --test --experimental-strip-types tests/*.test.ts
```

Node >= 22.6 is required (for built-in TypeScript type stripping).

Coverage:

| Suite | Covers |
| --- | --- |
| `tests/types.test.ts` | `questionOptions`, `hasCustomOption`, `answerGroups` |
| `tests/session.test.ts` | `messageText` over message shapes |
| `tests/clarify.test.ts` | `/clarify` command + the read-only `tool_call` / `agent_settled` guards |
| `tests/tool.test.ts` | `planning_questionnaire` execute paths + `renderCall` / `renderResult` |
| `tests/ui.test.ts` | `QuestionnaireComponent` render output + keyboard navigation/toggle/submit/cancel |

The tests use lightweight fakes (see `tests/helpers.ts`) so the real pi runtime
is never loaded.

## Files

| File | Responsibility |
| --- | --- |
| `index.ts` | Extension entry; wires the tool and command together |
| `tool.ts` | `planning_questionnaire` tool registration + renderers |
| `ui.ts` | Interactive `QuestionnaireComponent` (TUI state machine) |
| `clarify.ts` | `/clarify` command + read-only planning guards |
| `session.ts` | `messageText` helper for reading session context |
| `types.ts` | Schemas, domain types, constants, pure helpers |

## License

MIT
