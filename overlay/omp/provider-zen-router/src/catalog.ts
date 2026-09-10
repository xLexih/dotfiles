import type {Model} from "@oh-my-pi/pi-ai";

/**
 * zen-router serves the local opencode-free-router
 * (`http://127.0.0.1:2718`, OpenAI-compatible) behind one OMP provider id.
 * Two endpoint families share the base URL: Chat Completions models and
 * Responses-only models (Muse Spark). The router annotates every
 * `GET /v1/models` entry with its family, so new Zen free models flow into
 * OMP without a catalog change here — the static table below is fallback
 * only (router unreachable at discovery time).
 */
export type ZenRouterApi = "openai-completions" | "openai-responses";

export interface ZenRouterModelDescriptor {
	id: string;
	name: string;
	api: ZenRouterApi;
	/** Total context window from the upstream model card. */
	contextWindow: number;
	/** Output cap; see per-entry notes. */
	maxTokens: number;
	reasoning: boolean;
	input: ("text" | "image")[];
	highContextWarnTokens: number;
	highContextHint: "preferred" | "acceptable" | "avoid";
}

const BASE = (process.env.ZEN_ROUTER_BASE_URL?.trim() ?? "").replace(/\/+$/, "");
export const ZEN_ROUTER_BASE_URL = BASE || "http://127.0.0.1:2718/v1";
export const ZEN_ROUTER_MODELS_URL = `${ZEN_ROUTER_BASE_URL}/models`;

/**
 * Static fallback catalog. Numbers mirror
 * `overlay/omp/provider-opencode-free/src/catalog.ts` (upstream model
 * cards; `deepseek-v4-flash-free`/`big-pickle` conservative 128k
 * `UNCONFIRMED` defaults). Used at registration time and re-asserted when
 * the router is unreachable — the live path is `parseZenRouterModels`.
 */
export const ZEN_ROUTER_MODELS: readonly ZenRouterModelDescriptor[] = [
	{
		id: "muse-spark-1.3-contributor-free",
		name: "Muse Spark 1.3 Contributor Free (via router)",
		api: "openai-responses",
		contextWindow: 1_048_576,
		maxTokens: 32_768,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "preferred",
	},
	{
		id: "muse-spark-1.2-contributor-free",
		name: "Muse Spark 1.2 Contributor Free (via router)",
		api: "openai-responses",
		contextWindow: 1_048_576,
		maxTokens: 32_768,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "mimo-v2.5-free",
		name: "MiMo V2.5 Free (via router)",
		api: "openai-completions",
		contextWindow: 1_000_000,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "ling-3.0-flash-fin-free",
		name: "Ling 3.0 Flash Fin Free (via router)",
		api: "openai-completions",
		contextWindow: 262_144,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "nemotron-3-ultra-free",
		name: "Nemotron 3 Ultra Free (via router)",
		api: "openai-completions",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "nemotron-3.5-lightning-free",
		name: "Nemotron 3.5 Lightning Free (via router)",
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
		name: "DeepSeek V4 Flash Free (via router)",
		api: "openai-completions",
		contextWindow: 128_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 100_000,
		highContextHint: "acceptable",
	},
	{
		id: "big-pickle",
		name: "Big Pickle (via router)",
		api: "openai-completions",
		contextWindow: 128_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 100_000,
		highContextHint: "acceptable",
	},
];

const DESCRIPTORS_BY_ID = new Map(ZEN_ROUTER_MODELS.map(d => [d.id, d]));

/** Families learned from live router annotations (id → api). */
const learnedApiById = new Map<string, ZenRouterApi>();

/** Return the descriptor for a known fallback id, or `undefined`. */
export function getZenRouterDescriptor(id: string): ZenRouterModelDescriptor | undefined {
	return DESCRIPTORS_BY_ID.get(id);
}

/**
 * Endpoint family for a model id: fallback descriptor, else the live-learned
 * annotation, else the Muse Spark pattern, else chat. Used for stream
 * dispatch of ids the fallback table never heard of.
 */
export function familyForId(id: string): ZenRouterApi {
	return DESCRIPTORS_BY_ID.get(id)?.api ?? learnedApiById.get(id) ?? (id.includes("muse-spark-") ? "openai-responses" : "openai-completions");
}

/** True when the model must be served through the Responses endpoint. */
export function isResponsesModel(id: string): boolean {
	return familyForId(id) === "openai-responses";
}

/** Build a typed registry entry for OMP (compat is attached in `index.ts`). */
export function buildZenRouterModel(descriptor: ZenRouterModelDescriptor): Model<ZenRouterApi> {
	return {
		id: descriptor.id,
		name: descriptor.name,
		provider: "zen-router",
		baseUrl: ZEN_ROUTER_BASE_URL,
		api: descriptor.api,
		reasoning: descriptor.reasoning,
		input: descriptor.input,
		// The router pools free Zen keys; zero-cost so OMP shows no price lines.
		cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
		contextWindow: descriptor.contextWindow,
		maxTokens: descriptor.maxTokens,
		highContextWarnTokens: descriptor.highContextWarnTokens,
		highContextHint: descriptor.highContextHint,
	} as Model<ZenRouterApi>;
}

/** Static fallback list: registration time + router-unreachable discovery. */
export function staticZenRouterModels(): Model<ZenRouterApi>[] {
	return ZEN_ROUTER_MODELS.map(buildZenRouterModel);
}

function synthesizedDescriptor(id: string, family: ZenRouterApi): ZenRouterModelDescriptor {
	return {
		id,
		name: `${id} (via router)`,
		api: family,
		// UNCONFIRMED: router-discovered id with no curated card yet.
		// Conservative 128k/8k mirrors the stealth-model defaults.
		contextWindow: 128_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 100_000,
		highContextHint: "acceptable",
	};
}

/**
 * Convert the router's `GET /v1/models` payload
 * (`{data: [{id, family, endpoint}]}`) into registry entries, preserving
 * live order. Known ids use their descriptor; new ids are synthesized from
 * the router's family annotation (and learned for stream dispatch), so Zen
 * lineup changes need no update here.
 */
export function parseZenRouterModels(body: unknown): Model<ZenRouterApi>[] {
	if (!body || typeof body !== "object") return [];
	if (!("data" in body)) return [];
	const data = (body as Record<string, unknown>).data;
	if (!Array.isArray(data)) return [];
	const seen = new Set<string>();
	const out: Model<ZenRouterApi>[] = [];
	for (const entry of data) {
		if (!entry || typeof entry !== "object" || !("id" in entry) || typeof entry.id !== "string") continue;
		if (seen.has(entry.id)) continue;
		seen.add(entry.id);
		const known = DESCRIPTORS_BY_ID.get(entry.id);
		if (known) {
			out.push(buildZenRouterModel(known));
			continue;
		}
		const family: ZenRouterApi = "family" in entry && entry.family === "responses" ? "openai-responses" : "openai-completions";
		learnedApiById.set(entry.id, family);
		out.push(buildZenRouterModel(synthesizedDescriptor(entry.id, family)));
	}
	return out;
}
