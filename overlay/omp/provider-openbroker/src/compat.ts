import type {Model} from "@oh-my-pi/pi-ai";

/**
 * Hand-built OpenAI-compat policy for the broker's served model families,
 * mirroring what the built-in catalog would derive if it recognized these ids.
 */
export function openBrokerCompat(model: Model): Model["compat"] {
  const id = model.id.toLowerCase();
  const kimi = id.includes("kimi");
  const deepseek = id.includes("deepseek");
  const minimax = id.includes("minimax");
  return {
    supportsStore: false,
    supportsDeveloperRole: false,
    supportsMultipleSystemMessages: false,
    supportsReasoningEffort: true,
    supportsReasoningParams: true,
    supportsSamplingParams: true,
    supportsPenaltyAndStopParams: true,
    supportsUsageInStreaming: true,
    reasoningDeltasMayBeCumulative: minimax,
    // Match built-in reasoning-model watchdogs: long thinking pauses must not
    // trip the default idle timeout.
    streamIdleTimeoutMs: kimi || (deepseek && Boolean(model.reasoning)) ? 300_000 : undefined,
    // Reasoning prefill on the devshard can sit silent >300s before the first SSE
    // event; the first-event watchdog would kill it as a false timeout. 0 = no
    // first-event watchdog (unbounded prefill), while streamIdleTimeoutMs still
    // protects against genuine inter-event stalls. Mirrors the built-in's local
    // backend handling of unbounded model-load/prefill time.
    streamFirstEventTimeoutMs: kimi || (deepseek && Boolean(model.reasoning)) ? 0 : undefined,
    streamMarkupHealingPattern: kimi ? "kimi" : deepseek ? "dsml" : undefined,
    toolSchemaFlavor: kimi ? "moonshot-mfjs" : undefined,
    alwaysSendMaxTokens: kimi,
    disableReasoningOnForcedToolChoice: kimi,
    disableReasoningOnToolChoice: deepseek && Boolean(model.reasoning),
    supportsToolChoice: true,
    supportsForcedToolChoice: true,
    supportsNamedToolChoice: true,
    maxTokensField: "max_tokens",
    reasoningContentField: "reasoning_content",
    requiresReasoningContentForToolCalls: kimi || minimax || deepseek && Boolean(model.reasoning),
    requiresReasoningContentForAllAssistantTurns: minimax || deepseek && Boolean(model.reasoning),
    allowsSyntheticReasoningContentForToolCalls: !minimax && (!deepseek || !model.reasoning),
    requiresAssistantContentForToolCalls: kimi || minimax || deepseek && Boolean(model.reasoning),
    thinkingFormat: "openai",
    reasoningDisableMode: "lowest-effort",
    omitReasoningEffort: false,
    includeEncryptedReasoning: true,
    supportsStrictMode: false,
    toolStrictMode: "mixed",
  };
}
