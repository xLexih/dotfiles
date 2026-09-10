import type {Model} from "@oh-my-pi/pi-ai";

/**
 * Local GLM bridge (github.com/izaart95-jpg/GLM-Free-API) model catalog.
 *
 * The bridge is a stateless OpenAI-compatible proxy over chat.z.ai. Model ids
 * are Z.AI's own (`glm-5.3`, `glm-4.7`, ...); the live list comes from the
 * bridge's `GET /v1/models`, which itself mirrors Z.AI `/api/models`.
 *
 * Context windows: GLM-5.x models share the 1,048,576-token architectural max
 * (same upstream weights as TokenRouter's `z-ai/glm-5.3` routes, see
 * `overlay/omp/provider-tokenrouter/README.md`). `glm-4.7` is a GLM-4.x
 * model with a 128K window per the Z.AI model card.
 */

export interface GlmBridgeModelDescriptor {
	id: string;
	name: string;
	contextWindow: number;
	maxTokens: number;
	/** Free local bridge — costs are display-only zeros. */
	cost: {input: number; output: number; cacheRead: number; cacheWrite: number};
	reasoning: boolean;
	input: ("text" | "image")[];
	highContextWarnTokens: number;
	highContextHint: "preferred" | "acceptable" | "avoid";
}

const ZERO_COST = {input: 0, output: 0, cacheRead: 0, cacheWrite: 0};

export const GLM_BRIDGE_MODELS: readonly GlmBridgeModelDescriptor[] = [
	{id: "glm-5.3", name: "GLM 5.3", contextWindow: 1_048_576, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text"], highContextWarnTokens: 200_000, highContextHint: "acceptable"},
	{id: "glm-5.2", name: "GLM 5.2", contextWindow: 1_048_576, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text"], highContextWarnTokens: 200_000, highContextHint: "acceptable"},
	{id: "GLM-5.1", name: "GLM 5.1", contextWindow: 1_048_576, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text"], highContextWarnTokens: 200_000, highContextHint: "acceptable"},
	{id: "GLM-5-Turbo", name: "GLM 5 Turbo", contextWindow: 1_048_576, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text"], highContextWarnTokens: 200_000, highContextHint: "acceptable"},
	{id: "GLM-5v-Turbo", name: "GLM 5V Turbo (vision)", contextWindow: 1_048_576, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text", "image"], highContextWarnTokens: 200_000, highContextHint: "acceptable"},
	{id: "glm-4.7", name: "GLM 4.7", contextWindow: 131_072, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text"], highContextWarnTokens: 100_000, highContextHint: "acceptable"},
	// The bridge defaults a missing `model` to `glm-5`; register the alias
	// so it is selectable explicitly.
	{id: "glm-5", name: "GLM 5 (bridge default)", contextWindow: 1_048_576, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text"], highContextWarnTokens: 200_000, highContextHint: "acceptable"},
	// NOTE: the bridge advertises flash as `x-preview-l` (display name
	// "GLM-5.3-Flash"). `glm-5.3-flash` is NOT a valid upstream id — the
	// bridge forwards it verbatim and Z.AI answers a bare 500 (verified
	// 2026-09-09, guest and account sessions alike).
	{id: "x-preview-l", name: "GLM 5.3 Flash", contextWindow: 1_048_576, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input: ["text"], highContextWarnTokens: 200_000, highContextHint: "acceptable"},
];

const DESCRIPTORS_BY_ID = new Map(GLM_BRIDGE_MODELS.map(d => [d.id, d]));

/** Return the descriptor for a known id, or `undefined` if not curated. */
export function getGlmBridgeDescriptor(id: string): GlmBridgeModelDescriptor | undefined {
	return DESCRIPTORS_BY_ID.get(id);
}

/** Build a typed `Model<"openai-completions">` entry for OMP's registry. */
export function buildGlmBridgeModel(descriptor: GlmBridgeModelDescriptor, baseUrl: string): Model<"openai-completions"> {
	return {
		id: descriptor.id,
		name: descriptor.name,
		provider: "glm-local",
		baseUrl,
		api: "openai-completions",
		reasoning: descriptor.reasoning,
		input: descriptor.input,
		cost: descriptor.cost,
		contextWindow: descriptor.contextWindow,
		maxTokens: descriptor.maxTokens,
		highContextWarnTokens: descriptor.highContextWarnTokens,
		highContextHint: descriptor.highContextHint,
	} as Model<"openai-completions">;
}

/** Static curated list — registration-time fallback before discovery runs. */
export function staticGlmBridgeModels(baseUrl: string): Model<"openai-completions">[] {
	return GLM_BRIDGE_MODELS.map(d => buildGlmBridgeModel(d, baseUrl));
}
/**
 * Convert a raw `/v1/models` payload into the catalog.
 *
 * Known ids use their descriptor (ground-truth limits). Unknown ids (new
 * Z.AI point releases) are still registered with conservative defaults so a
 * bridge upgrade never leaves OMP with zero models; `architecture` advertises
 * vision support when present.
 */
export function parseGlmBridgeModels(body: unknown, baseUrl: string): Model<"openai-completions">[] {
	if (!body || typeof body !== "object") return [];
	if (!("data" in body)) return [];
	const data = (body as Record<string, unknown>).data;
	if (!Array.isArray(data)) return [];
	const seen = new Set<string>();
	const out: Model<"openai-completions">[] = [];
	for (const entry of data) {
		if (!entry || typeof entry !== "object") continue;
		if (!("id" in entry) || typeof entry.id !== "string") continue;
		if (seen.has(entry.id)) continue;
		seen.add(entry.id);
		const known = DESCRIPTORS_BY_ID.get(entry.id);
		if (known) {
			out.push(buildGlmBridgeModel(known, baseUrl));
			continue;
		}
		const input: ("text" | "image")[] = ["text"];
		if ("architecture" in entry && entry.architecture && typeof entry.architecture === "object") {
			const arch = entry.architecture as Record<string, unknown>;
			if (Array.isArray(arch["input_modalities"]) && (arch["input_modalities"] as unknown[]).includes("image")) {
				input.push("image");
			}
		}
		out.push(
			buildGlmBridgeModel(
				{id: entry.id, name: entry.id, contextWindow: 131_072, maxTokens: 16_384, cost: ZERO_COST, reasoning: true, input, highContextWarnTokens: 100_000, highContextHint: "acceptable"},
				baseUrl,
			),
		);
	}
	return out;
}
