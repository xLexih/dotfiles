/**
 * Free-tier client identity for OpenCode Zen in Oh My Pi.
 *
 * Wraps globalThis.fetch, but only rewrites JSON requests to the zen
 * inference API (https://opencode.ai/zen/v1/…) whose `model` is a free id
 * (`big-pickle`, `*-free`). Those get the client identity the gateway expects
 * from the real opencode client: UA `opencode/<version>`, a locally minted
 * `ses_…` session id in the session headers, `x-opencode-client: cli`, at
 * least two core tool names (in the endpoint's tool shape) and `stream:true`.
 * One 403 retry with a fresh session id. Paid models, the opencode-go gateway
 * and every other request pass through untouched. If preparing the rewrite
 * fails, the original request is sent as-is; network errors from the real
 * fetch propagate and are never replayed.
 */
import {forceStream, injectEnv, injectZenTools, isFreeModel, isZenInference, mintSessionId, toolStyleFor} from "./zen.ts";

/** Default matches the pinned opencode in this repo; override via env. */
const DEFAULT_UA_VERSION = "1.19.3";

function uaVersion(): string {
	return process.env.OPENCODE_UA_VERSION?.trim() || DEFAULT_UA_VERSION;
}

function zenHeaders(sessionId: string, existing: Headers): Headers {
	const headers = new Headers(existing);
	if (!headers.get("user-agent")?.startsWith("opencode/")) {
		headers.set("user-agent", `opencode/${uaVersion()}`);
	}
	if (!headers.has("x-opencode-client")) headers.set("x-opencode-client", "cli");
	for (const name of ["x-opencode-session", "x-opencode-session-id", "x-session-affinity", "x-session-id"]) {
		headers.set(name, sessionId);
	}
	if (!headers.has("x-opencode-project")) headers.set("x-opencode-project", "");
	headers.delete("content-length");
	return headers;
}

/** A free-tier zen request rewritten for the gateway, minus session headers. */
interface FreeRequest {
	init: RequestInit;
	headers: Headers;
}

/** The rewritten request, or null when it is not a free-tier zen call. */
async function prepareFreeRequest(
	url: string,
	input: Parameters<typeof fetch>[0],
	init: Parameters<typeof fetch>[1],
): Promise<FreeRequest | null> {
	const request = input instanceof Request ? input : undefined;
	const rawBody = init?.body !== undefined ? init.body : request ? await request.clone().text() : undefined;
	if (typeof rawBody !== "string") return null;
	const doc: unknown = JSON.parse(rawBody);
	if (!doc || typeof doc !== "object" || !("model" in doc) || !isFreeModel(doc.model)) return null;

	let body = forceStream(rawBody) ?? rawBody;
	if (process.env.ZEN_INJECT_ENV !== "0") body = injectEnv(body);
	if (process.env.ZEN_INJECT_TOOLS !== "0") body = injectZenTools(body, toolStyleFor(url)).text;

	const headers = new Headers(request?.headers);
	if (init?.headers) new Headers(init.headers).forEach((value, key) => headers.set(key, value));
	return {
		init: {...init, method: init?.method ?? request?.method ?? "POST", signal: init?.signal ?? request?.signal, body},
		headers,
	};
}

let warnedUsageLimit = false;

export interface ZenPatchHandle {
	patched: typeof fetch;
	restore: () => void;
}

/** Build the patched fetch. Split from install so tests can exercise the
 * wrapper without touching global state. */
export function createZenFetch(origFetch: typeof fetch): ZenPatchHandle {
	let sessionId = mintSessionId();

	const patchedFetch = async function zenFetch(
		this: unknown,
		input: Parameters<typeof fetch>[0],
		init?: Parameters<typeof fetch>[1],
	): Promise<Response> {
		const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
		if (!isZenInference(url)) return origFetch.call(this, input, init);

		let prepared: FreeRequest | null;
		try {
			prepared = await prepareFreeRequest(url, input, init);
		} catch {
			prepared = null;
		}
		if (!prepared) return origFetch.call(this, input, init);

		for (let attempt = 0; ; attempt++) {
			if (process.env.ZEN_HEADERS_DEBUG === "1") {
				console.error(`[opencode-zen-free] ${url.split("?")[0]} session=${sessionId.slice(0, 25)}`);
			}
			const response = await origFetch.call(this, url, {
				...prepared.init,
				headers: zenHeaders(sessionId, prepared.headers),
			});
			if (response.status === 429 && !warnedUsageLimit) {
				warnedUsageLimit = true;
				console.error(
					"[opencode-zen-free] zen free quota exhausted (per-IP, resets later); requests will 429 until then",
				);
			}
			if (response.status !== 403 || attempt > 0) return response;
			try {
				await response.body?.cancel();
			} catch {
				// release the socket before retrying
			}
			sessionId = mintSessionId();
		}
	};

	return {patched: patchedFetch, restore: () => (sessionId = mintSessionId())};
}

/** omp extension entry point — installs the fetch patch at startup. */
export default function opencodeZenFree(pi?: {
	logger?: {info?: (...args: unknown[]) => void; warn?: (...args: unknown[]) => void};
}): void {
	if (typeof globalThis.fetch !== "function") return;
	const {patched} = createZenFetch(globalThis.fetch);
	globalThis.fetch = patched;
	pi?.logger?.info?.(
		`[opencode-zen-free] fetch patch active (UA: opencode/${uaVersion()}, session: minted locally)`,
	);
}
