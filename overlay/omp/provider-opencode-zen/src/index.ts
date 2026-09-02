import type {Model} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {opencodeZenCompat} from "./compat.ts";
import {buildOpencodeZenModel, OPENCODE_ZEN_MODELS, parseOpencodeZenModels, staticOpencodeZenModels} from "./catalog.ts";

const MODELS_URL = "https://opencode.ai/zen/v1/models";

/**
 * Login is optional for OpenCode Zen. The free models in our catalog work
 * without an `Authorization` header, but Zen's paid models (which surface
 * in the same `/v1/models` list) require a key. `/login opencode` stores a
 * key for paid-model access; the free roster still works without one.
 */
async function loginOpencodeZen(callbacks: OAuthLoginCallbacks): Promise<string> {
	const apiKey = (await callbacks.onPrompt({message: "Paste your OpenCode Zen API key (optional — free models work without one)", placeholder: "oc_..."})).trim();
	if (callbacks.signal?.aborted) throw new Error("OpenCode Zen login cancelled");
	// Empty key is allowed: Zen's free models are anonymous-callable. We
	// still validate by listing models.
	const fetchImpl = callbacks.fetch ?? fetch;
	const headers: Record<string, string> = {"Accept-Encoding": "identity"};
	if (apiKey) headers.Authorization = `Bearer ${apiKey}`;
	const response = await fetchImpl(MODELS_URL, {method: "GET", headers, signal: AbortSignal.timeout(15_000)});
	if (!response.ok) throw new Error(`OpenCode Zen API key validation failed (${response.status})`);
	return apiKey;
}

const opencodeZenProvider: ExtensionFactory = pi => {
	const environmentKey = process.env.OPENCODE_API_KEY?.trim();

	const withCompat = (model: Model<"openai-completions">): Model<"openai-completions"> => ({
		...model,
		compat: opencodeZenCompat(model),
	} as Model<"openai-completions">);

	pi.registerProvider("opencode", {
		baseUrl: "https://opencode.ai/zen/v1",
		api: "openai-completions",
		// No `authHeader: true` and no `apiKey` at registration time — Zen's
		// free models work without auth. Once the user runs `/login opencode`,
		// OMP injects the Bearer header on subsequent requests.
		models: OPENCODE_ZEN_MODELS.map(d => withCompat(buildOpencodeZenModel(d))),
		...(environmentKey ? {apiKey: environmentKey} : {}),
		oauth: {name: "OpenCode Zen", login: loginOpencodeZen},
		fetchDynamicModels: async apiKey => {
			// `/v1/models` is public on Zen, so we always call it (with or
			// without a key). The response is intersected with the curated
			// descriptors; if the curated intersection is empty (e.g. Zen
			// dropped the entire free roster), fall back to the static list.
			const fetchImpl = fetch;
			const headers: Record<string, string> = {"Accept-Encoding": "identity"};
			if (apiKey?.trim()) headers.Authorization = `Bearer ${apiKey}`;
			const response = await fetchImpl(MODELS_URL, {method: "GET", headers, signal: AbortSignal.timeout(10_000)});
			if (!response.ok) return [];
			const models = parseOpencodeZenModels(await response.json());
			return models.length ? models : staticOpencodeZenModels().map(withCompat);
		},
	});
};

export default opencodeZenProvider;
