import {describe, expect, it} from "bun:test";
import {
	buildClineModel,
	CLINE_MODELS,
	getClineDescriptor,
	parseClineModels,
} from "../src/catalog.ts";

describe("Cline catalog", () => {
	it("contains the curated free models in a stable order", () => {
		expect(CLINE_MODELS.map(m => m.id)).toEqual([
			"z-ai/glm-5.2:free",
			"minimax/minimax-m3:free",
			"minimax/minimax-m2.7:free",
			"nvidia/nemotron-3-ultra-550b-a55b:free",
			"nvidia/nemotron-3-super-120b-a12b:free",
			"nvidia/nemotron-3.5-lightning:free",
			"nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
			"cohere/north-mini-code:free",
			"google/gemma-4-31b-it:free",
			"google/gemma-4-26b-a4b-it:free",
		]);
	});

	it("treats every model as zero-cost (free tier)", () => {
		for (const d of CLINE_MODELS) {
			expect(d).toBeDefined();
			const model = buildClineModel(d);
			expect(model.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
		}
	});

	it("flags reasoning-capable models correctly", () => {
		expect(getClineDescriptor("z-ai/glm-5.2:free")?.reasoning).toBe(true);
		expect(getClineDescriptor("minimax/minimax-m3:free")?.reasoning).toBe(true);
		expect(getClineDescriptor("minimax/minimax-m2.7:free")?.reasoning).toBe(true);
		expect(getClineDescriptor("nvidia/nemotron-3-super-120b-a12b:free")?.reasoning).toBe(true);
		expect(getClineDescriptor("cohere/north-mini-code:free")?.reasoning).toBe(false);
		expect(getClineDescriptor("google/gemma-4-31b-it:free")?.reasoning).toBe(false);
	});

	it("uses an enlarged maxTokens on m3 and a brake on m2.7", () => {
		expect(getClineDescriptor("minimax/minimax-m3:free")?.maxTokens).toBe(65_536);
		expect(getClineDescriptor("minimax/minimax-m2.7:free")?.maxTokens).toBe(16_384);
	});

	it("marks the small 32k-context gemma models as 'avoid'", () => {
		expect(getClineDescriptor("google/gemma-4-31b-it:free")?.highContextHint).toBe("avoid");
		expect(getClineDescriptor("google/gemma-4-26b-a4b-it:free")?.highContextHint).toBe("avoid");
	});

	it("exposes the OMP-typed model shape used at registration", () => {
		const model = buildClineModel(CLINE_MODELS[0]!);
		expect(model).toMatchObject({
			id: "z-ai/glm-5.2:free",
			provider: "cline",
			baseUrl: "https://api.cline.bot/api/v1",
			api: "openai-completions",
			reasoning: true,
			input: ["text"],
		});
	});
});

describe("parseClineModels", () => {
	it("extracts curated models from a standard OpenAI models payload", () => {
		const models = parseClineModels({
			object: "list",
			data: [
				{id: "openai/gpt-5", object: "model"},
				{id: "minimax/minimax-m3:free", object: "model"},
				{id: "google/gemma-4-31b-it:free", object: "model"},
			],
		});
		expect(models.map(m => m.id)).toEqual([
			"minimax/minimax-m3:free",
			"google/gemma-4-31b-it:free",
		]);
	});

	it("returns an empty list on a malformed payload", () => {
		expect(parseClineModels(null)).toEqual([]);
		expect(parseClineModels({})).toEqual([]);
		expect(parseClineModels({data: "not an array"})).toEqual([]);
	});

	it("drops entries with non-string ids and unknown curated ids", () => {
		const models = parseClineModels({
			data: [
				{id: 123},
				{id: null},
				{id: "minimax/minimax-m3:free"},
				{id: "minimax/never-released:free"},
			],
		});
		expect(models.map(m => m.id)).toEqual(["minimax/minimax-m3:free"]);
	});
});
