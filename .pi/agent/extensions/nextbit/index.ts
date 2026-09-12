/**
 * Nextbit provider extension.
 *
 * Registers the "nextbit" provider (https://api.nextbit256.com/v1, OpenAI
 * Chat Completions compatible). The model list is fetched from /v1/models at
 * startup, so context windows, pricing, and new models stay current without
 * editing this file. If the API is unreachable, a bundled snapshot of the
 * model list (captured 2025-09-12) is used instead.
 *
 * Auth: `/login nextbit` — key stored in ~/.pi/agent/auth.json.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const BASE_URL = "https://api.nextbit256.com/v1";
const FETCH_TIMEOUT_MS = 10_000;

/**
 * The gateway rejects requests whose max_completion_tokens gets close to the
 * model's context window (observed: prompt (~9K tokens) + 524288 rejected,
 * + 262144 accepted on a 1M-context model), even though pi only ever asks for
 * the remaining context. Capping output at 128K keeps requests well clear of
 * that limit; 128K output is far beyond anything a coding task needs.
 */
const MAX_OUTPUT_TOKENS_CAP = 131_072;

/** Display names for known models; unknown IDs fall back to the API's name. */
const DISPLAY_NAMES: Record<string, string> = {
    "alia-salamandra:40b": "ALIA Salamandra 40B",
    "deepseek:v4-flash": "DeepSeek V4 Flash",
    "deepseek:v4-flash-0731": "DeepSeek V4 Flash 0731",
    "deepseek:v4-pro": "DeepSeek V4 Pro",
    "deepseek:v4-pro-0813": "DeepSeek V4 Pro 0813",
    "euryale:33-70b": "Euryale 3.3 70B",
    "gemma-2:27b-it": "Gemma 2 27B",
    "gemma4:26b-a4b": "Gemma 4 26B A4B",
    "glm:5.3-flash": "GLM 5.3 Flash",
    "mythomax:13b": "MythoMax 13B",
    "qwen3:14b": "Qwen3 14B",
    "remm-slerp:l2-13b": "Remm Slerp L2 13B",
    "unslopnemo:12b": "UnslopNemo 12B",
};

/**
 * Model IDs verified to emit `reasoning_content`. The gateway reports
 * "reasoning" in supported_features for every model — including models with
 * no thinking support — so this list is empirical, not from the API.
 * Unknown models default to reasoning: false.
 */
const REASONING_IDS = new Set([
    "deepseek:v4-flash",
    "deepseek:v4-flash-0731",
    "deepseek:v4-pro",
    "deepseek:v4-pro-0813",
    "glm:5.3-flash",
]);

/** Model entry as returned by GET /v1/models. */
interface NextbitModelSpec {
    id: string;
    name?: string;
    context_length?: number;
    max_completion_tokens?: number;
    architecture?: { input_modalities?: string[] };
    pricing?: { prompt?: string; completion?: string; input_cache_read?: string };
}

/** Model config as accepted by pi.registerProvider (see docs/custom-provider.md). */
interface ProviderModelConfig {
    id: string;
    name: string;
    reasoning: boolean;
    input: ("text" | "image")[];
    contextWindow: number;
    maxTokens: number;
    cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
    compat: { supportsDeveloperRole: false };
}

