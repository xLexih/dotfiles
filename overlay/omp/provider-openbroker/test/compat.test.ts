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
});
