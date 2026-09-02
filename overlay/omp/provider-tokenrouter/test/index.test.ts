import {describe, expect, it} from "bun:test";
// Loading the top-level module exercises every import. If `index.ts`
// references an undefined identifier (a missing import, a typo, etc.) the
// load itself throws — exactly the regression this catches.
import tokenrouterProvider from "../src/index.ts";

describe("omp-provider-tokenrouter top-level module", () => {
	it("exports a default factory function", () => {
		expect(typeof tokenrouterProvider).toBe("function");
	});
});
