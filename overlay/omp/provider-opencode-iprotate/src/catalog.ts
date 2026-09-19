import type {Model} from "@oh-my-pi/pi-ai";

/**
 * opencode-iprotate drives Zen's free models through the local zenproxy
 * gateway (`http://127.0.0.1:8787`, OpenAI-compatible `/v1/*`), which
 * egresses via rotating proxy exits instead of your own IP.
 *
 * Two endpoint families share the base URL: Chat Completions models and
 * Responses-only models (Muse Spark). Dispatch is per model id.
 */
export type IpRotateApi = "openai-completions" | "openai-responses";

export interface IpRotateModelDescriptor {
	id: string;
	name: string;
	api: IpRotateApi;
	/** Total context window from the upstream model card. */
	contextWindow: number;
	/** Output cap; see per-entry notes. */
	maxTokens: number;
	reasoning: boolean;
	input: ("text" | "image")[];
	highContextWarnTokens: number;
	highContextHint: "preferred" | "acceptable" | "avoid";
}

const BASE = (process.env.IPROTATE_BASE_URL?.trim() ?? "").replace(/\/+$/, "");
export const IPROTATE_BASE_URL = BASE || "http://127.0.0.1:8787/v1";
export const IPROTATE_MODELS_URL = `${IPROTATE_BASE_URL}/models`;

/**
 * Header Zen's free tier requires on every request. Without it the gateway
 * returns `400 MissingSessionID` ("OpenCode's free tier can only be used in
 * OpenCode"). Copied from `provider-opencode-free` (see its `catalog.ts`
 * docs + https://dev.opencode.ai/docs/zen): the header lets Zen attribute
 * external-agent traffic to a prompt-cache lineage.
 */
export const IPROTATE_SESSION_HEADER = "x-opencode-session";

/**
 * Stable per-extension-load session id. OMP loads each extension once per
 * agent process, so one UUID at module init covers the whole conversation —
 * preserves prompt-cache affinity without merging unrelated agents. A
 * hardcoded value or a per-request UUID would both defeat the cache
 * (https://github.com/earendil-works/pi/issues/9237).
 */
export const IPROTATE_SESSION_ID: string = `omp-${crypto.randomUUID()}`;
/**
 * Static fallback catalog. Numbers mirror
 * `overlay/omp/provider-opencode-free/src/catalog.ts` (upstream model
 * cards; `deepseek-v4-flash-free`/`big-pickle` conservative 128k
 * `UNCONFIRMED` defaults). Used at registration time and re-asserted when
 * the gateway is unreachable — the live path is `parseIpRotateModels`.
 */
export const IPROTATE_MODELS: readonly IpRotateModelDescriptor[] = [
	{
		id: "muse-spark-1.3-contributor-free",
		name: "Muse Spark 1.3 Contributor Free (via iprotate)",
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
		name: "Muse Spark 1.2 Contributor Free (via iprotate)",
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
		name: "MiMo V2.5 Free (via iprotate)",
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
		name: "Ling 3.0 Flash Fin Free (via iprotate)",
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
		name: "Nemotron 3 Ultra Free (via iprotate)",
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
		name: "Nemotron 3.5 Lightning Free (via iprotate)",
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
		name: "DeepSeek V4 Flash Free (via iprotate)",
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
		name: "Big Pickle (via iprotate)",
		api: "openai-completions",
		contextWindow: 128_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 100_000,
		highContextHint: "acceptable",
	},
];

const DESCRIPTORS_BY_ID = new Map(IPROTATE_MODELS.map(d => [d.id, d]));

/** Families learned from live gateway discovery (id → api). */
const learnedApiById = new Map<string, IpRotateApi>();

/** Return the descriptor for a known fallback id, or `undefined`. */
export function getIpRotateDescriptor(id: string): IpRotateModelDescriptor | undefined {
	return DESCRIPTORS_BY_ID.get(id);
}

/**
 * Endpoint family for a model id: fallback descriptor, else the live-learned
 * annotation, else the Muse Spark pattern, else chat. Used for stream
 * dispatch of ids the fallback table never heard of.
 */
export function familyForId(id: string): IpRotateApi {
	return DESCRIPTORS_BY_ID.get(id)?.api ?? learnedApiById.get(id) ?? (id.includes("muse-spark-") ? "openai-responses" : "openai-completions");
}

/** True when the model must be served through the Responses endpoint. */
export function isResponsesModel(id: string): boolean {
	return familyForId(id) === "openai-responses";
}

/** Build a typed registry entry for OMP (compat is attached in `index.ts`). */
export function buildIpRotateModel(descriptor: IpRotateModelDescriptor): Model<IpRotateApi> {
	return {
		id: descriptor.id,
		name: descriptor.name,
		provider: "opencode-iprotate",
		baseUrl: IPROTATE_BASE_URL,
		api: descriptor.api,
		reasoning: descriptor.reasoning,
		input: descriptor.input,
		// The gateway pools free Zen exits; zero-cost so OMP shows no price lines.
		cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
		contextWindow: descriptor.contextWindow,
		maxTokens: descriptor.maxTokens,
		highContextWarnTokens: descriptor.highContextWarnTokens,
		highContextHint: descriptor.highContextHint,
		// Zen's free tier rejects requests without `x-opencode-session`
		// (400 MissingSessionID). pi-ai's `resolveOpenAIRequestSetup`
		// copies `model.headers` onto every outbound request, so baking
		// it into each built model covers both the static fallback and
		// the dynamic-discovery paths without touching the streamer.
		// The gateway forwards it untouched (not in its strip list).
		headers: {[IPROTATE_SESSION_HEADER]: IPROTATE_SESSION_ID},
	} as Model<IpRotateApi>;
}

/** Static fallback list: registration time + gateway-unreachable discovery. */
export function staticIpRotateModels(): Model<IpRotateApi>[] {
	return IPROTATE_MODELS.map(buildIpRotateModel);
}

function synthesizedDescriptor(id: string, family: IpRotateApi): IpRotateModelDescriptor {
	return {
		id,
		name: `${id} (via iprotate)`,
		api: family,
		// UNCONFIRMED: gateway-discovered id with no curated card yet.
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
 * Convert the gateway's `GET /v1/models` payload (plain OpenAI
 * `{data: [{id, ...}]}`, no family annotations) into registry entries,
 * preserving live order. Known ids use their descriptor; new ids are
 * synthesized from the Muse Spark id pattern (and learned for stream
 * dispatch), so Zen lineup changes need no update here.
 */
export function parseIpRotateModels(body: unknown): Model<IpRotateApi>[] {
	if (!body || typeof body !== "object") return [];
	if (!("data" in body)) return [];
	const data = (body as Record<string, unknown>).data;
	if (!Array.isArray(data)) return [];
	const seen = new Set<string>();
	const out: Model<IpRotateApi>[] = [];
	for (const entry of data) {
		if (!entry || typeof entry !== "object" || !("id" in entry) || typeof entry.id !== "string") continue;
		if (seen.has(entry.id)) continue;
		seen.add(entry.id);
		const known = DESCRIPTORS_BY_ID.get(entry.id);
		if (known) {
			out.push(buildIpRotateModel(known));
			continue;
		}
		const family: IpRotateApi = entry.id.includes("muse-spark-") ? "openai-responses" : "openai-completions";
		learnedApiById.set(entry.id, family);
		out.push(buildIpRotateModel(synthesizedDescriptor(entry.id, family)));
	}
	return out;
}
