# Todo Extension

Demonstrates state management via session entries by providing a persistent todo list that correctly branches with session history.

## Files

- `todo.ts` — Extension source

## What it does

Registers a `todo` tool (for the LLM) and a `/todos` command (for the user) to manage a todo list. Todos are stored in tool result **details** rather than external files, which means branching "just works" — when you branch from a point in history, the todo state is automatically correct for that branch.

## LLM Tool: `todo`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action` | `"list" \| "add" \| "toggle" \| "clear"` | Yes | The operation to perform |
| `text` | `string` | For `add` | Todo text to add |
| `id` | `number` | For `toggle` | Todo ID to toggle |

### Actions

| Action | Behavior |
|--------|----------|
| `list` | Returns all todos as `[x] #1: text` lines |
| `add` | Adds a new todo with auto-incrementing ID |
| `toggle` | Toggles the `done` status of a todo by ID |
| `clear` | Removes all todos and resets the ID counter |

### Result details

Each tool result stores the full state (`todos` array + `nextId`) in `details`. This is what enables branch-aware state reconstruction.

## User Command: `/todos`

Opens a custom TUI component (`TodoListComponent`) that renders todos in a styled bordered panel with:
- A header showing `Todos`
- Completion status (`3/5 completed`)
- Checkmarks (✓) for done items, circles (○) for pending
- Color-coded IDs and text
- Press Escape to close

Only works in TUI mode.

## State Management Strategy

Instead of reading/writing a file, state is **reconstructed from session history** every time a session starts or the session tree changes:

```typescript
const reconstructState = (ctx: ExtensionContext) => {
  todos = [];
  nextId = 1;
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "message" || entry.message.role !== "toolResult") continue;
    if (entry.message.toolName !== "todo") continue;
    const details = entry.message.details as TodoDetails;
    if (details) {
      todos = details.todos;
      nextId = details.nextId;
    }
  }
};
```

This makes the todo list naturally branch-aware — no file I/O, no merge conflicts.

## Events Consumed

| Event | Effect |
|-------|--------|
| `session_start` | Reconstructs state from current branch |
| `session_tree` | Reconstructs state after tree changes |

## Rendering

Both the tool call and tool result in the conversation UI are custom-rendered:

- **`renderCall`** — Compact single-line: `todo add "Buy milk" #5`
- **`renderResult`** — Shows checkmarks, IDs, colors. Collapsed view shows up to 5 items with `... N more` overflow.

## API Surface Used

- `pi.registerTool()` — registers the todo LLM tool with parameter schemas via `TypeBox`
- `pi.on("session_start" / "session_tree", ...)` — reconstructs state on session events
- `ctx.sessionManager.getBranch()` — iterates session history
- `ctx.ui.custom()` — renders the `/todos` TUI component
- `ctx.ui.notify()` — errors and status messages
- `ctx.ui.select()` — _(not used but available for future extension)_

## Dependencies

- `@earendil-works/pi-ai` (`StringEnum`)
- `@earendil-works/pi-coding-agent` (types: `ExtensionAPI`, `ExtensionContext`, `Theme`)
- `@earendil-works/pi-tui` (`matchesKey`, `Text`, `truncateToWidth`)
- `typebox` (parameter schema validation)