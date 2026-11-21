import {describe, expect, it} from "bun:test";
import type {Model} from "@oh-my-pi/pi-ai";
import {openBrokerCompat} from "../src/compat.ts";
import {reasoningProfileForParser} from "../src/profiles.ts";

const baseModel = {
  provider: "openbroker",
  baseUrl: "https://api.openbroker.gonka.gg/v1",
  api: "openai-completions",
  reasoning: true,
  id: "vendor/model",
} as unknown as Model;

const compatFor = (parser?: string): Record<string, unknown> =>
  openBrokerCompat(baseModel, reasoningProfileForParser(parser)) as Record<string, unknown>;

describe("OpenBroker reasoning profiles", () => {
  it("maps MiniMax inline thinking without a reasoning switch", () => {
    expect(reasoningProfileForParser("minimax_m2_append_think")).toMatchObject({
      reasoning: false,
      cumulativeDeltas: true,
      omitEffort: true,
      strictContent: true,
    });
  });

  it("maps DeepSeek to none-style off and low/high/max efforts", () => {
    expect(reasoningProfileForParser("deepseek_v4")).toMatchObject({
      reasoning: true,
      disableMode: "none-effort",
      idleTimeoutMs: 300_000,
      thinking: {mode: "effort", efforts: ["low", "high", "max"], defaultLevel: "high"},
    });
  });

  it("maps GLM to lowest-effort off and a max default", () => {
    expect(reasoningProfileForParser("glm45")).toMatchObject({
      reasoning: true,
      disableMode: "lowest-effort",
      thinking: {mode: "effort", efforts: ["low", "high", "max"], defaultLevel: "max"},
    });
  });

  it("maps Kimi to its native healing and tool schema rules", () => {
    expect(reasoningProfileForParser("kimi_k2")).toMatchObject({
      reasoning: true,
      disableMode: "lowest-effort",
      idleTimeoutMs: 300_000,
      markupHealing: "kimi",
      toolSchemaFlavor: "moonshot-mfjs",
      disableReasoningOnForcedToolChoice: true,
      thinking: {defaultLevel: "high"},
    });
  });

  it("treats an absent parser as non-reasoning and fails unknown parsers", () => {
    expect(reasoningProfileForParser(undefined)).toMatchObject({
      reasoning: false,
      cumulativeDeltas: false,
      omitEffort: true,
      strictContent: false,
    });
    expect(() => reasoningProfileForParser("future_parser")).toThrow(
      "Unknown OpenBroker reasoning parser: future_parser",
    );
  });
});

