import type {Model} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {clineCompat} from "./compat.ts";
import {buildClineModel, CLINE_MODELS, parseClineModels, staticClineModels} from "./catalog.ts";

const MODELS_URL = "https://api.cline.bot/api/v1/models";

async function loginCline(callbacks: OAuthLoginCallbacks): Promise<string> {
	const apiKey = (await callbacks.onPrompt({message: "Paste your Cline API key", placeholder: "sk_..."})).trim();
	if (callbacks.signal?.aborted) throw new Error("Cline login cancelled");
	if (!apiKey) throw new Error("A Cline API key is required");
	callbacks.onProgress?.("Validating Cline API key...");
	const fetchImpl = callbacks.fetch ?? fetch;
	const response = await fetchImpl(MODELS_URL, {
		method: "GET",
		headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
		signal: AbortSignal.timeout(15_000),
	});
	if (!response.ok) throw new Error(`Cline API key validation failed (${response.status})`);
	return apiKey;
}

const clineProvider: ExtensionFactory = pi => {
	const environmentKey = process.env.CLINE_API_KEY?.trim();

	const withCompat = (model: Model<"openai-completions">): Model<"openai-completions"> => ({
		...model,
		compat: clineCompat(model),
	} as Model<"openai-completions">);

	pi.registerProvider("cline", {
		baseUrl: "https://api.cline.bot/api/v1",
		api: "openai-completions",
		// Static fallback catalog; replaced by the dynamic-fetch result once
		// `fetchDynamicModels` succeeds.
		models: CLINE_MODELS.map(d => withCompat(buildClineModel(d))),
		...(environmentKey ? {apiKey: environmentKey} : {}),
		authHeader: true,
		oauth: {name: "Cline", login: loginCline},
		fetchDynamicModels: async apiKey => {
			// Cline's `/v1/models` is public, but the per-account `/v1/chat/completions`
			// quota differs by tier. Without a key we can still show the curated
			// model list — the user can `omp /login cline` to attach one.
			const fetchImpl = fetch;
			const headers: Record<string, string> = {"Accept-Encoding": "identity"};
			if (apiKey?.trim()) headers.Authorization = `Bearer ${apiKey}`;
			const response = await fetchImpl(MODELS_URL, {
				method: "GET",
				headers,
				signal: AbortSignal.timeout(10_000),
			});
			if (!response.ok) return [];
			const models = parseClineModels(await response.json());
			// If the live catalog doesn't list any of our curated ids (e.g. Cline
			// rotated the free roster), keep the static catalog visible so the
			// extension still works.
			return models.length ? models : staticClineModels().map(withCompat);
		},
	});
};

export default clineProvider;
