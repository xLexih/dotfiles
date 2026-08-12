import {describe, expect, it} from "bun:test";
import {fetchSurplusModels, mapSurplusModel, parseSurplusCatalog, parseSurplusMarkets, validateSurplusApiKey} from "../src/catalog.ts";

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
const market = {model: model.id, catalog_only: false, best_input_per_1m: 0.5, best_output_per_1m: 2, direct_input_per_1m: 2, healthy_seller_count: 3};
const json = (body: unknown, status = 200): Response => new Response(JSON.stringify(body), {status, headers: {"Content-Type": "application/json"}});

describe("Surplus model mapping", () => {
  it("uses the best live price and scales cache prices by its discount", () => {
    const mapped = mapSurplusModel(model, market);
    expect(mapped?.cost).toEqual({input: 0.5, output: 2, cacheRead: 0.05, cacheWrite: 0.25});
    expect(mapped?.input).toEqual(["text", "image"]);
    expect(mapped?.reasoning).toBe(true);
    expect(mapped?.compat).toEqual({supportsDeveloperRole: true, supportsReasoningEffort: true, maxTokensField: "max_tokens"});
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
});

describe("Surplus discovery", () => {
  it("validates the key and intersects the catalog with live markets", async () => {
    const urls: string[] = [];
    const fetchMock = (async input => {
      const url = String(input);
      urls.push(url);
      if (url.endsWith("/v1/buyer/me")) return json({balance_usdc: "1"});
      if (url.endsWith("/v1/models")) return json({data: [model, {...model, id: "not-routable"}]});
      return json([market]);
    }) as typeof fetch;
    const models = await fetchSurplusModels("inf_test", fetchMock);
    expect(models.map(({id}) => id)).toEqual([model.id]);
    expect(models[0]?.cost.input).toBe(0.5);
    expect(urls).toContain("https://api.surplusintelligence.ai/v1/buyer/me");
    expect(urls).toContain("https://www.surplusintelligence.ai/api/inference/markets");
  });

  it("returns no models without credentials and rejects invalid credentials", async () => {
    expect(await fetchSurplusModels(undefined)).toEqual([]);
    await expect(validateSurplusApiKey("bad", (async () => json({}, 401)) as typeof fetch)).rejects.toThrow("(401)");
  });

  it("fails closed so OMP can retain its last good cached catalog", async () => {
    const fetchMock = (async input => String(input).includes("/markets") ? json({}, 503) : String(input).endsWith("/models") ? json({data: [model]}) : json({})) as typeof fetch;
    await expect(fetchSurplusModels("inf_test", fetchMock)).rejects.toThrow("market request failed (503)");
  });
});
