import {describe, expect, it} from "bun:test";
import {
  BROKER_MODELS_URL,
  CHAIN_MODELS_URL,
  fetchBrokerModels,
  mergeBrokerModels,
  OPENBROKER_BASE_URL,
  parseBrokerModels,
  parseChainModels,
  validateOpenBrokerApiKey,
  type BrokerModel,
} from "../src/catalog.ts";

const json = (body: unknown, status = 200): Response =>
  new Response(JSON.stringify(body), {status, headers: {"Content-Type": "application/json"}});

const brokerBody = (ids: string[]) => ({data: ids.map(id => ({id}))});
const chainBody = (models: unknown[]) => ({model: models});
const chainModel = (id: string, args: string[]) => ({id, model_args: args});
const broker = (id: string): BrokerModel => ({id, name: id, input: ["text"]});

const route = (
  brokerResponse: () => Promise<Response>,
  chainResponse: () => Promise<Response>,
): typeof fetch =>
  (async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = new Request(input, init).url;
    if (url === BROKER_MODELS_URL) return brokerResponse();
    if (url === CHAIN_MODELS_URL) return chainResponse();
    throw new Error(`unexpected request ${url}`);
  }) as typeof fetch;

describe("OpenBroker catalog", () => {
  it("points at the broker API and the chain serving catalog", () => {
    expect(OPENBROKER_BASE_URL).toBe("https://api.openbroker.gonka.gg/v1");
    expect(BROKER_MODELS_URL).toBe("https://api.openbroker.gonka.gg/v1/models");
    expect(CHAIN_MODELS_URL).toBe(
      "https://rpc.gonka.gg/chain-api/productscience/inference/inference/models_all",
    );
  });

  it("parses broker availability without inventing limits", () => {
    const models = parseBrokerModels({data: [
      {id: "vendor/new-model", name: "New Model", context_length: 131_072, max_output_length: 32_768, input_modalities: ["text", "image", "audio", "image"], output_modalities: ["text"]},
      {id: "vendor/new-model", name: "Duplicate"},
      {id: "vendor/image-only", input_modalities: ["image"]},
      {id: "vendor/video", output_modalities: ["video"]},
      {id: "vendor/bad-input", input_modalities: "text"},
      {id: " "},
      {id: 1},
      null,
    ]});
    expect(models).toEqual([
      {id: "vendor/new-model", name: "New Model", input: ["text", "image"]},
    ]);
  });

  it("returns no broker models for malformed catalog bodies", () => {
    for (const body of [null, [], {}, {data: null}, {data: {}}]) expect(parseBrokerModels(body)).toEqual([]);
  });

  it("parses serving args from the chain catalog", () => {
    const chain = parseChainModels(chainBody([
      chainModel("MiniMaxAI/MiniMax-M2.7", ["--max-model-len", "180000", "--reasoning-parser", "minimax_m2_append_think", "--tool-call-parser", "minimax_m2"]),
      chainModel("deepseek-ai/DeepSeek-V4-Flash-0731", ["--max-model-len=400000", "--reasoning-parser=deepseek_v4"]),
      chainModel("broken-len", ["--max-model-len", "--reasoning-parser", "glm45"]),
      chainModel("no-len", ["--tool-call-parser", "kimi_k2"]),
      chainModel("bad-len", ["--max-model-len", "1.5"]),
      {id: "bad-args", model_args: "--max-model-len 1000"},
      {id: "duplicate", model_args: ["--max-model-len", "1"]},
      {id: "duplicate", model_args: ["--max-model-len", "2"]},
    ]));

    expect(chain.get("MiniMaxAI/MiniMax-M2.7")).toEqual({
      id: "MiniMaxAI/MiniMax-M2.7",
      maxModelLen: 180_000,
      maxModelLenRaw: "180000",
      reasoningParser: "minimax_m2_append_think",
      toolCallParser: "minimax_m2",
    });
    expect(chain.get("deepseek-ai/DeepSeek-V4-Flash-0731")).toEqual({
      id: "deepseek-ai/DeepSeek-V4-Flash-0731",
      maxModelLen: 400_000,
      maxModelLenRaw: "400000",
      reasoningParser: "deepseek_v4",
      toolCallParser: undefined,
    });
    expect(chain.get("broken-len")).toMatchObject({maxModelLen: undefined, reasoningParser: "glm45"});
    expect(chain.get("no-len")).toMatchObject({maxModelLen: undefined, reasoningParser: undefined, toolCallParser: "kimi_k2"});
    expect(chain.get("bad-len")).toMatchObject({maxModelLen: undefined, maxModelLenRaw: "1.5"});
    expect(chain.get("bad-args")).toMatchObject({maxModelLen: undefined, reasoningParser: undefined});
    expect(chain.get("duplicate")?.maxModelLen).toBe(1);
  });

  it("merges chain limits and parser profiles into active broker models", () => {
    const entries = mergeBrokerModels(parseBrokerModels(brokerBody([
      "MiniMaxAI/MiniMax-M2.7",
      "deepseek-ai/DeepSeek-V4-Flash-0731",
      "zai-org/GLM-5.3-Flash",
      "moonshotai/Kimi-K2.6",
    ])), parseChainModels(chainBody([
      chainModel("MiniMaxAI/MiniMax-M2.7", ["--max-model-len", "180000", "--reasoning-parser", "minimax_m2_append_think"]),
      chainModel("deepseek-ai/DeepSeek-V4-Flash-0731", ["--max-model-len", "400000", "--reasoning-parser", "deepseek_v4"]),
      chainModel("zai-org/GLM-5.3-Flash", ["--max-model-len", "400000", "--reasoning-parser", "glm45"]),
      chainModel("moonshotai/Kimi-K2.6", ["--max-model-len", "240000", "--reasoning-parser", "kimi_k2"]),
    ])));

    expect(entries.map(entry => [entry.model.id, entry.model.contextWindow, entry.model.reasoning])).toEqual([
      ["MiniMaxAI/MiniMax-M2.7", 180_000, false],
      ["deepseek-ai/DeepSeek-V4-Flash-0731", 400_000, true],
      ["zai-org/GLM-5.3-Flash", 400_000, true],
      ["moonshotai/Kimi-K2.6", 240_000, true],
    ]);
    for (const entry of entries) {
      expect(entry.model).toMatchObject({
        maxTokens: 16_384,
        omitMaxOutputTokens: true,
        cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
      });
    }
    expect(entries[0]?.profile).toMatchObject({cumulativeDeltas: true, omitEffort: true, strictContent: true});
    expect(entries[1]?.profile).toMatchObject({
      disableMode: "none-effort",
      idleTimeoutMs: 300_000,
      thinking: {efforts: ["low", "high", "max"], defaultLevel: "high"},
    });
    expect(entries[2]?.profile).toMatchObject({
      disableMode: "lowest-effort",
      thinking: {efforts: ["low", "high", "max"], defaultLevel: "max"},
    });
    expect(entries[3]?.profile).toMatchObject({
      disableMode: "lowest-effort",
      idleTimeoutMs: 300_000,
      markupHealing: "kimi",
      toolSchemaFlavor: "moonshot-mfjs",
      disableReasoningOnForcedToolChoice: true,
      thinking: {defaultLevel: "high"},
    });
  });

  it("treats an absent reasoning parser as a valid non-reasoning model", () => {
    const [entry] = mergeBrokerModels([broker("plain")], parseChainModels(chainBody([
      chainModel("plain", ["--max-model-len", "1000"]),
    ])));
    expect(entry?.model.reasoning).toBe(false);
    expect(entry?.model.thinking).toBeUndefined();
    expect(entry?.profile).toMatchObject({reasoning: false, omitEffort: true, strictContent: false});
  });

  it("fails when a live broker id is missing from serving metadata", () => {
    expect(() => mergeBrokerModels([broker("vendor/a"), broker("vendor/b")], new Map())).toThrow(
      "OpenBroker serving metadata is missing: vendor/a, vendor/b",
    );
  });

  it("fails when --max-model-len is missing or invalid", () => {
    expect(() => mergeBrokerModels([broker("plain")], parseChainModels(chainBody([
      chainModel("plain", ["--reasoning-parser", "glm45"]),
    ])))).toThrow("has missing --max-model-len");
    expect(() => mergeBrokerModels([broker("plain")], parseChainModels(chainBody([
      chainModel("plain", ["--max-model-len", "0"]),
    ])))).toThrow('has invalid --max-model-len "0"');
  });

  it("does not fall back to rich broker limits", () => {
    expect(() => mergeBrokerModels(
      [{id: "plain", name: "plain", input: ["text"], context_length: 100_000, max_output_length: 4_000} as BrokerModel],
      parseChainModels(chainBody([chainModel("plain", ["--tool-call-parser", "glm47"])])),
    )).toThrow("has missing --max-model-len");
  });

  it("fails on an unknown reasoning parser instead of guessing", () => {
    expect(() => mergeBrokerModels([broker("future")], parseChainModels(chainBody([
      chainModel("future", ["--max-model-len", "1000", "--reasoning-parser", "future_parser"]),
    ])))).toThrow("Unknown OpenBroker reasoning parser: future_parser");
  });

  it("rejects an empty broker catalog", () => {
    expect(() => mergeBrokerModels([], new Map())).toThrow("OpenBroker returned no chat models");
  });

  it("fetches broker availability and chain metadata in parallel", async () => {
    let started = 0;
    let release!: () => void;
    const gate = new Promise<void>(resolve => {
      release = resolve;
    });
    const fetchMock = (async (input: RequestInfo | URL, init?: RequestInit) => {
      started += 1;
      if (started === 2) release();
      await gate;
      const url = new Request(input, init).url;
      return url === BROKER_MODELS_URL
        ? json(brokerBody(["MiniMaxAI/MiniMax-M2.7"]))
        : json(chainBody([chainModel("MiniMaxAI/MiniMax-M2.7", ["--max-model-len", "180000"])]));
    }) as typeof fetch;

    let timer: ReturnType<typeof setTimeout>;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(() => reject(new Error("requests were not parallel")), 1_000);
    });
    const entries = await Promise.race([fetchBrokerModels(fetchMock), timeout]);
    clearTimeout(timer!);
    expect(started).toBe(2);
    expect(entries[0]?.model.contextWindow).toBe(180_000);
  });

  it("fetches both endpoints without credentials", async () => {
    const requests: Request[] = [];
    const fetchMock = (async (input: RequestInfo | URL, init?: RequestInit) => {
      const request = new Request(input, init);
      requests.push(request);
      return request.url === BROKER_MODELS_URL
        ? json(brokerBody(["MiniMaxAI/MiniMax-M2.7"]))
        : json(chainBody([chainModel("MiniMaxAI/MiniMax-M2.7", ["--max-model-len", "180000"])]));
    }) as typeof fetch;
    const entries = await fetchBrokerModels(fetchMock);
    expect(entries.map(entry => entry.model.id)).toEqual(["MiniMaxAI/MiniMax-M2.7"]);
    expect(requests.map(request => request.url).sort()).toEqual([BROKER_MODELS_URL, CHAIN_MODELS_URL].sort());
    expect(requests.every(request => !request.headers.has("Authorization"))).toBe(true);
  });

  it("rejects failed, empty, malformed, and uncorroborated discovery responses", async () => {
    const okBroker = () => Promise.resolve(json(brokerBody(["vendor/model"])));
    const okChain = () => Promise.resolve(json(chainBody([chainModel("vendor/model", ["--max-model-len", "1000"])])));
    await expect(fetchBrokerModels(route(() => Promise.resolve(json({}, 503)), okChain))).rejects.toThrow("(503)");
    await expect(fetchBrokerModels(route(okBroker, () => Promise.resolve(json({}, 500))))).rejects.toThrow("(500)");
    await expect(fetchBrokerModels(route(() => Promise.resolve(json({data: []})), okChain))).rejects.toThrow(
      "no chat models",
    );
    await expect(fetchBrokerModels(route(okBroker, () => Promise.resolve(json(chainBody([])))))).rejects.toThrow(
      "missing: vendor/model",
    );
    await expect(fetchBrokerModels(route(() => Promise.resolve(new Response("not json")), okChain))).rejects.toThrow();
    await expect(fetchBrokerModels(route(okBroker, () => Promise.resolve(new Response("not json"))))).rejects.toThrow();
    await expect(fetchBrokerModels(route(okBroker, () => Promise.reject(new Error("network unavailable"))))).rejects.toThrow(
      "network unavailable",
    );
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
