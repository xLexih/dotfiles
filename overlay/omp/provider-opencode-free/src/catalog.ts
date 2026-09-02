import type {Model} from "@oh-my-pi/pi-ai";

/**
 * OpenCode Zen serves its free models behind two different endpoint families
 * on the same host (see https://opencode.ai/docs/zen/#endpoints):
 *
 * - `POST /zen/v1/chat/completions` — OpenAI Chat Completions
 *   (`@ai-sdk/openai-compatible`): big-pickle, mimo-v2.5-free,
 *   ling-3.0-flash-fin-free, nemotron-3-ultra-free,
 *   nemotron-3.5-lightning-free (plus the live-only deepseek-v4-flash-free).
 * - `POST /zen/v1/responses` — OpenAI Responses (`@ai-sdk/openai`):
 *   muse-spark-1.3-contributor-free, muse-spark-1.2-contributor-free.
 *
 * Both families share the base URL `https://opencode.ai/zen/v1`; the
 * per-model `api` field below selects which pi-ai streamer (`index.ts`)
 * dispatches to. Pointing a Chat Completions client at a Responses-only
 * model id (or vice versa) is what surfaces as a gateway 500 — the exact
 * failure seen when driving `muse-spark-1.3-contributor-free` as chat.
 */
export type OpencodeFreeApi = "openai-completions" | "openai-responses";

export interface OpencodeFreeModelDescriptor {
	id: string;
	name: string;
	api: OpencodeFreeApi;
	/** Total context window from the upstream model card. */
	contextWindow: number;
	/** Output cap baked into the registration; see per-entry notes. */
	maxTokens: number;
	reasoning: boolean;
	input: ("text" | "image")[];
	highContextWarnTokens: number;
	highContextHint: "preferred" | "acceptable" | "avoid";
}

export const OPENCODE_FREE_BASE_URL = "https://opencode.ai/zen/v1";
export const OPENCODE_FREE_MODELS_URL = `${OPENCODE_FREE_BASE_URL}/models`;

/**
 * Curated free-tier catalog. Zen's `/v1/models` returns bare `{id}` entries
 * with no context/output metadata, so limits come from upstream model cards
 * and `fetchDynamicModels` intersects the live id list with this table.
 *
 * Deliberately excluded:
 *   - `laguna-s-2.1-free` — Poolside Laguna has no tool-call support (same
 *     reason `overlay/omp/provider-cline/src/catalog.ts` skips
 *     `poolside/laguna*`); an OMP coding agent cannot drive it.
 */
