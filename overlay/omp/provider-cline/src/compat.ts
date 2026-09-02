import type {Model} from "@oh-my-pi/pi-ai";

/**
 * Cline is an OpenRouter-shaped proxy; live probes on 2026-09-02 returned:
 *   - `choices[0].message.reasoning` is a string (not `reasoning_content`)
 *   - `choices[0].message.reasoning_details` may also be present as
 *     `[{format:"unknown", type:"reasoning.text", text:"..."}]` — the
 *     flat `reasoning` string is what OMP's `openai-completions` handler
 *     reads; the array is dropped.
 *   - `choices[0].native_finish_reason` is present alongside the OpenAI
 *     `finish_reason`; OMP uses the OpenAI field.
 *   - `usage.completion_tokens_details.reasoning_tokens` is accurate.
 *   - Standard `tool_calls` envelope; live `m3:free` test successfully
 *     returned a `tool_calls` choice with `finish_reason: "tool_calls"`.
 *   - Standard `content: string | null`; `m2.7:free` returned reasoning
 *     + `content: "OK"`.
 *
 * Cline is upstream of the actual inference providers (GMICloud, Google AI
 * Studio, Decart, etc.), so different free model ids route to different
 * backends with slightly different reasoning/prefill behavior. The compat
 * policy below branches on the model family rather than hard-coding a single
 * surface, mirroring the OpenBroker pattern at
 * `overlay/omp/provider-openbroker/src/compat.ts:17-78`.
 */
export function clineCompat(model: Pick<Model, "id">): Model<"openai-completions">["compat"] {
	const id = model.id.toLowerCase();
	const isMinimax = id.includes("minimax");
	const isKimi = id.includes("kimi");
	const isNemotron = id.includes("nemotron");
	const isGlm = id.includes("z-ai/glm") || id.includes("glm-");
	const isGemma = id.includes("gemma");
	const isCohere = id.includes("cohere") || id.includes("north");

	return {
		supportsStore: false,
		supportsDeveloperRole: false,
		supportsMultipleSystemMessages: false,
		// MiniMax m2.7/m3, kimi, nemotron, glm: reasoning-capable.
		// gemma-4 IT and cohere/north: plain instruct.
		supportsReasoningEffort: !isGemma && !isCohere,
		supportsReasoningParams: !isGemma && !isCohere,
		supportsSamplingParams: true,
		supportsPenaltyAndStopParams: true,
		supportsUsageInStreaming: true,
		// MiniMax m2/m3 reasoning is always-on and not user-controllable on
		// the underlying API — same as OpenBroker's `minimax` branch.
		reasoningDeltasMayBeCumulative: isMinimax,
		// Reasoning prefill on MiniMax/Kimi/Nemotron can sit silent past 300s
		// before the first SSE event. Same exemption OpenBroker uses for Kimi
		// at `overlay/omp/provider-openbroker/src/compat.ts:34-39`.
		streamIdleTimeoutMs: isKimi || isMinimax || isNemotron ? 300_000 : undefined,
		streamFirstEventTimeoutMs: isKimi || isMinimax || (isNemotron && Boolean(model.reasoning)) ? 0 : undefined,
		// Cline is a plain OpenAI surface — no DSML/inband healing.
		streamMarkupHealingPattern: undefined,
		toolSchemaFlavor: undefined,
		// MiniMax m2.7+ requires `max_tokens` on every request to size the
		// reasoning budget; other families accept it as optional.
		alwaysSendMaxTokens: isMinimax,
		disableReasoningOnForcedToolChoice: isKimi,
		disableReasoningOnToolChoice: false,
		supportsToolChoice: true,
		supportsForcedToolChoice: true,
		supportsNamedToolChoice: true,
		maxTokensField: "max_tokens",
		// Live probe confirmed the upstream field is `reasoning` on both
		// reasoning and non-reasoning routes.
		reasoningContentField: "reasoning",
		// See comment at top: do NOT force reasoning replay — the same lesson
		// from OpenBroker's `compat.ts:58-64` applies here.
		requiresReasoningContentForToolCalls: false,
		requiresReasoningContentForAllAssistantTurns: false,
		allowsSyntheticReasoningContentForToolCalls: true,
		requiresAssistantContentForToolCalls: false,
		thinkingFormat: "openai",
		reasoningDisableMode: "lowest-effort",
		// MiniMax M2/M3 thinking is always on; the underlying API rejects
		// `reasoning_effort` for those models.
		omitReasoningEffort: isMinimax,
		includeEncryptedReasoning: true,
		supportsStrictMode: false,
		toolStrictMode: "mixed",
		// GLM-5 family accepts the field; MiniMax rejects it.
	};
}
