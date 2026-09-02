import type {Model} from "@oh-my-pi/pi-ai";

/**
 * TokenRouter serves upstream chat-completions APIs behind an OpenAI-compatible
 * proxy at `https://api.tokenrouter.com/v1`. Pricing comes from TokenRouter's
 * model pages; context/output ceilings come from the upstream model card or
 * the GPU provider serving it.
 *
 * Per-model cost and context overrides are applied only when the model id
 * matches exactly — `fetchDynamicModels` filters the upstream `/v1/models`
 * payload through `coerceTokenrouterModel` so the overrides stay auditable.
 */
export interface TokenrouterModelDescriptor {
	id: string;
	name: string;
	/** Total context window from the upstream model card. */
	contextWindow: number;
	/** Output cap baked into the registration. Acts as a verbosity brake on
	 * the free route and prevents a 131k single-turn response from starving
	 * later turns. */
	maxTokens: number;
	/** USD per 1M tokens; OMP only displays cost totals. */
	cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
	reasoning: boolean;
	input: ("text" | "image")[];
	highContextWarnTokens: number;
	highContextHint: "preferred" | "acceptable" | "avoid";
}

/**
 * Curated catalog. TokenRouter does not publish per-model context/output on
 * its gateway page, so the numbers come from the upstream model card and the
 * third-party NIM/HF configs that serve the same weights.
 *
 * Both entries are reasoning-capable. The free `glm-5.3-free` route is
 * upstream-served GLM-5.3 (architectural max 1,048,576 tokens); the paid
 * `glm-5.3-flash` shares the same upstream model with a different serving
 * profile. A 16,384 `maxTokens` cap keeps free-tier turns from self-correcting
 * into 12k-character rambles — same rationale as the OpenBroker DeepSeek
 * verbosity brake in `overlay/omp/provider-openbroker/src/catalog.ts:32-33`.
 */
export const TOKENROUTER_MODELS: readonly TokenrouterModelDescriptor[] = [
	{
		id: "z-ai/glm-5.3-free",
		name: "GLM 5.3 Free",
		// Upstream Z.AI / GLM-5.3: max_position_embeddings = 1,048,576.
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		// Free through 2026-09-04; verified 200 OK on 2026-09-02.
		cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "z-ai/glm-5.3-flash",
		name: "GLM 5.3 Flash",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		// TokenRouter paid tier: $0.075 in / $0.250 out per 1M.
		cost: {input: 0.075, output: 0.25, cacheRead: 0, cacheWrite: 0},
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
];

const DESCRIPTORS_BY_ID = new Map(TOKENROUTER_MODELS.map(d => [d.id, d]));

/** Return the descriptor for a known id, or `undefined` if not curated. */
export function getTokenrouterDescriptor(id: string): TokenrouterModelDescriptor | undefined {
	return DESCRIPTORS_BY_ID.get(id);
}

/** Build a typed `Model<"openai-completions">` entry for OMP's registry. */
export function buildTokenrouterModel(descriptor: TokenrouterModelDescriptor): Model<"openai-completions"> {
	return {
		id: descriptor.id,
		name: descriptor.name,
		provider: "tokenrouter",
		baseUrl: "https://api.tokenrouter.com/v1",
		api: "openai-completions",
		reasoning: descriptor.reasoning,
		input: descriptor.input,
		cost: descriptor.cost,
		contextWindow: descriptor.contextWindow,
		maxTokens: descriptor.maxTokens,
		// OMP reads these off the model entry; high-context is a hint, not a
		// hard cap. `acceptable` is the safe default for a model that handles
		// 200k+ cleanly but loses focus past 200k in long sessions.
		highContextWarnTokens: descriptor.highContextWarnTokens,
		highContextHint: descriptor.highContextHint,
	} as Model<"openai-completions">;
}

/**
 * Pick the static curated list when no dynamic fetch ran. `fetchDynamicModels`
 * always returns the live catalog (filtered to descriptors when available);
 * this list is the static fallback for the moment between registration and
 * the first model discovery call.
 */
export function staticTokenrouterModels(): Model<"openai-completions">[] {
	return TOKENROUTER_MODELS.map(buildTokenrouterModel);
}

/** Filter raw `/v1/models` entries to only those we have a descriptor for. */
export function filterTokenrouterIds(rawIds: readonly string[]): TokenrouterModelDescriptor[] {
	const seen = new Set<string>();
	const out: TokenrouterModelDescriptor[] = [];
	for (const id of rawIds) {
		const d = DESCRIPTORS_BY_ID.get(id);
		if (d && !seen.has(id)) {
			seen.add(id);
			out.push(d);
		}
	}
	return out;
}

/**
 * Convert a raw `/v1/models` payload into the curated catalog.
 *
 * Strategy: intersect the live model ids with our static descriptor list. If
 * a curated entry exists for a live id, use the descriptor's hard-coded
 * context/output/cost (we have ground-truth from upstream model cards). If
 * no descriptor matches, drop the model — TokenRouter's catalog has 130+
 * models and we only want to register the two curated ones.
 */
export function parseTokenrouterModels(body: unknown): Model<"openai-completions">[] {
	if (!body || typeof body !== "object") return [];
	if (!("data" in body)) return [];
	const data = (body as Record<string, unknown>).data;
	if (!Array.isArray(data)) return [];
	const ids: string[] = [];
	for (const entry of data) {
		if (entry && typeof entry === "object" && "id" in entry && typeof entry.id === "string") {
			ids.push(entry.id);
		}
	}
	return filterTokenrouterIds(ids).map(buildTokenrouterModel);
}
