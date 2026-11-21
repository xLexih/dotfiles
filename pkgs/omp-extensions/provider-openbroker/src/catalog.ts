import {reasoningProfileForParser, type ReasoningProfile, type ThinkingProfile} from "./profiles.ts";

export interface BrokerModel {
  id: string;
  name: string;
  input: ("text" | "image")[];
}

export interface ChainModel {
  id: string;
  maxModelLen?: number;
  maxModelLenRaw?: string;
  reasoningParser?: string;
  toolCallParser?: string;
}

export interface OpenBrokerModel {
  id: string;
  name: string;
  reasoning: boolean;
  input: ("text" | "image")[];
  cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
  contextWindow: number;
  maxTokens: number;
  omitMaxOutputTokens: true;
  thinking?: ThinkingProfile;
}

export interface OpenBrokerEntry {
  model: OpenBrokerModel;
  profile: ReasoningProfile;
}

export const OPENBROKER_BASE_URL = "https://api.openbroker.gonka.gg/v1";
const BALANCE_URL = `${OPENBROKER_BASE_URL}/balance`;
export const BROKER_MODELS_URL = `${OPENBROKER_BASE_URL}/models`;
export const CHAIN_MODELS_URL = "https://rpc.gonka.gg/chain-api/productscience/inference/inference/models_all";

const DISCOVERY_TIMEOUT_MS = 5_000;
// The chain publishes no served output ceiling. Omit the wire cap and keep a
// local budget only for OMP's output accounting.
const LOCAL_OUTPUT_TOKEN_BUDGET = 16_384;

function record(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object" && !Array.isArray(value) ? (value as Record<string, unknown>) : undefined;
}

function positiveInteger(value: string | undefined): number | undefined {
  if (value === undefined) return undefined;
  const parsed = Number(value);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : undefined;
}

function flagValue(args: readonly string[], flag: string): string | undefined {
  const prefix = `${flag}=`;
  for (let index = 0; index < args.length; index++) {
    const arg = args[index]!;
    if (arg === flag) {
      const value = args[index + 1];
      return value === undefined || value.startsWith("--") || value === "" ? undefined : value;
    }
    if (arg.startsWith(prefix)) {
      const value = arg.slice(prefix.length);
      return value === "" ? undefined : value;
    }
  }
  return undefined;
}

export function parseBrokerModels(body: unknown): BrokerModel[] {
  const data = record(body)?.data;
  if (!Array.isArray(data)) return [];
  const models = new Map<string, BrokerModel>();
  for (const entry of data) {
    const value = record(entry);
    if (!value) continue;
    const id = typeof value.id === "string" ? value.id.trim() : "";
    if (!id || models.has(id)) continue;
    if (value.output_modalities !== undefined && (!Array.isArray(value.output_modalities) || !value.output_modalities.includes("text"))) continue;
    const input: BrokerModel["input"] = value.input_modalities === undefined ? ["text"]
      : Array.isArray(value.input_modalities) ? [...new Set(value.input_modalities.filter((modality): modality is "text" | "image" => modality === "text" || modality === "image"))] : [];
    if (!input.includes("text")) continue;
    models.set(id, {
      id,
      name: typeof value.name === "string" && value.name.trim() ? value.name.trim() : id,
      input,
    });
  }
  return [...models.values()];
}

export function parseChainModels(body: unknown): Map<string, ChainModel> {
  const entries = record(body)?.model;
  if (!Array.isArray(entries)) return new Map();
  const models = new Map<string, ChainModel>();
  for (const entry of entries) {
    const value = record(entry);
    if (!value) continue;
    const id = typeof value.id === "string" ? value.id.trim() : "";
    if (!id || models.has(id)) continue;
    const args = Array.isArray(value.model_args) ? value.model_args.filter((arg): arg is string => typeof arg === "string") : [];
    const maxModelLenRaw = flagValue(args, "--max-model-len");
    models.set(id, {
      id,
      ...(maxModelLenRaw !== undefined ? {maxModelLenRaw} : {}),
      maxModelLen: positiveInteger(maxModelLenRaw),
      reasoningParser: flagValue(args, "--reasoning-parser"),
      toolCallParser: flagValue(args, "--tool-call-parser"),
    });
  }
  return models;
}

/**
 * Merge the broker's live availability list with the chain's serving args.
 * There is no fallback table: an active broker id without a valid
 * `--max-model-len`, or with an unknown reasoning parser, fails discovery so
 * the operator can select another model instead of silently misbehaving.
 */
export function mergeBrokerModels(
  broker: readonly BrokerModel[],
  chain: ReadonlyMap<string, ChainModel>,
): OpenBrokerEntry[] {
  if (broker.length === 0) throw new Error("OpenBroker returned no chat models");
  const missing = broker.filter(model => !chain.has(model.id)).map(model => model.id);
  if (missing.length > 0) throw new Error(`OpenBroker serving metadata is missing: ${missing.join(", ")}`);

  return broker.map(model => {
    const metadata = chain.get(model.id)!;
    if (metadata.maxModelLen === undefined) {
      const detail = metadata.maxModelLenRaw === undefined
        ? "missing --max-model-len"
        : `invalid --max-model-len ${JSON.stringify(metadata.maxModelLenRaw)}`;
      throw new Error(`OpenBroker serving metadata for ${model.id} has ${detail}`);
    }
    const profile = reasoningProfileForParser(metadata.reasoningParser);
    return {
      model: {
        id: model.id,
        name: model.name,
        reasoning: profile.reasoning,
        input: model.input,
        cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
        contextWindow: metadata.maxModelLen,
        maxTokens: LOCAL_OUTPUT_TOKEN_BUDGET,
        omitMaxOutputTokens: true,
        ...(profile.thinking ? {thinking: profile.thinking} : {}),
      },
      profile,
    };
  });
}

async function fetchJson(url: string, label: string, fetchImpl: typeof fetch): Promise<unknown> {
  const response = await fetchImpl(url, {
    method: "GET",
    headers: {Accept: "application/json", "Accept-Encoding": "identity"},
    signal: AbortSignal.timeout(DISCOVERY_TIMEOUT_MS),
  });
  if (!response.ok) throw new Error(`${label} request failed (${response.status})`);
  return response.json();
}

export async function fetchBrokerModels(fetchImpl: typeof fetch = fetch): Promise<OpenBrokerEntry[]> {
  const [brokerBody, chainBody] = await Promise.all([
    fetchJson(BROKER_MODELS_URL, "OpenBroker model", fetchImpl),
    fetchJson(CHAIN_MODELS_URL, "OpenBroker serving metadata", fetchImpl),
  ]);
  return mergeBrokerModels(parseBrokerModels(brokerBody), parseChainModels(chainBody));
}

export async function validateOpenBrokerApiKey(apiKey: string, fetchImpl: typeof fetch = fetch): Promise<void> {
  const response = await fetchImpl(BALANCE_URL, {
    method: "GET",
    headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
    signal: AbortSignal.timeout(15_000),
  });
  if (!response.ok) throw new Error(`OpenBroker API key validation failed (${response.status})`);
}
