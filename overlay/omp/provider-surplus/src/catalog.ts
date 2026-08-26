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
  providerBreakdown?: unknown;
}

export interface SurplusProviderRoute {
  provider: string;
  trusted: boolean;
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
}

export interface SurplusProviderPrice {
  input: number;
  output: number;
  cacheRead?: number;
  cacheWrite?: number;
}

export type SurplusProviderPrices = Map<string, Map<string, SurplusProviderPrice>>;

export interface SurplusAccessPolicy {
  allowUntrusted?: boolean;
  blockedProviders: ReadonlySet<string>;
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
  supportsTools: boolean;
  routes: SurplusProviderRoute[];
}

const API_ORIGIN = "https://api.surplusintelligence.ai";
const CATALOG_URL = `${API_ORIGIN}/v1/models`;
const BUYER_URL = `${API_ORIGIN}/v1/buyer/me`;
const PREFERENCES_URL = `${API_ORIGIN}/v1/buyer/preferences`;
const PRICES_URL = `${API_ORIGIN}/v1/prices`;
const MARKETS_URL = "https://www.surplusintelligence.ai/api/inference/markets";
const MILLION = 1_000_000;
const PRICE_REFRESH_MS = 60 * 60 * 1_000;
const DEFAULT_CONTEXT = 128_000;
const DEFAULT_MAX_TOKENS = 65_536;
let cachedProviderPrices: SurplusProviderPrices | undefined;
let providerPricesAt = 0;

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

function providerKey(value: string): string {
  const normalized = value.trim().toLowerCase();
  try {
    return new URL(normalized.includes("://") ? normalized : `https://${normalized}`).hostname
      .replace(/^(?:api|www)\./, "").split(".")[0] ?? normalized;
  } catch {
    return normalized;
  }
}

function collectBlockedProviders(value: unknown, result: Set<string>): void {
  if (!value || typeof value !== "object") return;
  if (Array.isArray(value)) {
    for (const entry of value) collectBlockedProviders(entry, result);
    return;
  }
  for (const [key, entry] of Object.entries(value)) {
    if (["providers_blocked", "blocked_providers", "provider_blocklist", "provider_blacklist"].includes(key.replace(/[A-Z]/g, match => `_${match.toLowerCase()}`))) {
      if (Array.isArray(entry)) for (const provider of entry) if (typeof provider === "string" && provider.trim()) result.add(providerKey(provider));
    } else if (entry && typeof entry === "object") collectBlockedProviders(entry, result);
  }
}

export function parseSurplusAccessPolicy(body: unknown): SurplusAccessPolicy {
  const blockedProviders = new Set<string>();
  collectBlockedProviders(body, blockedProviders);
  if (!body || typeof body !== "object") return {blockedProviders};
  const record = body as Record<string, unknown>;
  const preferenceObjects = [record.preferences, record.preferences_key, record.preferences_account]
    .filter((value): value is Record<string, unknown> => Boolean(value) && typeof value === "object" && !Array.isArray(value));
  const allowUntrusted = preferenceObjects.map(value => value.allow_untrusted).find(value => typeof value === "boolean");
  return {blockedProviders, ...(typeof allowUntrusted === "boolean" ? {allowUntrusted} : {})};
}

function routeAllowed(route: SurplusProviderRoute, policy?: SurplusAccessPolicy): boolean {
  return !policy?.blockedProviders.has(providerKey(route.provider)) && (policy?.allowUntrusted !== false || route.trusted);
}

export function extendSurplusAccessPolicy(policy: SurplusAccessPolicy, blockedProviders: readonly string[]): SurplusAccessPolicy {
  const blocked = new Set(policy.blockedProviders);
  for (const provider of blockedProviders) if (provider.trim()) blocked.add(providerKey(provider));
  return {...policy, blockedProviders: blocked};
}

export function applySurplusAccessPolicy(models: readonly SurplusProviderModel[], policy: SurplusAccessPolicy): SurplusProviderModel[] {
  return models.flatMap(model => {
    const routes = model.routes.filter(route => routeAllowed(route, policy));
    return routes.length ? [{...model, routes}] : [];
  });
}

function advertised(values: unknown, target: string): boolean {
  return Array.isArray(values) && values.includes(target);
}

