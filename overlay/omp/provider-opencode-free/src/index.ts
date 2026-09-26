import {type FetchImpl, streamSimple} from "@oh-my-pi/pi-ai";
import type {ExtensionAPI} from "@oh-my-pi/pi-coding-agent";
import {opencodeFreeCompat} from "./compat.ts";
import {familyForId, parseZenModels, staticFreeModelConfigs} from "./models.ts";import {isFreeChatModel, isZenInferenceRequest, toZenSessionId, ZEN_SESSION_HEADER, ZEN_USER_AGENT} from "./session.ts";
import {createThinkingMapsFetcher} from "./thinking.ts";

export const OPENCODE_FREE_BASE_URL = "https://opencode.ai/zen/v1";
export const OPENCODE_FREE_MODELS_URL = `${OPENCODE_FREE_BASE_URL}/models`;

/**
 * `opencode-free`: the free-only view over Zen, found in OMP as
 * `opencode-free/<id>` with `/login opencode-zen` credentials.
 * Discovery is dynamic: `fetchDynamicModels` intersects the live
 * `GET /zen/v1/models` id list (public, no key needed) with the free-chat
 * rule, so new `-free` ids appear and retired ones drop out with no change
 * here — this already picked up `mimo-v2.6-flash-free`. Known ids carry
 * exact upstream-card windows (`src/models.ts`); unknown ids get
 * conservative synthesized defaults. Thinking levels (`xhigh` et al.) are
 * merged per id from models.dev's `opencode` slice (`src/thinking.ts`),
 * so new reasoning scales appear with no code change. A curated-only
 * static list covers fetch failures.
 *
 * Streaming flips each request onto the matching native `opencode-zen`
 * entry (same id, curated endpoint family, native compat/routing/auth) and
 * only adds the two client-identity signals the free tier gates on. The
 * `before_agent_start` hook below applies the same shim to directly
 * selected `opencode-zen/<free-id>` models.
 */
const customApiPrefix = "omp-opencode-zen-free:";

// Thinking levels (`xhigh` et al.) come from models.dev at discovery time
// (see `src/thinking.ts`) — never a per-model table here. The fetcher never
// throws; unknown/offline models simply keep Pi's default levels.
const fetchThinkingMaps = createThinkingMapsFetcher();

function identityFetch(fetch: FetchImpl, sessionId?: string): FetchImpl {
	return (input, init) => {
		if (!isZenInferenceRequest(input)) return fetch(input, init);
		const headers = new Headers(init?.headers ?? (input instanceof Request ? input.headers : undefined));
		const session = headers.get(ZEN_SESSION_HEADER) ?? sessionId;
		if (session !== undefined) headers.set(ZEN_SESSION_HEADER, toZenSessionId(session));
		headers.set("User-Agent", ZEN_USER_AGENT);
		return fetch(input, {...init, headers});
	};
}

