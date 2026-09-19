import {createAssistantMessageEventStream, type Context, type Model, type SimpleStreamOptions} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {streamOpenAICompletions} from "@oh-my-pi/pi-ai/providers/openai-completions";
import {streamOpenAIResponses} from "@oh-my-pi/pi-ai/providers/openai-responses";
import {ipRotateCompat} from "./compat.ts";
import {
	buildIpRotateModel,
	isResponsesModel,
	IPROTATE_BASE_URL,
	IPROTATE_MODELS,
	IPROTATE_MODELS_URL,
	parseIpRotateModels,
	staticIpRotateModels,
} from "./catalog.ts";

// NOTE: no oauth login by design. The gateway's `GET /v1/models` is public,
// so a login prompt could never validate the key — a wrong key would pass
// and surface on first inference. Supply the key via `OPENCODE_ZEN_API_KEY`
// (OMP side, sent as Bearer) or the gateway's own `.env` (injected for
// keyless clients) instead.

// Single provider id, two endpoint families. Dispatch is by curated model id
// (not `requested.api`, which the registry may overwrite with the provider
// api) — Responses-only ids such as `muse-spark-1.3-contributor-free` must go
// through `streamOpenAIResponses`; sending them to Chat Completions is what
// returns the gateway 500.
function ipRotateStream(requested: Model, context: Context, options?: SimpleStreamOptions) {
	const outer = createAssistantMessageEventStream();
	void (async () => {
		try {
			if (isResponsesModel(requested.id)) {
				const model = {
					...requested,
					api: "openai-responses",
					compat: requested.compat ?? ipRotateCompat("openai-responses"),
				} as Model<"openai-responses">;
				for await (const event of streamOpenAIResponses(model, context, options)) outer.push(event);
			} else {
				const model = {
					...requested,
					api: "openai-completions",
					compat: requested.compat ?? ipRotateCompat("openai-completions"),
				} as Model<"openai-completions">;
				for await (const event of streamOpenAICompletions(model, context, options)) outer.push(event);
			}
		} catch (error) {
			outer.fail(error);
		}
	})();
	return outer;
}

const ipRotateProvider: ExtensionFactory = pi => {
	// OMP requires apiKey (or oauth) at registration. When the user has no
	// key on the OMP side, send the well-known sentinel "iprotate": the
	// gateway recognizes it as "no key" and injects its own env key instead
	// of forwarding the dummy to Zen.
	const apiKey = process.env.OPENCODE_ZEN_API_KEY?.trim() || "iprotate";

	pi.registerProvider("opencode-iprotate", {
		baseUrl: IPROTATE_BASE_URL,
		// Custom discriminator (same pattern as surplus/openbroker): the real
		// endpoint family is per-model and resolved in `ipRotateStream`.
		api: "opencode-iprotate" as never,
		streamSimple: ipRotateStream,
		// Static fallback list — used at registration time and re-asserted if
		// the gateway is unreachable. `fetchDynamicModels` replaces it with
		// the live list.
		models: IPROTATE_MODELS.map(
			descriptor =>
				({...buildIpRotateModel(descriptor), compat: ipRotateCompat(descriptor.api)} as Model<"openai-completions">),
		),
		apiKey,
		authHeader: true,
		fetchDynamicModels: async apiKey => {
			const headers: Record<string, string> = {"Accept-Encoding": "identity"};
			if (apiKey?.trim()) headers.Authorization = `Bearer ${apiKey}`;
			const response = await fetch(IPROTATE_MODELS_URL, {
				method: "GET",
				headers,
				signal: AbortSignal.timeout(10_000),
			});
			if (!response.ok) return [];
			const models = parseIpRotateModels(await response.json());
			// Keep the static catalog visible if the live list contains none
			// of the curated free ids (e.g. Zen rotated the free roster).
			return models.length
				? models.map(m => ({...m, compat: ipRotateCompat(m.api)}))
				: staticIpRotateModels().map(m => ({...m, compat: ipRotateCompat(m.api)}));
		},
	});
};

export default ipRotateProvider;
