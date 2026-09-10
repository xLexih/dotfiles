import {describe, expect, it} from "bun:test";
// Loading the top-level module exercises every import. If `index.ts`
// references an undefined identifier (a missing import, a typo, etc.) the
// load itself throws — exactly the regression this catches.
import glmProvider from "../src/index.ts";

describe("omp-provider-glm top-level module", () => {
	it("exports a default factory function", () => {
		expect(typeof glmProvider).toBe("function");
	});
});
