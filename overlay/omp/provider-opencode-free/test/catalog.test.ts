import {describe, expect, it} from "bun:test";
import {
	buildOpencodeFreeModel,
	filterOpencodeFreeIds,
	getOpencodeFreeDescriptor,
	isResponsesModel,
	OPENCODE_FREE_BASE_URL,
	OPENCODE_FREE_MODELS,
	parseOpencodeFreeModels,
	staticOpencodeFreeModels,
} from "../src/catalog.ts";

describe("OpenCode Free catalog", () => {
	it("contains exactly the eight documented free entries", () => {
		expect(OPENCODE_FREE_MODELS.map(m => m.id)).toEqual([
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

	it("routes only the Muse Spark ids through Responses; the rest are chat", () => {
		for (const d of OPENCODE_FREE_MODELS) {
			const expected = d.id.startsWith("muse-spark-") ? "openai-responses" : "openai-completions";
			expect(d.api).toBe(expected);
			expect(isResponsesModel(d.id)).toBe(expected === "openai-responses");
		}
		expect(isResponsesModel("unknown-model")).toBe(false);
	});

	it("uses upstream-card context windows", () => {
		expect(getOpencodeFreeDescriptor("muse-spark-1.3-contributor-free")?.contextWindow).toBe(1_048_576);
		expect(getOpencodeFreeDescriptor("muse-spark-1.2-contributor-free")?.contextWindow).toBe(1_048_576);
		expect(getOpencodeFreeDescriptor("mimo-v2.5-free")?.contextWindow).toBe(1_000_000);
		expect(getOpencodeFreeDescriptor("ling-3.0-flash-fin-free")?.contextWindow).toBe(262_144);
		expect(getOpencodeFreeDescriptor("nemotron-3-ultra-free")?.contextWindow).toBe(1_048_576);
		expect(getOpencodeFreeDescriptor("nemotron-3.5-lightning-free")?.contextWindow).toBe(1_048_576);
	});

	it("marks every model as free, reasoning-capable, and text-only", () => {
		for (const d of OPENCODE_FREE_MODELS) {
			const model = buildOpencodeFreeModel(d);
			expect(model.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
			expect(d.reasoning).toBe(true);
			expect(d.input).toEqual(["text"]);
		}
	});

	it("exposes the shared Zen base URL and per-model api on built models", () => {
		for (const d of OPENCODE_FREE_MODELS) {
			const model = buildOpencodeFreeModel(d);
			expect(model).toMatchObject({
				id: d.id,
				provider: "opencode-free",
				baseUrl: OPENCODE_FREE_BASE_URL,
				api: d.api,
			});
		}
		expect(OPENCODE_FREE_BASE_URL).toBe("https://opencode.ai/zen/v1");
	});

	it("returns undefined for uncurated ids", () => {
		expect(getOpencodeFreeDescriptor("gpt-5.5")).toBeUndefined();
		expect(getOpencodeFreeDescriptor("laguna-s-2.1-free")).toBeUndefined();
	});

	it("static fallback covers the full curated list", () => {
		expect(staticOpencodeFreeModels().map(m => m.id)).toEqual(OPENCODE_FREE_MODELS.map(d => d.id));
	});
});

describe("filterOpencodeFreeIds", () => {
	it("intersects the live id list with curated descriptors in live order", () => {
		const out = filterOpencodeFreeIds([
			"gpt-5.5",
			"big-pickle",
			"muse-spark-1.3-contributor-free",
			"laguna-s-2.1-free",
			"mimo-v2.5-free",
		]);
		expect(out.map(d => d.id)).toEqual(["big-pickle", "muse-spark-1.3-contributor-free", "mimo-v2.5-free"]);
	});

	it("de-duplicates repeated ids", () => {
		const out = filterOpencodeFreeIds(["big-pickle", "big-pickle"]);
		expect(out.map(d => d.id)).toEqual(["big-pickle"]);
	});

	it("returns an empty list when no curated ids match", () => {
		expect(filterOpencodeFreeIds(["gpt-5.5", "glm-5.2"])).toEqual([]);
	});
});

describe("parseOpencodeFreeModels", () => {
	it("extracts curated models from the live Zen payload shape", () => {
		const models = parseOpencodeFreeModels({
			object: "list",
			data: [
				{id: "gpt-5.5", object: "model"},
				{id: "muse-spark-1.3-contributor-free", object: "model"},
				{id: "big-pickle", object: "model"},
				{id: "laguna-s-2.1-free", object: "model"},
			],
		});
		expect(models.map(m => m.id)).toEqual(["muse-spark-1.3-contributor-free", "big-pickle"]);
		// The per-model api survives the parse so the dispatcher can route it.
		expect(models.map(m => m.api)).toEqual(["openai-responses", "openai-completions"]);
	});

	it("returns an empty list on a malformed payload", () => {
		expect(parseOpencodeFreeModels(null)).toEqual([]);
		expect(parseOpencodeFreeModels({})).toEqual([]);
		expect(parseOpencodeFreeModels({data: "not an array"})).toEqual([]);
	});

	it("skips entries with non-string ids", () => {
		const models = parseOpencodeFreeModels({
			data: [{id: 123}, {id: null}, {id: "big-pickle"}],
		});
		expect(models.map(m => m.id)).toEqual(["big-pickle"]);
	});
});
