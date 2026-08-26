import type {ExtensionContext, ExtensionFactory} from "@oh-my-pi/pi-coding-agent";
import {DurationTracker, formatStatus} from "./timer.ts";

const STATUS_KEY = "time-manager";
const UPDATE_INTERVAL_MS = 1_000;

export function createTimeManager(now: () => number = Date.now): ExtensionFactory {
  return pi => {
    const tracker = new DurationTracker();
    let sessionContext: ExtensionContext | undefined;
    let ui: ExtensionContext["ui"] | undefined;
    let agentRunning = false;

    const render = (): void => ui?.setStatus(STATUS_KEY, formatStatus(tracker.snapshot(now())));
    const finish = (): void => {
      tracker.finishPrompt(now());
      agentRunning = false;
      render();
    };
    const renderTick = (): void => {
      const current = now();
      if (agentRunning && sessionContext?.isIdle()) {
        tracker.finishPrompt(current);
        agentRunning = false;
      }
      ui?.setStatus(STATUS_KEY, formatStatus(tracker.snapshot(current)));
    };

    pi.on("session_start", (_event, context) => {
      sessionContext = context;
      ui = context.ui;
      context.setInterval(renderTick, UPDATE_INTERVAL_MS);
    });
    pi.on("before_agent_start", () => {
      tracker.startPrompt(now());
      render();
    });
    pi.on("agent_start", () => {
      agentRunning = true;
      tracker.ensurePrompt(now());
      render();
    });
    pi.on("before_provider_request", () => {
      tracker.startCall(now());
      render();
    });
    pi.on("message_end", event => {
      if (event.message.role !== "assistant") return;
      if (event.message.stopReason === "aborted") return finish();
      tracker.finishCall(now());
      render();
    });
    pi.on("turn_end", () => {
      tracker.finishCall(now());
      render();
    });
    pi.on("agent_end", event => {
      if (!event.willContinue) finish();
    });
    pi.on("session_shutdown", () => ui?.setStatus(STATUS_KEY, undefined));
  };
}

export default createTimeManager();
