import {describe, expect, it} from "bun:test";
import {applySurplusAccessPolicy, extendSurplusAccessPolicy, fetchPublicSurplusModels, fetchSurplusAccessPolicy, fetchSurplusModels, mapSurplusModel, parseProviderPrices, parseSurplusAccessPolicy, parseSurplusCatalog, parseSurplusMarkets, validateSurplusApiKey} from "../src/catalog.ts";

const model = {
  id: "reasoning-vision",
  name: "Reasoning Vision",
  context_length: 256_000,
  architecture: {input_modalities: ["text", "image"], output_modalities: ["text"]},
  pricing: {prompt: "0.000002", completion: "0.000006", input_cache_read: "0.0000002", input_cache_write: "0.000001"},
  top_provider: {max_completion_tokens: 32_000},
  supported_parameters: ["reasoning_effort", "max_tokens"],
  supported_features: ["reasoning"],
};
const market = {model: model.id, catalog_only: false, best_input_per_1m: 0.5, best_output_per_1m: 2, direct_input_per_1m: 2, healthy_seller_count: 3,
  providerBreakdown: [
    {provider: "trusted-host", trusted: true, best_input_per_1m: 0.75, best_output_per_1m: 2.5, healthy_seller_count: 1},
    {provider: "wild-host", trusted: false, best_input_per_1m: 0.5, best_output_per_1m: 2, healthy_seller_count: 2},
  ]};
const priceMatrix = {models: [{model: model.id, providers: [{provider: "trusted-host", pricing: {input: 3, output: 9, cacheRead: 0.6, cacheWrite: 3.75}}]}]};
const json = (body: unknown, status = 200): Response => new Response(JSON.stringify(body), {status, headers: {"Content-Type": "application/json"}});

describe("Surplus model mapping", () => {
  it("uses the best live price and scales cache prices by its discount", () => {
    const mapped = mapSurplusModel(model, market);
    expect(mapped?.name).toBe("Surplus → Reasoning Vision");
    expect(mapped?.cost).toEqual({input: 0.5, output: 2, cacheRead: 0.05, cacheWrite: 0.25});
    expect(mapped?.input).toEqual(["text", "image"]);
    expect(mapped?.reasoning).toBe(true);
    expect(mapped?.compat).toEqual({supportsDeveloperRole: true, supportsReasoningEffort: true, maxTokensField: "max_tokens"});
    expect(mapped?.routes).toEqual([
      {provider: "trusted-host", trusted: true, input: 0.75, output: 2.5, cacheRead: 0.075, cacheWrite: 0.375},
      {provider: "wild-host", trusted: false, input: 0.5, output: 2, cacheRead: 0.05, cacheWrite: 0.25},
    ]);
  });

  it("uses fetched provider-specific cache prices", () => {
    const prices = parseProviderPrices({models: [{model: model.id, providers: [
      {provider: "trusted-host", pricing: {input: 3, output: 9, cacheRead: 0.6, cacheWrite: 3.75}},
    ]}]});
    expect(mapSurplusModel(model, market, prices)?.routes[0]).toEqual({
      provider: "trusted-host", trusted: true, input: 0.75, output: 2.5, cacheRead: 0.15, cacheWrite: 0.9375,
    });
  });

  it("filters malformed, non-chat, catalog-only, and unhealthy models", () => {
    const markets = parseSurplusMarkets([
      market,
      {...market, model: "catalog-only", catalog_only: true},
      {...market, model: "unhealthy", healthy_seller_count: 0},
      {...market, model: "bad-price", best_input_per_1m: null},
    ]);
    expect([...markets.keys()]).toEqual([model.id]);
    expect(parseSurplusCatalog({data: [model, {id: "video", architecture: {input_modalities: ["video"], output_modalities: ["video"]}}]}, markets).map(({id}) => id)).toEqual([model.id]);
  });

  it("falls back to live input pricing when cache pricing is unavailable", () => {
    const mapped = mapSurplusModel({...model, pricing: {prompt: model.pricing.prompt, completion: model.pricing.completion}}, market);
    expect(mapped?.cost.cacheRead).toBe(0.5);
    expect(mapped?.cost.cacheWrite).toBe(0.5);
  });

  it("filters providers blocked by the authenticated key", () => {
    const policy = parseSurplusAccessPolicy({preferences: {allow_untrusted: true}, limits: {providers_blocked: ["https://api.wild-host.ai/v1"]}});
    const mapped = mapSurplusModel(model, market, undefined, policy);
    expect(policy.allowUntrusted).toBe(true);
    expect([...policy.blockedProviders]).toEqual(["wild-host"]);
    expect(mapped?.routes.map(route => route.provider)).toEqual(["trusted-host"]);
  });

  it("honors trusted-only effective key access", () => {
    const policy = parseSurplusAccessPolicy({preferences: {allow_untrusted: false}});
    expect(mapSurplusModel(model, market, undefined, policy)?.routes.map(route => route.provider)).toEqual(["trusted-host"]);
  });

  it("merges configured endpoint blocks and applies them to cached models", () => {
    const policy = extendSurplusAccessPolicy(parseSurplusAccessPolicy({}), ["api.jatevo.ai", "lb.jatevo.ai"]);
    const mapped = mapSurplusModel(model, market)!;
    mapped.routes[1]!.provider = "Jatevo";
    expect([...policy.blockedProviders]).toEqual(["jatevo", "lb"]);
    expect(applySurplusAccessPolicy([mapped], policy)[0]?.routes.map(route => route.provider)).toEqual(["trusted-host"]);
  });
});

