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
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").streamMarkupHealingPattern).toBe("dsml");
  });
  it("disables the first-event watchdog for reasoning families", () => {
    // Reasoning prefill can sit silent >300s before the first SSE event; the
    // default first-event timeout aborts the stream as "timed out while waiting
    // for the first event". 0 keeps the idle watchdog while allowing unbounded
    // prefill time.
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").streamFirstEventTimeoutMs).toBe(0);
    expect(compatFor("moonshotai/Kimi-K2.6").streamFirstEventTimeoutMs).toBe(0);
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").streamFirstEventTimeoutMs).toBeUndefined();
  });
  it("injects non-empty assistant content on tool-call turns for every reasoning family", () => {
    // DeepSeek reasoning rejected `content: ""` next to tool_calls with
    // `400 messages[N].content[0].text: must not be empty`, which stranded
    // every tool call (e.g. read) and surfaced as an unexpected stop.
    expect(compatFor("deepseek-ai/DeepSeek-V4-Flash-0731").requiresAssistantContentForToolCalls).toBe(true);
    expect(compatFor("MiniMaxAI/MiniMax-M2.7").requiresAssistantContentForToolCalls).toBe(true);
    expect(compatFor("moonshotai/Kimi-K2.6").requiresAssistantContentForToolCalls).toBe(true);
  });
});
