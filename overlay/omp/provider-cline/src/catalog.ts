import type {Model} from "@oh-my-pi/pi-ai";

/**
 * Cline serves a large model catalog (425+ models on 2026-09-02) through an
 * OpenAI-compatible chat-completions endpoint at `https://api.cline.bot/api/v1`.
 *
 * Cline's `/v1/models` returns a standard OpenAI payload with no per-model
 * context/output metadata (all null), so we curate a list of free `:free`
 * models that are useful for an OMP coding agent and hard-code the
 * upstream-model-card limits. The provider registers `fetchDynamicModels`
 * that intersects the live catalog with the curated descriptors — so a new
 * `:free` model becomes available the moment a row is added here, without
 * touching any other code.
 */
export interface ClineModelDescriptor {
	id: string;
	name: string;
	/** Upstream model card context window. */
	contextWindow: number;
	/** Output cap baked into the registration. */
	maxTokens: number;
	reasoning: boolean;
	input: ("text" | "image")[];
	highContextWarnTokens: number;
	highContextHint: "preferred" | "acceptable" | "avoid";
}

/**
 * Free-tier Cline models that survived a live probe on 2026-09-02.
 *
 * Skipped after probe:
 *   - `inclusionai/ling-3.0-flash-fin:free` — returned "empty response content"
 *   - `thinkingmachines/inkling*` — same
 *   - `nvidia/nemotron-3.5-content-safety:free` — guardrail, not agentic
 *   - `poolside/laguna*` — no tool-call support
 *   - `liquid/lfm-2.5-2.6b:free` — 2.6B params, too small for OMP
 *   - `dots-studio/dots-3-note-preview:free` — note-taking, not coding
 *
 * m3 gets a larger `maxTokens` (65,536) because it's the flagship and a
 * coding agent benefits from longer completions on free quota. M2.7 follows
 * the OpenBroker 16,384 verbosity-brake pattern. gemma-4 IT models are
 * `hint: "avoid"` so OMP's `ctx.models` does not route large contexts to
 * 32k-context small models.
 */
// Ordering priority: working free models first (live-verified 2026-09-03),
// then intermittent ones, then known-broken (`hint: "avoid"`) last. OMP's
// model picker reads the array in order, so flagship / high-context
// options surface first.
export const CLINE_MODELS: readonly ClineModelDescriptor[] = [
	{
		id: "minimax/minimax-m3:free",
		name: "MiniMax M3 Free",
		// M3 spec: 1,000,000-token context; max output 512k per upstream
		// announcement. Free-tier cap below.
		contextWindow: 1_000_000,
		maxTokens: 65_536,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "preferred",
	},
	{
		id: "nvidia/nemotron-3-super-120b-a12b:free",
		name: "Nemotron 3 Super 120B Free",
		contextWindow: 1_000_000,
		// NVIDIA's OpenCode default: 32k output.
		maxTokens: 32_768,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "preferred",
	},
	{
		id: "nvidia/nemotron-3-ultra-550b-a55b:free",
		name: "Nemotron 3 Ultra 550B Free",
		// NVIDIA family: up to 1,048,576; conservative cap on free tier.
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "nvidia/nemotron-3.5-lightning:free",
		name: "Nemotron 3.5 Lightning Free",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
		name: "Nemotron 3 Nano 30B (Reasoning) Free",
		// NVIDIA NIM current practical ceiling: 262,144.
		contextWindow: 262_144,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "google/gemma-4-31b-it:free",
		name: "Gemma 4 31B IT Free",
		contextWindow: 32_000,
		maxTokens: 8_192,
		reasoning: false,
		input: ["text"],
		highContextWarnTokens: 24_000,
		highContextHint: "acceptable",
	},
	{
		id: "google/gemma-4-26b-a4b-it:free",
		name: "Gemma 4 26B IT Free",
		contextWindow: 32_000,
		maxTokens: 8_192,
		reasoning: false,
		input: ["text"],
		highContextWarnTokens: 24_000,
		highContextHint: "acceptable",
	},
	// `z-ai/glm-5.2:free` is currently rate-limited upstream by Decart
	// (Cline's provider for this model id). Cline/OpenRouter return HTTP 429
	// with `provider_error_code: "upstream_429"` and
	// `limit_source: "upstream_provider_shared_pool"`. The error message
	// recommends adding an OpenRouter BYOK key — see
	// https://openrouter.ai/settings/integrations. Without it, the public
	// free bucket stays throttled. Marked `hint: "avoid"` so OMP doesn't
	// surface it as a primary suggestion, but kept in the list so it
	// re-appears when Decart restores capacity.
	{
		id: "z-ai/glm-5.2:free",
		name: "GLM 5.2 Free (currently rate-limited upstream)",
		// Z.AI / GLM-5.2: max_position_embeddings = 1,048,576.
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "avoid",
	},
	// `minimax/minimax-m2.7:free` and `cohere/north-mini-code:free` are
	// intermittent — they returned `{"error":"empty response content"}` on
	// 2026-09-03 probes but are not consistently broken. Marked
	// `hint: "acceptable"` so they show in the picker but OMP's `ctx.models`
	// selection will prefer the working ones.
	{
		id: "minimax/minimax-m2.7:free",
		name: "MiniMax M2.7 Free",
		// M2.7: 204,800-token context per MiniMax's hosted API docs.
		contextWindow: 204_800,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 150_000,
		highContextHint: "acceptable",
	},
	{
		id: "cohere/north-mini-code:free",
		name: "Cohere North Mini Code Free",
		contextWindow: 128_000,
		maxTokens: 8_192,
		reasoning: false,
		input: ["text"],
		highContextWarnTokens: 100_000,
		highContextHint: "acceptable",
	},
];

