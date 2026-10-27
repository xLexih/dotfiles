import {describe, expect, it} from "bun:test";
import {envBlock, forceStream, injectEnv, injectZenTools, mintSessionId, type ZenEnv} from "../src/zen.ts";

describe("session id minting", () => {
	it("matches opencode's ses_ shape: 6 hex bytes + 14 base62 chars", () => {
		const id = mintSessionId(1_760_000_000_000, 1);
		expect(id).toMatch(/^ses_[0-9a-f]{12}[0-9A-Za-z]{14}$/);
	});

	it("derives the hex prefix from time and counter only", () => {
		expect(mintSessionId(1_760_000_000_000, 1).slice(0, 16)).toBe(
			mintSessionId(1_760_000_000_000, 1).slice(0, 16),
		);
		expect(mintSessionId(1_760_000_000_000, 1).slice(0, 16)).not.toBe(
			mintSessionId(1_760_000_000_000, 2).slice(0, 16),
		);
	});

	it("mints distinct ids across calls (fresh random tails)", () => {
		expect(mintSessionId()).not.toBe(mintSessionId());
	});
});

describe("tool stub injection", () => {
	const stub = (name: string) => ({
		type: "function",
		function: {name, description: expect.any(String), parameters: expect.anything()},
	});

	it("injects bash and read when no tools present", () => {
		const body = JSON.stringify({model: "m", messages: []});
		const r = injectZenTools(body);
		expect(r.injected.sort()).toEqual(["bash", "read"]);
		const tools = JSON.parse(r.text).tools as {function: {name: string}}[];
		expect(tools.map(t => t.function.name)).toEqual(["bash", "read"]);
	});

	it("tops up to two core tools when one is present", () => {
		const body = JSON.stringify({
			messages: [],
			tools: [{type: "function", function: {name: "bash", parameters: {}}}],
		});
		const tools = injectZenTools(body);
		expect(tools.injected).toEqual(["read"]);
		expect(tools.present).toBe(1);
	});

	it("leaves requests with both core tools untouched", () => {
		const body = JSON.stringify({
			messages: [],
			tools: [
				{type: "function", function: {name: "bash", parameters: {}}},
				{type: "function", function: {name: "read", parameters: {}}},
			],
		});
		const result = injectZenTools(body);
		expect(result.text).toBe(body);
		expect(result.injected).toEqual([]);
	});

	it("counts responses-style entries (name at top level)", () => {
		const body = JSON.stringify({messages: [], tools: [{name: "bash"}, {name: "other"}]});
		const result = injectZenTools(body);
		expect(result.present).toBe(1);
		expect(result.injected).toEqual(["read"]);
	});

	it("uses the anthropic messages tool shape when asked", () => {
		const result = injectZenTools(JSON.stringify({model: "m", messages: []}), "anthropic");
		const tools = JSON.parse(result.text).tools as {name: string; input_schema: unknown; type?: string}[];
		expect(tools.map(t => t.name)).toEqual(["bash", "read"]);
		expect(tools.every(t => t.input_schema !== undefined && t.type === undefined)).toBe(true);
	});

	it("refuses to inject when tool_choice forces tool use", () => {
		for (const choice of ["required", "any", {type: "required"}]) {
			const body = JSON.stringify({messages: [], tool_choice: choice});
			const result = injectZenTools(body);
			expect(result.text).toBe(body);
			expect(result.injected).toEqual([]);
		}
	});

	it("returns malformed JSON untouched", () => {
		expect(injectZenTools("not json").text).toBe("not json");
		expect(injectZenTools("[1,2]").text).toBe("[1,2]");
	});
});

describe("forceStream", () => {
	it("adds stream:true to a non-streaming body", () => {
		const out = forceStream(JSON.stringify({model: "m", messages: []}));
		expect(JSON.parse(out!)).toEqual({model: "m", messages: [], stream: true});
	});

	it("returns null when the body already streams", () => {
		expect(forceStream(JSON.stringify({stream: true}))).toBeNull();
	});

	it("returns null for malformed or non-object JSON", () => {
		expect(forceStream("not json")).toBeNull();
		expect(forceStream("[1,2]")).toBeNull();
	});
});

describe("env block injection", () => {
	const env: ZenEnv = {
		workingDirectory: "/work",
		workspaceRoot: "/work",
		isGitRepo: true,
		platform: "linux",
		date: "Mon Oct 26 2026",
	};
	const block = `<env>
  Working directory: /work
  Workspace root folder: /work
  Is directory a git repo: yes
  Platform: linux
  Today's date: Mon Oct 26 2026
</env>`;

	it("renders the exact block the gateway expects", () => {
		expect(envBlock(env)).toBe(block);
	});

	it("prepends the block to a string system message", () => {
		const body = JSON.stringify({
			model: "m",
			messages: [{role: "system", content: "hello"}, {role: "user", content: "hi"}],
		});
		const doc = JSON.parse(injectEnv(body, env));
		expect(doc.messages[0].content).toBe(`${block}\n\nhello`);
		expect(doc.messages[1].content).toBe("hi");
	});

	it("does not duplicate an existing env block", () => {
		const body = JSON.stringify({messages: [{role: "system", content: block}]});
		expect(injectEnv(body, env)).toBe(body);
	});

	it("adds a system message when the body has none", () => {
		const body = JSON.stringify({messages: [{role: "user", content: "hi"}]});
		const doc = JSON.parse(injectEnv(body, env));
		expect(doc.messages[0]).toEqual({role: "system", content: block});
		expect(doc.messages[1].content).toBe("hi");
	});

	it("prepends a text part to array system content", () => {
		const body = JSON.stringify({
			messages: [{role: "system", content: [{type: "text", text: "hello"}]}],
		});
		const doc = JSON.parse(injectEnv(body, env));
		expect(doc.messages[0].content[0]).toEqual({type: "text", text: block});
		expect(doc.messages[0].content[1].text).toBe("hello");
	});

	it("leaves malformed or non-object bodies untouched", () => {
		expect(injectEnv("not json", env)).toBe("not json");
		expect(injectEnv("[1,2]", env)).toBe("[1,2]");
	});
});
