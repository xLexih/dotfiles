import {describe, expect, it} from "bun:test";
import opencodeZenProvider from "../src/index.ts";

describe("omp-provider-opencode-zen top-level module", () => {
	it("exports a default factory function", () => {
		expect(typeof opencodeZenProvider).toBe("function");
	});
});
