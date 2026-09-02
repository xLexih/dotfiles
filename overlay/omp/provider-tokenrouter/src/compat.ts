import type {Model} from "@oh-my-pi/pi-ai";

/**
 * OpenAI-compat policy for TokenRouter's GLM-5.3 routes.
 *
 * Authoritative shape from a live probe on 2026-09-02:
 *   POST /v1/chat/completions with `z-ai/glm-5.3-free` returns
 *   `choices[0].message.reasoning` (the standard OpenAI reasoning field, not
 *   `reasoning_content`). `choices[0].finish_reason` is `"stop"` or `"length"`.
 *   The `usage.completion_tokens_details.reasoning_tokens` counter is present
 *   and accurate.
 *
 * TokenRouter is a plain OpenAI surface. It does NOT impose DeepSeek-style
 * DSML/inband tool envelopes, strict assistant content shape, or replay
 * semantics. Tool calls use the standard `tool_calls` field. As such, the
 * compat policy is conservative: accept everything OpenAI accepts, and turn
 * OFF the flags that bit OpenBroker's MiniMax integration when reasoning was
 * off (empty `reasoning_content: ""` injected on every replay, see
 * `overlay/omp/provider-openbroker/src/compat.ts:58-64`).
 */
export function tokenrouterCompat(): Model<"openai-completions">["compat"] {
	return {
		supportsStore: false,
		supportsDeveloperRole: false,
		supportsMultipleSystemMessages: false,
		supportsReasoningEffort: true,
		supportsReasoningParams: true,
		supportsSamplingParams: true,
		supportsPenaltyAndStopParams: true,
		supportsUsageInStreaming: true,
		// GLM-5.3 does not stream cumulative reasoning deltas; the `reasoning`
		// field is set per-chunk and the OMP handler should treat it as
		// authoritative.
		reasoningDeltasMayBeCumulative: false,
		// Long thinking prefill on a free/cheap route can sit silent past the
		// default 300s idle timeout. Match OpenBroker's Kimi exemption at
		// `overlay/omp/provider-openbroker/src/compat.ts:34-39`.
		streamIdleTimeoutMs: 300_000,
		// Reasoning prefill may also sit silent past the first-event watchdog.
		// 0 = no first-event watchdog; the inter-event watchdog still bounds
		// genuine stalls.
		streamFirstEventTimeoutMs: 0,
		// TokenRouter is a plain OpenAI surface — do NOT enable the
		// DeepSeek/Kimi markup healing patterns.
		streamMarkupHealingPattern: undefined,
		toolSchemaFlavor: undefined,
		// Don't force `max_tokens` on every request; let the model/library
		// pick the natural completion length.
		alwaysSendMaxTokens: false,
		disableReasoningOnForcedToolChoice: false,
		disableReasoningOnToolChoice: false,
		supportsToolChoice: true,
		supportsForcedToolChoice: true,
		supportsNamedToolChoice: true,
		maxTokensField: "max_tokens",
		// Live probe confirmed the upstream field is `reasoning`, not
		// `reasoning_content`. Using the wrong field name would make
		// pi-ai silently drop thinking text.
		reasoningContentField: "reasoning",
		// See comment at top: do NOT force reasoning replay.
		requiresReasoningContentForToolCalls: false,
		requiresReasoningContentForAllAssistantTurns: false,
		allowsSyntheticReasoningContentForToolCalls: true,
		// Tool turns can send `content: null` — TokenRouter accepts it.
		requiresAssistantContentForToolCalls: false,
		thinkingFormat: "openai",
		// GLM-5.3 accepts `reasoning_effort` (low/high/max) on both the free
		// and Flash routes.
		reasoningDisableMode: "lowest-effort",
		omitReasoningEffort: false,
		includeEncryptedReasoning: true,
		supportsStrictMode: false,
		toolStrictMode: "mixed",
	};
}
