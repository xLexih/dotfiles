import {describe, expect, it} from "bun:test";
import {
	buildZenRouterModel,
	familyForId,
	getZenRouterDescriptor,
	isResponsesModel,
	parseZenRouterModels,
	staticZenRouterModels,
	ZEN_ROUTER_BASE_URL,
	ZEN_ROUTER_MODELS,
} from "../src/catalog.ts";

describe("zen-router catalog", () => {
	it("falls back to the eight documented free entries", () => {
		expect(ZEN_ROUTER_MODELS.map(d => d.id)).toEqual([
			"muse-spark-1.3-contributor-free",
			"muse-spark-1.2-contributor-free",
			"mimo-v2.5-free",
			"ling-3.0-flash-fin-free",
			"nemotron-3-ultra-free",
			"nemotron-3.5-lightning-free",
			"deepseek-v4-flash-free",
			"big-pickle",
		]);
	});

	it("points every built model at the local router with zero cost", () => {
		for (const m of staticZenRouterModels()) {
			expect(m.baseUrl).toBe(ZEN_ROUTER_BASE_URL);
			expect(m.provider).toBe("zen-router");
			expect(m.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
		}
	});

	it("routes only the Muse Spark ids through Responses", () => {
		expect(isResponsesModel("muse-spark-1.3-contributor-free")).toBe(true);
		expect(isResponsesModel("mimo-v2.5-free")).toBe(false);
		expect(familyForId("muse-spark-9-contributor-free")).toBe("openai-responses");
		expect(familyForId("something-new-free")).toBe("openai-completions");
	});

	it("returns undefined for uncurated fallback ids", () => {
		expect(getZenRouterDescriptor("gpt-5.5")).toBeUndefined();
	});

	it("static fallback covers the full fallback list", () => {
		expect(staticZenRouterModels().map(m => m.id)).toEqual(ZEN_ROUTER_MODELS.map(d => d.id));
	});

	it("builds a typed entry preserving the descriptor family", () => {
		const descriptor = getZenRouterDescriptor("mimo-v2.5-free")!;
		const model = buildZenRouterModel(descriptor);
		expect(model.id).toBe("mimo-v2.5-free");
		expect(model.api).toBe("openai-completions");
		expect(model.contextWindow).toBe(1_000_000);
	});
});

describe("parseZenRouterModels", () => {
	it("maps router-annotated entries preserving live order", () => {
		const models = parseZenRouterModels({
			data: [
				{id: "mimo-v2.5-free", family: "chat", endpoint: "/v1/chat/completions"},
				{id: "gpt-5-paid", family: "chat", endpoint: "/v1/chat/completions"},
				{id: "muse-spark-1.3-contributor-free", family: "responses", endpoint: "/v1/responses"},
			],
		});
		// Paid ids pass through here (the router already filters to free);
		// unknown ids are synthesized from the annotation.
		expect(models.map(m => [m.id, m.api])).toEqual([
			["mimo-v2.5-free", "openai-completions"],
			["gpt-5-paid", "openai-completions"],
			["muse-spark-1.3-contributor-free", "openai-responses"],
		]);
	});

	it("learns synthesized families for stream dispatch", () => {
		parseZenRouterModels({data: [{id: "brand-new-free", family: "responses"}]});
		expect(isResponsesModel("brand-new-free")).toBe(true);
	});

	it("de-duplicates repeated ids and rejects malformed payloads", () => {
		expect(parseZenRouterModels({data: [{id: "mimo-v2.5-free"}, {id: "mimo-v2.5-free"}]}).map(m => m.id)).toEqual([
			"mimo-v2.5-free",
		]);
		expect(parseZenRouterModels(null)).toEqual([]);
		expect(parseZenRouterModels({})).toEqual([]);
		expect(parseZenRouterModels({data: "nope"})).toEqual([]);
	});
});
