import {describe, expect, it} from "bun:test";
import {zenRouterCompat} from "../src/compat.ts";

describe("zenRouterCompat", () => {
	it("uses the OpenAI-standard `reasoning` field on both families", () => {
		expect(zenRouterCompat("openai-completions").reasoningContentField).toBe("reasoning");
		expect(zenRouterCompat("openai-responses").reasoningContentField).toBe("reasoning");
	});

	it("disables the DeepSeek-style replay flags that bit OpenBroker", () => {
		for (const api of ["openai-completions", "openai-responses"] as const) {
			const c = zenRouterCompat(api);
			expect(c.requiresReasoningContentForToolCalls).toBe(false);
			expect(c.requiresReasoningContentForAllAssistantTurns).toBe(false);
			expect(c.allowsSyntheticReasoningContentForToolCalls).toBe(true);
		}
	});

	it("extends the stream idle watchdog to 5 minutes and disables the first-event watchdog", () => {
		for (const api of ["openai-completions", "openai-responses"] as const) {
			const c = zenRouterCompat(api);
			expect(c.streamIdleTimeoutMs).toBe(300_000);
			expect(c.streamFirstEventTimeoutMs).toBe(0);
		}
	});

	it("enables OpenAI-style tool calls and forced/named tool choice", () => {
		const c = zenRouterCompat("openai-completions");
		expect(c.supportsToolChoice).toBe(true);
		expect(c.supportsForcedToolChoice).toBe(true);
		expect(c.supportsNamedToolChoice).toBe(true);
		expect(c.toolSchemaFlavor).toBeUndefined();
		expect(c.streamMarkupHealingPattern).toBeUndefined();
	});

	it("keeps encrypted-reasoning replay on chat but off on Responses", () => {
		expect(zenRouterCompat("openai-completions").includeEncryptedReasoning).toBe(true);
		expect(zenRouterCompat("openai-responses").includeEncryptedReasoning).toBe(false);
	});
});
