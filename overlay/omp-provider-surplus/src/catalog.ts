export interface SurplusCatalogModel {
  id?: unknown;
  name?: unknown;
  context_length?: unknown;
  architecture?: {input_modalities?: unknown; output_modalities?: unknown};
  pricing?: {
    prompt?: unknown;
    completion?: unknown;
    input_cache_read?: unknown;
    input_cache_write?: unknown;
  };
  top_provider?: {max_completion_tokens?: unknown};
  supported_parameters?: unknown;
  supported_features?: unknown;
}

export interface SurplusMarket {
  model?: unknown;
  catalog_only?: unknown;
  best_input_per_1m?: unknown;
  best_output_per_1m?: unknown;
  direct_input_per_1m?: unknown;
  healthy_seller_count?: unknown;
}

export interface SurplusProviderModel {
  id: string;
  name: string;
  reasoning: boolean;
  input: ("text" | "image")[];
  cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
  contextWindow: number;
  maxTokens: number;
  compat: {
    supportsDeveloperRole: boolean;
    supportsReasoningEffort: boolean;
    maxTokensField: "max_tokens" | "max_completion_tokens";
  };
}

const API_ORIGIN = "https://api.surplusintelligence.ai";
const CATALOG_URL = `${API_ORIGIN}/v1/models`;
const BUYER_URL = `${API_ORIGIN}/v1/buyer/me`;
const MARKETS_URL = "https://www.surplusintelligence.ai/api/inference/markets";
const MILLION = 1_000_000;
const DEFAULT_CONTEXT = 128_000;
const DEFAULT_MAX_TOKENS = 65_536;

function finitePositive(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : fallback;
}

function finitePrice(value: unknown): number | undefined {
  const numeric = typeof value === "number" ? value : typeof value === "string" && value.trim() ? Number(value) : NaN;
  return Number.isFinite(numeric) && numeric >= 0 ? numeric : undefined;
}

function catalogPrice(value: unknown): number {
  return (finitePrice(value) ?? 0) * MILLION;
}

function advertised(values: unknown, target: string): boolean {
  return Array.isArray(values) && values.includes(target);
}

function cachePrice(value: unknown, marketInput: number, directInput: unknown): number {
  const direct = finitePrice(directInput);
  const reference = catalogPrice(value);
  const result = direct && direct > 0 ? reference * (marketInput / direct) : reference;
  return Number(result.toFixed(12));
}

function isRoutable(market: SurplusMarket): market is SurplusMarket & {
  model: string;
  best_input_per_1m: number;
  best_output_per_1m: number;
} {
  return typeof market.model === "string"
    && market.model.length > 0
    && market.catalog_only !== true
    && finitePositive(market.healthy_seller_count, 0) > 0
    && finitePrice(market.best_input_per_1m) !== undefined
    && finitePrice(market.best_output_per_1m) !== undefined;
}

export function parseSurplusMarkets(body: unknown): Map<string, SurplusMarket> {
  if (!Array.isArray(body)) return new Map();
  return new Map(body.filter((entry): entry is SurplusMarket => Boolean(entry) && typeof entry === "object" && isRoutable(entry as SurplusMarket)).map(market => [market.model as string, market]));
}

export function mapSurplusModel(model: SurplusCatalogModel, market?: SurplusMarket): SurplusProviderModel | undefined {
  if (typeof model.id !== "string" || !model.id.trim()) return undefined;
  if (!advertised(model.architecture?.input_modalities, "text") || !advertised(model.architecture?.output_modalities, "text")) return undefined;
  if (market && (!isRoutable(market) || market.model !== model.id)) return undefined;

  const parameters = model.supported_parameters;
  const features = model.supported_features;
  const reasoning = ["reasoning", "reasoning_effort", "include_reasoning"].some(value => advertised(parameters, value))
    || ["reasoning", "include_reasoning"].some(value => advertised(features, value));
  const inputPrice = market ? finitePrice(market.best_input_per_1m)! : catalogPrice(model.pricing?.prompt);
  const outputPrice = market ? finitePrice(market.best_output_per_1m)! : catalogPrice(model.pricing?.completion);

  return {
    id: model.id,
    name: `${typeof model.name === "string" && model.name.trim() ? model.name : model.id} (Surplus)`,
    reasoning,
    input: advertised(model.architecture?.input_modalities, "image") ? ["text", "image"] : ["text"],
    cost: {
      input: inputPrice,
      output: outputPrice,
      cacheRead: market ? cachePrice(model.pricing?.input_cache_read, inputPrice, market.direct_input_per_1m) : catalogPrice(model.pricing?.input_cache_read),
      cacheWrite: market ? cachePrice(model.pricing?.input_cache_write, inputPrice, market.direct_input_per_1m) : catalogPrice(model.pricing?.input_cache_write),
    },
    contextWindow: finitePositive(model.context_length, DEFAULT_CONTEXT),
    maxTokens: finitePositive(model.top_provider?.max_completion_tokens, DEFAULT_MAX_TOKENS),
    compat: {
      supportsDeveloperRole: true,
      supportsReasoningEffort: advertised(parameters, "reasoning_effort"),
      maxTokensField: advertised(parameters, "max_tokens") ? "max_tokens" : "max_completion_tokens",
    },
  };
}

export function parseSurplusCatalog(body: unknown, markets?: Map<string, SurplusMarket>): SurplusProviderModel[] {
  if (!body || typeof body !== "object" || !Array.isArray((body as {data?: unknown}).data)) return [];
  return (body as {data: unknown[]}).data.flatMap(entry => {
    if (!entry || typeof entry !== "object") return [];
    const model = entry as SurplusCatalogModel;
    if (markets && (typeof model.id !== "string" || !markets.has(model.id))) return [];
    const mapped = mapSurplusModel(model, markets?.get(model.id as string));
    return mapped ? [mapped] : [];
  });
}

async function request(url: string, apiKey: string, fetchImpl: typeof fetch): Promise<Response> {
  return fetchImpl(url, {
    method: "GET",
    headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
    signal: AbortSignal.timeout(15_000),
  });
}

export async function validateSurplusApiKey(apiKey: string, fetchImpl: typeof fetch = fetch): Promise<void> {
  const response = await request(BUYER_URL, apiKey, fetchImpl);
  if (!response.ok) throw new Error(`Surplus API key validation failed (${response.status})`);
}

export async function fetchSurplusModels(apiKey: string | undefined, fetchImpl: typeof fetch = fetch): Promise<SurplusProviderModel[]> {
  if (!apiKey?.trim()) return [];
  const [buyerResponse, catalogResponse, marketsResponse] = await Promise.all([
    request(BUYER_URL, apiKey, fetchImpl),
    request(CATALOG_URL, apiKey, fetchImpl),
    request(MARKETS_URL, apiKey, fetchImpl),
  ]);
  if (!buyerResponse.ok) throw new Error(`Surplus API key validation failed (${buyerResponse.status})`);
  if (!catalogResponse.ok) throw new Error(`Surplus catalog request failed (${catalogResponse.status})`);
  if (!marketsResponse.ok) throw new Error(`Surplus market request failed (${marketsResponse.status})`);

  const markets = parseSurplusMarkets(await marketsResponse.json());
  if (!markets.size) throw new Error("Surplus returned no routable markets");
  const models = parseSurplusCatalog(await catalogResponse.json(), markets);
  if (!models.length) throw new Error("Surplus returned no accessible chat models");
  return models;
}
