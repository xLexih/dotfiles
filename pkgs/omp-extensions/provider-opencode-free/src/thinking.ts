/**
 * Thinking levels from models.dev (pure logic, no pi-ai imports so
 * `bun test` runs without resolving peer dependencies).
 *
 * models.dev is the same catalog opencode itself builds on: its `opencode`
 * provider slice carries per-model `reasoning_options`, e.g. Muse Spark
 * advertises `{type: "effort", values: ["minimal", "low", "medium", "high",
 * "xhigh"]}`.
 *
 * Two shapes are emitted because two runtimes read them:
 * - `thinking: {mode: "effort", efforts: [...]}` — what OMP 18.0.8's
 *   `/thinking` picker actually gates on. Verified against its runtime
 *   catalog (`~/.omp/agent/models.db`): the native `opencode-zen` Spark
 *   entry carries exactly this with `xhigh`, while entries without it
 *   fall back to the core default `[minimal, low, medium, high]`.
 *   A `thinkingLevelMap`-only entry is stored WITHOUT `xhigh` — the core
 *   strips the unknown field and substitutes defaults.
 * - `thinkingLevelMap` — the upstream-pi shape (pi.dev model pages), kept
 *   so the entries stay correct if the runtime ever adopts it.
 *
 * Rule (no per-model knowledge anywhere): a model gets a spec iff
 * models.dev lists an `effort` option for it. Known Pi levels map to
 * themselves in canonical order, holes are dropped from `efforts` (nulled
 * in the map), unrecognized values are ignored. Models models.dev doesn't
 * cover (or when the fetch fails) keep today's behavior: no thinking
 * fields, core defaults apply.
 */

export const MODELS_DEV_URL = "https://models.dev/api.json";

/** Pi thinking levels, in picker order. */
export const PI_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;

export type ThinkingLevelMap = Record<string, string | null>;

/** Runtime thinking config: the effort levels the picker offers. */
export interface ThinkingConfig {
	mode: "effort";
	efforts: string[];
}

/** Full per-model spec: runtime config plus the upstream-pi map. */
export interface ThinkingSpec extends ThinkingConfig {
	thinkingLevelMap: ThinkingLevelMap;
}

/** How long a fetched snapshot stays fresh before revalidation. Levels change rarely. */
export const THINKING_MAPS_TTL_MS = 24 * 60 * 60 * 1_000;

/**
 * Build a Pi `thinkingLevelMap` from advertised effort values.
 * Returns `undefined` when there is nothing mappable (no array, empty,
 * or no recognized Pi level) so callers fall back to omitting the map.
 */
export function thinkingLevelMapForEffort(values: unknown): ThinkingLevelMap | undefined {
	if (!Array.isArray(values)) return undefined;
	const advertised = new Set(values.filter((v): v is string => typeof v === "string"));
	if (!PI_THINKING_LEVELS.some(level => advertised.has(level))) return undefined;
	return Object.fromEntries(PI_THINKING_LEVELS.map(level => [level, advertised.has(level) ? level : null]));
}

/**
 * Build the full thinking spec from advertised effort values:
 * `efforts` is the known levels in canonical order (holes dropped),
 * alongside the identity-with-holes map.
 */
export function thinkingSpecForEffort(values: unknown): ThinkingSpec | undefined {
	const thinkingLevelMap = thinkingLevelMapForEffort(values);
	if (!thinkingLevelMap) return undefined;
	return {
		mode: "effort",
		efforts: PI_THINKING_LEVELS.filter(level => thinkingLevelMap[level] !== null),
		thinkingLevelMap,
	};
}

/**
 * Extract id → thinking spec from a models.dev api.json payload for one
 * provider slice (default `opencode`, whose ids match Zen's). Only the
 * `effort`-typed reasoning option is read; `toggle`/`budget_tokens` shapes
 * and bare `[]`/`null` entries yield no spec.
 */
export function thinkingSpecsFromModelsDev(body: unknown, provider = "opencode"): Map<string, ThinkingSpec> {
	const out = new Map<string, ThinkingSpec>();
	if (!body || typeof body !== "object") return out;
	const slice = (body as Record<string, unknown>)[provider];
	if (!slice || typeof slice !== "object") return out;
	const models = (slice as Record<string, unknown>).models;
	if (!models || typeof models !== "object") return out;
	for (const [id, entry] of Object.entries(models)) {
		if (!entry || typeof entry !== "object") continue;
		const options = (entry as Record<string, unknown>).reasoning_options;
		if (!Array.isArray(options)) continue;
		const effort = options.find(
			(option): option is {values: unknown} =>
				!!option &&
				typeof option === "object" &&
				(option as Record<string, unknown>).type === "effort" &&
				Array.isArray((option as Record<string, unknown>).values),
		);
		if (!effort) continue;
		const spec = thinkingSpecForEffort(effort.values);
		if (spec) out.set(id, spec);
	}
	return out;
}

export interface ThinkingMapsFetcherOptions {
	url?: string;
	provider?: string;
	ttlMs?: number;
	fetchImpl?: typeof fetch;
	now?: () => number;
}

/**
 * Fetcher with in-memory snapshot + ETag revalidation. Never throws:
 * failures and unknown ids resolve to an empty map (or the last good
 * snapshot), so discovery always proceeds.
 */
export function createThinkingMapsFetcher(options?: ThinkingMapsFetcherOptions): () => Promise<Map<string, ThinkingSpec>> {
	const url = options?.url ?? MODELS_DEV_URL;
	const provider = options?.provider ?? "opencode";
	const ttlMs = options?.ttlMs ?? THINKING_MAPS_TTL_MS;
	const fetchImpl = options?.fetchImpl ?? fetch;
	const now = options?.now ?? Date.now;
	let cache: {at: number; etag: string | undefined; maps: Map<string, ThinkingSpec>} | undefined;
	return async () => {
		const started = now();
		if (cache && started - cache.at < ttlMs) return cache.maps;
		try {
			const headers: Record<string, string> = {Accept: "application/json"};
			if (cache?.etag) headers["If-None-Match"] = cache.etag;
			const response = await fetchImpl(url, {headers, signal: AbortSignal.timeout(15_000)});
			if (response.status === 304 && cache) {
				cache.at = started;
				return cache.maps;
			}
			if (!response.ok) return cache?.maps ?? new Map();
			const maps = thinkingSpecsFromModelsDev(await response.json(), provider);
			cache = {at: started, etag: response.headers.get("etag") ?? undefined, maps};
			return maps;
		} catch {
			return cache?.maps ?? new Map();
		}
	};
}
