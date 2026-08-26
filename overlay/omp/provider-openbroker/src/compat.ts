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
    // MiniMax streams cumulative reasoning_content snapshots; the built-in catalog
    // derives this from the /minimax/i id pattern, which a hand-built compat must
    // carry explicitly or thinking deltas concatenate as if incremental.
    reasoningDeltasMayBeCumulative: minimax,
    // Match built-in reasoning-model watchdogs: long thinking pauses must not
    // trip the default idle timeout.
    streamIdleTimeoutMs: kimi || (deepseek && Boolean(model.reasoning)) ? 300_000 : undefined,
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
    requiresAssistantContentForToolCalls: kimi || minimax,
    thinkingFormat: "openai",
    reasoningDisableMode: "lowest-effort",
    omitReasoningEffort: false,
    includeEncryptedReasoning: true,
    supportsStrictMode: false,
    toolStrictMode: "mixed",
  };
}
