import {afterEach, describe, expect, it} from "bun:test";
import {createZenFetch} from "../src/index.ts";

const ZEN_CHAT = "https://opencode.ai/zen/v1/chat/completions";
const FREE_BODY = JSON.stringify({model: "big-pickle", messages: []});

interface Call {
	input: unknown;
	init?: RequestInit;
}

function recorder(respond: (call: number) => Response = () => new Response("{}")) {
	const calls: Call[] = [];
	const orig = (async (input: unknown, init?: RequestInit) => {
		calls.push({input, init});
		return respond(calls.length);
	}) as unknown as typeof fetch;
	return {calls, orig};
}

describe("zen fetch patch", () => {
	afterEach(() => {
		delete process.env.ZEN_INJECT_TOOLS;
		delete process.env.ZEN_INJECT_ENV;
		delete process.env.OPENCODE_UA_VERSION;
	});

	it("leaves non-zen hosts, paid models and the opencode-go gateway untouched", async () => {
		const {calls, orig} = recorder();
		const {patched} = createZenFetch(orig);
		const paid = {method: "POST", body: JSON.stringify({model: "claude-opus-5", messages: []})};
		const goFree = {method: "POST", body: JSON.stringify({model: "ox-alpha-free", messages: []})};
		await patched("https://example.com/v1/chat", {method: "POST", body: FREE_BODY});
		await patched(ZEN_CHAT, paid);
		await patched("https://opencode.ai/zen/go/v1/chat/completions", goFree);
		expect(calls.map(c => c.init)).toEqual([{method: "POST", body: FREE_BODY}, paid, goFree]);
	});

	it("adds identity headers to free zen requests", async () => {
		const {calls, orig} = recorder();
		const {patched} = createZenFetch(orig);
		await patched(ZEN_CHAT, {method: "POST", body: FREE_BODY});
		const seen = new Headers(calls[0].init?.headers);
		expect(seen.get("user-agent")).toMatch(/^opencode\//);
		expect(seen.get("x-opencode-client")).toBe("cli");
		for (const name of ["x-opencode-session", "x-opencode-session-id", "x-session-affinity", "x-session-id"]) {
			expect(seen.get(name)).toMatch(/^ses_[0-9a-f]{12}[0-9A-Za-z]{14}$/);
		}
		expect(seen.has("x-opencode-project")).toBe(true);
	});

	it("preserves an existing opencode user agent", async () => {
		const {calls, orig} = recorder();
		const {patched} = createZenFetch(orig);
		await patched(ZEN_CHAT, {method: "POST", headers: {"user-agent": "opencode/9.9.9"}, body: FREE_BODY});
		expect(new Headers(calls[0].init?.headers).get("user-agent")).toBe("opencode/9.9.9");
	});

	it("forces stream:true and injects missing core tools, dropping stale content-length", async () => {
		const {calls, orig} = recorder();
		const {patched} = createZenFetch(orig);
		await patched(ZEN_CHAT, {method: "POST", headers: {"content-length": "37"}, body: FREE_BODY});
		const body = JSON.parse(calls[0].init!.body as string);
		expect(body.stream).toBe(true);
		expect(body.messages[0].role).toBe("system");
		expect(body.messages[0].content).toContain("<env>");
		expect((body.tools as {function: {name: string}}[]).map(t => t.function.name)).toEqual(["bash", "read"]);
		expect(new Headers(calls[0].init!.headers).has("content-length")).toBe(false);
	});

	it("injects Responses-shaped stubs on the /responses endpoint", async () => {
		const {calls, orig} = recorder();
		const {patched} = createZenFetch(orig);
		await patched("https://opencode.ai/zen/v1/responses", {
			method: "POST",
			body: JSON.stringify({model: "muse-spark-1.3-contributor-free", input: []}),
		});
		const tools = JSON.parse(calls[0].init!.body as string).tools;
		expect(tools.map((t: {type: string; name: string}) => [t.type, t.name])).toEqual([
			["function", "bash"],
			["function", "read"],
		]);
		expect(tools[0].function).toBeUndefined();
	});

	it("rewrites a free request passed as a Request object", async () => {
		const {calls, orig} = recorder();
		const {patched} = createZenFetch(orig);
		await patched(new Request(ZEN_CHAT, {method: "POST", body: FREE_BODY, headers: {"x-extra": "1"}}));
		const {init} = calls[0];
		expect(init?.method).toBe("POST");
		expect(new Headers(init?.headers).get("x-extra")).toBe("1");
		expect(new Headers(init?.headers).get("x-opencode-client")).toBe("cli");
		expect(JSON.parse(init!.body as string).stream).toBe(true);
	});

	it("retries once with a fresh session on 403", async () => {
		const {calls, orig} = recorder(n => new Response("{}", {status: n === 1 ? 403 : 200}));
		const {patched} = createZenFetch(orig);
		const response = await patched(ZEN_CHAT, {method: "POST", body: FREE_BODY});
		expect(response.status).toBe(200);
		const sessions = calls.map(c => new Headers(c.init?.headers).get("x-opencode-session-id"));
		expect(sessions).toHaveLength(2);
		expect(sessions[0]).not.toBe(sessions[1]);
	});

	it("passes 429 through without retrying", async () => {
		const {calls, orig} = recorder(() => new Response("{}", {status: 429}));
		const {patched} = createZenFetch(orig);
		expect((await patched(ZEN_CHAT, {method: "POST", body: FREE_BODY})).status).toBe(429);
		expect(calls).toHaveLength(1);
	});

	it("propagates network errors without replaying the request", async () => {
		let calls = 0;
		const orig = (async () => {
			calls++;
			throw new TypeError("ECONNRESET");
		}) as unknown as typeof fetch;
		const {patched} = createZenFetch(orig);
		await expect(patched(ZEN_CHAT, {method: "POST", body: FREE_BODY})).rejects.toThrow("ECONNRESET");
		expect(calls).toBe(1);
	});

	it("sends a request it cannot parse unmodified", async () => {
		const {calls, orig} = recorder();
		const {patched} = createZenFetch(orig);
		const init = {method: "POST", body: "{not json"};
		await patched(ZEN_CHAT, init);
		expect(calls[0].init).toBe(init);
	});

	it("restore() rotates the session id for the next request", async () => {
		const {calls, orig} = recorder();
		const handle = createZenFetch(orig);
		await handle.patched(ZEN_CHAT, {method: "POST", body: FREE_BODY});
		handle.restore();
		await handle.patched(ZEN_CHAT, {method: "POST", body: FREE_BODY});
		const [first, second] = calls.map(c => new Headers(c.init?.headers).get("x-opencode-session-id"));
		expect(second).not.toBe(first);
	});
});
