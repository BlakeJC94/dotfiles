# Nextbit Provider Extension

Registers the [Nextbit](https://api.nextbit256.com/v1) API as a custom provider for pi, making its models available for selection in the model picker.

## Files

- `index.ts` — Extension source

## What it does

Adds the "Nextbit" provider to pi's provider registry. Model data (IDs, context windows, pricing) is fetched dynamically from `GET /v1/models` on startup. If the API is unreachable, a bundled fallback snapshot (captured 2025-09-12) is used instead.

## Models

The extension dynamically discovers models from the API. Known models (with display name mappings) include:

| Model ID | Display Name | Reasoning | Context Window |
|----------|-------------|-----------|----------------|
| `alia-salamandra:40b` | ALIA Salamandra 40B | — | 32K |
| `deepseek:v4-flash` | DeepSeek V4 Flash | ✅ | 1M |
| `deepseek:v4-flash-0731` | DeepSeek V4 Flash 0731 | ✅ | 1M |
| `deepseek:v4-pro` | DeepSeek V4 Pro | ✅ | 1M |
| `deepseek:v4-pro-0813` | DeepSeek V4 Pro 0813 | ✅ | 1M |
| `euryale:33-70b` | Euryale 3.3 70B | — | 128K |
| `gemma-2:27b-it` | Gemma 2 27B | — | 8K |
| `gemma4:26b-a4b` | Gemma 4 26B A4B | — | 256K |
| `glm:5.3-flash` | GLM 5.3 Flash | ✅ | 1M |
| `mythomax:13b` | MythoMax 13B | — | 4K |
| `qwen3:14b` | Qwen3 14B | — | 40K |
| `remm-slerp:l2-13b` | Remm Slerp L2 13B | — | 6K |
| `unslopnemo:12b` | UnslopNemo 12B | — | 32K |

## How it works

### Model fetching

1. On load, the extension fetches `GET https://api.nextbit256.com/v1/models` with a 10-second timeout.
2. Each model spec returned by the API is mapped to pi's `ProviderModelConfig` format with:
   - **ID/name** — from API, with known IDs mapped to friendly display names
   - **Reasoning support** — hardcoded set based on empirical testing (the API reports `"reasoning"` in `supported_features` for all models, including non-reasoning ones)
   - **Input modalities** — `["text"]` or `["text", "image"]` based on `architecture.input_modalities`
   - **Context window** / **max tokens** — from API, with output capped at 128K tokens (see caveat below)
   - **Pricing** — per-token prices converted to dollars per million tokens
   - **Compatibility** — `supportsDeveloperRole: false` (API rejects OpenAI's `"developer"` role; use `"system"` instead)
3. If the fetch fails (network error, empty list, HTTP error), the bundled fallback snapshot is used silently.

### Provider registration

Calls `pi.registerProvider("nextbit", ...)` with:

| Field | Value |
|-------|-------|
| `name` | `"Nextbit"` |
| `baseUrl` | `https://api.nextbit256.com/v1` |
| `api` | `"openai-completions"` |
| `models` | Dynamically fetched or fallback list |

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

The bundled fallback has 13 models captured on 2025-09-12. This ensures the extension works offline or when Nextbit's API is down.

## API Surface Used

- `pi.registerProvider()` — registers the custom provider with name, base URL, API type, and model list

## Dependencies

- `@earendil-works/pi-coding-agent` (types: `ExtensionAPI`)
- Node.js built-in: `fetch` (global) with `AbortSignal.timeout`