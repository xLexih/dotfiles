export interface OpenBrokerModel {
  id: string;
  name: string;
  reasoning: boolean;
  input: ("text" | "image")[];
  cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
  contextWindow: number;
  maxTokens: number;
}

const BALANCE_URL = "https://api.openbroker.gonka.gg/v1/balance";
export const BROKER_MODELS_URL = "https://proxy.gonkabroker.com/v1/models";

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
    const contextWindow = positiveInteger(value.context_length);
    const maxTokens = positiveInteger(value.max_output_length);
    if (!id || !contextWindow || !maxTokens) continue;
    if (value.output_modalities !== undefined && (!Array.isArray(value.output_modalities) || !value.output_modalities.includes("text"))) continue;
    const input: OpenBrokerModel["input"] = value.input_modalities === undefined ? ["text"]
      : Array.isArray(value.input_modalities) ? [...new Set(value.input_modalities.filter((modality): modality is "text" | "image" => modality === "text" || modality === "image"))] : [];
    if (!input.includes("text")) continue;
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
  if (!response.ok) throw new Error(`Gonka Broker model request failed (${response.status})`);
  const models = parseBrokerModels(await response.json());
  if (!models.length) throw new Error("Gonka Broker returned no usable chat models");
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