describe("OpenBroker compat", () => {
  it("marks MiniMax reasoning deltas as cumulative", () => {
    expect(compatFor("minimax_m2_append_think").reasoningDeltasMayBeCumulative).toBe(true);
    expect(compatFor("kimi_k2").reasoningDeltasMayBeCumulative).toBe(false);
    expect(compatFor("deepseek_v4").reasoningDeltasMayBeCumulative).toBe(false);
  });

  it("extends stream idle watchdogs for Kimi and DeepSeek reasoning", () => {
    expect(compatFor("minimax_m2_append_think").streamIdleTimeoutMs).toBeUndefined();
    expect(compatFor("kimi_k2").streamIdleTimeoutMs).toBe(300_000);
    expect(compatFor("deepseek_v4").streamIdleTimeoutMs).toBe(300_000);
    expect(compatFor("glm45").streamIdleTimeoutMs).toBeUndefined();
  });

  it("selects markup healing and tool schema flavors from the parser", () => {
    expect(compatFor("minimax_m2_append_think").streamMarkupHealingPattern).toBeUndefined();
    expect(compatFor("kimi_k2").streamMarkupHealingPattern).toBe("kimi");
    expect(compatFor("kimi_k2").toolSchemaFlavor).toBe("moonshot-mfjs");
    // The broker is a standard OpenAI surface (delta.tool_calls), not a DeepSeek
    // DSML/inband surface — dsml healing would corrupt tool parsing.
    expect(compatFor("deepseek_v4").streamMarkupHealingPattern).toBeUndefined();
  });

  it("allows the documented 20-minute header wait for all models", () => {
    for (const parser of [undefined, "minimax_m2_append_think", "deepseek_v4", "glm45", "kimi_k2"]) {
      expect(compatFor(parser).streamFirstEventTimeoutMs).toBe(1_200_000);
    }
  });

  it("uses the parser's reasoning-off behavior", () => {
    expect(compatFor("deepseek_v4").reasoningDisableMode).toBe("none-effort");
    expect(compatFor("glm45").reasoningDisableMode).toBe("lowest-effort");
    expect(compatFor("kimi_k2").reasoningDisableMode).toBe("lowest-effort");
    expect(compatFor("minimax_m2_append_think").reasoningDisableMode).toBe("lowest-effort");
  });

  it("reads thinking from either reasoning alias the broker emits", () => {
    // Streams carry both `reasoning` and `reasoning_content`; parsing accepts
    // either, and replay keeps using `reasoning`.
    for (const parser of [undefined, "deepseek_v4", "glm45", "kimi_k2", "minimax_m2_append_think"]) {
      expect(compatFor(parser).reasoningContentField).toBe("reasoning");
    }
  });

  it("does not enforce DeepSeek-native reasoning replay", () => {
    // The broker rebuilds history server-side as a plain OpenAI surface; it does
    // not require `reasoning_content` passthrough the way DeepSeek's native API
    // does. Enabling it caused pi-ai to inject empty `reasoning_content: ""` on
    // every assistant turn when the model produced no thinking, poisoning the
    // request and degrading the model into a loop as context grew.
    for (const parser of [undefined, "deepseek_v4", "glm45", "kimi_k2", "minimax_m2_append_think"]) {
      expect(compatFor(parser).requiresReasoningContentForToolCalls).toBe(false);
      expect(compatFor(parser).requiresReasoningContentForAllAssistantTurns).toBe(false);
      expect(compatFor(parser).allowsSyntheticReasoningContentForToolCalls).toBe(true);
    }
  });

  it("sends standard content:null on tool-call turns instead of empty text arrays", () => {
    // Empty `content: [{type:"text",text:""}]` next to tool_calls 400s on the
    // broker ("content[].text: must not be empty"). Standard OpenAI `content:
    // null` avoids the validator; the MiniMax route's array-format requirement
    // is handled by the payload normalizer.
    for (const parser of [undefined, "deepseek_v4", "glm45", "kimi_k2", "minimax_m2_append_think"]) {
      expect(compatFor(parser).requiresAssistantContentForToolCalls).toBe(false);
    }
  });

  it("omits reasoning_effort only where the parser has no switch", () => {
    expect(compatFor("minimax_m2_append_think").omitReasoningEffort).toBe(true);
    expect(compatFor(undefined).omitReasoningEffort).toBe(true);
    expect(compatFor("deepseek_v4").omitReasoningEffort).toBe(false);
    expect(compatFor("glm45").omitReasoningEffort).toBe(false);
    expect(compatFor("kimi_k2").omitReasoningEffort).toBe(false);
  });

  it("advertises reasoning effort only for parser families that accept it", () => {
    expect(compatFor("deepseek_v4").supportsReasoningEffort).toBe(true);
    expect(compatFor("glm45").supportsReasoningEffort).toBe(true);
    expect(compatFor("kimi_k2").supportsReasoningEffort).toBe(true);
    expect(compatFor("minimax_m2_append_think").supportsReasoningEffort).toBe(false);
    expect(compatFor(undefined).supportsReasoningEffort).toBe(false);
  });

  it("keeps tool_choice from silently disabling DeepSeek reasoning", () => {
    expect(compatFor("deepseek_v4").disableReasoningOnToolChoice).toBe(false);
    expect(compatFor("kimi_k2").disableReasoningOnForcedToolChoice).toBe(true);
  });

  it("uses the broker's documented max_tokens field", () => {
    for (const parser of [undefined, "deepseek_v4", "glm45", "kimi_k2", "minimax_m2_append_think"]) {
      expect(compatFor(parser).maxTokensField).toBe("max_tokens");
    }
  });
});
