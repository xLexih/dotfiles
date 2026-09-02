export interface OpenBrokerModel {
  id: string;
  name: string;
  reasoning: boolean;
  input: ("text" | "image")[];
  cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
  contextWindow: number;
  maxTokens: number;

  /** Soft warning threshold above which the provider suggests compacting. */
  highContextWarnTokens: number;
  /** Recommendation for sessions running at large context. */
  highContextHint: "preferred" | "acceptable" | "avoid";
}

const BALANCE_URL = "https://api.openbroker.gonka.gg/v1/balance";
export const BROKER_MODELS_URL = "https://proxy.gonkabroker.com/v1/models";

/**
 * OpenBroker's actively served chat models. The OpenBroker API host currently does
 * not expose a usable model list, so keeping this catalog local avoids startup I/O.
 * Costs are deliberately omitted from live accounting: GNK is the billed currency and
 * OMP's model-cost contract only accepts USD-per-million-token estimates.
 */
export const OPENBROKER_MODELS: OpenBrokerModel[] = [
  // Effective limits from the public Gonka Broker GET /v1/models catalog.
  //
  // DeepSeek's maxTokens is lowered from the broker's advertised 16,384 to 4,096
  // as a verbosity brake. The model can naturally finish shorter responses; the
  // previous 16k budget let mid-stream self-corrections spiral into 12k+ char
  // rambles that hit `length` mid-thought, which combined with the 18.0.6 retry
  // wedge caused the 1260-iteration loops. A 4k cap keeps the model on-task.
  //
  // highContextWarnTokens is the soft threshold above which the provider suggests
  // OMP compact. The broker's devshard accepts 200k+ prompt tokens cleanly (probed
  // 2026-08-28), so this is a *nudge* not a *ceiling* — the real failure mode was
  // the retry wedge, not context overflow.
  //
  // highContextHint ranks the model for sessions running at large context. Kimi
  // produced the cleanest outputs at 200k in the probe (consistent 3-token
  // responses); MiniMax is acceptable but always-on thinking burns output
  // budget; DeepSeek is acceptable with the lowered maxTokens cap.
  {id: "MiniMaxAI/MiniMax-M2.7", name: "MiniMax M2.7", reasoning: true, input: ["text"], cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}, contextWindow: 204_800, maxTokens: 16_384, highContextWarnTokens: 150_000, highContextHint: "acceptable"},
  {id: "moonshotai/Kimi-K2.6", name: "Kimi K2.6", reasoning: true, input: ["text"], cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}, contextWindow: 262_144, maxTokens: 8_192, highContextWarnTokens: 200_000, highContextHint: "preferred"},
  {id: "deepseek-ai/DeepSeek-V4-Flash-0731", name: "DeepSeek V4 Flash 0731", reasoning: true, input: ["text"], cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}, contextWindow: 400_000, maxTokens: 4_096, highContextWarnTokens: 150_000, highContextHint: "acceptable"},
];

function positiveInteger(value: unknown): number | undefined {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0 ? value : undefined;
}

/** Parse the public broker catalog without allowing unknown models or bad limits in. */
export function parseBrokerModels(body: unknown): OpenBrokerModel[] {
  if (!body || typeof body !== "object" || !Array.isArray((body as {data?: unknown}).data)) return [];
  const entries = new Map((body as {data: unknown[]}).data.flatMap(entry => {
    if (!entry || typeof entry !== "object") return [];
    const value = entry as Record<string, unknown>;
    const id = typeof value.id === "string" ? value.id : undefined;
    const contextWindow = positiveInteger(value.context_length);
    const maxTokens = positiveInteger(value.max_output_length);
    return id && contextWindow && maxTokens ? [[id, {contextWindow, maxTokens}] as const] : [];
  }));
  return OPENBROKER_MODELS.map(model => {
    const limits = entries.get(model.id);
    return limits ? {...model, ...limits} : model;
  });
}

export async function fetchBrokerModels(fetchImpl: typeof fetch = fetch): Promise<OpenBrokerModel[]> {
  const response = await fetchImpl(BROKER_MODELS_URL, {
    method: "GET",
    headers: {Accept: "application/json", "Accept-Encoding": "identity"},
    signal: AbortSignal.timeout(5_000),
  });
  if (!response.ok) throw new Error(`Gonka Broker model request failed (${response.status})`);
  const models = parseBrokerModels(await response.json());
  if (!models.length) throw new Error("Gonka Broker returned no usable model limits");
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
