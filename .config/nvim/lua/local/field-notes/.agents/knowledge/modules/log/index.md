# Log Module — `lua/field-notes/log.lua`

Handles the weekly log system: `:Log`, `:ThisWeek`, `:NextWeek`, and `:LastWeek` commands. All four commands are thin wrappers around `notes.open_note`, delegating the heavy lifting to the notes and templates modules.

---

## Core Date Math (`:Log [offset]`)

```lua
local offset = tonumber(opts.args) or 0
local timestamp = os.time() + (offset * 7 * 86400) - ((os.date("%u", os.time()) - 1) * 86400)
local title = os.date("%Y-W%W: %b %d", timestamp)
```

This computes the Monday midnight timestamp of the target week in a single expression:

| Step | Expression | Value (example: today=Wed Sep 24) |
|------|-----------|----------------------------------|
| `os.time()` | Current Unix timestamp | `1727146800` |
| `os.date("%u")` | Weekday (Mon=1..Sun=7) | `3` (Wednesday) |
| `((weekday - 1) * 86400)` | Seconds since Monday | `172800` (2 days) |
| `os.time() - ((%u-1)*86400)` | Monday midnight (this week) | `1726974000` |
| `+ (offset * 7 * 86400)` | Shift by offset weeks | +0, +604800, or -604800 |

The result is the **Monday 00:00:00** of the requested week — used both as the reference timestamp for template rendering and to generate the week title.

### Title Format

The week title is computed from the Monday timestamp:

```lua
os.date("%Y-W%W: %b %d", monday_timestamp)
```

| Component | Meaning | Example |
|-----------|---------|---------|
| `%Y` | 4-digit year | `2025` |
| `W` | Literal "W" separator | `W` |
| `%W` | Monday-based week number (00-53) | `39` |
| `: ` | Literal separator | `: ` |
| `%b` | Abbreviated month | `Sep` |
| `%d` | Zero-padded day | `22` |

**Output**: `2025-W39: Sep 22`

The title is passed to `open_note` as-is (no prefix). The **filename is determined by the template's `# heading`**, not the title directly. See [Filename from Template Heading](#filename-from-template-heading) below.

> **Note on `%W`**: Week 01 is the first week with at least 4 days in the new year? No — `%W` is the first week with at least 1 day. So `W00` can appear for early January days before the first Monday. `W01` starts on the first Monday of the year. This is *not* ISO 8601 (`%V` would be ISO), but uses Lua's native `%W` specifier.

### Offset Behavior

| Command | Offset | Computed Week |
|---------|--------|--------------|
| `:Log 0` / `:ThisWeek` | 0 | Current week |
| `:Log 1` / `:NextWeek` | 1 | Next week |
| `:Log -1` / `:LastWeek` | -1 | Previous week |
| `:Log 2` | 2 | Two weeks from now |

Omitting the argument ( `:Log` ) defaults to offset `0` (this week).

---

## Command Implementation Details

### `:Log` — The Core Command

```lua
nargs = "?", bang = true
```

- **nargs `?`**: accepts 0 or 1 argument (the offset)
- **bang `true`**: `:Log!` passes the bang to `notes.open_note`, which inserts a link at cursor before opening

Delegates to:
```lua
notes.open_note(bang, string.format("%q log", title), {
    require_quoted_arg = true,
    template_context = { reference_timestamp = timestamp },
})
```

Key details:
- The args passed to `open_note` are `"<title> log"` — the `%q` quoting means the title is double-quoted, followed by the literal word `log` as the template name
- `require_quoted_arg = true` ensures `open_note` parses this as a quoted title + template name
- `template_context.reference_timestamp` is set to the **Monday midnight** of the target week — this is consumed by `templates.render_variables` so that `{{date}}`, `{{week}}`, and `{{strftime}}` all render relative to the *target* week, not the current date
- The **title no longer includes a `"Log: "` prefix** — the template's heading controls the filename (see below)

### `:Journal` — The Companion Command

Identical structure to `:Log`, except:
- Uses template name `"journal"` (configurable via `default_template_journal`)
- Intended for a separate template that provides its own heading (e.g. `# Journal: {{week}}`)

