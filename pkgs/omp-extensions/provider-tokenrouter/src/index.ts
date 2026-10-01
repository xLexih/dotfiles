import type {Model} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {tokenrouterCompat} from "./compat.ts";
import {buildTokenrouterModel, parseTokenrouterModels, staticTokenrouterModels, TOKENROUTER_MODELS} from "./catalog.ts";

const MODELS_URL = "https://api.tokenrouter.com/v1/models";

async function loginTokenrouter(callbacks: OAuthLoginCallbacks): Promise<string> {
	const apiKey = (await callbacks.onPrompt({message: "Paste your TokenRouter API key", placeholder: "tr_..."})).trim();
	if (callbacks.signal?.aborted) throw new Error("TokenRouter login cancelled");
	if (!apiKey) throw new Error("A TokenRouter API key is required");
	callbacks.onProgress?.("Validating TokenRouter API key...");
	const fetchImpl = callbacks.fetch ?? fetch;
	const response = await fetchImpl(MODELS_URL, {
		method: "GET",
		headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
		signal: AbortSignal.timeout(15_000),
	});
	if (!response.ok) throw new Error(`TokenRouter API key validation failed (${response.status})`);
	return apiKey;
}


const tokenrouterProvider: ExtensionFactory = pi => {
	const environmentKey = process.env.TOKENROUTER_API_KEY?.trim();

	const compat = tokenrouterCompat();
	const makeModel = (descriptor: typeof TOKENROUTER_MODELS[number]): Model<"openai-completions"> => ({
		...buildTokenrouterModel(descriptor),
		compat,
	} as Model<"openai-completions">);

	pi.registerProvider("tokenrouter", {
		baseUrl: "https://api.tokenrouter.com/v1",
		api: "openai-completions",
		// Static fallback list — used immediately at registration time and as
		// a safety net if `/v1/models` is unavailable. Once
		// `fetchDynamicModels` succeeds, OMP replaces this with the live
		// (descriptor-filtered) list.
		models: TOKENROUTER_MODELS.map(makeModel),
		...(environmentKey ? {apiKey: environmentKey} : {}),
		authHeader: true,
		oauth: {name: "TokenRouter", login: loginTokenrouter},
		fetchDynamicModels: async apiKey => {
			if (!apiKey?.trim()) return [];
			const fetchImpl = fetch;
			const response = await fetchImpl(MODELS_URL, {
				method: "GET",
				headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
				signal: AbortSignal.timeout(10_000),
			});
			if (!response.ok) return [];
			const models = parseTokenrouterModels(await response.json());
			// Fall back to the static catalog if the curated intersection is
			// empty (e.g. the live catalog renamed/retired both entries).
			return models.length ? models : staticTokenrouterModels().map(m => ({...m, compat}));
		},
	});
};

export default tokenrouterProvider;
