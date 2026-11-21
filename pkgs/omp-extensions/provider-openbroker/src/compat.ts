import type {Model} from "@oh-my-pi/pi-ai";
import type {ReasoningProfile} from "./profiles.ts";

/**
 * OpenAI-compat policy derived from chain serving metadata, not model ids.
 *
 * Authoritative source: openbroker.gonka.gg/docs and the chain `model_args`.
 * OpenBroker is a normal OpenAI-compatible proxy over the Gonka devshard
 * network (`POST /v1/chat/completions`); it does NOT re-impose DeepSeek-native
 * contracts.
 * - Reasoning arrives on both `reasoning` and `reasoning_content`
 *   (`choices[].delta.*`, before content). Parsing accepts either alias.
 * - MiniMax streams its thinking inline in `content` (`<think >...`) and
 *   has no reasoning field or switch.
 * - The broker accepts standard OpenAI content (string or `[{type:"text"}]`)
 *   and standard OpenAI `tool_calls`; it is not a DSML/inband DeepSeek surface.
 * - `reasoning_effort` is accepted for parser families with a thinking switch:
 *   GLM supports low/high/max (default max); DeepSeek supports none/low/high/max.
 */
export function openBrokerCompat(model: Model, profile: ReasoningProfile): Model["compat"] {
  return {
    supportsStore: false,
    supportsDeveloperRole: false,
    supportsMultipleSystemMessages: false,
    supportsReasoningEffort: profile.reasoning,
    supportsReasoningParams: profile.reasoning,
    supportsSamplingParams: true,
    supportsPenaltyAndStopParams: true,
    supportsUsageInStreaming: true,
    reasoningDeltasMayBeCumulative: profile.cumulativeDeltas,
    // Match built-in reasoning-model watchdogs: long thinking pauses must not
    // trip the default idle timeout.
    streamIdleTimeoutMs: profile.idleTimeoutMs,
    // OpenBroker waits up to 20 minutes for response headers while it picks a
    // host. Match that budget instead of the 5-minute pi-ai default.
    streamFirstEventTimeoutMs: 1_200_000,
    // The broker serves standard OpenAI `tool_calls` and `content` — NOT the
    // DeepSeek DSML/inband tool envelope or plain-text tool calls. `dsml` healing
    // would corrupt parsed tool calls, so only Kimi's native pattern applies.
    streamMarkupHealingPattern: profile.markupHealing,
    toolSchemaFlavor: profile.toolSchemaFlavor,
    disableReasoningOnForcedToolChoice: profile.disableReasoningOnForcedToolChoice,
    disableReasoningOnToolChoice: false,
    supportsToolChoice: true,
    supportsForcedToolChoice: true,
    supportsNamedToolChoice: true,
    maxTokensField: "max_tokens",
    // Streams carry both `reasoning` and `reasoning_content` (verified
    // 2026-11-18). Keep `reasoning` for replay compatibility; parsing accepts
    // either alias.
    reasoningContentField: "reasoning",
    // The broker is a plain OpenAI surface that rebuilds history server-side; it
    // does NOT require reasoning replay the way DeepSeek's native API does.
    // Forcing these on was the root cause: when a model produced no reasoning,
    // pi-ai emitted empty `reasoning_content: ""` on every assistant turn
    // (Tier-2 replay), poisoning the request and degrading the model into a
    // degenerate loop as context grew.
    requiresReasoningContentForToolCalls: false,
    requiresReasoningContentForAllAssistantTurns: false,
    allowsSyntheticReasoningContentForToolCalls: true,
    // Let tool-call turns send standard `content: null` instead of forcing an
    // empty `content: [{type:"text",text:""}]` array, which the proxy rejects
    // with "content[].text: must not be empty" (seen on the wire).
    requiresAssistantContentForToolCalls: false,
    thinkingFormat: "openai",
    // DeepSeek treats `reasoning_effort: "none"` as chat mode. GLM has no off
    // switch, so its off setting maps to the supported low effort.
    reasoningDisableMode: profile.disableMode,
    // MiniMax M2.7 streams thinking inline in content and has no switch, so it
    // never receives `reasoning_effort`.
    omitReasoningEffort: profile.omitEffort,
    includeEncryptedReasoning: true,
    supportsStrictMode: false,
    toolStrictMode: "mixed",
  };
}
