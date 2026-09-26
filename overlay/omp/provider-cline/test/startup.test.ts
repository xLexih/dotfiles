import { describe, expect, it, beforeEach } from "bun:test";
import clineFreeProvider from "../src/index.ts";

const RECOMMENDED_FIXTURE = {
  free: [
    { id: "poolside/laguna-s-2.1:free", name: "laguna-s-2.1:free" },
    { id: "cline-free/solar-pro4", name: "Solar Pro 4" },
  ],
};

const CATALOG_FIXTURE = {
  data: [
    {
      id: "poolside/laguna-s-2.1:free",
      name: "Poolside Laguna S 2.1",
      context_length: 262_144,
      supported_parameters: ["include_reasoning", "max_tokens", "reasoning"],
      architecture: { modality: "text->text", input_modalities: ["text"] },
      top_provider: { max_completion_tokens: 32_768, context_length: 262_144 },
    },
    {
      id: "qwen/qwen3.8-27b:free",
      name: "Qwen3.8 27B",
      context_length: 262_144,
      supported_parameters: ["max_tokens", "reasoning"],
      architecture: { modality: "text+image->text", input_modalities: ["text", "image"] },
      top_provider: { max_completion_tokens: 32_768, context_length: 262_144 },
    },
    {
      id: "nvidia/nemotron-3.5-content-safety:free",
      name: "Nemotron 3.5 Content Safety",
      context_length: 256_000,
      supported_parameters: ["max_tokens"],
      architecture: { modality: "text->text", input_modalities: ["text"] },
      top_provider: { max_completion_tokens: 8_192, context_length: 256_000 },
    },
  ],
};

function stubFetch(handler: (url: URL) => unknown) {
  (globalThis as Record<string, unknown>).fetch = async (input: unknown) => {
    const url = new URL(String(input));
    return { ok: true, status: 200, json: async () => handler(url) } as Response;
  };
}

function fakePi() {
  const registrations: { id: string; config: Record<string, any> }[] = [];
  const commands: Record<string, unknown> = {};
  const pi = {
    registerProvider: (id: string, config: Record<string, any>) => {
      registrations.push({ id, config });
    },
    registerCommand: (name: string, def: unknown) => {
      commands[name] = def;
    },
    on: (_event: string, _handler: unknown) => {},
  };
  return { pi, registrations, commands };
}

const liveFetch = () =>
  stubFetch(url =>
    url.pathname.endsWith("/ai/cline/recommended-models") ? RECOMMENDED_FIXTURE : CATALOG_FIXTURE,
  );

describe("cline startup model fetch", () => {
  beforeEach(liveFetch);

  it("registers a non-empty static fallback catalog immediately", async () => {
    const { pi, registrations } = fakePi();
    await clineFreeProvider(pi as never);
    expect(registrations.length).toBe(1);
    expect(registrations[0]!.id).toBe("cline");
    const models = registrations[0]!.config.models as Record<string, unknown>[];
    expect(models.length).toBeGreaterThan(0);
    for (const model of models) {
      expect(model).toMatchObject({ provider: "cline", baseUrl: "https://api.cline.bot/api/v1", api: "openai-completions" });
    }
  });

  it("fetchDynamicModels unions curated free with catalog :free routes", async () => {
    const { pi, registrations } = fakePi();
    await clineFreeProvider(pi as never);
    const models = (await registrations[0]!.config.fetchDynamicModels()) as Record<string, unknown>[];
    // Curated order first, then catalog extras; guardrails excluded.
    expect(models.map(m => m.id)).toEqual([
      "poolside/laguna-s-2.1:free",
      "cline-free/solar-pro4",
      "qwen/qwen3.8-27b:free",
    ]);
    // Enriched from live catalog metadata.
    expect(models.find(m => m.id === "poolside/laguna-s-2.1:free")).toMatchObject({
      provider: "cline",
      baseUrl: "https://api.cline.bot/api/v1",
      api: "openai-completions",
      contextWindow: 262_144,
      maxTokens: 32_768,
      reasoning: true,
      input: ["text"],
    });
    // Unknown to the catalog: still registered with safe defaults.
    expect(models.find(m => m.id === "cline-free/solar-pro4")).toMatchObject({
      provider: "cline",
      contextWindow: 128_000,
      maxTokens: 65_536,
    });
  });

  it("falls back to the static snapshot when discovery fails", async () => {
    (globalThis as Record<string, unknown>).fetch = async () => {
      throw new Error("offline");
    };
    const { pi, registrations } = fakePi();
    await clineFreeProvider(pi as never);
    const models = (await registrations[0]!.config.fetchDynamicModels()) as unknown[];
    expect(models.length).toBeGreaterThan(0);
  });
});
