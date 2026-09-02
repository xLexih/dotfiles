import type {Model} from "@oh-my-pi/pi-ai";
import type {ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {opencodeZenCompat} from "./compat.ts";
import {buildOpencodeZenModel, OPENCODE_ZEN_MODELS, parseOpencodeZenModels, staticOpencodeZenModels} from "./catalog.ts";

const MODELS_URL = "https://opencode.ai/zen/v1/models";

/**
 * OpenCode Zen free-model provider. The provider id is `opencode-free` (not
 * `opencode`) to keep it distinct from any future built-in or third-party
 * `opencode` provider, and to make the model picker's prefix self-documenting
 * — every model under this prefix is a no-auth free route.
 *
 * Zen's `/v1/models` is public; the `:free` models in our catalog accept
 * chat-completions without an `Authorization` header. The provider therefore
 * registers without `authHeader: true` and without an `oauth` login flow:
 * the user can pick any of the 6 free models immediately after install, no
 * `/login` step required.
 */
const opencodeFreeProvider: ExtensionFactory = pi => {
	const environmentKey = process.env.OPENCODE_API_KEY?.trim();

	const withCompat = (model: Model<"openai-completions">): Model<"openai-completions"> => ({
		...model,
		compat: opencodeZenCompat(model),
	} as Model<"openai-completions">);

	pi.registerProvider("opencode-free", {
		baseUrl: "https://opencode.ai/zen/v1",
		api: "openai-completions",
		// `auth: "none"` tells OMP 18.0.8's runtime-register check that this
		// provider is intentionally keyless. The Zen free models accept
		// chat-completions without an `Authorization` header, so neither
		// `apiKey` nor `oauth` is needed. See the runtime check at
		// omp-linux-x64:507217: `(t.auth ?? "apiKey") !== "none"`.
		auth: "none",
		models: OPENCODE_ZEN_MODELS.map(d => withCompat(buildOpencodeZenModel(d))),
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

export default opencodeFreeProvider;
