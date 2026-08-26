import {describe, expect, it} from "bun:test";
import {DurationTracker, formatDuration, formatStatus} from "../src/timer.ts";

describe("duration tracker", () => {
  it("tracks each model call independently and the entire prompt", () => {
    const tracker = new DurationTracker();
    tracker.startPrompt(1_000);
    tracker.startCall(2_000);
    expect(tracker.snapshot(5_000)).toEqual({active: true, taskMs: 3_000, totalMs: 4_000});
    tracker.finishCall(7_000);
    tracker.startCall(10_000);
    expect(tracker.snapshot(12_000)).toEqual({active: true, taskMs: 2_000, totalMs: 11_000});
    tracker.finishPrompt(16_000);
    expect(tracker.snapshot(99_000)).toEqual({active: false, taskMs: 6_000, totalMs: 15_000});
  });

  it("starts safely when a provider call arrives without prompt hooks", () => {
    const tracker = new DurationTracker();
    tracker.startCall(5_000);
    tracker.finishPrompt(8_000);
    expect(tracker.snapshot(10_000)).toEqual({active: false, taskMs: 3_000, totalMs: 3_000});
  });

  it("formats active and completed durations for the status bar", () => {
    expect(formatDuration(65_999)).toBe("1:05");
    expect(formatDuration(3_661_000)).toBe("1:01:01");
    expect(formatStatus({active: true, taskMs: 12_000, totalMs: 82_000})).toBe("Total 1:22 · Task 0:12");
    expect(formatStatus({active: false})).toBeUndefined();
  });
});
