import {describe, expect, it} from "bun:test";
import {BROKER_MODELS_URL, fetchBrokerModels, parseBrokerModels, validateOpenBrokerApiKey} from "../src/catalog.ts";

const json = (body: unknown, status = 200): Response => new Response(JSON.stringify(body), {status, headers: {"Content-Type": "application/json"}});

describe("OpenBroker catalog", () => {
  it("discovers new models without retaining models absent from the broker", () => {
    const models = parseBrokerModels({data: [
      {id: "vendor/new-model", name: "New Model", context_length: 131_072, max_output_length: 32_768, input_modalities: ["text"], output_modalities: ["text"], supported_features: ["reasoning", "tools"]},
    ]});
    expect(models.map(model => model.id)).toEqual(["vendor/new-model"]);
    expect(models[0]).toMatchObject({name: "New Model", reasoning: true, contextWindow: 131_072, maxTokens: 32_768});
  });

  it("uses broker metadata without model-specific overrides or fabricated USD costs", () => {
    const [model] = parseBrokerModels({data: [{id: "deepseek-ai/DeepSeek-V4-Flash-0731", context_length: 400_000, max_output_length: 16_384, input_modalities: ["text", "image", "audio", "image"], supported_features: ["tools"], pricing: {input: 0.2}}]});
    expect(model).toEqual({
      id: "deepseek-ai/DeepSeek-V4-Flash-0731", name: "deepseek-ai/DeepSeek-V4-Flash-0731",
      contextWindow: 400_000, maxTokens: 16_384, reasoning: false, input: ["text", "image"],
      cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
    });
  });

  it("rejects malformed catalogs, invalid limits, and non-chat models", () => {
    for (const body of [null, [], {}, {data: null}, {data: {}}]) expect(parseBrokerModels(body)).toEqual([]);
    const valid = {id: "vendor/model", context_length: 1000, max_output_length: 100};
    expect(parseBrokerModels({data: [
      null, [], "model", {...valid, id: " "}, {...valid, id: 1},
      ...[0, -1, 1.5, Infinity, Number.MAX_SAFE_INTEGER + 1, "100", null].flatMap(limit => [
        {...valid, context_length: limit}, {...valid, max_output_length: limit},
      ]),
      {...valid, output_modalities: ["embeddings"]}, {...valid, output_modalities: "text"},
      {...valid, input_modalities: ["audio"]}, {...valid, input_modalities: null},
    ]})).toEqual([]);
  });

  it("deduplicates valid models without letting invalid duplicates overwrite them", () => {
    const models = parseBrokerModels({data: [
      {id: "MiniMaxAI/MiniMax-M2.7", context_length: 204_800, max_output_length: 16_384},
      {id: "moonshotai/Kimi-K2.6", context_length: 262_144, max_output_length: 8_192},
      {id: "deepseek-ai/DeepSeek-V4-Flash-0731", context_length: 400_000, max_output_length: 16_384},
      {id: "unknown/model", context_length: 1, max_output_length: 1},
      {id: "moonshotai/Kimi-K2.6", context_length: -1, max_output_length: 0},
    ]});
    expect(models.map(model => [model.id, model.contextWindow, model.maxTokens])).toEqual([
      ["MiniMaxAI/MiniMax-M2.7", 204_800, 16_384],
      ["moonshotai/Kimi-K2.6", 262_144, 8_192],
      ["deepseek-ai/DeepSeek-V4-Flash-0731", 400_000, 16_384],
      ["unknown/model", 1, 1],
    ]);
  });

  it("rejects failed, empty, and malformed discovery responses without a static fallback", async () => {
    await expect(fetchBrokerModels((async () => json({}, 503)) as typeof fetch)).rejects.toThrow("(503)");
    for (const body of [{data: []}, {}, {data: [{id: "incomplete"}]}]) {
      await expect(fetchBrokerModels((async () => json(body)) as typeof fetch)).rejects.toThrow("no usable chat models");
    }
    await expect(fetchBrokerModels((async () => new Response("not json")) as typeof fetch)).rejects.toThrow();
    await expect(fetchBrokerModels((async () => { throw new Error("network unavailable"); }) as typeof fetch)).rejects.toThrow("network unavailable");
  });

  it("discovers models from the public broker endpoint", async () => {
    let request: Request | undefined;
    const models = await fetchBrokerModels((async (input: RequestInfo | URL, init?: RequestInit) => {
      request = new Request(input, init);
      return json({data: [{id: "MiniMaxAI/MiniMax-M2.7", context_length: 200_000, max_output_length: 12_000}]});
    }) as typeof fetch);
    expect(request?.url).toBe(BROKER_MODELS_URL);
    expect(request?.headers.has("Authorization")).toBe(false);
    expect(models).toHaveLength(1);
    expect(models.find(model => model.id === "MiniMaxAI/MiniMax-M2.7")).toMatchObject({contextWindow: 200_000, maxTokens: 12_000});
  });
});

describe("OpenBroker API key validation", () => {
  it("uses the documented bearer-authenticated balance endpoint", async () => {
    let request: Request | undefined;
    const fetchMock = (async (input: RequestInfo | URL, init?: RequestInit) => {
      request = new Request(input, init);
      return json({status: "active"});
    }) as typeof fetch;
    await expect(validateOpenBrokerApiKey("obk_test", fetchMock)).resolves.toBeUndefined();
    expect(request?.url).toBe("https://api.openbroker.gonka.gg/v1/balance");
    expect(request?.headers.get("Authorization")).toBe("Bearer obk_test");
  });

  it("rejects invalid credentials", async () => {
    await expect(validateOpenBrokerApiKey("bad", (async () => json({}, 401)) as typeof fetch)).rejects.toThrow("(401)");
  });
});
