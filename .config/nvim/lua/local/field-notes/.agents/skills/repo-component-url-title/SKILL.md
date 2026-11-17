---
name: repo-component-url-title
description: Change the URL-under-cursor title fetch and Markdown replacement in field-notes.nvim. Use for `lua/field-notes/urltitle.lua` or the exported `url_title` integration.
---

# URL title conversion

## Responsibility

`lua/field-notes/urltitle.lua` implements the `url_title` function exposed by `init.lua`. It fetches a web page title and replaces the URL under the cursor with `[title](url)`.

## Current behavior

- The URL is read from `<cfile>`, trailing punctuation is stripped, and only `http://` or `https://` URLs are accepted.
- The module runs `curl -sL --max-time 15 -A Mozilla/5.0 <url>`. It uses `vim.system` asynchronously when available and a synchronous `vim.fn.system` fallback otherwise.
- It extracts and whitespace-normalizes the HTML `<title>`, then decodes common named and numeric HTML entities.
- An extmark tracks the URL position while fetching. Before replacing text, the callback verifies that the buffer still exists and the URL text is unchanged. Failures leave the buffer unchanged and notify the user.
- The function is exposed as `require("field-notes").url_title`; the README shows an example key mapping. No user command is registered for it in `init.lua`.

## Relationships

- `init.lua` re-exports the function from this module.
- The external `curl` executable is required for the fetch operation.

## Source of truth

Read `lua/field-notes/urltitle.lua` and the export in `lua/field-notes/init.lua` before changing the fetch or replacement flow.
