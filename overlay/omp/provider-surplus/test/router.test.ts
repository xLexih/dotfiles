import {describe, expect, it} from "bun:test";
import type {Context} from "@oh-my-pi/pi-ai";
import type {SurplusProviderModel} from "../src/catalog.ts";
import {approvedRouteRestored, cheapAliasLabel, CHEAP_TRUSTED_MODEL_ID, CHEAP_UNTRUSTED_MODEL_ID, CONTINUE_WITH_MODEL, createCheapModels, estimateInputTokens, pinSurplusProvider, resolveSurplusModel, routeAfterChoice, routeRequiresApproval, selectCheapestRoute, selectCheapestRoutes, surplusModelLabel, updateRoutingProfile} from "../src/router.ts";

const candidate = (id: string, input: number, output: number, overrides: Partial<SurplusProviderModel> = {}): SurplusProviderModel => ({
  id,
  name: id,
  reasoning: false,
  input: ["text"],
  cost: {input, output, cacheRead: 0, cacheWrite: 0},
  contextWindow: 128_000,
  maxTokens: 16_384,
  compat: {supportsDeveloperRole: true, supportsReasoningEffort: false, maxTokensField: "max_tokens"},
  supportsTools: true,
  routes: [{provider: `${id}-trusted`, trusted: true, input, output, cacheRead: input, cacheWrite: input}],
  ...overrides,
});

const context = (text = "hello"): Context => ({messages: [{role: "user", content: text, timestamp: 0}]});

