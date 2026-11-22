# Nextbit Provider Extension

Registers the [Nextbit](https://api.nextbit256.com/v1) API as a custom provider for pi, making its models available for selection in the model picker.

## Files

- `index.ts` — Extension source

## What it does

Adds the "Nextbit" provider to pi's provider registry. The bundled model snapshot (IDs, context windows, pricing) is registered immediately so startup and `/reload` never block on the network, then `GET /v1/models` refreshes the catalog in the background. If the API is unreachable, the snapshot stays in place.

## Models

The extension registers a bundled snapshot immediately, then discovers models from the API in the background. Known models (with display name mappings) include:

| Model ID | Display Name | Reasoning | Context Window |
|----------|-------------|-----------|----------------|
| `alia-salamandra:40b` | ALIA Salamandra 40B | — | 64K |
| `deepseek:v4.1-flash` | deepseek:v4.1-flash | — | 1M |
| `deepseek:v4-flash-0731` | DeepSeek V4 Flash 0731 | ✅ | 1M |
| `deepseek:v4-pro` | DeepSeek V4 Pro | ✅ | 1M |
| `deepseek:v4-pro-0813` | DeepSeek V4 Pro 0813 | ✅ | 1M |
| `gemma-2:27b-it` | Gemma 2 27B | — | 8K |
| `gemma3:12b-it` | gemma3:12b-it | — | 128K |
| `gemma3:27b` | gemma3:27b | — | 128K |
| `gemma4:26b-a4b` | Gemma 4 26B A4B | — | 256K |
| `gemma4:31b` | gemma4:31b | — | 256K |
| `qwen3:14b` | Qwen3 14B | — | 40K |

## How it works

### Model fetching

1. On load, the extension registers the bundled fallback snapshot synchronously, so startup and `/reload` complete without waiting on the network.
2. It then fetches `GET https://api.nextbit256.com/v1/models` in the background with a 10-second timeout and re-registers the provider with the result. Calls to `pi.registerProvider` after the load phase take effect immediately, so no `/reload` is needed.
3. Each model spec returned by the API is mapped to pi's `ProviderModelConfig` format with:
   - **ID/name** — from API, with known IDs mapped to friendly display names
   - **Reasoning support** — hardcoded set based on empirical testing (the API reports `"reasoning"` in `supported_features` for all models, including non-reasoning ones)
   - **Input modalities** — `["text"]` or `["text", "image"]` based on `architecture.input_modalities`
   - **Context window** / **max tokens** — from API, with output capped at 128K tokens (see caveat below)
   - **Pricing** — per-token prices converted to dollars per million tokens
   - **Compatibility** — `supportsDeveloperRole: false` (API rejects OpenAI's `"developer"` role; use `"system"` instead)
4. If the fetch fails (network error, empty list, HTTP error), or the extension is reloaded before it resolves, the snapshot stays in place.

### Provider registration

Calls `pi.registerProvider("nextbit", ...)` twice: once synchronously with the bundled snapshot, then again in the background with the fetched catalog. Both calls use:

| Field | Value |
|-------|-------|
| `name` | `"Nextbit"` |
| `baseUrl` | `https://api.nextbit256.com/v1` |
| `api` | `"openai-completions"` |
| `models` | Bundled snapshot, then the fetched list once available |

## Auth

```
/login nextbit
```

The API key is stored in `~/.pi/agent/auth.json`.

## Output Token Cap

The gateway rejects requests where `max_completion_tokens` approaches the model's context window (observed: ~9K prompt + 524,288 output rejected, but +262,144 accepted on a 1M-context model). All models are capped at **131,072 max output tokens** to stay well clear of this limit.

## Reasoning Support

Reasoning is determined by an **empirical hardcoded set** (`REASONING_IDS`), not from the API, because the gateway reports `"reasoning"` in `supported_features` for every model — even those without thinking support. Unknown models default to `reasoning: false`.

## Fallback Snapshot

The bundled fallback has 11 models captured on 2026-11-22. It is registered synchronously on load and remains in place if the API is unreachable.

## API Surface Used

- `pi.registerProvider()` — registers the custom provider with name, base URL, API type, and model list

## Dependencies

- `@earendil-works/pi-coding-agent` (types: `ExtensionAPI`)
- Node.js built-in: `fetch` (global) with `AbortSignal.timeout`