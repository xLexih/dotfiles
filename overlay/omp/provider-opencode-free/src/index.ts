import {createAssistantMessageEventStream, type Context, type Model, type SimpleStreamOptions} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {streamOpenAICompletions} from "@oh-my-pi/pi-ai/providers/openai-completions";
import {streamOpenAIResponses} from "@oh-my-pi/pi-ai/providers/openai-responses";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {opencodeFreeCompat} from "./compat.ts";
import {
	buildOpencodeFreeModel,
	isResponsesModel,
	OPENCODE_FREE_BASE_URL,
	OPENCODE_FREE_MODELS,
	OPENCODE_FREE_MODELS_URL,
	parseOpencodeFreeModels,
	staticOpencodeFreeModels,
} from "./catalog.ts";

async function loginOpencodeFree(callbacks: OAuthLoginCallbacks): Promise<string> {
	const apiKey = (
		await callbacks.onPrompt({
			message: "Paste your OpenCode Zen API key (from https://opencode.ai/auth)",
			placeholder: "From https://opencode.ai/auth",
		})
	).trim();
	if (callbacks.signal?.aborted) throw new Error("OpenCode Free login cancelled");
	if (!apiKey) throw new Error("An OpenCode Zen API key is required");
	callbacks.onProgress?.("Validating OpenCode Zen API key...");
	const fetchImpl = callbacks.fetch ?? fetch;
	const response = await fetchImpl(OPENCODE_FREE_MODELS_URL, {
		method: "GET",
		headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
		signal: AbortSignal.timeout(15_000),
	});
	// NOTE: `GET /zen/v1/models` is public (200 without a key), so this only
	// proves the endpoint is reachable — a wrong key surfaces on first inference.
	if (!response.ok) throw new Error(`OpenCode Zen API key validation failed (${response.status})`);
	return apiKey;
}

// Single provider id, two endpoint families. Dispatch is by curated model id
// (not `requested.api`, which the registry may overwrite with the provider
// api) — Responses-only ids such as `muse-spark-1.3-contributor-free` must go
// through `streamOpenAIResponses`; sending them to Chat Completions is what
// returns the gateway 500.
function opencodeFreeStream(requested: Model, context: Context, options?: SimpleStreamOptions) {
	const outer = createAssistantMessageEventStream();
	void (async () => {
		try {
			if (isResponsesModel(requested.id)) {
				const model = {
					...requested,
					api: "openai-responses",
					compat: requested.compat ?? opencodeFreeCompat("openai-responses"),
				} as Model<"openai-responses">;
				for await (const event of streamOpenAIResponses(model, context, options)) outer.push(event);
			} else {
				const model = {
					...requested,
					api: "openai-completions",
					compat: requested.compat ?? opencodeFreeCompat("openai-completions"),
				} as Model<"openai-completions">;
				for await (const event of streamOpenAICompletions(model, context, options)) outer.push(event);
			}
		} catch (error) {
			outer.fail(error);
		}
	})();
	return outer;
}

const opencodeFreeProvider: ExtensionFactory = pi => {
	const environmentKey = process.env.OPENCODE_ZEN_API_KEY?.trim();

	pi.registerProvider("opencode-free", {
		baseUrl: OPENCODE_FREE_BASE_URL,
		// Custom discriminator (same pattern as surplus/openbroker): the real
		// endpoint family is per-model and resolved in `opencodeFreeStream`.
		api: "opencode-free" as never,
		streamSimple: opencodeFreeStream,
		// Static fallback list — used at registration time and re-asserted if
		// the live fetch fails. `fetchDynamicModels` replaces it with the
		// live (descriptor-filtered) list after login.
		models: OPENCODE_FREE_MODELS.map(
			descriptor =>
				({...buildOpencodeFreeModel(descriptor), compat: opencodeFreeCompat(descriptor.api)} as Model<"openai-completions">),
		),
		...(environmentKey ? {apiKey: environmentKey} : {}),
		authHeader: true,
		oauth: {name: "OpenCode Free", login: loginOpencodeFree},
		fetchDynamicModels: async apiKey => {
			const headers: Record<string, string> = {"Accept-Encoding": "identity"};
			if (apiKey?.trim()) headers.Authorization = `Bearer ${apiKey}`;
			const response = await fetch(OPENCODE_FREE_MODELS_URL, {
				method: "GET",
				headers,
				signal: AbortSignal.timeout(10_000),
			});
			if (!response.ok) return [];
			const models = parseOpencodeFreeModels(await response.json());
			// Keep the static catalog visible if the live list contains none
			// of the curated free ids (e.g. Zen rotated the free roster).
			return models.length
				? models.map(m => ({...m, compat: opencodeFreeCompat(m.api)}))
				: staticOpencodeFreeModels().map(m => ({...m, compat: opencodeFreeCompat(m.api)}));
		},
	});
};

export default opencodeFreeProvider;
