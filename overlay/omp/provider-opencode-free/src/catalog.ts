import type {Model} from "@oh-my-pi/pi-ai";

/**
 * OpenCode Zen's free model catalog. Zen serves `https://opencode.ai/zen/v1`
 * with a public `/v1/models` and accepts anonymous chat-completions for the
 * `:free`-suffixed models. Live probe on 2026-09-02 confirmed:
 *
 *   curl -X POST https://opencode.ai/zen/v1/chat/completions \
 *     -H 'Content-Type: application/json' \
 *     -d '{"model":"mimo-v2.5-free","messages":[{"role":"user","content":"Reply OK"}],"max_tokens":200,"stream":false}'
 *
 * returns `choices[0].message.reasoning` (string), `content: "OK"`, and
 * `usage.prompt_tokens_details.cached_tokens: 192`. No `Authorization` header
 * is required for the free models — the provider id is `opencode` and the
 * transport omits the Bearer header when no key is set.
 *
 * `deepseek-v4-flash-free` was confirmed unavailable at probe time
 * (`{"error":{"type":"server_error","message":"Error from provider (Console): Upstream request failed: Model is unavailable."}}`)
 * and is dropped from the curated list. Re-add it by appending a row once
 * Zen brings it back.
 */
export interface OpencodeZenModelDescriptor {
	id: string;
	name: string;
	contextWindow: number;
	maxTokens: number;
	reasoning: boolean;
	input: ("text" | "image")[];
	highContextWarnTokens: number;
	highContextHint: "preferred" | "acceptable" | "avoid";
}

export const OPENCODE_ZEN_MODELS: readonly OpencodeZenModelDescriptor[] = [
	{
		id: "mimo-v2.5-free",
		name: "MiMo V2.5 Free",
		contextWindow: 32_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 24_000,
		highContextHint: "acceptable",
	},
	{
		id: "muse-spark-1.3-contributor-free",
		name: "Muse Spark 1.3 Contributor Free",
		contextWindow: 200_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 150_000,
		highContextHint: "acceptable",
	},
	{
		id: "muse-spark-1.2-contributor-free",
		name: "Muse Spark 1.2 Contributor Free",
		contextWindow: 200_000,
		maxTokens: 8_192,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 150_000,
		highContextHint: "acceptable",
	},
	{
		id: "nemotron-3-ultra-free",
		name: "Nemotron 3 Ultra Free",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "nemotron-3.5-lightning-free",
		name: "Nemotron 3.5 Lightning Free",
		contextWindow: 1_048_576,
		maxTokens: 16_384,
		reasoning: true,
		input: ["text"],
		highContextWarnTokens: 200_000,
		highContextHint: "acceptable",
	},
	{
		id: "ling-3.0-flash-fin-free",
		name: "Ling 3.0 Flash Fin Free",
		contextWindow: 32_000,
		maxTokens: 8_192,
		reasoning: false,
		input: ["text"],
		highContextWarnTokens: 24_000,
		highContextHint: "acceptable",
	},
];

const DESCRIPTORS_BY_ID = new Map(OPENCODE_ZEN_MODELS.map(d => [d.id, d]));

export function getOpencodeZenDescriptor(id: string): OpencodeZenModelDescriptor | undefined {
	return DESCRIPTORS_BY_ID.get(id);
}

export function buildOpencodeZenModel(descriptor: OpencodeZenModelDescriptor): Model<"openai-completions"> {
	return {
		id: descriptor.id,
		name: descriptor.name,
		provider: "opencode",
		baseUrl: "https://opencode.ai/zen/v1",
		api: "openai-completions",
		reasoning: descriptor.reasoning,
		input: descriptor.input,
		cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
		contextWindow: descriptor.contextWindow,
		maxTokens: descriptor.maxTokens,
		highContextWarnTokens: descriptor.highContextWarnTokens,
		highContextHint: descriptor.highContextHint,
	} as Model<"openai-completions">;
}

export function staticOpencodeZenModels(): Model<"openai-completions">[] {
	return OPENCODE_ZEN_MODELS.map(buildOpencodeZenModel);
}

/** Filter the live `/v1/models` payload to curated entries. */
export function parseOpencodeZenModels(body: unknown): Model<"openai-completions">[] {
	if (!body || typeof body !== "object") return [];
	if (!("data" in body)) return [];
	const data = (body as Record<string, unknown>).data;
	if (!Array.isArray(data)) return [];
	const out: Model<"openai-completions">[] = [];
	for (const entry of data) {
		if (!entry || typeof entry !== "object" || !"id" in entry) continue;
		const id = (entry as {id: unknown}).id;
		if (typeof id !== "string") continue;
		const d = DESCRIPTORS_BY_ID.get(id);
		if (d) out.push(buildOpencodeZenModel(d));
	}
	return out;
}
