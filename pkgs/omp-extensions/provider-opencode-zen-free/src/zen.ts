/**
 * Minimal helpers for passing OpenCode Zen's free-tier client-identity gate.
 *
 * Probed against https://opencode.ai/zen/v1/chat/completions (2026-10-24):
 * - stream:false or missing session headers -> 403 FreeTierError
 * - UA `opencode/<ver>` + locally minted `ses_…` session id -> accepted
 * (429 FreeUsageLimitError afterwards is a per-IP quota, not an identity gate)
 */
import {existsSync} from "node:fs";
import {dirname, join} from "node:path";

/** `ses_` + 6 bytes of ~(ms*0x1000 + counter) hex + 14 random base62 chars —
 * the exact shape opencode 1.19.3 mints client-side (Session ID brand `ses_`). */
export function mintSessionId(now: number = Date.now(), counter = 1): string {
	const x = ~(BigInt(now) * 0x1000n + BigInt(counter));
	const hex6 = Array.from({length: 6}, (_, i) =>
		((x >> BigInt(40 - 8 * i)) & 0xffn).toString(16).padStart(2, "0"),
	).join("");
	const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	const randoms = crypto.getRandomValues(new Uint8Array(14));
	let tail = "";
	for (const r of randoms) tail += alphabet[r % 62];
	return `ses_${hex6}${tail}`;
}

/** Free-tier zen inference lives under https://opencode.ai/zen/v1/ (chat,
 * responses and anthropic messages). The paid opencode-go gateway
 * (/zen/go/v1) and everything else on the host are out of scope. */
export function isZenInference(url: string): boolean {
	try {
		const parsed = new URL(url);
		return parsed.hostname.toLowerCase() === "opencode.ai" && parsed.pathname.startsWith("/zen/v1/");
	} catch {
		return false;
	}
}

/** Zen's free model ids: `big-pickle` and every `*-free` id. */
export function isFreeModel(model: unknown): boolean {
	return typeof model === "string" && (model === "big-pickle" || model.endsWith("-free"));
}

/** Tool entry shape per endpoint: Responses and Anthropic messages put the
 * name at the top level, chat completions nests it under `function`. */
export type ToolStyle = "chat" | "responses" | "anthropic";

export function toolStyleFor(url: string): ToolStyle {
	const path = new URL(url).pathname.replace(/\/+$/, "");
	if (path.endsWith("/responses")) return "responses";
	if (path.endsWith("/messages")) return "anthropic";
	return "chat";
}

export const ZEN_REQUIRED_TOOL_NAMES = ["bash", "read"] as const;

const STUB_DESCRIPTION = "Gateway-validation stub. NOT IMPLEMENTED — never call this tool.";
const STUB_PARAMETERS = {
	type: "object",
	properties: {command: {type: "string"}, description: {type: "string"}},
	required: ["command"],
	additionalProperties: false,
};

/** Tool name sits at `entry.name` (responses / anthropic style) or
 * `entry.function.name` (chat-completions style); anything else is not a
 * readable tool entry. */
function readToolName(entry: unknown): string | null {
	if (!entry || typeof entry !== "object") return null;
	if ("name" in entry && typeof entry.name === "string") return entry.name;
	if ("function" in entry) {
		const fn: unknown = entry.function;
		if (fn && typeof fn === "object" && "name" in fn && typeof fn.name === "string") return fn.name;
	}
	return null;
}

/** Append stubs for missing core tool names until two are present, in the
 * tool shape of the target endpoint. Returns the original text unchanged on
 * any parse doubt or when the request forces tool_choice (the model must then
 * pick a real tool). */
