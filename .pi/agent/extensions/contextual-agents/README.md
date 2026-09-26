# Contextual Agents Extension

Automatically discovers and injects path-scoped context files (like `AGENTS.md` and `CLAUDE.md`) into the system prompt whenever the agent reads, edits, or writes a file — making context aware of which directory a file lives in.

## Files

- `index.ts` — Extension source

## What it does

When you place `AGENTS.md` or `CLAUDE.md` files throughout your repository, this extension watches which files the agent touches (via `read`, `edit`, `write` tools) and injects the relevant context files from ancestor directories into the system prompt. This means instructions in a `src/api/AGENTS.md` will automatically be included when the agent works on files under `src/api/`.

## How it works

### Scanning

On every `tool_call` to `read`, `edit`, or `write`, the extension:

1. Resolves the target file/directory path to an absolute path.
2. Walks the directory chain from the repo root down to the target's parent directory.
3. For each directory in the chain, checks for `AGENTS.md` and `CLAUDE.md`.
4. If found and not already part of the repo-root defaults or already discovered, adds them to a discovered set.

### Discovery vs. defaults

- **Default context files** — `AGENTS.md` / `CLAUDE.md` files found by walking *upward* from `process.cwd()` at startup. These are always present and are **not** re-discovered.
- **Discovered context files** — found later by walking *downward* from the repo root toward the target path. These are injected into the system prompt via `before_agent_start`.

### Injection

On `before_agent_start`, if any path-scoped files were discovered, the extension appends a block to the system prompt listing each file's path and its markdown content:

```
Additional path-scoped context files discovered during this session:

Path: /repo/src/api/AGENTS.md
\`\`\`markdown
...content...
\`\`\`
```

### Deduplication

- `checkedDirs` set ensures each directory is scanned only once per session.
- `discoveredFileSet` prevents re-adding the same file.
- Default context files are excluded from discovery (they're already injected by other means).

## Events Consumed

| Event | Effect |
|-------|--------|
| `tool_call` | Triggers path scanning when tool is `read`, `edit`, or `write` |
| `before_agent_start` | Injects discovered context into the system prompt |

## Events Produced

None directly — the extension returns a `systemPrompt` override from `before_agent_start`.

## Configuration

| Constant | Value | Description |
|----------|-------|-------------|
| `CONTEXT_FILENAMES` | `["AGENTS.md", "CLAUDE.md"]` | Filenames recognized as context files |
| `PATH_TOOLS` | `new Set(["read", "edit", "write"])` | Tools that trigger path scanning |

## Constraints

- Only activates within a **git repository** (checks for `.git` directory).
- Scanning is bounded by the repo root — files outside the repo are ignored.
- Each directory is scanned **once per session** to minimize filesystem overhead.

## API Surface Used

- `pi.on("tool_call", ...)` — intercepts file-access tool calls
- `pi.on("before_agent_start", ...)` — injects context into the system prompt
- `event.toolName` / `event.input.path` — reads the tool call parameters
- `ctx.cwd` — resolves relative paths

## Dependencies

- `@earendil-works/pi-coding-agent` (types: `ExtensionAPI`)
- Node.js built-ins: `node:fs`, `node:path`