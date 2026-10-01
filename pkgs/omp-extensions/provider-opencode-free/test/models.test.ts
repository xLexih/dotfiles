import {describe, expect, it} from "bun:test";
import {buildFreeModelConfig, familyForId, parseZenModels, staticFreeModelConfigs} from "../src/models.ts";
import {isFreeChatId} from "../src/session.ts";

const API = "opencode-free";

describe("isFreeChatId", () => {
	it("passes big-pickle and -free ids, minus jev/systemone", () => {
		expect(isFreeChatId("big-pickle")).toBe(true);
		expect(isFreeChatId("mimo-v2.6-flash-free")).toBe(true);
		expect(isFreeChatId("gpt-5.5")).toBe(false);
		expect(isFreeChatId("jev-1.13-free")).toBe(false);
		expect(isFreeChatId("system-one-free")).toBe(false);
	});
});

describe("familyForId", () => {
	it("routes Muse Spark through Responses, everything else through chat", () => {
		expect(familyForId("muse-spark-1.3-contributor-free")).toBe("openai-responses");
		expect(familyForId("mimo-v2.6-flash-free")).toBe("openai-completions");
		expect(familyForId("some-unknown-free")).toBe("openai-completions");
		expect(familyForId("muse-spark-9-unknown-free")).toBe("openai-responses");
	});
});

describe("parseZenModels", () => {
	const liveShape = {
		object: "list",
		data: [
			{id: "gpt-5.5", object: "model"},
			{id: "muse-spark-1.3-contributor-free", object: "model"},
			{id: "big-pickle", object: "model"},
			{id: "jev-1.13-free", object: "model"},
			{id: "mimo-v2.6-flash-free", object: "model"},
		],
	};

	it("keeps live order, drops paid and judge ids", () => {
		expect(parseZenModels(liveShape, API).map(m => m.id)).toEqual([
			"muse-spark-1.3-contributor-free",
			"big-pickle",
			"mimo-v2.6-flash-free",
		]);
	});

	it("picks up new free ids with synthesized conservative metadata", () => {
		const [mimo] = parseZenModels({data: [{id: "mimo-v2.6-flash-free"}]}, API);
		expect(mimo.name).toBe("MiMo V2.6 Flash Free");
		expect(mimo.contextWindow).toBe(128_000);
		expect(mimo.maxTokens).toBe(8_192);
		const [synth] = parseZenModels({data: [{id: "totally-new-free"}]}, API);
		expect(synth.name).toBe("Totally New Free");
		expect(synth.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
	});

	it("marks every entry free, reasoning-capable, text-only, on the custom dispatch api", () => {
		for (const m of parseZenModels(liveShape, API)) {
			expect(m.api).toBe(API);
			expect(m.reasoning).toBe(true);
			expect(m.input).toEqual(["text"]);
			expect(m.cost).toEqual({input: 0, output: 0, cacheRead: 0, cacheWrite: 0});
		}
	});

	it("uses curated windows for known ids", () => {
		const byId = new Map(parseZenModels(liveShape, API).map(m => [m.id, m]));
		expect(byId.get("muse-spark-1.3-contributor-free")?.contextWindow).toBe(1_048_576);
		expect(byId.get("big-pickle")?.contextWindow).toBe(128_000);
	});

	it("attaches a usable compat policy (pi-ai dereferences it unconditionally)", () => {
		for (const m of parseZenModels(liveShape, API)) {
			expect(m.compat).toMatchObject({
				disableReasoningOnForcedToolChoice: false,
				reasoningContentField: "reasoning",
				supportsToolChoice: true,
			});
		}
		// Encrypted-reasoning replay stays on for chat, off for Responses.
		const byId = new Map(parseZenModels(liveShape, API).map(m => [m.id, m]));
		expect(byId.get("muse-spark-1.3-contributor-free")?.compat).toMatchObject({includeEncryptedReasoning: false});
		expect(byId.get("big-pickle")?.compat).toMatchObject({includeEncryptedReasoning: true});
	});

	it("de-duplicates and rejects malformed payloads", () => {
		expect(parseZenModels({data: [{id: "big-pickle"}, {id: "big-pickle"}]}, API).map(m => m.id)).toEqual([
			"big-pickle",
		]);
		expect(parseZenModels(null, API)).toEqual([]);
		expect(parseZenModels({}, API)).toEqual([]);
		expect(parseZenModels({data: "nope"}, API)).toEqual([]);
		expect(parseZenModels({data: [{id: 123}, {id: null}]}, API)).toEqual([]);
	});
});

describe("staticFreeModelConfigs", () => {
	it("covers the curated rows as the offline fallback", () => {
		const ids = staticFreeModelConfigs(API).map(m => m.id);
		expect(ids).toContain("muse-spark-1.3-contributor-free");
		expect(ids).toContain("mimo-v2.6-flash-free");
		expect(ids).toContain("big-pickle");
		expect(ids).not.toContain("jev-1.13-free");
	});

	it("builds a well-formed entry", () => {
		expect(buildFreeModelConfig("big-pickle", API)).toMatchObject({id: "big-pickle", name: "Big Pickle", api: API});
	});
});
