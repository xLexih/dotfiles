/**
 * Zen client-identity helpers (pure logic, no pi-ai imports so `bun test`
 * runs without resolving peer dependencies).
 *
 * The native `opencode-zen` provider already owns model discovery, endpoint
 * routing, and compat — this extension only spoofs the two client-identity
 * signals Zen's free tier gates on (see `src/index.ts`):
 *
 * - `User-Agent: opencode/...` — anonymous `-free` capacity returns
 *   `429 FreeUsageLimitError` for any other UA. Any `opencode/*` value
 *   passes; the pin below tracks the locally installed client.
 * - `x-opencode-session: ses_...` — required since 09/06; carries the
 *   prompt-cache lineage. Values are mapped per OMP conversation so
 *   separate conversations never share a lineage.
 */

/** Header Zen's free tier requires on every inference request. */
export const ZEN_SESSION_HEADER = "x-opencode-session";

/** Pinned to the locally installed client (`opencode --version`); any `opencode/*` passes the UA gate. */
export const ZEN_USER_AGENT = "opencode/1.18.30";

/** `ses_` + 26 chars, mirroring opencode's `Identifier.create("ses", ...)`. */
export const ZEN_SESSION_PATTERN = /^ses_[0-9a-f]{12}[0-9A-Za-z]{14}$/;

/** opencode's own base62 alphabet (`packages/opencode/src/id/id.ts`). */
const BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

/** Inference paths whose requests must carry the spoofed identity. Discovery (`/models`) is public and untouched. */
const ZEN_INFERENCE_PATH =
	/^\/zen\/(?:v\d+(?:beta)?\/)?(?:chat\/completions|responses|messages|systemone|models\/[^/]+:(?:streamGenerateContent|generateContent))\/?$/;

function sha256Hex(input: string): string {
	return new Bun.CryptoHasher("sha256").update(input).digest("hex") as string;
}

/**
 * Map an OMP conversation id to a Zen session id in opencode's own format:
 * `ses_` + 12 lowercase hex (time-bytes shape) + 14 base62 (random-suffix
 * shape), 26 chars total — e.g. `ses_f36bdb647ffeCD6SkW3nr4RoBL`.
 *
 * Deterministic per conversation (sha256 of the OMP id), so the mapping is
 * stable across turns and process restarts without any persisted state,
 * keeping OpenCode's prompt-cache affinity while isolating conversations.
 */
export function toZenSessionId(ompSessionId: string): string {
	const hex = sha256Hex(ompSessionId);
	const timePart = hex.slice(0, 12);
	let randPart = "";
	for (let i = 0; i < 14; i++) {
		const byte = parseInt(hex.slice(12 + i * 2, 14 + i * 2), 16);
		randPart += BASE62[byte % 62];
	}
	return `ses_${timePart}${randPart}`;
}

/** True when a fetch input targets Zen inference (identity spoof applies). */
export function isZenInferenceRequest(input: string | URL | Request): boolean {
	try {
		const url = input instanceof Request ? new URL(input.url) : new URL(input);
		return url.origin === "https://opencode.ai" && ZEN_INFERENCE_PATH.test(url.pathname);
	} catch {
		return false;
	}
}

/** Structural subset of pi-ai's `Model` needed for the free-tier filter. */
export interface FreeChatModelCandidate {
	provider: string;
	id: string;
	kind?: string;
	api: string | { toString(): string };
}

/** Raw-id rule: `big-pickle` and `*-free`, excluding the judge (`jev-*`) and SystemOne families. */
export function isFreeChatId(id: string): boolean {
	return (
		(id === "big-pickle" || id.endsWith("-free")) && !/^(?:jev|system[-_]?one)(?:[-_.]|$)/i.test(id)
	);
}
/** pi-ai's judgment APIs (e.g. `typesafe`) never ride the chat shim. */
function isJudgmentApi(api: FreeChatModelCandidate["api"]): boolean {
	const name = typeof api === "string" ? api : String(api);
	return name === "typesafe" || name.toLowerCase().includes("judg");
}

/**
 * Free chat models that must go through the identity shim: `big-pickle` and
 * `*-free`, excluding the judge (`jev-*`) and SystemOne families, non-chat
 * kinds, and judgment APIs. Paid models pass through to the native provider
 * untouched. New `-free` ids flow in via native discovery with no change
 * here.
 */
export function isFreeChatModel(model: FreeChatModelCandidate): boolean {
	return (
		model.provider === "opencode-zen" &&
		isFreeChatId(model.id) &&
		(model.kind === undefined || model.kind === "chat") &&
		!isJudgmentApi(model.api)
	);
}
