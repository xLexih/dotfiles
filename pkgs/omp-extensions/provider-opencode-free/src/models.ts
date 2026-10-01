import {opencodeFreeCompat} from "./compat.ts";
import type {ThinkingConfig} from "./thinking.ts";
import {isFreeChatId} from "./session.ts";

/**
 * Dynamic free-model catalog for the `opencode-free` provider (pure logic,
 * no pi-ai imports so `bun test` runs without resolving peer dependencies).
 *
 * Inclusion is driven by the LIVE `GET /zen/v1/models` id list
 * (`parseZenModels`): any bare `{id}` that passes the free-chat rule
 * appears, retired ids drop out, no code change needed — this already
 * picked up `mimo-v2.6-flash-free`, which a static list would have missed.
 * That endpoint returns bare ids with no context/output metadata, so the
 * small table below only enriches known ids with exact windows from
 * upstream model cards; unknown ids get conservative synthesized defaults
 * (same 128k/8k pair this repo uses for stealth models).
 *
 * Routing note: `muse-spark-*` ids are Responses-only (driving them as
 * chat is what surfaces as a gateway 500); everything else is chat.
 * `familyForId` is the single place that rule lives, shared by config
 * building and stream dispatch.
 */

export type FreeModelApi = "openai-completions" | "openai-responses";

export interface FreeModelMeta {
	api: FreeModelApi;
	contextWindow: number;
	maxTokens: number;
	name: string;
}

/** Exact windows for known ids (upstream cards; deepseek/big-pickle/mimo-2.6 conservative UNCONFIRMED defaults). */
const KNOWN: Record<string, FreeModelMeta> = {
	"muse-spark-1.3-contributor-free": {
		api: "openai-responses",
		contextWindow: 1_048_576,
		maxTokens: 32_768,
		name: "Muse Spark 1.3 Contributor Free",
	},
	"muse-spark-1.2-contributor-free": {
		api: "openai-responses",
		contextWindow: 1_048_576,
		maxTokens: 32_768,
		name: "Muse Spark 1.2 Contributor Free",
	},
	"mimo-v2.5-free": {api: "openai-completions", contextWindow: 1_000_000, maxTokens: 16_384, name: "MiMo V2.5 Free"},
	// UNCONFIRMED: live since ~2026-09, no public card yet.
	"mimo-v2.6-flash-free": {
		api: "openai-completions",
		contextWindow: 128_000,
		maxTokens: 8_192,
		name: "MiMo V2.6 Flash Free",
	},
	"ling-3.0-flash-fin-free": {
		api: "openai-completions",
		contextWindow: 262_144,
		maxTokens: 16_384,
		name: "Ling 3.0 Flash Fin Free",
	},
	"nemotron-3-ultra-free": {
		api: "openai-completions",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		name: "Nemotron 3 Ultra Free",
	},
	"nemotron-3.5-lightning-free": {
		api: "openai-completions",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		name: "Nemotron 3.5 Lightning Free",
	},
	"deepseek-v4-flash-free": {
		api: "openai-completions",
		contextWindow: 128_000,
		maxTokens: 8_192,
		name: "DeepSeek V4 Flash Free",
	},
	"big-pickle": {api: "openai-completions", contextWindow: 128_000, maxTokens: 8_192, name: "Big Pickle"},
};

/** Conservative synthesized defaults for live ids with no curated row. */
const SYNTH_CONTEXT_WINDOW = 128_000;
const SYNTH_MAX_TOKENS = 8_192;

/** Endpoint family for a model id: curated row, else Muse Spark pattern, else chat. */
export function familyForId(id: string): FreeModelApi {
	return KNOWN[id]?.api ?? (id.includes("muse-spark-") ? "openai-responses" : "openai-completions");
}

function prettyName(id: string): string {
	return id
		.split(/[-_.]+/)
		.map(word => (word ? word[0].toUpperCase() + word.slice(1) : word))
		.join(" ");
}

function metaForId(id: string): FreeModelMeta {
	return (
		KNOWN[id] ?? {
			api: familyForId(id),
			contextWindow: SYNTH_CONTEXT_WINDOW,
			maxTokens: SYNTH_MAX_TOKENS,
			name: prettyName(id),
		}
	);
}

/** Registry entry shape (structural subset of pi-ai/pi-coding-agent model config; cast at the register site). */
export interface FreeModelConfig {
	id: string;
	name: string;
	api: string;
	reasoning: boolean;
	input: ("text" | "image")[];
	cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
	contextWindow: number;
	maxTokens: number;
	// Required: pi-ai dereferences compat unconditionally at stream time.
	compat: ReturnType<typeof opencodeFreeCompat>;
	/** Runtime thinking config, merged at discovery from models.dev (see `src/thinking.ts`). */
	thinking?: ThinkingConfig;
	/** Upstream-pi thinking map, merged alongside `thinking` for forward compatibility. */
	thinkingLevelMap?: Record<string, string | null>;
}

/**
 * Build the registry entry for one free id. `api` is the provider's custom
 * dispatch key (see `src/index.ts`); the native endpoint family is resolved
 * at stream time via `familyForId`, so entries never go stale.
 */
export function buildFreeModelConfig(id: string, api: string): FreeModelConfig {
	const meta = metaForId(id);
	return {
		id,
		name: meta.name,
		api,
		reasoning: true,
		input: ["text"],
		cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
		contextWindow: meta.contextWindow,
		maxTokens: meta.maxTokens,
		compat: opencodeFreeCompat(meta.api),
	};
}

/**
 * Convert a live Zen `/v1/models` payload (`{data: [{id, ...}]}`) into free
 * registry entries, preserving live order. Paid models, the `jev-*` judge
 * family, and SystemOne ids are dropped; unknown free ids are synthesized.
 */
export function parseZenModels(body: unknown, api: string): FreeModelConfig[] {
	if (!body || typeof body !== "object" || !("data" in body)) return [];
	const data = (body as Record<string, unknown>).data;
	if (!Array.isArray(data)) return [];
	const seen = new Set<string>();
	const out: FreeModelConfig[] = [];
	for (const entry of data) {
		if (!entry || typeof entry !== "object" || !("id" in entry) || typeof entry.id !== "string") continue;
		if (seen.has(entry.id) || !isFreeChatId(entry.id)) continue;
		seen.add(entry.id);
		out.push(buildFreeModelConfig(entry.id, api));
	}
	return out;
}

/** Static fallback: curated rows only, used when the live fetch fails. */
export function staticFreeModelConfigs(api: string): FreeModelConfig[] {
	return Object.keys(KNOWN).map(id => buildFreeModelConfig(id, api));
}
