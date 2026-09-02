import {describe, expect, it} from "bun:test";
import {tokenrouterCompat} from "../src/compat.ts";

describe("tokenrouterCompat", () => {
	const c = tokenrouterCompat();

	it("uses the OpenAI-standard `reasoning` field (not `reasoning_content`)", () => {
		expect(c.reasoningContentField).toBe("reasoning");
	});

	it("disables the DeepSeek-style replay flags that bit OpenBroker", () => {
		expect(c.requiresReasoningContentForToolCalls).toBe(false);
		expect(c.requiresReasoningContentForAllAssistantTurns).toBe(false);
		expect(c.allowsSyntheticReasoningContentForToolCalls).toBe(true);
	});

	it("extends the stream idle watchdog to 5 minutes and disables the first-event watchdog", () => {
		// Long thinking prefill can sit silent past the default 300s idle
		// timeout — same exemption OpenBroker applies for Kimi.
		expect(c.streamIdleTimeoutMs).toBe(300_000);
		expect(c.streamFirstEventTimeoutMs).toBe(0);
	});

	it("enables OpenAI-style tool calls and forced/named tool choice", () => {
		expect(c.supportsToolChoice).toBe(true);
		expect(c.supportsForcedToolChoice).toBe(true);
		expect(c.supportsNamedToolChoice).toBe(true);
		expect(c.toolSchemaFlavor).toBeUndefined();
		expect(c.streamMarkupHealingPattern).toBeUndefined();
	});

	it("uses the standard `max_tokens` field and lets the request omit it", () => {
		expect(c.maxTokensField).toBe("max_tokens");
		expect(c.alwaysSendMaxTokens).toBe(false);
	});

	it("lets assistant content be null on tool-call turns", () => {
		expect(c.requiresAssistantContentForToolCalls).toBe(false);
	});

	it("accepts `reasoning_effort` and exposes the standard OpenAI thinking format", () => {
		expect(c.supportsReasoningEffort).toBe(true);
		expect(c.thinkingFormat).toBe("openai");
		expect(c.omitReasoningEffort).toBe(false);
		expect(c.reasoningDisableMode).toBe("lowest-effort");
	});

	it("does not impose strict tool-call schemas", () => {
		expect(c.supportsStrictMode).toBe(false);
		expect(c.toolStrictMode).toBe("mixed");
	});
});
