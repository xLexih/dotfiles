import {createAssistantMessageEventStream, type Context, type Model, type SimpleStreamOptions} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {streamOpenAICompletions} from "@oh-my-pi/pi-ai/providers/openai-completions";
import {streamOpenAIResponses} from "@oh-my-pi/pi-ai/providers/openai-responses";
import {zenRouterCompat} from "./compat.ts";
import {
	buildZenRouterModel,
	isResponsesModel,
	ZEN_ROUTER_BASE_URL,
	ZEN_ROUTER_MODELS,
	ZEN_ROUTER_MODELS_URL,
	parseZenRouterModels,
	staticZenRouterModels,
} from "./catalog.ts";

// Single provider id, two endpoint families. Dispatch is by model id via
// `familyForId` (fallback descriptor → live-learned router annotation →
// Muse Spark pattern — never `requested.api`, which the registry may
// overwrite with the provider api). Responses-only ids sent to Chat
// Completions come back as gateway 500s.
function zenRouterStream(requested: Model, context: Context, options?: SimpleStreamOptions) {
	const outer = createAssistantMessageEventStream();
	void (async () => {
		try {
			if (isResponsesModel(requested.id)) {
				const model = {
					...requested,
					api: "openai-responses",
					compat: requested.compat ?? zenRouterCompat("openai-responses"),
				} as Model<"openai-responses">;
				for await (const event of streamOpenAIResponses(model, context, options)) outer.push(event);
			} else {
				const model = {
					...requested,
					api: "openai-completions",
					compat: requested.compat ?? zenRouterCompat("openai-completions"),
				} as Model<"openai-completions">;
				for await (const event of streamOpenAICompletions(model, context, options)) outer.push(event);
			}
		} catch (error) {
			outer.fail(error);
		}
	})();
	return outer;
}

const zenRouterProvider: ExtensionFactory = pi => {
	// The router ignores client auth (keys live in its keys.json), so a
	// dummy key avoids any login dance. Override only to point elsewhere.
	const apiKey = process.env.ZEN_ROUTER_API_KEY?.trim() || "router";

	pi.registerProvider("zen-router", {
		baseUrl: ZEN_ROUTER_BASE_URL,
		// Custom discriminator (same pattern as surplus/openbroker): the real
		// endpoint family is per-model and resolved in `zenRouterStream`.
		api: "zen-router" as never,
		streamSimple: zenRouterStream,
		// Static fallback list — used at registration time and re-asserted if
		// the router is unreachable. `fetchDynamicModels` replaces it with
		// the live (router-annotated) list.
		models: ZEN_ROUTER_MODELS.map(
			descriptor =>
				({...buildZenRouterModel(descriptor), compat: zenRouterCompat(descriptor.api)} as Model<"openai-completions">),
		),
		apiKey,
		authHeader: true,
		fetchDynamicModels: async () => {
			// No auth: the router's /v1/models is public, like Zen's.
			const response = await fetch(ZEN_ROUTER_MODELS_URL, {
				method: "GET",
				headers: {"Accept-Encoding": "identity"},
				signal: AbortSignal.timeout(10_000),
			});
			if (!response.ok) return [];
			const models = parseZenRouterModels(await response.json());
			// Keep the static catalog visible if the router has no roster
			// yet (e.g. first boot before its own Zen refresh).
			return models.length
				? models.map(m => ({...m, compat: zenRouterCompat(m.api)}))
				: staticZenRouterModels().map(m => ({...m, compat: zenRouterCompat(m.api)}));
		},
	});
};

export default zenRouterProvider;
