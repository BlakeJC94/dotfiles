# Herdr Agent State Extension

Reports pi's agent lifecycle state (idle / working / blocked) to a parent [Herdr](https://github.com/earendil-works/herdr) terminal multiplexer process over a Unix socket.

## Files

- `herdr-agent-state.ts` — Extension source (auto-generated, managed by Herdr)

## What it does

This extension establishes a bidirectional communication channel between pi and Herdr. It reports pi's current agent state so that Herdr can display status indicators (e.g., a spinner when working, a warning when blocked) in the terminal UI.

## How it works

### State machine

The extension tracks two independent signals and derives a single desired state:

| blockedCount > 0 | agentActive | Resulting State |
|-----------------|-------------|-----------------|
| No              | No          | `idle`          |
| No              | Yes         | `working`       |
| Yes             | —           | `blocked`       |

- **blocked** is set/cleared via the `herdr:blocked` event (fired by a custom tool, extension, or frontend when the agent is waiting on user input or an external process).
- **working** is set when `agent_start` fires and cleared when `agent_settled` fires and the context reports idle.

### Communication protocol

Messages are JSON over a Unix socket (`net.createConnection`) to the path in `HERDR_SOCKET_PATH`.

Two request methods:

| Method | Purpose |
|--------|---------|
| `pane.report_agent` | Reports current agent state + session reference |
| `pane.report_agent_session` | Reports session metadata (id/path + start reason) |

Each message includes `pane_id`, `source: "herdr:pi"`, `agent: "pi"`, `state`, a monotonically increasing `seq` number, and optional `message` text.

### Delivery guarantees

- **Retry** — each send attempts delivery twice (500ms + 1500ms timeouts).
- **Queueing** — rapid state changes are coalesced via a single-item queue to avoid flooding the socket.
- **Debouncing** — duplicate states are suppressed (no re-send if the state + message hasn't changed).

### Session linking

On `session_start` (TUI mode only), the extension captures the session file path or session ID from the context's `sessionManager` and includes it in all subsequent messages. This lets Herdr associate agent reports with specific sessions.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `HERDR_ENV=1` | Enables the extension |
| `HERDR_SOCKET_PATH` | Unix socket path for communication |
| `HERDR_PANE_ID` | Identifies which Herdr pane this agent runs in |

The extension is a no-op if any of these are missing.

## Events Consumed

| Event | Effect |
|-------|--------|
| `herdr:blocked` | Increments/decrements blocked counter |
| `session_start` | Captures session ref, reports session, initializes state |
| `agent_start` | Sets `agentActive = true`, re-reports session if possible |
| `agent_settled` | Sets `agentActive = false` if context is idle |

## Constraints

- Only activates in **TUI mode** (`ctx.mode === "tui"`). RPC/JSON/print modes have no PTY for Herdr to display.
- Only the **root session** (first `session_start` in TUI) drives state reporting to avoid duplicate messages from branched sessions.
- This file is **managed by Herdr** — manual edits will be overwritten on reinstalls. Place custom hooks in sibling files.