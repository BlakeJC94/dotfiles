# mac-system-theme extension

Syncs pi theme with macOS system appearance (dark/light mode).

- Location: `~/.pi/agent/extensions/mac-system-theme.ts`
- Configures: `gruvbox-dark` / `gruvbox-light` (edit the `darkTheme` / `lightTheme` consts to change)

## Usage

Place in `~/.pi/agent/extensions/` for auto-discovery and `/reload` support.

## Bugs fixed

### 1. Orphaned polling interval on `/reload`

**Symptom:** After `/reload`, theme switching becomes erratic or duplicated (two intervals polling macOS appearance and racing).

**Root cause:** The interval ID was stored in a module-scoped `let` variable. When jiti re-evaluates the module on `/reload`, that variable is reset to `null` in the fresh module scope. But the original `setInterval` — held in the old module's closure — keeps running. The new module's `session_shutdown` handler sees `null` and never calls `clearInterval`, while `session_start` registers a *second* interval. Now two intervals poll `osascript` every 2s and fight over `ctx.ui.setTheme()`.

**Fix:** Store the interval ID in `globalThis.__pi_mac_theme_sync_interval` so it survives module reload. The factory function proactively clears any orphaned interval at the top before registering handlers. Both `session_shutdown` (safety net) and the factory cleanup drain from the same `globalThis` slot.

### 2. Partial theme application on `/reload` / `/resume`

**Symptom:** On a fresh start the theme is fully correct. After `/reload` or `/resume`, the background color is correct but syntax highlighting is wrong (shows the previous theme's colors).

**Root cause:** `ctx.ui.setTheme(themeObj)` applies the theme *in-memory only* to avoid writing `settings.json`. On startup this works because the TUI and editor initialize after the in-memory apply. But on `/reload` and `/resume`, the editor component reinitializes **after** `session_start`, so the in-memory-only apply has already happened and the editor's fresh state misses the syntax styles. The background color sticks because it's set at the TUI container level (which doesn't reinitialize).

**Fix:** The initial theme application in `session_start` uses the **theme name** (`ctx.ui.setTheme("gruvbox-dark")`) instead of the theme object. This writes to `settings.json` and applies to all TUI components fully, including the editor's syntax colors. Subsequent interval-driven changes (when macOS toggles dark/light mode) continue to use the in-memory **object** form to avoid writing `settings.json` on every 2s poll.

```typescript
// session_start: use name for full application (catches editor reinit)
ctx.ui.setTheme(currentTheme);

// interval tick: use object to avoid writing settings.json on every poll
const themeObj = ctx.ui.getTheme(newTheme);
if (themeObj) ctx.ui.setTheme(themeObj);
```

## Lifecycle reference

Relevant event order for `/reload`:

```
/reload
  ├─► session_shutdown { reason: "reload" }
  │     (old extension instance cleans up)
  ├─► module re-evaluated (jiti)
  │     (factory cleanup catches any orphaned interval)
  └─► session_start { reason: "reload" }
        (name-based setTheme for full component coverage)
```

Relevant event order for `/resume`:

```
/resume
  ├─► session_before_switch
  ├─► session_shutdown
  ├─► session_start { reason: "resume" }
  └─► resources_discover
```