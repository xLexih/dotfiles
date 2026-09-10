import {describe, expect, it} from "bun:test";
import {glmBridgeCompat} from "../src/compat.ts";

describe("glmBridgeCompat", () => {
	it("uses the bridge's `reasoning_content` field (not OpenAI-standard `reasoning`)", () => {
		// Grounded in bridge source: format.go:66, handlers.go:241.
		expect(glmBridgeCompat().reasoningContentField).toBe("reasoning_content");
	});

	it("treats reasoning deltas as incremental, not cumulative", () => {
		// handlers.go:232 appends only the fresh slice per chunk.
		expect(glmBridgeCompat().reasoningDeltasMayBeCumulative).toBe(false);
	});

	it("keeps the conservative plain-OpenAI surface", () => {
		const c = glmBridgeCompat();
		expect(c.requiresReasoningContentForToolCalls).toBe(false);
		expect(c.requiresReasoningContentForAllAssistantTurns).toBe(false);
		expect(c.allowsSyntheticReasoningContentForToolCalls).toBe(true);
		expect(c.includeEncryptedReasoning).toBe(false);
		expect(c.toolSchemaFlavor).toBeUndefined();
		expect(c.streamMarkupHealingPattern).toBeUndefined();
	});

	it("extends the stream idle watchdog to 5 minutes and disables the first-event watchdog", () => {
		// Captcha + cold session init can sit silent past the defaults.
		const c = glmBridgeCompat();
		expect(c.streamIdleTimeoutMs).toBe(300_000);
		expect(c.streamFirstEventTimeoutMs).toBe(0);
	});

	it("enables OpenAI-style tool calls and forced/named tool choice", () => {
		const c = glmBridgeCompat();
		expect(c.supportsToolChoice).toBe(true);
		expect(c.supportsForcedToolChoice).toBe(true);
		expect(c.supportsNamedToolChoice).toBe(true);
	});

	it("uses the standard `max_tokens` field and lets the request omit it", () => {
		const c = glmBridgeCompat();
		expect(c.maxTokensField).toBe("max_tokens");
		expect(c.alwaysSendMaxTokens).toBe(false);
	});

	it("lets assistant content be null on tool-call turns", () => {
		expect(glmBridgeCompat().requiresAssistantContentForToolCalls).toBe(false);
	});

	it("accepts `reasoning_effort` and exposes the standard OpenAI thinking format", () => {
		const c = glmBridgeCompat();
		expect(c.supportsReasoningEffort).toBe(true);
		expect(c.thinkingFormat).toBe("openai");
		expect(c.omitReasoningEffort).toBe(false);
		expect(c.reasoningDisableMode).toBe("lowest-effort");
	});

	it("does not impose strict tool-call schemas", () => {
		const c = glmBridgeCompat();
		expect(c.supportsStrictMode).toBe(false);
		expect(c.toolStrictMode).toBe("mixed");
	});
});
