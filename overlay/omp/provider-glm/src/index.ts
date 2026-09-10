import type {Model} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import type {OAuthLoginCallbacks} from "@oh-my-pi/pi-ai/oauth/types";
import {glmBridgeCompat} from "./compat.ts";
import {buildGlmBridgeModel, getGlmBridgeDescriptor, parseGlmBridgeModels, staticGlmBridgeModels, GLM_BRIDGE_MODELS} from "./catalog.ts";

const DEFAULT_BASE_URL = "http://127.0.0.1:3001/v1";
const DEFAULT_API_KEY = "Waguri";

function resolveBaseUrl(): string {
	return process.env.GLM_BRIDGE_URL?.trim().replace(/\/+$/, "") || DEFAULT_BASE_URL;
}

function resolveApiKey(): string {
	return process.env.GLM_BRIDGE_API_KEY?.trim() || DEFAULT_API_KEY;
}

async function loginGlmBridge(callbacks: OAuthLoginCallbacks): Promise<string> {
	const apiKey = (await callbacks.onPrompt({message: "Paste your GLM bridge AUTH_TOKEN", placeholder: DEFAULT_API_KEY})).trim();
	if (callbacks.signal?.aborted) throw new Error("GLM bridge login cancelled");
	if (!apiKey) throw new Error("A GLM bridge AUTH_TOKEN is required");
	callbacks.onProgress?.("Validating GLM bridge token...");
	const fetchImpl = callbacks.fetch ?? fetch;
	const baseUrl = resolveBaseUrl();
	const response = await fetchImpl(`${baseUrl}/models`, {
		method: "GET",
		headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
		signal: AbortSignal.timeout(15_000),
	});
	if (!response.ok) throw new Error(`GLM bridge token validation failed (${response.status}) — is the bridge running at ${baseUrl}?`);
	return apiKey;
}

const glmProvider: ExtensionFactory = pi => {
	const baseUrl = resolveBaseUrl();
	const environmentKey = resolveApiKey();

	const compat = glmBridgeCompat();
	const makeModel = (id: string): Model<"openai-completions"> => {
		const descriptor = getGlmBridgeDescriptor(id);
		if (!descriptor) throw new Error(`unknown GLM bridge model: ${id}`);
		return {...buildGlmBridgeModel(descriptor, baseUrl), compat} as Model<"openai-completions">;
	};

	pi.registerProvider("glm-local", {
		baseUrl,
		api: "openai-completions",
		// Static fallback list — used immediately at registration time and as
		// a safety net if `/v1/models` is unreachable (bridge down). Once
		// `fetchDynamicModels` succeeds, OMP replaces this with the live
		// list. The bridge always requires auth, and the default AUTH_TOKEN
		// is `Waguri`, so register the default key rather than running
		// keyless.
		models: GLM_BRIDGE_MODELS.map(d => makeModel(d.id)),
		apiKey: environmentKey,
		authHeader: true,
		oauth: {name: "GLM Bridge", login: loginGlmBridge},
		fetchDynamicModels: async apiKey => {
			if (!apiKey?.trim()) return [];
			const response = await fetch(`${baseUrl}/models`, {
				method: "GET",
				headers: {Authorization: `Bearer ${apiKey}`, "Accept-Encoding": "identity"},
				signal: AbortSignal.timeout(10_000),
			});
			if (!response.ok) return [];
			const models = parseGlmBridgeModels(await response.json(), baseUrl);
			// Fall back to the static catalog if the live list parses to
			// nothing (e.g. bridge mid-restart serving an error page).
			const live = models.length ? models : staticGlmBridgeModels(baseUrl);
			return live.map(m => ({...m, compat}));
		},
	});
};

export default glmProvider;
