import type {Model} from "@oh-my-pi/pi-ai";

/**
 * OpenCode Zen compat policy. Zen is a clean OpenAI surface (live probe on
 * 2026-09-02 returned `choices[0].message.reasoning` as a string, standard
 * `usage` block with `prompt_tokens_details.cached_tokens`, and the standard
 * `finish_reason` set). The compat policy mirrors the OpenBroker Kimi/Nemotron
 * branches for the prefill-stall exemption that reasoning models need.
 */
export function opencodeZenCompat(model: Pick<Model, "id">): Model<"openai-completions">["compat"] {
	const id = model.id.toLowerCase();
	const isReasoning = id.includes("mimo") || id.includes("nemotron") || id.includes("muse");
	const isNemotron = id.includes("nemotron");

	return {
		supportsStore: false,
		supportsDeveloperRole: false,
		supportsMultipleSystemMessages: false,
		supportsReasoningEffort: isReasoning,
		supportsReasoningParams: isReasoning,
		supportsSamplingParams: true,
		supportsPenaltyAndStopParams: true,
		supportsUsageInStreaming: true,
		reasoningDeltasMayBeCumulative: false,
		// Nemotron reasoning prefill can sit silent past 300s — same
		// exemption OpenBroker applies for Kimi.
		streamIdleTimeoutMs: isNemotron ? 300_000 : undefined,
		streamFirstEventTimeoutMs: isNemotron ? 0 : undefined,
		streamMarkupHealingPattern: undefined,
		toolSchemaFlavor: undefined,
		alwaysSendMaxTokens: false,
		disableReasoningOnForcedToolChoice: false,
		disableReasoningOnToolChoice: false,
		supportsToolChoice: true,
		supportsForcedToolChoice: true,
		supportsNamedToolChoice: true,
		maxTokensField: "max_tokens",
		// Live probe confirmed the upstream field is `reasoning`.
		reasoningContentField: "reasoning",
		// Same lesson as OpenBroker: do NOT force replay.
		requiresReasoningContentForToolCalls: false,
		requiresReasoningContentForAllAssistantTurns: false,
		allowsSyntheticReasoningContentForToolCalls: true,
		requiresAssistantContentForToolCalls: false,
		thinkingFormat: "openai",
		reasoningDisableMode: "lowest-effort",
		omitReasoningEffort: false,
		includeEncryptedReasoning: true,
		supportsStrictMode: false,
		toolStrictMode: "mixed",
	};
}
