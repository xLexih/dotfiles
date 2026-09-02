import {describe, expect, it} from "bun:test";
import {opencodeZenCompat} from "../src/compat.ts";

const compat = (id: string) => opencodeZenCompat({id} as {id: string});

describe("opencodeZenCompat per-family branches", () => {
	it("uses the OpenAI-standard `reasoning` field on every family", () => {
		for (const id of [
			"mimo-v2.5-free",
			"muse-spark-1.3-contributor-free",
			"nemotron-3-ultra-free",
			"ling-3.0-flash-fin-free",
		]) {
			expect(compat(id).reasoningContentField).toBe("reasoning");
		}
	});

	it("disables the DeepSeek-style replay flags on every family", () => {
		for (const id of [
			"mimo-v2.5-free",
			"nemotron-3-ultra-free",
			"muse-spark-1.3-contributor-free",
		]) {
			const c = compat(id);
			expect(c.requiresReasoningContentForToolCalls).toBe(false);
			expect(c.requiresReasoningContentForAllAssistantTurns).toBe(false);
			expect(c.allowsSyntheticReasoningContentForToolCalls).toBe(true);
		}
	});

	it("applies the Nemotron branch: 5-minute idle watchdog, no first-event watchdog", () => {
		const c = compat("nemotron-3-ultra-free");
		expect(c.streamIdleTimeoutMs).toBe(300_000);
		expect(c.streamFirstEventTimeoutMs).toBe(0);
	});

	it("applies the mimo / muse branch: standard OpenAI-compat, no special watchdogs", () => {
		for (const id of ["mimo-v2.5-free", "muse-spark-1.3-contributor-free"]) {
			const c = compat(id);
			expect(c.streamIdleTimeoutMs).toBeUndefined();
			expect(c.streamFirstEventTimeoutMs).toBeUndefined();
		}
	});

	it("applies the ling branch: no reasoning controls at all", () => {
		const c = compat("ling-3.0-flash-fin-free");
		expect(c.supportsReasoningEffort).toBe(false);
		expect(c.supportsReasoningParams).toBe(false);
	});

	it("lets tool-call turns send content: null on every family", () => {
		for (const id of [
			"mimo-v2.5-free",
			"nemotron-3-ultra-free",
			"muse-spark-1.3-contributor-free",
			"ling-3.0-flash-fin-free",
		]) {
			expect(compat(id).requiresAssistantContentForToolCalls).toBe(false);
		}
	});

	it("enables OpenAI-style tool choice and standard tool-strict behavior", () => {
		const c = compat("mimo-v2.5-free");
		expect(c.supportsToolChoice).toBe(true);
		expect(c.supportsForcedToolChoice).toBe(true);
		expect(c.supportsNamedToolChoice).toBe(true);
		expect(c.toolSchemaFlavor).toBeUndefined();
		expect(c.streamMarkupHealingPattern).toBeUndefined();
		expect(c.toolStrictMode).toBe("mixed");
	});
});
