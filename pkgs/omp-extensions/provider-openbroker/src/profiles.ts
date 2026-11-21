export type ThinkingEffort = "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

export interface ThinkingProfile {
  mode: "effort";
  efforts: readonly ThinkingEffort[];
  defaultLevel?: ThinkingEffort;
}

/**
 * Wire behavior implied by a chain `--reasoning-parser`. The parser is the
 * serving contract: it decides whether thinking is a separate stream, whether
 * an effort switch exists, and how tool calls are encoded.
 */
export interface ReasoningProfile {
  reasoning: boolean;
  /** MiniMax streams cumulative thinking deltas inline in `content`. */
  cumulativeDeltas: boolean;
  /** No `reasoning_effort` field is accepted. */
  omitEffort: boolean;
  disableMode: "none-effort" | "lowest-effort";
  idleTimeoutMs?: number;
  markupHealing?: "kimi";
  toolSchemaFlavor?: "moonshot-mfjs";
  disableReasoningOnForcedToolChoice: boolean;
  /** MiniMax rejects non-array assistant/tool content. */
  strictContent: boolean;
  thinking?: ThinkingProfile;
}

const REASONING_EFFORTS = ["low", "high", "max"] as const;

export function reasoningProfileForParser(parser: string | undefined): ReasoningProfile {
  switch (parser) {
    case undefined:
      return {reasoning: false, cumulativeDeltas: false, omitEffort: true, disableMode: "lowest-effort", disableReasoningOnForcedToolChoice: false, strictContent: false};
    case "minimax_m2_append_think":
      return {reasoning: false, cumulativeDeltas: true, omitEffort: true, disableMode: "lowest-effort", disableReasoningOnForcedToolChoice: false, strictContent: true};
    case "deepseek_v4":
      return {
        reasoning: true,
        cumulativeDeltas: false,
        omitEffort: false,
        disableMode: "none-effort",
        idleTimeoutMs: 300_000,
        disableReasoningOnForcedToolChoice: false,
        strictContent: false,
        thinking: {mode: "effort", efforts: REASONING_EFFORTS, defaultLevel: "high"},
      };
    case "glm45":
      return {
        reasoning: true,
        cumulativeDeltas: false,
        omitEffort: false,
        disableMode: "lowest-effort",
        disableReasoningOnForcedToolChoice: false,
        strictContent: false,
        thinking: {mode: "effort", efforts: REASONING_EFFORTS, defaultLevel: "max"},
      };
    case "kimi_k2":
      return {
        reasoning: true,
        cumulativeDeltas: false,
        omitEffort: false,
        disableMode: "lowest-effort",
        idleTimeoutMs: 300_000,
        markupHealing: "kimi",
        toolSchemaFlavor: "moonshot-mfjs",
        disableReasoningOnForcedToolChoice: true,
        strictContent: false,
        thinking: {mode: "effort", efforts: REASONING_EFFORTS, defaultLevel: "high"},
      };
    default:
      throw new Error(`Unknown OpenBroker reasoning parser: ${parser}`);
  }
}
