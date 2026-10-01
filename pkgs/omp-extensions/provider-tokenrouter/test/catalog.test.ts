import {describe, expect, it} from "bun:test";
import {
	buildTokenrouterModel,
	filterTokenrouterIds,
	getTokenrouterDescriptor,
	parseTokenrouterModels,
	TOKENROUTER_MODELS,
} from "../src/catalog.ts";

describe("TokenRouter catalog", () => {
	it("contains exactly the two documented GLM-5.3 entries", () => {
		expect(TOKENROUTER_MODELS.map(m => m.id)).toEqual([
			"z-ai/glm-5.3-free",
			"z-ai/glm-5.3-flash",
		]);
	});

	it("uses the upstream GLM-5.3 1,048,576-token context window", () => {
		for (const d of TOKENROUTER_MODELS) {
			expect(d.contextWindow).toBe(1_048_576);
		}
	});

	it("applies the 16,384 verbosity-brake maxTokens on both entries", () => {
		for (const d of TOKENROUTER_MODELS) {
			expect(d.maxTokens).toBe(16_384);
		}
	});

	it("marks the free route as zero-cost and the Flash route as paid", () => {
		const free = getTokenrouterDescriptor("z-ai/glm-5.3-free");
		const flash = getTokenrouterDescriptor("z-ai/glm-5.3-flash");
		expect(free?.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
		expect(flash?.cost).toEqual({input: 0.075, output: 0.25, cacheRead: 0, cacheWrite: 0});
	});

	it("flags every model as reasoning-capable and text-only", () => {
		for (const d of TOKENROUTER_MODELS) {
			expect(d.reasoning).toBe(true);
			expect(d.input).toEqual(["text"]);
		}
	});

	it("exposes the same OMP-typed model shape used at registration", () => {
		const model = buildTokenrouterModel(TOKENROUTER_MODELS[0]!);
		expect(model).toMatchObject({
			id: "z-ai/glm-5.3-free",
			provider: "tokenrouter",
			baseUrl: "https://api.tokenrouter.com/v1",
			api: "openai-completions",
			reasoning: true,
			input: ["text"],
			contextWindow: 1_048_576,
			maxTokens: 16_384,
		});
	});
});

describe("filterTokenrouterIds", () => {
	it("intersects the live id list with curated descriptors", () => {
		const out = filterTokenrouterIds([
			"openai/gpt-5",
			"z-ai/glm-5.3-free",
			"z-ai/glm-5.3-flash",
			"minimax/minimax-m2.5",
			"some/unknown-model",
		]);
		expect(out.map(d => d.id)).toEqual(["z-ai/glm-5.3-free", "z-ai/glm-5.3-flash"]);
	});

	it("de-duplicates repeated ids", () => {
		const out = filterTokenrouterIds([
			"z-ai/glm-5.3-free",
			"z-ai/glm-5.3-free",
			"z-ai/glm-5.3-flash",
		]);
		expect(out.map(d => d.id)).toEqual(["z-ai/glm-5.3-free", "z-ai/glm-5.3-flash"]);
	});

	it("returns an empty list when no curated ids match", () => {
		expect(filterTokenrouterIds(["openai/gpt-5", "minimax/minimax-m2.5"])).toEqual([]);
	});
});

describe("parseTokenrouterModels", () => {
	it("extracts curated models from a standard OpenAI models payload", () => {
		const models = parseTokenrouterModels({
			data: [
				{id: "openai/gpt-5", object: "model"},
				{id: "z-ai/glm-5.3-free", object: "model"},
				{id: "z-ai/glm-5.3-flash", object: "model"},
			],
		});
		expect(models.map(m => m.id)).toEqual(["z-ai/glm-5.3-free", "z-ai/glm-5.3-flash"]);
	});

	it("returns an empty list on a malformed payload", () => {
		expect(parseTokenrouterModels(null)).toEqual([]);
		expect(parseTokenrouterModels({})).toEqual([]);
		expect(parseTokenrouterModels({data: "not an array"})).toEqual([]);
	});

	it("skips entries with non-string ids", () => {
		const models = parseTokenrouterModels({
			data: [{id: 123}, {id: null}, {id: "z-ai/glm-5.3-free"}],
		});
		expect(models.map(m => m.id)).toEqual(["z-ai/glm-5.3-free"]);
	});
});
