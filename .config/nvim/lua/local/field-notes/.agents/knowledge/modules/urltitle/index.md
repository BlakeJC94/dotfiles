# URL Title Module — `lua/field-notes/urltitle.lua`

Turns a bare web URL under the cursor into a markdown link whose text is the fetched page `<title>`. It is the web counterpart to `:NoteLink` / `link.lua`, which link to notes.

Unlike other modules, it registers no user command. The single public function `M.url_title` is re-exported from `init.lua` so a consumer config can bind it:

```lua
vim.keymap.set("n", "gX", require("field-notes").url_title, { desc = "Fetch URL title" })
```

---

## Public API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `M.url_title` | `M.url_title()` | Replace the `http(s)://` URL under the cursor with `[page title](url)` |

---

## Flow (`url_title`)

```
gX (cursor on a URL)
  │
  ├─ url = expand("<cfile>")          -- URL under cursor
  │   └─ strip trailing punctuation: . , ; : ! ? ) ] } > " '
  │   └─ require ^https?://            → notify + abort otherwise
  │
  ├─ find_url_range(line, url, col)    -- exact byte range at/after cursor
  │   └─ notify + abort if not found
  │
  ├─ set extmark at URL start (ns "field-notes.url-title")
  │   └─ tracks position across unrelated buffer edits
  │
  ├─ curl(url, callback)               -- async
  │   curl -sL --max-time 15 -A "Mozilla/5.0" <url>
  │   vim.system(...) when available, else vim.fn.system fallback
  │
  └─ vim.schedule(...)  -- back on the main loop
      ├─ buffer still valid?              else silent abort
      ├─ exit code == 0?                  else notify error
      ├─ extract_title(body)             else notify "no title"
      ├─ extmark still exists?           else notify "URL moved"
      ├─ text at extmark still == url?   else notify "URL changed"
      └─ nvim_buf_set_text("[title](url)")
          └─ del extmark, notify title
```

---

## URL Detection & Range Finding

`vim.fn.expand("<cfile>")` returns the "file" (including URLs) under the cursor, but can absorb surrounding punctuation — notably the closing paren of a markdown link or a trailing sentence period. These are stripped:

```lua
url:gsub("[%.,;:!?%)%]}>\"']+$", "")
```

`find_url_range` then locates that string in the current line. Because the same URL may appear more than once, it walks every occurrence and returns the one whose byte range contains the cursor column; if none contains it, it falls back to the first occurrence.

---

## Title Extraction & Entity Decoding

`extract_title` matches the first `<title>…</title>` case-insensitively, collapses runs of whitespace to single spaces, trims, and returns `nil` for an empty/missing title.

`decode_entities` resolves the HTML entities that commonly appear in titles:

- Named entities from a small table (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, `&apos;`, `&nbsp;`)
- Decimal numeric entities `&#NNN;` via `vim.fn.nr2char(tonumber(...))`
- Hex numeric entities `&#xHH;` via `vim.fn.nr2char(tonumber(..., 16))`

Unknown named entities are left as-is.

---

## Async Fetch

The fetch uses `curl` rather than a Lua HTTP client. When `vim.system` exists (Neovim 0.10+) the process runs asynchronously and its result is delivered to a callback; on older versions it falls back to synchronous `vim.fn.system`. The callback always reschedules onto the main loop with `vim.schedule` before touching the buffer, since `vim.system` callbacks run in a fast event context.

---

## Safe Replacement

Two guards prevent clobbering the wrong text if the buffer changes while the request is in flight:

1. The URL's start is marked with an **extmark**, so edits above the line shift the mark rather than invalidating it.
2. Before replacing, the module re-reads the line and verifies the bytes at the extmark still equal the original URL.

If either check fails the buffer is left untouched and a warning is shown. A missing title or a failed fetch also leaves the URL unchanged.

---

## Behavior Summary

| Situation | Result |
|-----------|--------|
| Cursor on `http(s)://` URL | Replaced with `[title](url)` |
| Cursor not on a URL | Warn `gX: no URL under cursor` |
| `curl` non-zero exit | Warn `gX: curl failed for <url>` |
| No/empty `<title>` | Warn `gX: no title found for <url>` |
| Buffer/URL changed mid-flight | Warn, no edit |

---

## Integration Points

| Component | Role |
|-----------|------|
| `init.lua` | Re-exports `M.url_title` for consumer keymaps |
| Consumer config (`lua/plugins/field_notes.lua`) | Binds `gX` to `require("field-notes.urltitle").url_title` |
| `curl` | External dependency used to fetch page HTML |
