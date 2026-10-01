import {describe, expect, it} from "bun:test";
import {
	createThinkingMapsFetcher,
	thinkingLevelMapForEffort,
	thinkingSpecForEffort,
	thinkingSpecsFromModelsDev,
} from "../src/thinking.ts";

describe("thinkingLevelMapForEffort", () => {
	it("identity-maps known levels with null holes (Muse Spark shape)", () => {
		expect(thinkingLevelMapForEffort(["minimal", "low", "medium", "high", "xhigh"])).toEqual({
			off: null,
			minimal: "minimal",
			low: "low",
			medium: "medium",
			high: "high",
			xhigh: "xhigh",
			max: null,
		});
	});

	it("ignores unrecognized values, omits the map when none are known", () => {
		expect(thinkingLevelMapForEffort(["none", "high"])).toMatchObject({high: "high", off: null});
		expect(thinkingLevelMapForEffort(["none"])).toBeUndefined();
		expect(thinkingLevelMapForEffort([])).toBeUndefined();
		expect(thinkingLevelMapForEffort(null)).toBeUndefined();
		expect(thinkingLevelMapForEffort("xhigh")).toBeUndefined();
	});
});

describe("thinkingSpecForEffort", () => {
	it("emits the runtime shape with xhigh for Muse Spark values", () => {
		expect(thinkingSpecForEffort(["minimal", "low", "medium", "high", "xhigh"])).toEqual({
			mode: "effort",
			efforts: ["minimal", "low", "medium", "high", "xhigh"],
			thinkingLevelMap: {
				off: null,
				minimal: "minimal",
				low: "low",
				medium: "medium",
				high: "high",
				xhigh: "xhigh",
				max: null,
			},
		});
	});

	it("drops holes from efforts and maps max when advertised", () => {
		expect(thinkingSpecForEffort(["low", "medium", "xhigh"])?.efforts).toEqual(["low", "medium", "xhigh"]);
		expect(thinkingSpecForEffort(["low", "high", "max"])?.efforts).toEqual(["low", "high", "max"]);
		expect(thinkingSpecForEffort(["none"])).toBeUndefined();
	});
});

describe("thinkingSpecsFromModelsDev", () => {
	const payload = {
		opencode: {
			models: {
				"muse-spark-1.3-contributor-free": {
					reasoning_options: [{type: "effort", values: ["minimal", "low", "medium", "high", "xhigh"]}],
				},
				"qwen3.8-flash": {
					reasoning_options: [{type: "toggle"}, {type: "effort", values: ["low", "medium", "xhigh"]}, {type: "budget_tokens"}],
				},
				"mimo-v2.5-free": {reasoning_options: []},
				"qwen3-coder": {reasoning_options: null},
				"minimax-m3-free": {reasoning_options: [{type: "toggle"}]},
				"north-mini-code-free": {reasoning_options: [{type: "effort", values: ["none", "high"]}]},
				broken: null,
			},
		},
	};

	it("maps effort-advertising models, skips the rest", () => {
		const specs = thinkingSpecsFromModelsDev(payload);
		expect(specs.get("muse-spark-1.3-contributor-free")).toMatchObject({
			mode: "effort",
			efforts: ["minimal", "low", "medium", "high", "xhigh"],
		});
		expect(specs.get("qwen3.8-flash")?.efforts).toEqual(["low", "medium", "xhigh"]);
		expect(specs.get("north-mini-code-free")?.efforts).toEqual(["high"]);
		expect(specs.has("mimo-v2.5-free")).toBe(false);
		expect(specs.has("qwen3-coder")).toBe(false);
		expect(specs.has("minimax-m3-free")).toBe(false);
		expect(specs.has("broken")).toBe(false);
	});

	it("rejects malformed payloads and unknown slices", () => {
		expect(thinkingSpecsFromModelsDev(null).size).toBe(0);
		expect(thinkingSpecsFromModelsDev({}).size).toBe(0);
		expect(thinkingSpecsFromModelsDev(payload, "nope").size).toBe(0);
		expect(thinkingSpecsFromModelsDev({opencode: {models: null}}).size).toBe(0);
	});
});

describe("createThinkingMapsFetcher", () => {
	const body = {opencode: {models: {"muse-spark-1.3-contributor-free": {reasoning_options: [{type: "effort", values: ["low", "xhigh"]}]}}}};
	const okResponse = (etag: string | null = "e1") =>
		({
			ok: true,
			status: 200,
			headers: {get: (_: string) => etag},
			json: async () => body,
		}) as unknown as Response;

	it("caches within TTL and revalidates with ETag afterwards", async () => {
		let calls = 0;
		let lastHeaders: Record<string, string> = {};
		const fetchImpl = (async (_url: string, init?: {headers?: Record<string, string>}) => {
			calls++;
			lastHeaders = init?.headers ?? {};
			return okResponse();
		}) as unknown as typeof fetch;
		const fetchMaps = createThinkingMapsFetcher({fetchImpl, ttlMs: 1_000, now: () => 0});
		expect((await fetchMaps()).get("muse-spark-1.3-contributor-free")).toMatchObject({
			mode: "effort",
			efforts: ["low", "xhigh"],
		});
		expect(await fetchMaps()).toBe(await fetchMaps());
		expect(calls).toBe(1);
		expect(lastHeaders).not.toHaveProperty("If-None-Match");
	});

	it("sends If-None-Match after TTL and reuses the snapshot on 304", async () => {
		let now = 0;
		const seen: Record<string, string>[] = [];
		const fetchImpl = (async (_url: string, init?: {headers?: Record<string, string>}) => {
			seen.push(init?.headers ?? {});
			if (seen.length === 1) return okResponse("e1");
			return {ok: false, status: 304, headers: {get: () => null}, json: async () => null} as unknown as Response;
		}) as unknown as typeof fetch;
		const fetchMaps = createThinkingMapsFetcher({fetchImpl, ttlMs: 1_000, now: () => now});
		const first = await fetchMaps();
		now = 2_000;
		const second = await fetchMaps();
		expect(second).toBe(first);
		expect(seen[1]?.["If-None-Match"]).toBe("e1");
	});

	it("never throws: failures resolve to empty or stale maps", async () => {
		const failing = (async () => {
			throw new Error("down");
		}) as unknown as typeof fetch;
		expect((await createThinkingMapsFetcher({fetchImpl: failing})()).size).toBe(0);
		const badStatus = (async () =>
			({ok: false, status: 500, headers: {get: () => null}, json: async () => null}) as unknown as Response) as unknown as typeof fetch;
		expect((await createThinkingMapsFetcher({fetchImpl: badStatus})()).size).toBe(0);
	});
});