export const OPENCODE_FREE_MODELS: readonly OpencodeFreeModelDescriptor[] = [
	{
		id: "muse-spark-1.3-contributor-free",
		name: "Muse Spark 1.3 Contributor Free",
		api: "openai-responses",
		// Meta Muse family: 1,048,576-token context
		// (https://dev.meta.ai/docs/models; 1.3 launch confirms 1M).
		contextWindow: 1_048_576,
		// Flagship coding model: 32k completion budget, clamped further by
		// pi-ai's 64k OPENAI_MAX_OUTPUT_TOKENS ceiling.
		maxTokens: 32_768,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "preferred",
	},
	{
		id: "muse-spark-1.2-contributor-free",
		name: "Muse Spark 1.2 Contributor Free",
		api: "openai-responses",
		// Same 1,048,576-token family window as 1.3.
		contextWindow: 1_048_576,
		maxTokens: 32_768,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "mimo-v2.5-free",
		name: "MiMo V2.5 Free",
		api: "openai-completions",
		// Xiaomi MiMo-V2.5: 1M context (https://mimo.mi.com/models/mimo-v2.5).
		contextWindow: 1_000_000,
		// 16,384 verbosity brake — same rationale as the OpenBroker DeepSeek
		// brake in `overlay/omp/provider-openbroker/src/catalog.ts:32-33`.
		maxTokens: 16_384,
		reasoning: true,
		// Upstream is omni-modal, but the Zen chat surface is unverified for
		// images — declare text-only so OMP never routes image turns here.
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "ling-3.0-flash-fin-free",
		name: "Ling 3.0 Flash Fin Free",
		api: "openai-completions",
		// InclusionAI Ling-3.0-flash: 262,144 native context
		// (https://huggingface.co/inclusionAI/Ling-3.0-flash).
		contextWindow: 262_144,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "nemotron-3-ultra-free",
		name: "Nemotron 3 Ultra Free",
		api: "openai-completions",
		// NVIDIA Nemotron 3 family: up to 1,048,576; conservative free-tier
		// cap, matching `overlay/omp/provider-cline/src/catalog.ts:74-83`.
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "nemotron-3.5-lightning-free",
		name: "Nemotron 3.5 Lightning Free",
		api: "openai-completions",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "deepseek-v4-flash-free",
		name: "DeepSeek V4 Flash Free",
		api: "openai-completions",
		// UNCONFIRMED: present in live `GET /zen/v1/models` (2026-09-03) but
		// absent from the Zen pricing table, so no documented window.
		// Conservative 128k matches DeepSeek's historical official context
		// until a card or probe says otherwise.
		contextWindow: 128_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 100_000,
		highContextHint: "acceptable",
	},
	{
		id: "big-pickle",
		name: "Big Pickle",
		api: "openai-completions",
		// UNCONFIRMED: stealth model with no public card. Conservative
		// defaults mirroring OpenCode's own fallback assumptions.
		contextWindow: 128_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 100_000,
		highContextHint: "acceptable",
	},
];

const DESCRIPTORS_BY_ID = new Map(OPENCODE_FREE_MODELS.map(d => [d.id, d]));

/** Return the descriptor for a known free id, or `undefined` if not curated. */
export function getOpencodeFreeDescriptor(id: string): OpencodeFreeModelDescriptor | undefined {
	return DESCRIPTORS_BY_ID.get(id);
}

/** True when the model must be served through the Responses endpoint. */
export function isResponsesModel(id: string): boolean {
	return DESCRIPTORS_BY_ID.get(id)?.api === "openai-responses";
}

/** Build a typed registry entry for OMP (compat is attached in `index.ts`). */
export function buildOpencodeFreeModel(descriptor: OpencodeFreeModelDescriptor): Model<OpencodeFreeApi> {
	return {
		id: descriptor.id,
		name: descriptor.name,
		provider: "opencode-free",
		baseUrl: OPENCODE_FREE_BASE_URL,
		api: descriptor.api,
		reasoning: descriptor.reasoning,
		input: descriptor.input,
		// All curated entries are free; zero-cost so OMP shows no price lines.
		cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
		contextWindow: descriptor.contextWindow,
		maxTokens: descriptor.maxTokens,
		highContextWarnTokens: descriptor.highContextWarnTokens,
		highContextHint: descriptor.highContextHint,
	} as Model<OpencodeFreeApi>;
}

/**
 * Static fallback list: used at registration time and re-asserted when the
 * live fetch fails or returns none of the curated ids.
 */
export function staticOpencodeFreeModels(): Model<OpencodeFreeApi>[] {
	return OPENCODE_FREE_MODELS.map(buildOpencodeFreeModel);
}

/** Filter raw `/v1/models` ids to only those with a curated descriptor. */
export function filterOpencodeFreeIds(rawIds: readonly string[]): OpencodeFreeModelDescriptor[] {
	const seen = new Set<string>();
	const out: OpencodeFreeModelDescriptor[] = [];
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
 * Convert a raw Zen `/v1/models` payload (`{data: [{id, ...}]}`) into the
 * curated catalog, preserving live order. Unknown ids (paid models,
 * `laguna-s-2.1-free`, retired entries) are dropped.
 */
export function parseOpencodeFreeModels(body: unknown): Model<OpencodeFreeApi>[] {
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
	return filterOpencodeFreeIds(ids).map(buildOpencodeFreeModel);
}
