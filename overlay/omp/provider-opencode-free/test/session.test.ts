import {describe, expect, it} from "bun:test";
import {isFreeChatModel, isZenInferenceRequest, toZenSessionId, ZEN_SESSION_HEADER, ZEN_SESSION_PATTERN, ZEN_USER_AGENT} from "../src/session.ts";

describe("toZenSessionId", () => {
	it("emits opencode-shaped ses_ ids (12 hex + 14 base62, 26 chars)", () => {
		expect(toZenSessionId("conversation-123")).toMatch(ZEN_SESSION_PATTERN);
		// The user's real opencode client id matches the same shape.
		expect("ses_f36bdb647ffeCD6SkW3nr4RoBL").toMatch(ZEN_SESSION_PATTERN);
	});

	it("is deterministic per OMP conversation (cache affinity across restarts)", () => {
		expect(toZenSessionId("conversation-123")).toBe(toZenSessionId("conversation-123"));
	});

	it("isolates conversations (distinct OMP ids map to distinct Zen sessions)", () => {
		expect(toZenSessionId("conversation-123")).not.toBe(toZenSessionId("conversation-456"));
	});
});

describe("isFreeChatModel", () => {
	const chat = (id: string, extra = {}) => ({provider: "opencode-zen", id, api: "openai-completions", ...extra});

	it("passes big-pickle and -free chat ids", () => {
		expect(isFreeChatModel(chat("big-pickle"))).toBe(true);
		expect(isFreeChatModel(chat("mimo-v2.6-flash-free"))).toBe(true);
		expect(isFreeChatModel(chat("muse-spark-1.3-contributor-free", {api: "openai-responses"}))).toBe(true);
	});

	it("excludes paid models and other providers", () => {
		expect(isFreeChatModel(chat("gpt-5.5"))).toBe(false);
		expect(isFreeChatModel({provider: "opencode-free", id: "big-pickle", api: "openai-completions"})).toBe(false);
	});

	it("excludes the judge (jev-*) and SystemOne families", () => {
		expect(isFreeChatModel(chat("jev-1.13-free"))).toBe(false);
		expect(isFreeChatModel(chat("system-one-free"))).toBe(false);
		expect(isFreeChatModel(chat("systemone-2.1-free"))).toBe(false);
	});

	it("excludes non-chat kinds and judgment APIs", () => {
		expect(isFreeChatModel(chat("mimo-v2.6-flash-free", {kind: "image"}))).toBe(false);
		expect(isFreeChatModel(chat("mimo-v2.6-flash-free", {kind: "chat"}))).toBe(true);
		expect(isFreeChatModel(chat("mimo-v2.6-flash-free", {api: "typesafe"}))).toBe(false);
	});
});

describe("isZenInferenceRequest", () => {
	it("matches every Zen inference family", () => {
		for (const path of [
			"/zen/v1/chat/completions",
			"/zen/v1/responses",
			"/zen/v1/messages",
			"/zen/v1/systemone",
			"/zen/v1/models/gemini-3:streamGenerateContent",
			"/zen/v1/models/gemini-3:generateContent",
		]) {
			expect(isZenInferenceRequest(`https://opencode.ai${path}`)).toBe(true);
		}
	});

	it("leaves discovery, other hosts, and garbage untouched", () => {
		expect(isZenInferenceRequest("https://opencode.ai/zen/v1/models")).toBe(false);
		expect(isZenInferenceRequest("https://openrouter.ai/api/v1/chat/completions")).toBe(false);
		expect(isZenInferenceRequest("not a url")).toBe(false);
	});
});

describe("client identity constants", () => {
	it("uses the documented session header and an opencode/* UA", () => {
		expect(ZEN_SESSION_HEADER).toBe("x-opencode-session");
		expect(ZEN_USER_AGENT).toMatch(/^opencode\//);
	});
});
