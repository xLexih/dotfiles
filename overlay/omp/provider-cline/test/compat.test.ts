import {describe, expect, it} from "bun:test";
import {clineCompat} from "../src/compat.ts";

const compat = (id: string) => clineCompat({id} as {id: string});

describe("clineCompat per-family branches", () => {
	it("uses the OpenAI-standard `reasoning` field across all families", () => {
		for (const id of [
			"z-ai/glm-5.2:free",
			"minimax/minimax-m3:free",
			"minimax/minimax-m2.7:free",
			"nvidia/nemotron-3-super-120b-a12b:free",
			"nvidia/nemotron-3.5-lightning:free",
		]) {
			expect(compat(id).reasoningContentField).toBe("reasoning");
		}
	});

	it("disables the DeepSeek-style replay flags across all families", () => {
		for (const id of [
			"minimax/minimax-m3:free",
			"nvidia/nemotron-3-super-120b-a12b:free",
			"z-ai/glm-5.2:free",
		]) {
			const c = compat(id);
			expect(c.requiresReasoningContentForToolCalls).toBe(false);
			expect(c.requiresReasoningContentForAllAssistantTurns).toBe(false);
			expect(c.allowsSyntheticReasoningContentForToolCalls).toBe(true);
		}
	});

	it("applies the MiniMax exemption: always-on thinking, required max_tokens, no effort field", () => {
		const c = compat("minimax/minimax-m2.7:free");
		expect(c.reasoningDeltasMayBeCumulative).toBe(true);
		expect(c.alwaysSendMaxTokens).toBe(true);
		expect(c.omitReasoningEffort).toBe(true);
		expect(c.streamIdleTimeoutMs).toBe(300_000);
		expect(c.streamFirstEventTimeoutMs).toBe(0);
	});

	it("applies the Nemotron branch: no always-on thinking, no alwaysSendMaxTokens, accepts effort", () => {
		const c = compat("nvidia/nemotron-3-super-120b-a12b:free");
		expect(c.reasoningDeltasMayBeCumulative).toBe(false);
		expect(c.alwaysSendMaxTokens).toBe(false);
		expect(c.omitReasoningEffort).toBe(false);
		expect(c.supportsReasoningEffort).toBe(true);
		expect(c.streamIdleTimeoutMs).toBe(300_000);
	});

	it("applies the GLM branch: accepts effort, no always-on thinking", () => {
		const c = compat("z-ai/glm-5.2:free");
		expect(c.omitReasoningEffort).toBe(false);
		expect(c.supportsReasoningEffort).toBe(true);
		expect(c.alwaysSendMaxTokens).toBe(false);
	});

	it("applies the gemma branch: no reasoning controls at all", () => {
		const c = compat("google/gemma-4-31b-it:free");
		expect(c.supportsReasoningEffort).toBe(false);
		expect(c.supportsReasoningParams).toBe(false);
	});

	it("applies the cohere branch: no reasoning controls at all", () => {
		const c = compat("cohere/north-mini-code:free");
		expect(c.supportsReasoningEffort).toBe(false);
		expect(c.supportsReasoningParams).toBe(false);
	});

	it("lets tool-call turns send content: null on every family", () => {
		for (const id of [
			"minimax/minimax-m3:free",
			"nvidia/nemotron-3-super-120b-a12b:free",
			"z-ai/glm-5.2:free",
			"google/gemma-4-31b-it:free",
		]) {
			expect(compat(id).requiresAssistantContentForToolCalls).toBe(false);
		}
	});

	it("enables OpenAI-style tool choice and standard tool-strict behavior", () => {
		const c = compat("minimax/minimax-m3:free");
		expect(c.supportsToolChoice).toBe(true);
		expect(c.supportsForcedToolChoice).toBe(true);
		expect(c.supportsNamedToolChoice).toBe(true);
		expect(c.toolSchemaFlavor).toBeUndefined();
		expect(c.streamMarkupHealingPattern).toBeUndefined();
		expect(c.toolStrictMode).toBe("mixed");
	});
});