describe("Surplus cheapest routing", () => {
  it("orders non-dominated routes using exact observed usage", () => {
    const deepseek = candidate("deepseek", 0.003996, 0.008991, {contextWindow: 1_000_000, cost: {input: 0.003996, output: 0.008991, cacheRead: 0.0007992, cacheWrite: 0.003996},
      routes: [{provider: "deepseek-trusted", trusted: true, input: 0.003996, output: 0.008991, cacheRead: 0.0007992, cacheWrite: 0.003996}]});
    const luna = candidate("luna", 0.004, 0.023998, {contextWindow: 1_000_000, cost: {input: 0.004, output: 0.023998, cacheRead: 0.0004, cacheWrite: 0.005},
      routes: [{provider: "luna-trusted", trusted: true, input: 0.004, output: 0.023998, cacheRead: 0.0004, cacheWrite: 0.005}]});
    const usage = {input: 35_000, output: 310, cacheRead: 65_000, cacheWrite: 0};
    expect(selectCheapestRoute([deepseek, luna], CHEAP_TRUSTED_MODEL_ID, context("x".repeat(400_000)), undefined, usage)?.model.id).toBe("luna");
  });

  it("keeps only routes that are not dominated across input, output, and cache prices", () => {
    const balanced = candidate("balanced", 1, 1);
    const outputCheap = candidate("output-cheap", 2, 0.5);
    const dominated = candidate("dominated", 2, 2);
    expect(selectCheapestRoutes([balanced, outputCheap, dominated], CHEAP_TRUSTED_MODEL_ID, context()).map(value => value.model.id)).toEqual(["balanced", "output-cheap"]);
  });

  it("uses exact successful usage without seeded ratios or smoothing", () => {
    const next = updateRoutingProfile({input: 100, output: 10, cacheRead: 900, cacheWrite: 5, totalTokens: 1015, cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0}});
    expect(next).toEqual({input: 100, output: 10, cacheRead: 900, cacheWrite: 5});
  });

  it("filters candidates by tools, vision, context, and output capacity", () => {
    const cheap = candidate("cheap", 0, 0, {supportsTools: false, contextWindow: 100, maxTokens: 32});
    const viable = candidate("viable", 1, 1, {input: ["text", "image"]});
    const request = {
      messages: [{role: "user", content: [{type: "image", data: "abc", mimeType: "image/png"}], timestamp: 0}],
      tools: [{name: "read", description: "read", parameters: {type: "object", properties: {}}}],
    } as Context;
    expect(selectCheapestRoute([cheap, viable], CHEAP_TRUSTED_MODEL_ID, request, {maxTokens: 1024})?.model.id).toBe("viable");
    expect(estimateInputTokens(request)).toBeGreaterThan(0);
  });

  it("uses stable tie-breaking and creates both synthetic aliases", () => {
    const models = [candidate("z-model", 1, 1), candidate("a-model", 1, 1)];
    expect(selectCheapestRoute(models, CHEAP_TRUSTED_MODEL_ID, context())?.model.id).toBe("a-model");
    expect(createCheapModels(models).map(({id, name}) => ({id, name}))).toEqual([
      {id: CHEAP_TRUSTED_MODEL_ID, name: "Surplus → Cheapest[T] → a-model"},
      {id: CHEAP_UNTRUSTED_MODEL_ID, name: "Surplus → Cheapest[T] → a-model"},
    ]);
    expect(cheapAliasLabel(CHEAP_TRUSTED_MODEL_ID, true)).toBe("Cheapest[T]");
    expect(cheapAliasLabel(CHEAP_UNTRUSTED_MODEL_ID, false)).toBe("Cheapest['T]");
    expect(surplusModelLabel(models[0]!, CHEAP_TRUSTED_MODEL_ID)).toBe("Surplus → Cheapest[T] → z-model");
    expect(surplusModelLabel(models[0]!, CHEAP_UNTRUSTED_MODEL_ID, false)).toBe("Surplus → Cheapest['T] → z-model");
    expect(surplusModelLabel({...models[0]!, name: "Surplus → Z Model"})).toBe("Surplus → Z Model");
  });

  it("keeps untrusted routes out of cheap-trusted but allows them in cheap-untrusted", () => {
    const model = candidate("luna", 1, 1, {routes: [
      {provider: "trusted", trusted: true, input: 1, output: 1, cacheRead: 1, cacheWrite: 1},
      {provider: "untrusted", trusted: false, input: 0.1, output: 0.1, cacheRead: 0.1, cacheWrite: 0.1},
    ]});
    expect(selectCheapestRoute([model], CHEAP_TRUSTED_MODEL_ID, context())?.route.provider).toBe("trusted");
    expect(selectCheapestRoute([model], CHEAP_UNTRUSTED_MODEL_ID, context())?.route.provider).toBe("untrusted");
    expect(createCheapModels([model]).map(({name}) => name)).toEqual([
      "Surplus → Cheapest[T] → luna",
      "Surplus → Cheapest['T] → luna",
    ]);
  });

  it("requires approval for route switches and price increases, but not decreases", () => {
    const model = candidate("luna", 1, 1);
    const current = {model, route: model.routes[0]!, score: 1};
    expect(routeRequiresApproval(current, {...current, route: {...current.route, input: 0.9}, score: 0.9})).toBe(false);
    expect(routeRequiresApproval(current, {...current, route: {...current.route, output: 1.1}, score: 1.1})).toBe(true);
    expect(routeRequiresApproval(current, {...current, route: {...current.route, cacheRead: 1.1}, score: 1.1})).toBe(true);
    expect(routeRequiresApproval(current, {...current, route: {...current.route, provider: "other"}})).toBe(true);
    expect(routeRequiresApproval(current, {...current, model: {...model, id: "other"}})).toBe(true);
  });

  it("can continue with the previously approved model/provider", () => {
    const previousModel = candidate("terra", 0.02, 0.12);
    const nextModel = candidate("grok", 0.4, 0.8);
    const previous = {model: previousModel, route: previousModel.routes[0]!, score: 1};
    const next = {model: nextModel, route: nextModel.routes[0]!, score: 2};
    expect(routeAfterChoice(CONTINUE_WITH_MODEL, previous, next)).toBe(previous);
    expect(routeAfterChoice("Switch once", previous, next)).toBe(next);
  });

  it("waits for the approved route and all component prices to be restored", () => {
    const model = candidate("luna", 1, 1);
    const current = {model, route: model.routes[0]!, score: 1};
    expect(approvedRouteRestored(current, {...current, route: {...current.route, input: 0.9, output: 1}})).toBe(true);
    expect(approvedRouteRestored(current, {...current, route: {...current.route, input: 0.9, output: 1.1}})).toBe(false);
    expect(approvedRouteRestored(current, {...current, route: {...current.route, cacheWrite: 1.1}})).toBe(false);
    expect(approvedRouteRestored(current, {...current, route: {...current.route, provider: "other", input: 0.5, output: 0.5}})).toBe(false);
  });

  it("pins the approved provider in the outgoing payload and preserves hooks", () => {
    let observed: unknown;
    const payload: Record<string, unknown> = {model: "luna"};
    const options = pinSurplusProvider({onPayload: value => { observed = value; }}, "inferhub");
    options.onPayload?.(payload);
    expect(payload.provider).toBe("inferhub");
    expect(observed).toBe(payload);
  });

  it("returns no route when no model can satisfy the request", () => {
    expect(selectCheapestRoute([candidate("tiny", 0, 0, {maxTokens: 8})], CHEAP_TRUSTED_MODEL_ID, context(), {maxTokens: 1024})).toBeUndefined();
  });

  it("routes only the synthetic alias and preserves explicit concrete selections", () => {
    const cheap = candidate("cheap", 0.1, 0.1);
    const explicit = candidate("explicit", 10, 10);
    const concrete = resolveSurplusModel({...explicit, provider: "surplus", api: "surplus-cheapest", baseUrl: "https://example.test"} as never, [cheap, explicit], context());
    expect(concrete.model.id).toBe("explicit");
    expect(concrete.model.api).toBe("openai-completions");
    const alias = {...createCheapModels([cheap, explicit])[0], provider: "surplus", api: "surplus-cheapest", baseUrl: "https://example.test"} as never;
    const routed = resolveSurplusModel(alias, [cheap, explicit], context());
    expect(routed.model.id).toBe("cheap");
    expect(routed.selected?.route.provider).toBe("cheap-trusted");
  });
});