export function injectZenTools(
	bodyText: string,
	style: ToolStyle = "chat",
): {text: string; injected: string[]; present: number} {
	const passthrough = {text: bodyText, injected: [] as string[], present: 0};
	let doc: unknown;
	try {
		doc = JSON.parse(bodyText);
	} catch {
		return passthrough;
	}
	if (!doc || typeof doc !== "object" || Array.isArray(doc)) return passthrough;
	const toolsRaw = "tools" in doc ? doc.tools : undefined;
	const toolsList: unknown[] = Array.isArray(toolsRaw) ? toolsRaw : [];
	const names = toolsList.map(readToolName).filter((n): n is string => n !== null);
	const missing = ZEN_REQUIRED_TOOL_NAMES.filter(n => !names.includes(n));
	const present = ZEN_REQUIRED_TOOL_NAMES.length - missing.length;
	const choice = "tool_choice" in doc ? doc.tool_choice : undefined;
	let forced = choice === "required" || choice === "any";
	if (choice && typeof choice === "object" && !Array.isArray(choice) && "type" in choice) {
		forced = choice.type === "required" || choice.type === "any";
	}
	if (present >= 2 || missing.length === 0 || forced) {
		return {text: bodyText, injected: [], present};
	}
	const stubs: unknown[] = [];
	const injected: string[] = [];
	for (const name of missing) {
		if (present + stubs.length >= 2) break;
		const description = STUB_DESCRIPTION;
		const parameters = STUB_PARAMETERS;
		stubs.push(
			style === "anthropic"
				? {name, description, input_schema: parameters}
				: style === "responses"
					? {type: "function", name, description, parameters}
					: {type: "function", function: {name, description, parameters}},
		);
		injected.push(name);
	}
	// No content-length handling here: the fetch wrapper re-sets headers.
	const out = {...doc, tools: [...(Array.isArray(toolsRaw) ? toolsRaw : []), ...stubs]};
	return {text: JSON.stringify(out), injected, present};
}

/** Force `stream:true` on a zen JSON body — non-streaming free-tier requests
 * are rejected by gateway policy (omp's title generator etc.).
 * Returns null when the body already streams or cannot be safely rewritten. */
export function forceStream(bodyText: string): string | null {
	let doc: unknown;
	try {
		doc = JSON.parse(bodyText);
	} catch {
		return null;
	}
	if (!doc || typeof doc !== "object" || Array.isArray(doc)) return null;
	if ("stream" in doc && doc.stream === true) return null;
	return JSON.stringify({...doc, stream: true});
}

/** Environment facts the free-tier gate expects in the system prompt. */
export interface ZenEnv {
	workingDirectory: string;
	workspaceRoot: string;
	isGitRepo: boolean;
	platform: string;
	date: string;
}

function findWorkspace(cwd: string): {root: string; isGitRepo: boolean} {
	let dir = cwd;
	for (;;) {
		if (existsSync(join(dir, ".git"))) return {root: dir, isGitRepo: true};
		const parent = dirname(dir);
		if (parent === dir) return {root: "/", isGitRepo: false};
		dir = parent;
	}
}

/** Build the `<env>` block from the process context (overridable in tests). */
export function currentEnv(now: Date = new Date(), cwd: string = process.cwd()): ZenEnv {
	const {root, isGitRepo} = findWorkspace(cwd);
	return {
		workingDirectory: cwd,
		workspaceRoot: root,
		isGitRepo,
		platform: process.platform,
		date: now.toDateString(),
	};
}

export function envBlock(env: ZenEnv): string {
	return `<env>
  Working directory: ${env.workingDirectory}
  Workspace root folder: ${env.workspaceRoot}
  Is directory a git repo: ${env.isGitRepo ? "yes" : "no"}
  Platform: ${env.platform}
  Today's date: ${env.date}
</env>`;
}

function hasEnv(content: unknown): boolean {
	if (typeof content === "string") return content.includes("<env>");
	if (!Array.isArray(content)) return false;
	return content.some(part => {
		if (typeof part === "string") return part.includes("<env>");
		return Boolean(part) && typeof part === "object" && "text" in part && typeof part.text === "string" && part.text.includes("<env>");
	});
}

/** Prepend the `<env>` block to the first system message. The gateway rejects
 * free-model requests whose system prompt lacks it (429 FreeUsageLimitError),
 * even when every header matches the real client. */
export function injectEnv(bodyText: string, env: ZenEnv = currentEnv()): string {
	let doc: unknown;
	try {
		doc = JSON.parse(bodyText);
	} catch {
		return bodyText;
	}
	if (!doc || typeof doc !== "object" || Array.isArray(doc) || !("messages" in doc) || !Array.isArray(doc.messages)) {
		return bodyText;
	}
	const messages = doc.messages as unknown[];
	const system = messages.find(m => Boolean(m) && typeof m === "object" && (m as {role?: unknown}).role === "system") as
		| {content?: unknown}
		| undefined;
	const block = envBlock(env);
	if (!system) {
		messages.unshift({role: "system", content: block});
		return JSON.stringify(doc);
	}
	if (hasEnv(system.content)) return bodyText;
	if (typeof system.content === "string") system.content = `${block}\n\n${system.content}`;
	else if (Array.isArray(system.content)) system.content.unshift({type: "text", text: block});
	else system.content = block;
	return JSON.stringify(doc);
}
