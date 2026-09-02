import {describe, expect, it} from "bun:test";
import {
	buildOpencodeZenModel,
	getOpencodeZenDescriptor,
	OPENCODE_ZEN_MODELS,
	parseOpencodeZenModels,
} from "../src/catalog.ts";

describe("OpenCode Zen catalog", () => {
	it("contains the curated free models in a stable order", () => {
		expect(OPENCODE_ZEN_MODELS.map(m => m.id)).toEqual([
			"mimo-v2.5-free",
			"muse-spark-1.3-contributor-free",
			"muse-spark-1.2-contributor-free",
			"nemotron-3-ultra-free",
			"nemotron-3.5-lightning-free",
			"ling-3.0-flash-fin-free",
		]);
	});

	it("treats every model as zero-cost (free tier)", () => {
		for (const d of OPENCODE_ZEN_MODELS) {
			const model = buildOpencodeZenModel(d);
			expect(model.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
		}
	});

	it("flags reasoning-capable models correctly", () => {
		expect(getOpencodeZenDescriptor("mimo-v2.5-free")?.reasoning).toBe(true);
		expect(getOpencodeZenDescriptor("muse-spark-1.3-contributor-free")?.reasoning).toBe(true);
		expect(getOpencodeZenDescriptor("nemotron-3-ultra-free")?.reasoning).toBe(true);
		expect(getOpencodeZenDescriptor("ling-3.0-flash-fin-free")?.reasoning).toBe(false);
	});

	it("exposes the OMP-typed model shape used at registration", () => {
		const model = buildOpencodeZenModel(OPENCODE_ZEN_MODELS[0]!);
		expect(model).toMatchObject({
			id: "mimo-v2.5-free",
			provider: "opencode",
			baseUrl: "https://opencode.ai/zen/v1",
			api: "openai-completions",
			reasoning: true,
			input: ["text"],
		});
	});
});

describe("parseOpencodeZenModels", () => {
	it("extracts curated models from the public models payload", () => {
		const models = parseOpencodeZenModels({
			object: "list",
			data: [
				{id: "claude-opus-5", object: "model"},
				{id: "mimo-v2.5-free", object: "model"},
				{id: "nemotron-3-ultra-free", object: "model"},
			],
		});
		expect(models.map(m => m.id)).toEqual([
			"mimo-v2.5-free",
			"nemotron-3-ultra-free",
		]);
	});

	it("returns an empty list on a malformed payload", () => {
		expect(parseOpencodeZenModels(null)).toEqual([]);
		expect(parseOpencodeZenModels({})).toEqual([]);
		expect(parseOpencodeZenModels({data: "not an array"})).toEqual([]);
	});

	it("drops entries with non-string ids and unknown curated ids", () => {
		const models = parseOpencodeZenModels({
			data: [
				{id: 123},
				{id: null},
				{id: "mimo-v2.5-free"},
				{id: "never-released-free"},
			],
		});
		expect(models.map(m => m.id)).toEqual(["mimo-v2.5-free"]);
	});
});
