import {describe, expect, it} from "bun:test";
import {createTimeManager} from "../src/index.ts";

describe("time-manager extension lifecycle", () => {
  it("freezes task on assistant completion and total on OMP idle fallback", async () => {
    const handlers = new Map<string, (...args: never[]) => unknown>();
    const statuses: (string | undefined)[] = [];
    let tick = (): void => {};
    let idle = false;
    let now = 0;
    createTimeManager(() => now)({on: (event: string, handler: (...args: never[]) => unknown) => handlers.set(event, handler)} as never);
    const emit = async (event: string, value: unknown = {type: event}): Promise<void> => {
      await handlers.get(event)?.(value as never, {
        ui: {setStatus: (_key: string, text: string | undefined) => statuses.push(text)},
        isIdle: () => idle,
        setInterval: (callback: () => void) => { tick = callback; },
      } as never);
    };

    await emit("session_start");
    await emit("before_agent_start");
    await emit("agent_start");
    await emit("before_provider_request");
    now = 3_000;
    tick();
    expect(statuses.at(-1)).toBe("Total 0:03 · Task 0:03");

    await emit("message_end", {type: "message_end", message: {role: "assistant"}});
    now = 5_000;
    tick();
    expect(statuses.at(-1)).toBe("Total 0:05 · Task 0:03");

    idle = true;
    now = 6_000;
    tick();
    now = 9_000;
    tick();
    expect(statuses.at(-1)).toBe("Total 0:06 · Task 0:03");
  });

  it("freezes both timers immediately when the assistant request is cancelled", async () => {
    const handlers = new Map<string, (...args: never[]) => unknown>();
    const statuses: (string | undefined)[] = [];
    let tick = (): void => {};
    let now = 0;
    createTimeManager(() => now)({on: (event: string, handler: (...args: never[]) => unknown) => handlers.set(event, handler)} as never);
    const emit = async (event: string, value: unknown = {type: event}): Promise<void> => {
      await handlers.get(event)?.(value as never, {
        ui: {setStatus: (_key: string, text: string | undefined) => statuses.push(text)},
        isIdle: () => false,
        setInterval: (callback: () => void) => { tick = callback; },
      } as never);
    };

    await emit("session_start");
    await emit("before_agent_start");
    await emit("agent_start");
    await emit("before_provider_request");
    now = 8_000;
    await emit("message_end", {type: "message_end", message: {role: "assistant", stopReason: "aborted"}});
    expect(statuses.at(-1)).toBe("Total 0:08 · Task 0:08");

    now = 30_000;
    tick();
    expect(statuses.at(-1)).toBe("Total 0:08 · Task 0:08");
  });
});
