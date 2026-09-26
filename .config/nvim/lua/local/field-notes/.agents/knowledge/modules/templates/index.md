# Templates Module — `lua/field-notes/templates.lua`

Handles template directory discovery, template variable rendering with date arithmetic, and template application to new notes.

---

## Template Discovery

### `template_dir()`
Returns the templates directory:
- `field_notes_templates_dir` if configured
- Otherwise `<field_notes_dir>/_templates/`

### `list_templates()`
Scans the template directory with `vim.uv.fs_scandir`, filters for `.md` files, strips extensions, returns sorted stems.

### `template_complete(arg_lead)`
Filters `list_templates()` by prefix match — used for command completion after a quoted note title.

---

## Variable Rendering (`render_variables`)

The template engine supports these variables in both note titles and template bodies:

| Variable | Description | Example Output |
|----------|-------------|---------------|
| `{{title}}` | The note title | `My Note Title` |
| `{{date}}` | Current date (YYYY-MM-DD) | `2025-09-24` |
| `{{week}}` | Week title (Monday-based %W) | `2025-W39: Sep 22` |
| `{{strftime:FORMAT}}` | Arbitrary `os.date` format | `{{strftime:%Y-%m-%d}}` → `2025-09-24` |
| `{{strftime:FORMAT:base+offset}}` | Date arithmetic | `{{strftime:%A:monday+2}}` → `Wednesday` |

### How `{{week}}` Is Computed

```lua
local week_monday = os.time() - ((weekday - 1) * 86400)
-- where weekday = tonumber(os.date("%u", now))  -- Monday=1, Sunday=7
```

The week title format: `YYYY-WW: Mon DD` (e.g. `2025-W39: Sep 22`). Uses Lua's `%W` (week number, Monday-based, first week with at least 1 day in the new year is week 00). This means `W01` is possible, matching ISO-like output for most of the year.

### Date Arithmetic (`{{strftime:fmt:base+offset}}`)

The `base` can be:
- `today` — current date/time
- `monday` — Monday 00:00:00 of the current week

The `offset` is an integer number of days (positive or negative). Examples from the log template:

| Expression | Value (for week of Sep 22 2025) |
|------------|-------------------------------|
| `{{strftime:%A - %b %d:monday+0}}` | `Monday - Sep 22` |
| `{{strftime:%A - %b %d:monday+1}}` | `Tuesday - Sep 23` |
| `{{strftime:%A - %b %d:monday+2}}` | `Wednesday - Sep 24` |
| `{{strftime:%A - %b %d:monday+3}}` | `Thursday - Sep 25` |
| `{{strftime:%A - %b %d:monday+4}}` | `Friday - Sep 26` |
| `{{strftime:%A - %b %d:monday+5}}` | `Saturday - Sep 27` |
| `{{strftime:%A - %b %d:monday+6}}` | `Sunday - Sep 28` |

### Timestamp Context

The renderer accepts an optional `context.reference_timestamp` (Unix time). This is used by the log module to render a *different* week's template (e.g. last week or next week). If not provided, defaults to `os.time()`.

```lua
-- Log module passes:
{
  reference_timestamp = os.time() + (offset * 7 * 86400) - ((weekday - 1) * 86400)
  -- This shifts to the Monday of the target week
}
```

### Substitution Order

Variables are substituted in this exact order:
1. `{{title}}`
2. `{{date}}`
3. `{{week}}`
4. `{{strftime:fmt:base+offset}}` — with date arithmetic
5. `{{strftime:fmt}}` — simple format

The more specific pattern (`strftime:...base+offset`) is matched before the simple one to avoid false positives.

---

## Template Application (`apply_template`)

```lua
M.apply_template(template_name, title, context)
```

1. Reads template file from disk using `vim.uv.fs_open` / `fs_read` / `fs_close`
2. Renders variables with `render_variables(content, title, context)`
3. Splits the result into lines (`vim.split(content, "\n")`)
4. Returns the lines array (or `nil` if template file not found)

The caller (`notes.open_note`) sets these lines into the new buffer.

---

## Default Template

`_templates/log.md` (in the notes' `_templates` directory) is the template used by `:Log` commands. It includes:

- `# {{week}}` heading
- **Quests** section (Main / Side / Misc)
- **Log** section with 7 daily blocks (`monday+0` through `monday+4` for weekdays)
- Each day has Morning / Afternoon sections with checkboxes `1. [ ] ...`
- **Notes** section at the bottom
- Scheduled times like `1300--1400`, `1400--1430 Greg sync`, `1500--1530 Week planning`

This is a *default* template explicitly named `log` — the `:Log` command passes `template_name = "log"` to `open_note`.