/** Snapshot of the model list, used when /v1/models cannot be fetched. */
const FALLBACK_MODELS: ProviderModelConfig[] = [
    {
        "id": "alia-salamandra:40b",
        "name": "ALIA Salamandra 40B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 32768,
        "maxTokens": 32768,
        "cost": { "input": 0.3, "output": 0.6, "cacheRead": 0, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "deepseek:v4-flash",
        "name": "DeepSeek V4 Flash",
        "reasoning": true,
        "input": ["text"],
        "contextWindow": 1048576,
        "maxTokens": 131072,
        "cost": { "input": 0.15, "output": 0.35, "cacheRead": 0.035, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "deepseek:v4-flash-0731",
        "name": "DeepSeek V4 Flash 0731",
        "reasoning": true,
        "input": ["text"],
        "contextWindow": 1048576,
        "maxTokens": 131072,
        "cost": { "input": 0.352, "output": 1.056, "cacheRead": 0.012, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "deepseek:v4-pro",
        "name": "DeepSeek V4 Pro",
        "reasoning": true,
        "input": ["text"],
        "contextWindow": 1048576,
        "maxTokens": 131072,
        "cost": { "input": 2, "output": 4, "cacheRead": 0.17, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "deepseek:v4-pro-0813",
        "name": "DeepSeek V4 Pro 0813",
        "reasoning": true,
        "input": ["text"],
        "contextWindow": 1048576,
        "maxTokens": 131072,
        "cost": { "input": 1.122, "output": 3.366, "cacheRead": 0.037, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "euryale:33-70b",
        "name": "Euryale 3.3 70B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 131072,
        "maxTokens": 16384,
        "cost": { "input": 0.65, "output": 0.75, "cacheRead": 0, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "gemma-2:27b-it",
        "name": "Gemma 2 27B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 8192,
        "maxTokens": 2048,
        "cost": { "input": 0.65, "output": 0.65, "cacheRead": 0, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "gemma4:26b-a4b",
        "name": "Gemma 4 26B A4B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 262144,
        "maxTokens": 131072,
        "cost": { "input": 0.09, "output": 0.3, "cacheRead": 0.05, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "glm:5.3-flash",
        "name": "GLM 5.3 Flash",
        "reasoning": true,
        "input": ["text"],
        "contextWindow": 1048576,
        "maxTokens": 128000,
        "cost": { "input": 0.15, "output": 0.5, "cacheRead": 0.03, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "mythomax:13b",
        "name": "MythoMax 13B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 4096,
        "maxTokens": 4096,
        "cost": { "input": 0.06, "output": 0.06, "cacheRead": 0, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "qwen3:14b",
        "name": "Qwen3 14B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 40960,
        "maxTokens": 40960,
        "cost": { "input": 0.1, "output": 0.22, "cacheRead": 0, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "remm-slerp:l2-13b",
        "name": "Remm Slerp L2 13B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 6144,
        "maxTokens": 4096,
        "cost": { "input": 0.45, "output": 0.65, "cacheRead": 0, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    },
    {
        "id": "unslopnemo:12b",
        "name": "UnslopNemo 12B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 32768,
        "maxTokens": 32768,
        "cost": { "input": 0.4, "output": 0.4, "cacheRead": 0, "cacheWrite": 0 },
        "compat": { "supportsDeveloperRole": false }
    }
];

/** Convert a per-token price string to dollars per million tokens. */
function toMillions(perToken: string | undefined): number {
    if (!perToken) return 0;
    return Math.round(parseFloat(perToken) * 1_000_000 * 10_000) / 10_000;
}

/** Map a /v1/models entry to a pi provider model config. */
function toModelConfig(m: NextbitModelSpec): ProviderModelConfig {
    return {
        id: m.id,
        name: DISPLAY_NAMES[m.id] ?? m.name ?? m.id,
        reasoning: REASONING_IDS.has(m.id),
        input: m.architecture?.input_modalities?.includes("image")
            ? ["text", "image"]
            : ["text"],
        contextWindow: m.context_length ?? 128_000,
        maxTokens: Math.min(m.max_completion_tokens ?? 16_384, MAX_OUTPUT_TOKENS_CAP),
        cost: {
            input: toMillions(m.pricing?.prompt),
            output: toMillions(m.pricing?.completion),
            cacheRead: toMillions(m.pricing?.input_cache_read),
            cacheWrite: 0
        },
        // The API rejects the OpenAI "developer" role with HTTP 400; use "system".
        compat: { supportsDeveloperRole: false }
    };
}

async function fetchModels(): Promise<ProviderModelConfig[]> {
    const response = await fetch(`${BASE_URL}/models`, {
        signal: AbortSignal.timeout(FETCH_TIMEOUT_MS)
    });
    if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
    }
    const payload = (await response.json()) as { data?: NextbitModelSpec[] };
    return (payload.data ?? []).map(toModelConfig);
}

export default async function (pi: ExtensionAPI): Promise<void> {
    let models: ProviderModelConfig[];
    try {
        models = await fetchModels();
        if (models.length === 0) {
            throw new Error("empty model list");
        }
    } catch {
        // API unreachable (offline, down, or rate-limited): use the snapshot.
        models = FALLBACK_MODELS;
    }

    pi.registerProvider("nextbit", {
        name: "Nextbit",
        baseUrl: BASE_URL,
        api: "openai-completions",
        models
    });
}