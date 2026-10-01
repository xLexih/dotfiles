export interface OpenBrokerModel {
  id: string;
  name: string;
  reasoning: boolean;
  input: ("text" | "image")[];
  cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
  contextWindow: number;
  maxTokens: number;
}

export const OPENBROKER_BASE_URL = "https://api.openbroker.gonka.gg/v1";
const BALANCE_URL = `${OPENBROKER_BASE_URL}/balance`;
export const BROKER_MODELS_URL = `${OPENBROKER_BASE_URL}/models`;

/**
 * Curated serving limits per model id.
 *
 * `GET /v1/models` on the new API host returns bare `{id}` entries with no
 * `context_length` / `max_output_length` metadata (verified 2026-09-21), so
 * limits come from the Gonka devshard serving profile (previously published
 * on the rich `proxy.gonkabroker.com/v1/models` catalog) or the upstream
 * model card. When the broker does publish rich fields, those win over this
 * table; bare entries fall back to it, and wholly unknown ids get
 * conservative defaults so new models (e.g. Qwen) register instead of
 * disappearing.
 */
const KNOWN_LIMITS: Readonly<Record<string, {contextWindow: number; maxTokens: number}>> = {
  // Gonka devshard serving profile (old rich catalog): 204800 / 16384.
  "MiniMaxAI/MiniMax-M2.7": {contextWindow: 204_800, maxTokens: 16_384},
  // Gonka devshard serving profile (old rich catalog): 400000 / 16384.
  "deepseek-ai/DeepSeek-V4-Flash-0731": {contextWindow: 400_000, maxTokens: 16_384},
  // Gonka devshard serving profile (old rich catalog): 400000 / 16384.
  // Upstream Z.AI advertises 1M context / 131k output; the devshard serves
  // the smaller window, so keep the serving profile here.
  "zai-org/GLM-5.3-Flash": {contextWindow: 400_000, maxTokens: 16_384},
  // Upstream HF card (Qwen/Qwen3-235B-A22B-Instruct-2507-FP8): 262144 native
  // context; 16384 recommended output for instruct models.
  "Qwen/Qwen3-235B-A22B-Instruct-2507-FP8": {contextWindow: 262_144, maxTokens: 16_384},
  "Qwen/Qwen3-235B-A22B-Instruct-2507": {contextWindow: 262_144, maxTokens: 16_384},
  // Deprecated on OpenBroker (no validation weights, requests fail) but kept
  // so a stale catalog entry still registers with its last-known window.
  "moonshotai/Kimi-K2.6": {contextWindow: 262_144, maxTokens: 8_192},
};

const DEFAULT_CONTEXT_WINDOW = 128_000;
const DEFAULT_MAX_TOKENS = 16_384;

// Best-effort non-chat guard for bare entries, which carry no
// `output_modalities` to filter on. Rich entries are still filtered by
// `output_modalities` below; this only covers ids we know are not chat.
const KNOWN_NON_CHAT_IDS = new Set(["BAAI/bge-m3"]);

function positiveInteger(value: unknown): number | undefined {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0 ? value : undefined;
}

export function parseBrokerModels(body: unknown): OpenBrokerModel[] {
  if (!body || typeof body !== "object" || !Array.isArray((body as {data?: unknown}).data)) return [];
  const models = new Map<string, OpenBrokerModel>();
  for (const entry of (body as {data: unknown[]}).data) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue;
    const value = entry as Record<string, unknown>;
    const id = typeof value.id === "string" ? value.id.trim() : "";
    if (!id) continue;
    if (value.output_modalities !== undefined && (!Array.isArray(value.output_modalities) || !value.output_modalities.includes("text"))) continue;
    if (value.output_modalities === undefined && KNOWN_NON_CHAT_IDS.has(id)) continue;
    const input: OpenBrokerModel["input"] = value.input_modalities === undefined ? ["text"]
      : Array.isArray(value.input_modalities) ? [...new Set(value.input_modalities.filter((modality): modality is "text" | "image" => modality === "text" || modality === "image"))] : [];
    if (!input.includes("text")) continue;
    // Rich entries carry explicit limits; bare `{id}` entries from the new
    // endpoint fall back to the curated table, then conservative defaults.
    // A present-but-invalid limit means malformed metadata, so skip instead
    // of silently substituting a fallback.
    let contextWindow: number | undefined;
    if (value.context_length === undefined) {
      contextWindow = KNOWN_LIMITS[id]?.contextWindow ?? DEFAULT_CONTEXT_WINDOW;
    } else {
      contextWindow = positiveInteger(value.context_length);
      if (!contextWindow) continue;
    }
    let maxTokens: number | undefined;
    if (value.max_output_length === undefined) {
      maxTokens = KNOWN_LIMITS[id]?.maxTokens ?? DEFAULT_MAX_TOKENS;
    } else {
      maxTokens = positiveInteger(value.max_output_length);
      if (!maxTokens) continue;
    }
    if (models.has(id)) continue;
    models.set(id, {
      id,
      name: typeof value.name === "string" && value.name.trim() ? value.name.trim() : id,
      reasoning: Array.isArray(value.supported_features) && value.supported_features.includes("reasoning"),
      input,
      cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
      contextWindow,
      maxTokens,
    });
  }
  return [...models.values()];
}

export async function fetchBrokerModels(fetchImpl: typeof fetch = fetch): Promise<OpenBrokerModel[]> {
  const response = await fetchImpl(BROKER_MODELS_URL, {
    method: "GET",
    headers: {Accept: "application/json", "Accept-Encoding": "identity"},
    signal: AbortSignal.timeout(5_000),
  });
  if (!response.ok) throw new Error(`OpenBroker model request failed (${response.status})`);
  const models = parseBrokerModels(await response.json());
  if (!models.length) throw new Error("OpenBroker returned no usable chat models");
  return models;
}

export async function validateOpenBrokerApiKey(apiKey: string, fetchImpl: typeof fetch = fetch): Promise<void> {
  const response = await fetchImpl(BALANCE_URL, {
    method: "GET",
    headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
    signal: AbortSignal.timeout(15_000),
  });
  if (!response.ok) throw new Error(`OpenBroker API key validation failed (${response.status})`);
}
