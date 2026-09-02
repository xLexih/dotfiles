import type {Model} from "@oh-my-pi/pi-ai";

/**
 * Hand-built OpenAI-compat policy for the broker's served model families,
 * mirroring what the built-in catalog would derive if it recognized these ids.
 *
 * Authoritative source: docs.gonkabroker.com — "OpenAI API Compatibility" and
 * "Supported Models". OpenBroker is a normal OpenAI-compatible proxy over the
 * Gonka devshard network; it does NOT re-impose DeepSeek-native contracts.
 * - Reasoning for thinking models arrives in the `reasoning` field
 *   (`choices[].delta.reasoning` streaming, before content), never
 *   `reasoning_content`.
 * - The broker accepts standard OpenAI content (string or `[{type:"text"}]`)
 *   and standard OpenAI `tool_calls`; it is not a DSML/inband DeepSeek surface.
 * - `reasoning_effort` is accepted for model families with a thinking switch.
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
    // protects against genuine inter-event stalls.
    streamFirstEventTimeoutMs: kimi || (deepseek && Boolean(model.reasoning)) ? 0 : undefined,
    // The broker serves standard OpenAI `tool_calls` and `content` — NOT the
    // DeepSeek DSML/inband tool envelope or plain-text tool calls. `dsml` healing
    // would corrupt parsed tool calls, so only Kimi's native pattern applies.
    streamMarkupHealingPattern: kimi ? "kimi" : undefined,
    toolSchemaFlavor: kimi ? "moonshot-mfjs" : undefined,
    alwaysSendMaxTokens: kimi,
    disableReasoningOnForcedToolChoice: kimi,
    disableReasoningOnToolChoice: false,
    supportsToolChoice: true,
    supportsForcedToolChoice: true,
    supportsNamedToolChoice: true,
    maxTokensField: "max_tokens",
    // OpenBroker streams thinking under `reasoning` (delta.reasoning), not
    // `reasoning_content`. Using the wrong field name made pi-ai never capture
    // thinking and, combined with the `requiresReasoningContent*` flags below,
    // inject empty `reasoning_content` on every replayed assistant turn.
    reasoningContentField: "reasoning",
    // The broker is a plain OpenAI surface that rebuilds history server-side; it
    // does NOT require reasoning replay the way DeepSeek's native API does.
    // Forcing these on was the root cause: when a model produced no reasoning
    // (e.g. DeepSeek V4 Flash, thinking off by default), pi-ai emitted empty
    // `reasoning_content: ""` on every assistant turn (Tier-2 replay), poisoning
    // the request and degrading the model into a degenerate loop as context grew.
    requiresReasoningContentForToolCalls: false,
    requiresReasoningContentForAllAssistantTurns: false,
    allowsSyntheticReasoningContentForToolCalls: true,
    // Let tool-call turns send standard `content: null` instead of forcing an
    // empty `content: [{type:"text",text:""}]` array, which the proxy rejects
    // with "content[].text: must not be empty" (seen on the wire).
    requiresAssistantContentForToolCalls: false,
    thinkingFormat: "openai",
    reasoningDisableMode: "lowest-effort",
    // MiniMax M2.7 thinking is always on and not controllable — it accepts no
    // `reasoning_effort`, so omit the field entirely for it.
    omitReasoningEffort: minimax,
    includeEncryptedReasoning: true,
    supportsStrictMode: false,
    toolStrictMode: "mixed",
  };
}
