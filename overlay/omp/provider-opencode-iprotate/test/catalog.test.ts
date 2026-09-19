import {describe, expect, it} from "bun:test";
import {
	buildIpRotateModel,
	familyForId,
	getIpRotateDescriptor,
	isResponsesModel,
	parseIpRotateModels,
	staticIpRotateModels,
	IPROTATE_BASE_URL,
	IPROTATE_MODELS,
} from "../src/catalog.ts";

describe("iprotate catalog", () => {
	it("falls back to the eight documented free entries", () => {
		expect(IPROTATE_MODELS.map(d => d.id)).toEqual([
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

	it("points every built model at the local gateway with zero cost", () => {
		for (const m of staticIpRotateModels()) {
			expect(m.baseUrl).toBe(IPROTATE_BASE_URL);
			expect(m.provider).toBe("opencode-iprotate");
			expect(m.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
		}
	});

	it("stamps every model with the Zen session header (else 400 MissingSessionID)", () => {
		for (const m of staticIpRotateModels()) {
			expect((m.headers as Record<string, string>)["x-opencode-session"]).toMatch(/^omp-/);
		}
		const parsed = parseIpRotateModels({data: [{id: "brand-new-free"}]});
		expect((parsed[0].headers as Record<string, string>)["x-opencode-session"]).toMatch(/^omp-/);
	});

	it("routes only the Muse Spark ids through Responses", () => {
		expect(isResponsesModel("muse-spark-1.3-contributor-free")).toBe(true);
		expect(isResponsesModel("mimo-v2.5-free")).toBe(false);
		expect(familyForId("muse-spark-9-contributor-free")).toBe("openai-responses");
		expect(familyForId("something-new-free")).toBe("openai-completions");
	});

	it("returns undefined for uncurated fallback ids", () => {
		expect(getIpRotateDescriptor("gpt-5.5")).toBeUndefined();
	});

	it("static fallback covers the full fallback list", () => {
		expect(staticIpRotateModels().map(m => m.id)).toEqual(IPROTATE_MODELS.map(d => d.id));
	});

	it("builds a typed entry preserving the descriptor family", () => {
		const descriptor = getIpRotateDescriptor("mimo-v2.5-free")!;
		const model = buildIpRotateModel(descriptor);
		expect(model.id).toBe("mimo-v2.5-free");
		expect(model.api).toBe("openai-completions");
		expect(model.contextWindow).toBe(1_000_000);
	});
});

describe("parseIpRotateModels", () => {
	it("maps plain OpenAI payloads preserving live order", () => {
		const models = parseIpRotateModels({
			object: "list",
			data: [
				{id: "mimo-v2.5-free", object: "model", owned_by: "opencode"},
				{id: "some-paid-model", object: "model", owned_by: "opencode"},
				{id: "muse-spark-1.3-contributor-free", object: "model", owned_by: "opencode"},
			],
		});
		expect(models.map(m => [m.id, m.api])).toEqual([
			["mimo-v2.5-free", "openai-completions"],
			["some-paid-model", "openai-completions"],
			["muse-spark-1.3-contributor-free", "openai-responses"],
		]);
	});

	it("learns synthesized families for stream dispatch", () => {
		parseIpRotateModels({data: [{id: "brand-new-spark-muse-spark-x"}]});
		expect(isResponsesModel("brand-new-spark-muse-spark-x")).toBe(true);
	});

	it("de-duplicates repeated ids and rejects malformed payloads", () => {
		expect(parseIpRotateModels({data: [{id: "mimo-v2.5-free"}, {id: "mimo-v2.5-free"}]}).map(m => m.id)).toEqual([
			"mimo-v2.5-free",
		]);
		expect(parseIpRotateModels(null)).toEqual([]);
		expect(parseIpRotateModels({})).toEqual([]);
		expect(parseIpRotateModels({data: "nope"})).toEqual([]);
	});
});
