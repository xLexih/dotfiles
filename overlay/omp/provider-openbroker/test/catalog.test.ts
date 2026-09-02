import {describe, expect, it} from "bun:test";
import {BROKER_MODELS_URL, fetchBrokerModels, OPENBROKER_MODELS, parseBrokerModels, validateOpenBrokerApiKey} from "../src/catalog.ts";

const json = (body: unknown, status = 200): Response => new Response(JSON.stringify(body), {status, headers: {"Content-Type": "application/json"}});

describe("OpenBroker catalog", () => {
  it("contains only the documented active chat models", () => {
    expect(OPENBROKER_MODELS.map(model => model.id)).toEqual([
      "MiniMaxAI/MiniMax-M2.7",
      "moonshotai/Kimi-K2.6",
      "deepseek-ai/DeepSeek-V4-Flash-0731",
    ]);
  });

  it("uses explicit context limits and no fabricated USD cost", () => {
    expect(OPENBROKER_MODELS.every(model => model.contextWindow > 0 && model.maxTokens > 0)).toBe(true);
    expect(OPENBROKER_MODELS.every(model => Object.values(model.cost).every(cost => cost === 0))).toBe(true);
  });

  it("uses the broker-published context window but a verbosity-braked maxTokens for DeepSeek", () => {
    expect(Object.fromEntries(OPENBROKER_MODELS.map(model => [model.id, [model.contextWindow, model.maxTokens]]))).toEqual({
      "MiniMaxAI/MiniMax-M2.7": [204_800, 16_384],
      "moonshotai/Kimi-K2.6": [262_144, 8_192],
      // DeepSeek's maxTokens is intentionally 4,096 — well below the broker's
      // advertised 16,384 — as a verbosity brake. The model can naturally
      // finish shorter responses; 4k prevents the 12k ramble pattern that
      // combined with the 18.0.6 retry wedge to produce 1260-iteration loops.
      "deepseek-ai/DeepSeek-V4-Flash-0731": [400_000, 4_096],
    });
  });

  it("tags models with high-context warning thresholds and a recommended-for-large-context hint", () => {
    const byId = Object.fromEntries(OPENBROKER_MODELS.map(model => [model.id, model]));
    expect(byId["MiniMaxAI/MiniMax-M2.7"]?.highContextWarnTokens).toBe(150_000);
    expect(byId["MiniMaxAI/MiniMax-M2.7"]?.highContextHint).toBe("acceptable");
    expect(byId["moonshotai/Kimi-K2.6"]?.highContextHint).toBe("preferred");
    expect(byId["deepseek-ai/DeepSeek-V4-Flash-0731"]?.highContextHint).toBe("acceptable");
  });

  it("marks all broker chat models as reasoning-capable", () => {
    expect(OPENBROKER_MODELS.every(model => model.reasoning)).toBe(true);
  });

  it("uses full human-readable model names", () => {
    expect(OPENBROKER_MODELS.map(model => model.name)).toEqual([
      "MiniMax M2.7",
      "Kimi K2.6",
      "DeepSeek V4 Flash 0731",
    ]);
  });

  it("accepts only valid limits for the known model IDs", () => {
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
    ]);
  });

  it("refreshes limits from the public broker endpoint", async () => {
    let request: Request | undefined;
    const models = await fetchBrokerModels((async (input: RequestInfo | URL, init?: RequestInit) => {
      request = new Request(input, init);
      return json({data: [{id: "MiniMaxAI/MiniMax-M2.7", context_length: 200_000, max_output_length: 12_000}]});
    }) as typeof fetch);
    expect(request?.url).toBe(BROKER_MODELS_URL);
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
