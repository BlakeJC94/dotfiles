# Web Search Extension

Provides web search and page-fetching capabilities using DuckDuckGo's HTML endpoint — no API key required.

## Files

- `web-search.ts` — Extension source

## What it does

Registers three LLM tools (`web_search`, `web_fetch`, `web_research`) and one user command (`/websearch`) for querying the web and extracting content from pages.

## LLM Tools

### `web_search`

Search DuckDuckGo and return results with titles, snippets, and URLs.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | `string` | — | Search query |
| `maxResults` | `integer` | `5` | Max results (1–10) |

Returns structured results with individual title/snippet/URL per item.

### `web_fetch`

Fetch a URL and extract clean text content. Strips HTML, scripts, styles, and decodes entities.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | `string` | — | URL to fetch |
| `maxLength` | `integer` | `15000` | Max characters (1000–50000) |

Handles:
- **HTML pages** — title extraction + text stripping
- **JSON responses** — pretty-printed output
- **Plain text** — direct return
- **Redirects** — followed automatically

### `web_research`

Combined research: search DuckDuckGo, then fetch and extract full text from the top results.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | `string` | — | Research query |
| `depth` | `integer` | `3` | Number of results to fully fetch (1–5) |
| `maxSearchResults` | `integer` | `8` | Number of search results to list (1–10) |

Returns a markdown-style report with search results list, fetched content summaries, and any fetch errors.

## User Command

| Command | Args | Description |
|---------|------|-------------|
| `/websearch` | `<query>` | Quick DuckDuckGo search, displays top 5 results inline |

## Security & Safety

| Measure | Detail |
|---------|--------|
| **URL validation** | Only `http:` and `https:` protocols allowed |
| **Content size limits** | 50KB per fetch, 100KB per search results page |
| **Text truncation** | Extracted text capped at 30K characters |
| **No JS execution** | Pure HTTP fetch with no browser/JS engine |
| **Timeout protection** | Fetches: 15s, Searches: 10s |
| **Prompt injection** | Handled externally by a separate `injection-guard` extension via `tool_call` / `tool_result` lifecycle events |

## HTML Parsing

The extension uses a custom `htmlToText()` function (no external HTML parser dependency):

1. Strips `<script>` and `<style>` blocks
2. Converts block-level tags → newlines
3. Converts inline tags → spaces
4. Strips remaining tags
5. Decodes common HTML entities (`&amp;`, `&lt;`, etc.)
6. Collapses whitespace

DuckDuckGo results are parsed with two strategies:
- **Primary**: extract `<div class="result results_links results_links_deep">` blocks
- **Fallback**: scan for `rel="nofollow"` links when primary parser yields no results

## API Surface Used

- `pi.registerTool()` — registers the three web tools with TypeBox parameter schemas
- `pi.registerCommand()` — registers `/websearch`
- `ctx.ui.setStatus()` — shows a search indicator
- `ctx.ui.notify()` — displays results or errors

## Dependencies

- `@earendil-works/pi-coding-agent` (types: `ExtensionAPI`)
- `typebox` (parameter schema validation — `Type`, `Static`)
- Node.js built-in: `fetch` (global), `URL`, `AbortSignal.timeout`