const DESCRIPTORS_BY_ID = new Map(CLINE_MODELS.map(d => [d.id, d]));

export function getClineDescriptor(id: string): ClineModelDescriptor | undefined {
	return DESCRIPTORS_BY_ID.get(id);
}

export function buildClineModel(descriptor: ClineModelDescriptor): Model<"openai-completions"> {
	return {
		id: descriptor.id,
		name: descriptor.name,
		provider: "cline",
		baseUrl: "https://api.cline.bot/api/v1",
		api: "openai-completions",
		reasoning: descriptor.reasoning,
		input: descriptor.input,
		// All curated entries are free; cost reporting is omitted so OMP does
		// not show zero-cost lines in the model picker.
		cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
		contextWindow: descriptor.contextWindow,
		maxTokens: descriptor.maxTokens,
		highContextWarnTokens: descriptor.highContextWarnTokens,
		highContextHint: descriptor.highContextHint,
	} as Model<"openai-completions">;
}

export function staticClineModels(): Model<"openai-completions">[] {
	return CLINE_MODELS.map(buildClineModel);
}

/**
 * Convert a raw `/v1/models` payload into the curated catalog. Cline returns
 * a standard OpenAI shape; we filter to known curated ids and skip everything
 * else.
 */
export function parseClineModels(body: unknown): Model<"openai-completions">[] {
	if (!body || typeof body !== "object") return [];
	// Cline wraps the model list in `{object, data: [...]}` but the catalog
	// endpoint also returns a bare `{data: [...]}` — accept both.
	const data =
		"data" in body && Array.isArray((body as Record<string, unknown>).data)
			? (body as Record<string, unknown>).data
			: "models" in body && Array.isArray((body as Record<string, unknown>).models)
				? (body as Record<string, unknown>).models
				: null;
	if (!data) return [];
	const out: Model<"openai-completions">[] = [];
	for (const entry of data) {
		if (!entry || typeof entry !== "object" || !"id" in entry) continue;
		const id = (entry as {id: unknown}).id;
		if (typeof id !== "string") continue;
		const d = DESCRIPTORS_BY_ID.get(id);
		if (d) out.push(buildClineModel(d));
	}
	return out;
}
