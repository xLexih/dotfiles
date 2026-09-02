import {describe, expect, it} from "bun:test";
import type {Model} from "@oh-my-pi/pi-ai";
import {openBrokerCompat} from "../src/compat.ts";

const baseModel = {
  provider: "openbroker",
  baseUrl: "https://api.openbroker.gonka.gg/v1",
  api: "openai-completions",
  reasoning: true,
} as unknown as Model;

const compatFor = (id: string): Record<string, unknown> =>
  openBrokerCompat({...baseModel, id}) as Record<string, unknown>;

describe("OpenBroker compat", () => {
  it("marks MiniMax reasoning deltas as cumulative", () => {
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").reasoningDeltasMayBeCumulative).toBe(true);
    expect(compatFor("moonshotai/Kimi-K2.6").reasoningDeltasMayBeCumulative).toBe(false);
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").reasoningDeltasMayBeCumulative).toBe(false);
  });

  it("extends stream idle watchdogs for Kimi and DeepSeek reasoning", () => {
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").streamIdleTimeoutMs).toBeUndefined();
    expect(compatFor("moonshotai/Kimi-K2.6").streamIdleTimeoutMs).toBe(300_000);
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").streamIdleTimeoutMs).toBe(300_000);
  });

  it("selects markup healing and tool schema flavors per family", () => {
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").streamMarkupHealingPattern).toBeUndefined();
    expect(compatFor("moonshotai/Kimi-K2.6").streamMarkupHealingPattern).toBe("kimi");
    expect(compatFor("moonshotai/Kimi-K2.6").toolSchemaFlavor).toBe("moonshot-mfjs");
    // The broker is a standard OpenAI surface (delta.tool_calls), not a DeepSeek
    // DSML/inband surface — dsml healing would corrupt tool parsing.
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").streamMarkupHealingPattern).toBeUndefined();
  });

  it("disables the first-event watchdog for reasoning families", () => {
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").streamFirstEventTimeoutMs).toBe(0);
    expect(compatFor("moonshotai/Kimi-K2.6").streamFirstEventTimeoutMs).toBe(0);
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").streamFirstEventTimeoutMs).toBeUndefined();
  });

  it("reads thinking from the `reasoning` field the broker actually emits", () => {
    // docs.gonkabroker.com: thinking arrives in `reasoning`
    // (`choices[].delta.reasoning`), never `reasoning_content`.
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").reasoningContentField).toBe("reasoning");
    expect(compatFor("moonshotai/Kimi-K2.6").reasoningContentField).toBe("reasoning");
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").reasoningContentField).toBe("reasoning");
  });

  it("does not enforce DeepSeek-native reasoning replay", () => {
    // The broker rebuilds history server-side as a plain OpenAI surface; it does
    // not require `reasoning_content` passthrough the way DeepSeek's native API
    // does. Enabling it caused pi-ai to inject empty `reasoning_content: ""` on
    // every assistant turn when the model produced no thinking, poisoning the
    // request and degrading the model into a loop as context grew.
    for (const id of ["deepseek-ai/DeepSeek-V4-Flash-0731", "moonshotai/Kimi-K2.6", "MiniMaxAI/MiniMax-M2.7"]) {
      expect(compatFor(id).requiresReasoningContentForToolCalls).toBe(false);
      expect(compatFor(id).requiresReasoningContentForAllAssistantTurns).toBe(false);
      expect(compatFor(id).allowsSyntheticReasoningContentForToolCalls).toBe(true);
    }
  });

  it("sends standard content:null on tool-call turns instead of empty text arrays", () => {
    // Empty `content: [{type:"text",text:""}]` next to tool_calls 400s on the
    // broker ("content[].text: must not be empty"). Standard OpenAI `content:
    // null` avoids the validator; the MiniMax route's array-format requirement
    // is handled by the payload normalizer.
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").requiresAssistantContentForToolCalls).toBe(false);
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").requiresAssistantContentForToolCalls).toBe(false);
    expect(compatFor("moonshotai/Kimi-K2.6").requiresAssistantContentForToolCalls).toBe(false);
  });

  it("omits reasoning_effort for MiniMax, whose thinking is always on and not controllable", () => {
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").omitReasoningEffort).toBe(true);
    expect(compatFor("moonshotai/Kimi-K2.6").omitReasoningEffort).toBe(false);
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").omitReasoningEffort).toBe(false);
  });

  it("keeps tool_choice from silently disabling DeepSeek reasoning", () => {
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").disableReasoningOnToolChoice).toBe(false);
  });
});
