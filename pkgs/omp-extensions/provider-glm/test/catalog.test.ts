import {describe, expect, it} from "bun:test";
import {buildGlmBridgeModel, getGlmBridgeDescriptor, parseGlmBridgeModels, staticGlmBridgeModels, GLM_BRIDGE_MODELS} from "../src/catalog.ts";

const BASE = "http://127.0.0.1:3001/v1";

describe("glm bridge catalog", () => {
	it("registers the bridge's documented model ids", () => {
		const ids = GLM_BRIDGE_MODELS.map(d => d.id);
		for (const id of ["x-preview-l", "glm-5.3", "glm-5.2", "GLM-5.1", "GLM-5-Turbo", "GLM-5v-Turbo", "glm-4.7", "glm-5"]) {
			expect(ids).toContain(id);
		}
	});

	it("marks only the vision model as image-capable", () => {
		for (const d of GLM_BRIDGE_MODELS) {
			if (d.id === "GLM-5v-Turbo") expect(d.input).toContain("image");
			else expect(d.input).not.toContain("image");
		}
	});

	it("builds registry entries against the resolved base URL", () => {
		const m = buildGlmBridgeModel(getGlmBridgeDescriptor("glm-4.7")!, "https://glm.example.com/v1");
		expect(m.provider).toBe("glm-local");
		expect(m.baseUrl).toBe("https://glm.example.com/v1");
		expect(m.api).toBe("openai-completions");
	});

	it("parses a live /v1/models payload, keeping known ids and admitting new ones", () => {
		const models = parseGlmBridgeModels(
			{data: [{id: "glm-4.7"}, {id: "glm-5.4", architecture: {input_modalities: ["text", "image"]}}, {id: "glm-4.7"}]},
			BASE,
		);
		expect(models.map(m => m.id)).toEqual(["glm-4.7", "glm-5.4"]);
		const fresh = models.find(m => m.id === "glm-5.4")!;
		expect(fresh.input).toContain("image");
		// Known ids keep descriptor metadata, not the raw payload.
		expect(models.find(m => m.id === "glm-4.7")!.contextWindow).toBe(131_072);
	});

	it("rejects malformed payloads without throwing", () => {
		expect(parseGlmBridgeModels(null, BASE)).toEqual([]);
		expect(parseGlmBridgeModels({}, BASE)).toEqual([]);
		expect(parseGlmBridgeModels({data: [{nope: 1}]}, BASE)).toEqual([]);
	});

	it("static fallback covers every curated id", () => {
		expect(staticGlmBridgeModels(BASE).map(m => m.id).sort()).toEqual(
			GLM_BRIDGE_MODELS.map(d => d.id).sort(),
		);
	});
});