export default function (pi: ExtensionAPI) {
	pi.registerProvider("opencode-free", {
		baseUrl: OPENCODE_FREE_BASE_URL,
		// Custom dispatch key; entries carry it as their `api` so every
		// request lands in `opencodeFreeStream` below.
		api: "opencode-free" as never,
		streamSimple(model, context, options) {
			// Execute as the native entry: curated family, native compat,
			// native routing and credentials. Only the fetch identity is ours.
			// The compat fallback guards registries that drop extension
			// compat (pi-ai dereferences it unconditionally).
			const family = familyForId(model.id);
			const nativeModel = {
				...model,
				provider: "opencode-zen",
				api: family,
				compat: model.compat ?? opencodeFreeCompat(family),
			};
			const fetch = options?.fetch ?? globalThis.fetch;
			// The outer custom-API dispatch already holds the provider's concurrency slot.
			return streamSimple(nativeModel, context, {
				...options,
				fetch: identityFetch(fetch, options?.sessionId),
				maxInFlightRequests: {},
			});
		},
		fetchDynamicModels: async () => {
			try {
				const [response, thinking] = await Promise.all([
					fetch(OPENCODE_FREE_MODELS_URL, {
						method: "GET",
						headers: {"Accept-Encoding": "identity"},
						signal: AbortSignal.timeout(10_000),
					}),
					fetchThinkingMaps(),
				]);
				if (!response.ok) return staticFreeModelConfigs("opencode-free");
				const models = parseZenModels(await response.json(), "opencode-free");
				if (!models.length) return staticFreeModelConfigs("opencode-free");
				for (const model of models) {
					const spec = thinking.get(model.id);
					if (spec) {
						model.thinking = {mode: spec.mode, efforts: spec.efforts};
						model.thinkingLevelMap = spec.thinkingLevelMap;
					}
				}
				return models;
			} catch {
				return staticFreeModelConfigs("opencode-free");
			}
		},
	});

	const registeredApis = new Set<string>();
	pi.on("before_agent_start", async (_event, ctx) => {
		const model = ctx.model;
		if (!model || model.api.startsWith(customApiPrefix) || !isFreeChatModel(model)) return;
		const nativeApi = model.api;
		const customApi = `${customApiPrefix}${nativeApi}`;
		if (!registeredApis.has(nativeApi)) {
			pi.registerProvider("opencode-zen", {
				api: customApi,
				streamSimple(model, context, options) {
					const nativeModel = {
						...model,
						api: nativeApi,
						compat:
							model.compat ??
							(nativeApi === "openai-completions" || nativeApi === "openai-responses"
								? opencodeFreeCompat(nativeApi)
								: undefined),
					};
					const fetch = options?.fetch ?? globalThis.fetch;
					// The outer custom-API dispatch already holds the provider's concurrency slot.
					return streamSimple(nativeModel, context, {
						...options,
						fetch: isFreeChatModel(nativeModel) ? identityFetch(fetch, options?.sessionId) : fetch,
						maxInFlightRequests: {},
					});
				},
			});
			registeredApis.add(nativeApi);
		}
		await pi.setModel({...model, api: customApi});
	});

	pi.registerCommand("zen-judge", {
		description: "Judge JSON {state, questions} with Jev 1.13 Free (noul, choice, score).",
		async handler(args, ctx) {
			let request: {state: unknown; questions: unknown};
			try {
				request = JSON.parse(args) as {state: unknown; questions: unknown};
				if (
					!request ||
					!(
						typeof request.state === "string" ||
						(request.state !== null && typeof request.state === "object")
					) ||
					!request.questions ||
					typeof request.questions !== "object" ||
					Array.isArray(request.questions)
				) {
					throw new Error("Expected {state, questions}.");
				}
			} catch {
				ctx.ui.notify(
					'Usage: /zen-judge {"state":"...", "questions":{"id":{"type":"noul","instructions":"..."}}}',
					"error",
				);
				return;
			}
			// The judgment module only exists on newer pi-ai; dynamic-import
			// keeps the shim loading on older runtimes (e.g. omp 18.0.x).
			let judgment: typeof import("@oh-my-pi/pi-ai/judgment");
			try {
				judgment = await import("@oh-my-pi/pi-ai/judgment");
			} catch {
				ctx.ui.notify("zen-judge needs an omp with the pi-ai judgment module; update omp and retry.", "error");
				return;
			}
			const sessionId = ctx.sessionManager.getSessionId();
			const judge = new judgment.TypeSafeJudge({
				apiKey: ctx.modelRegistry.resolver("opencode-zen", {
					sessionId,
					baseUrl: "https://opencode.ai/zen",
					modelId: "jev-1.13-free",
				}),
				api: "typesafe",
				provider: "opencode-zen",
				baseUrl: "https://opencode.ai/zen",
				model: "jev-1.13-free",
				fetch: identityFetch(globalThis.fetch, sessionId),
			});
			const result = await judge.judge(request as never);
			pi.sendMessage({
				customType: "zen-judge",
				content: JSON.stringify(result, null, 2),
				details: result,
				display: true,
			});
		},
	});
}