describe("Surplus discovery", () => {
  it("validates the key and intersects the catalog with live markets", async () => {
    const urls: string[] = [];
    const fetchMock = (async input => {
      const url = String(input);
      urls.push(url);
      if (url.endsWith("/v1/buyer/me")) return json({balance_usdc: "1"});
      if (url.endsWith("/v1/buyer/preferences")) return json({preferences: {allow_untrusted: true}, limits: {}});
      if (url.endsWith("/v1/models")) return json({data: [model, {...model, id: "not-routable"}]});
      if (url.endsWith("/v1/prices")) return json(priceMatrix);
      return json([market]);
    }) as typeof fetch;
    const models = await fetchSurplusModels("inf_test", fetchMock);
    expect(models.map(({id}) => id)).toEqual([model.id]);
    expect(models[0]?.cost.input).toBe(0.5);
    expect(urls).toContain("https://api.surplusintelligence.ai/v1/buyer/me");
    expect(urls).toContain("https://www.surplusintelligence.ai/api/inference/markets");
  });

  it("fetches effective access policy from the authenticated key", async () => {
    const policy = await fetchSurplusAccessPolicy("inf_test", (async () => json({
      preferences: {allow_untrusted: true},
      preferences_key: {providersBlocked: ["Jatevo"]},
    })) as typeof fetch);
    expect(policy.allowUntrusted).toBe(true);
    expect([...policy.blockedProviders]).toEqual(["jatevo"]);
  });

  it("returns no models without credentials and rejects invalid credentials", async () => {
    expect(await fetchSurplusModels(undefined)).toEqual([]);
    await expect(validateSurplusApiKey("bad", (async () => json({}, 401)) as typeof fetch)).rejects.toThrow("(401)");
  });

  it("refreshes public prices without sending an authorization header", async () => {
    const headers: HeadersInit[] = [];
    const fetchMock = (async (input, init) => {
      headers.push(init?.headers ?? {});
      if (String(input).endsWith("/models")) return json({data: [model]});
      if (String(input).endsWith("/prices")) return json(priceMatrix);
      return json([market]);
    }) as typeof fetch;
    expect((await fetchPublicSurplusModels(fetchMock)).map(({id}) => id)).toEqual([model.id]);
    expect(headers.every(value => !("Authorization" in value))).toBe(true);
  });

  it("fails closed so OMP can retain its last good cached catalog", async () => {
    const fetchMock = (async input => String(input).includes("/markets") ? json({}, 503) : String(input).endsWith("/models") ? json({data: [model]}) : json(priceMatrix)) as typeof fetch;
    await expect(fetchSurplusModels("inf_test", fetchMock)).rejects.toThrow("market request failed (503)");
  });
});