```lua
notes.open_note(bang, string.format("%q journal", title), {
    require_quoted_arg = true,
    template_context = { reference_timestamp = timestamp },
})
```

### Filename from Template Heading

When `open_note` receives a template, it **pre-renders** the template and extracts the first `# heading` to use as the title for slugification. This means the filename always matches what the note says at the top.

| Template heading | Rendered | Filename |
|-----------------|----------|----------|
| `# {{week}}` (log) | `# 2025-W39: Sep 22` | `2025-w39-sep-22.md` |
| `# Journal: {{week}}` (journal) | `# Journal: 2025-W39: Sep 22` | `journal-2025-w39-sep-22.md` |

The pre-rendered lines are cached and reused when populating the new buffer — no double rendering.

### Aliases

| Command | Expands To | Bang Pass-through |
|---------|-----------|-------------------|
| `:ThisWeek` | `:Log 0` | Yes |
| `:NextWeek` | `:Log 1` | Yes |
| `:LastWeek` | `:Log -1` | Yes |

Each alias is a full user command (not a `cabbrev`), properly passing the bang through:

```lua
vim.cmd((opts.bang and "Log!" or "Log") .. " 0")
```

This means `:ThisWeek!` correctly expands to `:Log! 0`, which inserts a link at cursor before opening this week's log.

---

## Template Integration

### Default Template

The log commands always pass `"log"` as the template name. The template file is expected at:

```
<field_notes_dir>/_templates/log.md
```

If the file already exists for the target week, the template is silently discarded (no overwrite). This behavior comes from `notes.open_note`:

```lua
if template_name and (note_exists_on_disk or note_buffer_exists) then
    template_name = nil
end
```

### Template Context Injection

The `reference_timestamp` in `template_context` is the key integration point. It ensures all template variables render *as if* the current date were the Monday of the target week.

For `{{strftime:%A:monday+2}}` in a log template:
- If viewing this week (offset 0): renders Wednesday of the current week
- If viewing next week (offset 1): renders Wednesday of next week
- If viewing last week (offset -1): renders Wednesday of last week

This works because `render_variables` uses `context.reference_timestamp` instead of `os.time()` when present:

```lua
local function resolve_now(context)
    return (context and context.reference_timestamp) or os.time()
end
```

And `resolve_base_timestamp("monday", context)` always snaps to the Monday of that reference timestamp.

---

## Data Flow Summary

```
:Log 1  (next week)
  │
  ├─ Compute Monday of next week: os.time() + 604800 - ((%u-1)*86400)
  ├─ Build title: os.date("%Y-W%W: %b %d", monday)  →  "2025-W40: Sep 29"
  │
  └─ notes.open_note(bang, '"2025-W40: Sep 29" log', {
        require_quoted_arg = true,
        template_context = { reference_timestamp = monday_midnight }
      })
        │
        ├─ Parse args: title="2025-W40: Sep 29", template_name="log"
        │
        ├─ Pre-render template "log":
        │   apply_template("log", "2025-W40: Sep 29", ctx)
        │     └─ render_variables:
        │        # {{week}} → # 2025-W40: Sep 29
        │        {{strftime:%A - %b %d:monday+1}} → Tuesday - Sep 30
        │   Extract # heading: "2025-W40: Sep 29" → title
        │
        ├─ If bang: link.link_note(title)
        ├─ Slugify → "2025-w40-sep-29.md"
        ├─ Build path → <field_notes_dir>/2025-w40-sep-29.md
        ├─ Check existence
        └─ If new: set buffer to cached template_lines
```

---

## Commands Registered

| Command | Args | Bang | Implementation |
|---------|------|------|---------------|
| `:Log [offset]` | 0-1 (number) | Yes | Core: computes Monday timestamp, delegates to `open_note` with template `log` |
| `:Journal [offset]` | 0-1 (number) | Yes | Same as `:Log` but uses template `journal` (or `default_template_journal`) |
| `:ThisWeek` | 0 | Yes | Expands to `Log 0` |
| `:NextWeek` | 0 | Yes | Expands to `Log 1` |
| `:LastWeek` | 0 | Yes | Expands to `Log -1` |

All commands are registered in `M.setup()` which is called from `init.lua`'s `setup()`.