import type {Model} from "@oh-my-pi/pi-ai";

/**
 * OpenAI-compat policy for the local GLM bridge (GLM-Free-API).
 *
 * Grounded in the bridge source (`internal/zbridge`), not a live probe:
 *
 * - Reasoning field is `reasoning_content`, NOT the OpenAI-standard
 *   `reasoning` (TokenRouter's GLM routes use `reasoning`; this bridge does
 *   not). See `format.go:66` (non-streaming message) and `handlers.go:241`
 *   (streaming delta). Using the wrong name makes pi-ai silently drop
 *   thinking text.
 * - Reasoning deltas are incremental, not cumulative: `handlers.go:232`
 *   appends each fresh `result.Reasoning` to `fullReasoning` and emits only
 *   the new slice per chunk.
 * - `reasoning_effort: "high" | "max"` is forwarded (forces
 *   `enable_thinking=true`); anything else is ignored upstream.
 * - Tool calls require the bridge's agent mode (`--agent-mode`): without it
 *   `tools` in the request body are ignored upstream and the model never
 *   emits `tool_calls`. The extension cannot fix this server-side — run the
 *   bridge with agent mode on (see README).
 */
export function glmBridgeCompat(): Model<"openai-completions">["compat"] {
	return {
		supportsStore: false,
		supportsDeveloperRole: false,
		supportsMultipleSystemMessages: false,
		supportsReasoningEffort: true,
		supportsReasoningParams: true,
		supportsSamplingParams: true,
		supportsPenaltyAndStopParams: true,
		supportsUsageInStreaming: true,
		// handlers.go emits only the fresh reasoning slice per chunk.
		reasoningDeltasMayBeCumulative: false,
		// Captcha + cold session init can sit silent past the default 300s
		// idle timeout. Same exemption as TokenRouter/OpenBroker Kimi.
		streamIdleTimeoutMs: 300_000,
		// Reasoning prefill may sit silent past the first-event watchdog.
		// 0 = no first-event watchdog; the inter-event watchdog still bounds
		// genuine stalls.
		streamFirstEventTimeoutMs: 0,
		// Plain OpenAI surface — no DeepSeek/Kimi markup healing.
		streamMarkupHealingPattern: undefined,
		toolSchemaFlavor: undefined,
		// Don't force `max_tokens` on every request; let the catalog cap
		// speak when the caller sets one.
		alwaysSendMaxTokens: false,
		disableReasoningOnForcedToolChoice: false,
		disableReasoningOnToolChoice: false,
		supportsToolChoice: true,
		supportsForcedToolChoice: true,
		supportsNamedToolChoice: true,
		maxTokensField: "max_tokens",
		// Bridge emits `reasoning_content` (format.go, handlers.go).
		reasoningContentField: "reasoning_content",
		// The bridge never replays encrypted reasoning; don't ask it to.
		requiresReasoningContentForToolCalls: false,
		requiresReasoningContentForAllAssistantTurns: false,
		allowsSyntheticReasoningContentForToolCalls: true,
		// Standard `content: null` on tool-call turns is accepted.
		requiresAssistantContentForToolCalls: false,
		thinkingFormat: "openai",
		reasoningDisableMode: "lowest-effort",
		omitReasoningEffort: false,
		// No encrypted-reasoning envelope on this surface; replay would be
		// forwarded as an unknown field.
		includeEncryptedReasoning: false,
		supportsStrictMode: false,
		toolStrictMode: "mixed",
	};
}
