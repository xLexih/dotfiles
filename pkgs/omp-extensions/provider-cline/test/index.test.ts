import {describe, expect, it} from "bun:test";
import clineProvider from "../src/index.ts";

describe("omp-provider-cline top-level module", () => {
	it("exports a default factory function", () => {
		expect(typeof clineProvider).toBe("function");
	});
});
