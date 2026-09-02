import {describe, expect, it} from "bun:test";
import {opencodeFreeCompat} from "../src/compat.ts";

describe("opencodeFreeCompat", () => {
	it("uses the OpenAI-standard `reasoning` field on both families", () => {
		expect(opencodeFreeCompat("openai-completions").reasoningContentField).toBe("reasoning");
		expect(opencodeFreeCompat("openai-responses").reasoningContentField).toBe("reasoning");
	});

	it("disables the DeepSeek-style replay flags that bit OpenBroker", () => {
		for (const api of ["openai-completions", "openai-responses"] as const) {
			const c = opencodeFreeCompat(api);
			expect(c.requiresReasoningContentForToolCalls).toBe(false);
			expect(c.requiresReasoningContentForAllAssistantTurns).toBe(false);
			expect(c.allowsSyntheticReasoningContentForToolCalls).toBe(true);
		}
	});

	it("extends the stream idle watchdog to 5 minutes and disables the first-event watchdog", () => {
		for (const api of ["openai-completions", "openai-responses"] as const) {
			const c = opencodeFreeCompat(api);
			expect(c.streamIdleTimeoutMs).toBe(300_000);
			expect(c.streamFirstEventTimeoutMs).toBe(0);
		}
	});

	it("enables OpenAI-style tool calls and forced/named tool choice", () => {
		const c = opencodeFreeCompat("openai-completions");
		expect(c.supportsToolChoice).toBe(true);
		expect(c.supportsForcedToolChoice).toBe(true);
		expect(c.supportsNamedToolChoice).toBe(true);
		expect(c.toolSchemaFlavor).toBeUndefined();
		expect(c.streamMarkupHealingPattern).toBeUndefined();
	});

	it("keeps encrypted-reasoning replay on chat but off on Responses", () => {
		// Third-party `/v1/responses` proxies may reject encrypted-reasoning
		// replay; the chat family keeps it like TokenRouter.
		expect(opencodeFreeCompat("openai-completions").includeEncryptedReasoning).toBe(true);
		expect(opencodeFreeCompat("openai-responses").includeEncryptedReasoning).toBe(false);
	});

	it("accepts `reasoning_effort` and exposes the standard OpenAI thinking format", () => {
		for (const api of ["openai-completions", "openai-responses"] as const) {
			const c = opencodeFreeCompat(api);
			expect(c.supportsReasoningEffort).toBe(true);
			expect(c.thinkingFormat).toBe("openai");
			expect(c.omitReasoningEffort).toBe(false);
			expect(c.reasoningDisableMode).toBe("lowest-effort");
		}
	});

	it("does not impose strict tool-call schemas", () => {
		const c = opencodeFreeCompat("openai-responses");
		expect(c.supportsStrictMode).toBe(false);
		expect(c.toolStrictMode).toBe("mixed");
	});
});
