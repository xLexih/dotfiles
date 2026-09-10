import type {Model} from "@oh-my-pi/pi-ai";
import type {ZenRouterApi} from "./catalog.ts";

/**
 * OpenAI-compat policy for traffic via the local Zen router.
 *
 * The router is a plain OpenAI gateway (no DSML/inband tool envelopes,
 * standard `tool_calls`), so the chat policy mirrors the proven TokenRouter
 * surface (`overlay/omp/provider-tokenrouter/src/compat.ts`): OpenAI-standard
 * `reasoning` field, no forced reasoning replay, standard tool choice.
 *
 * The single Responses difference is `includeEncryptedReasoning`: pi-ai's own
 * endpoint-constraints doc warns third-party `/v1/responses` proxies may
 * reject encrypted-reasoning replay or `previous_response_id` chaining, so
 * the Responses branch omits it (stateless `store: false` likewise keeps
 * chaining off — the Responses default for non-OpenAI hosts).
 */
export function zenRouterCompat(api: ZenRouterApi): Model<"openai-completions">["compat"] {
	return {
		supportsStore: false,
		supportsDeveloperRole: false,
		supportsMultipleSystemMessages: false,
		supportsReasoningEffort: true,
		supportsReasoningParams: true,
		supportsSamplingParams: true,
		supportsPenaltyAndStopParams: true,
		supportsUsageInStreaming: true,
		reasoningDeltasMayBeCumulative: false,
		// Long thinking prefill on a free tier can sit silent past the
		// default 300s idle timeout. Same exemption OpenBroker uses for Kimi
		// at `overlay/omp/provider-openbroker/src/compat.ts:34-39`.
		streamIdleTimeoutMs: 300_000,
		// Reasoning prefill may also sit silent past the first-event
		// watchdog. 0 = no first-event watchdog; the inter-event watchdog
		// still bounds genuine stalls.
		streamFirstEventTimeoutMs: 0,
		// Plain OpenAI surface — no DSML/inband markup healing.
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
		// The router speaks OpenAI-standard `reasoning`, not
		// `reasoning_content` (same live-probe lesson as TokenRouter).
		reasoningContentField: "reasoning",
		// Do NOT force reasoning replay — the OpenBroker `compat.ts:58-64`
		// lesson applies to any plain OpenAI proxy.
		requiresReasoningContentForToolCalls: false,
		requiresReasoningContentForAllAssistantTurns: false,
		allowsSyntheticReasoningContentForToolCalls: true,
		// Tool turns can send `content: null`.
		requiresAssistantContentForToolCalls: false,
		thinkingFormat: "openai",
		reasoningDisableMode: "lowest-effort",
		omitReasoningEffort: false,
		includeEncryptedReasoning: api === "openai-completions",
		supportsStrictMode: false,
		toolStrictMode: "mixed",
	};
}