function discountedPrice(reference: number | undefined, referenceInput: number | undefined, marketInput: number): number {
  if (reference === undefined || !referenceInput) return marketInput;
  return Number((reference * marketInput / referenceInput).toFixed(12));
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

export function parseProviderPrices(body: unknown): SurplusProviderPrices {
  if (!body || typeof body !== "object" || !Array.isArray((body as {models?: unknown}).models)) return new Map();
  const result: SurplusProviderPrices = new Map();
  for (const entry of (body as {models: unknown[]}).models) {
    if (!entry || typeof entry !== "object" || typeof (entry as {model?: unknown}).model !== "string") continue;
    const providers = (entry as {providers?: unknown}).providers;
    const rows = Array.isArray(providers) ? providers : providers && typeof providers === "object"
      ? Object.entries(providers).map(([provider, pricing]) => ({provider, pricing})) : [];
    const mapped = new Map<string, SurplusProviderPrice>();
    for (const row of rows) {
      if (!row || typeof row !== "object") continue;
      const record = row as {provider?: unknown; pricing?: unknown};
      if (typeof record.provider !== "string" || !record.pricing || typeof record.pricing !== "object") continue;
      const pricing = record.pricing as Record<string, unknown>;
      const input = finitePrice(pricing.input);
      const output = finitePrice(pricing.output);
      if (input === undefined || output === undefined) continue;
      const cacheRead = finitePrice(pricing.cacheRead);
      const cacheWrite = finitePrice(pricing.cacheWrite);
      mapped.set(record.provider.toLowerCase(), {input, output, ...(cacheRead === undefined ? {} : {cacheRead}), ...(cacheWrite === undefined ? {} : {cacheWrite})});
    }
    result.set((entry as {model: string}).model, mapped);
  }
  return result;
}

function parseProviderRoutes(value: unknown, referenceInput: number, referenceCacheRead: number | undefined,
  referenceCacheWrite: number | undefined, providerPrices?: Map<string, SurplusProviderPrice>): SurplusProviderRoute[] {
  if (!Array.isArray(value)) return [];
  return value.flatMap(entry => {
    if (!entry || typeof entry !== "object") return [];
    const route = entry as Record<string, unknown>;
    const input = finitePrice(route.best_input_per_1m);
    const output = finitePrice(route.best_output_per_1m);
    if (typeof route.provider !== "string" || !route.provider.trim()
      || typeof route.trusted !== "boolean"
      || finitePositive(route.healthy_seller_count, 0) <= 0
      || input === undefined || output === undefined) return [];
    const provider = route.provider.trim();
    const direct = providerPrices?.get(provider.toLowerCase());
    return [{provider, trusted: route.trusted, input, output,
      cacheRead: discountedPrice(direct?.cacheRead ?? referenceCacheRead, direct?.input ?? referenceInput, input),
      cacheWrite: discountedPrice(direct?.cacheWrite ?? referenceCacheWrite, direct?.input ?? referenceInput, input)}];
  });
}

export function parseSurplusMarkets(body: unknown): Map<string, SurplusMarket> {
  if (!Array.isArray(body)) return new Map();
  return new Map(body.filter((entry): entry is SurplusMarket => Boolean(entry) && typeof entry === "object" && isRoutable(entry as SurplusMarket)).map(market => [market.model as string, market]));
}

export function mapSurplusModel(model: SurplusCatalogModel, market?: SurplusMarket, prices?: SurplusProviderPrices,
  policy?: SurplusAccessPolicy): SurplusProviderModel | undefined {
  if (typeof model.id !== "string" || !model.id.trim()) return undefined;
  if (!advertised(model.architecture?.input_modalities, "text") || !advertised(model.architecture?.output_modalities, "text")) return undefined;
  if (market && (!isRoutable(market) || market.model !== model.id)) return undefined;

  const parameters = model.supported_parameters;
  const features = model.supported_features;
  const reasoning = ["reasoning", "reasoning_effort", "include_reasoning"].some(value => advertised(parameters, value))
    || ["reasoning", "include_reasoning"].some(value => advertised(features, value));
  const inputPrice = market ? finitePrice(market.best_input_per_1m)! : catalogPrice(model.pricing?.prompt);
  const outputPrice = market ? finitePrice(market.best_output_per_1m)! : catalogPrice(model.pricing?.completion);
  const referenceInput = finitePrice(market?.direct_input_per_1m) ?? catalogPrice(model.pricing?.prompt);
  const referenceCacheRead = finitePrice(model.pricing?.input_cache_read);
  const referenceCacheWrite = finitePrice(model.pricing?.input_cache_write);
  const routes = market ? parseProviderRoutes(market.providerBreakdown, referenceInput,
    referenceCacheRead === undefined ? undefined : referenceCacheRead * MILLION,
    referenceCacheWrite === undefined ? undefined : referenceCacheWrite * MILLION, prices?.get(model.id)).filter(route => routeAllowed(route, policy)) : [];
  if (market && !routes.length) return undefined;
  const bestRoute = routes.find(route => route.input === inputPrice && route.output === outputPrice);

  return {
    id: model.id,
    name: `Surplus → ${typeof model.name === "string" && model.name.trim() ? model.name : model.id}`,
    reasoning,
    input: advertised(model.architecture?.input_modalities, "image") ? ["text", "image"] : ["text"],
    cost: {
      input: inputPrice,
      output: outputPrice,
      cacheRead: market ? bestRoute?.cacheRead ?? inputPrice : catalogPrice(model.pricing?.input_cache_read),
      cacheWrite: market ? bestRoute?.cacheWrite ?? inputPrice : catalogPrice(model.pricing?.input_cache_write),
    },
    contextWindow: finitePositive(model.context_length, DEFAULT_CONTEXT),
    maxTokens: finitePositive(model.top_provider?.max_completion_tokens, DEFAULT_MAX_TOKENS),
    compat: {
      supportsDeveloperRole: true,
      supportsReasoningEffort: advertised(parameters, "reasoning_effort"),
      maxTokensField: advertised(parameters, "max_tokens") ? "max_tokens" : "max_completion_tokens",
    },
    supportsTools: ["tools", "tool_choice", "functions"].some(value => advertised(parameters, value)),
    routes,
  };
}

export function parseSurplusCatalog(body: unknown, markets?: Map<string, SurplusMarket>, prices?: SurplusProviderPrices,
  policy?: SurplusAccessPolicy): SurplusProviderModel[] {
  if (!body || typeof body !== "object" || !Array.isArray((body as {data?: unknown}).data)) return [];
  return (body as {data: unknown[]}).data.flatMap(entry => {
    if (!entry || typeof entry !== "object") return [];
    const model = entry as SurplusCatalogModel;
    if (markets && (typeof model.id !== "string" || !markets.has(model.id))) return [];
    const mapped = mapSurplusModel(model, markets?.get(model.id as string), prices, policy);
    return mapped ? [mapped] : [];
  });
}

async function request(url: string, apiKey: string | undefined, fetchImpl: typeof fetch): Promise<Response> {
  return fetchImpl(url, {
    method: "GET",
    headers: {...(apiKey ? {Authorization: `Bearer ${apiKey}`} : {}), "Accept-Encoding": "identity"},
    signal: AbortSignal.timeout(15_000),
  });
}

async function fetchProviderPrices(apiKey: string | undefined, fetchImpl: typeof fetch): Promise<SurplusProviderPrices> {
  if (fetchImpl === fetch && cachedProviderPrices && Date.now() - providerPricesAt < PRICE_REFRESH_MS) return cachedProviderPrices;
  const response = await request(PRICES_URL, apiKey, fetchImpl);
  if (!response.ok) throw new Error(`Surplus price matrix request failed (${response.status})`);
  const prices = parseProviderPrices(await response.json());
  if (!prices.size) throw new Error("Surplus returned no provider price rows");
  if (fetchImpl === fetch) {
    cachedProviderPrices = prices;
    providerPricesAt = Date.now();
  }
  return prices;
}

export async function validateSurplusApiKey(apiKey: string, fetchImpl: typeof fetch = fetch): Promise<void> {
  const response = await request(BUYER_URL, apiKey, fetchImpl);
  if (!response.ok) throw new Error(`Surplus API key validation failed (${response.status})`);
}

export async function fetchSurplusAccessPolicy(apiKey: string, fetchImpl: typeof fetch = fetch): Promise<SurplusAccessPolicy> {
  const response = await request(PREFERENCES_URL, apiKey, fetchImpl);
  if (!response.ok) throw new Error(`Surplus key preferences request failed (${response.status})`);
  return parseSurplusAccessPolicy(await response.json());
}

async function fetchCatalogAndMarkets(apiKey: string | undefined, fetchImpl: typeof fetch, policy?: SurplusAccessPolicy): Promise<SurplusProviderModel[]> {
  const [catalogResponse, marketsResponse, prices] = await Promise.all([
    request(CATALOG_URL, apiKey, fetchImpl),
    request(MARKETS_URL, apiKey, fetchImpl),
    fetchProviderPrices(apiKey, fetchImpl),
  ]);
  if (!catalogResponse.ok) throw new Error(`Surplus catalog request failed (${catalogResponse.status})`);
  if (!marketsResponse.ok) throw new Error(`Surplus market request failed (${marketsResponse.status})`);

  const markets = parseSurplusMarkets(await marketsResponse.json());
  if (!markets.size) throw new Error("Surplus returned no routable markets");
  const models = parseSurplusCatalog(await catalogResponse.json(), markets, prices, policy);
  if (!models.length) throw new Error("Surplus returned no accessible chat models");
  return models;
}

export async function fetchPublicSurplusModels(fetchImpl: typeof fetch = fetch, policy?: SurplusAccessPolicy): Promise<SurplusProviderModel[]> {
  return fetchCatalogAndMarkets(undefined, fetchImpl, policy);
}

export async function fetchSurplusModels(apiKey: string | undefined, fetchImpl: typeof fetch = fetch,
  policy?: SurplusAccessPolicy): Promise<SurplusProviderModel[]> {
  if (!apiKey?.trim()) return [];
  await validateSurplusApiKey(apiKey, fetchImpl);
  return fetchCatalogAndMarkets(apiKey, fetchImpl, policy);
}
