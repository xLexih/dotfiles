import {describe, expect, it} from "bun:test";
import {normalizeAssistantContent} from "../src/normalize.ts";

describe("normalizeAssistantContent", () => {
  it("rewrites an empty-string assistant content into a MiniMax-valid text-part array", () => {
    const payload = {
      model: "MiniMaxAI/MiniMax-M2.7",
      messages: [
        {role: "user", content: [{type: "text", text: "list files"}]},
        {role: "assistant", content: "", tool_calls: [{id: "call_1", type: "function", function: {name: "read", arguments: "{}"}}]},
        {role: "tool", tool_call_id: "call_1", content: "a.txt"},
      ],
    };
    normalizeAssistantContent(payload);
    const assistant = payload.messages[1];
    expect(assistant?.content).toEqual([{type: "text", text: "[empty]", name: "assistant"}]);
    expect(assistant?.tool_calls).toBeDefined();
  });

  it("rewrites null and blank assistant content too", () => {
    const payload = {
      messages: [
        {role: "assistant", content: null, tool_calls: []},
        {role: "assistant", content: "   ", tool_calls: []},
      ],
    };
    normalizeAssistantContent(payload);
    expect(payload.messages[0]?.content).toEqual([{type: "text", text: "[empty]", name: "assistant"}]);
    expect(payload.messages[1]?.content).toEqual([{type: "text", text: "   ", name: "assistant"}]);
  });

  it("wraps strings and repairs malformed assistant parts", () => {
    const payload = {
      messages: [
        {role: "assistant", content: "real answer"},
        {role: "assistant", content: [{type: "text", text: "x", name: "a"}, {type: "text", text: "", name: ""}]},
        {role: "user", content: "hello"},
      ],
    };
    normalizeAssistantContent(payload);
    expect(payload.messages[0]?.content).toEqual([{type: "text", text: "real answer", name: "assistant"}]);
    expect(payload.messages[1]?.content).toEqual([{type: "text", text: "x", name: "a"}, {type: "text", text: "[empty]", name: "assistant"}]);
    expect(payload.messages[2]?.content).toBe("hello");
  });

  it("wraps tool-result strings too", () => {
    const payload = {messages: [{role: "tool", content: "file contents"}]};
    normalizeAssistantContent(payload);
    expect(payload.messages[0]?.content).toEqual([{type: "text", text: "file contents", name: "tool"}]);
  });

  it("uses the tool's name when a tool result provides one", () => {
    const payload = {messages: [{role: "tool", name: "exec_command", content: []}]};
    normalizeAssistantContent(payload);
    expect(payload.messages[0]?.content).toEqual([{type: "text", text: "[empty]", name: "exec_command"}]);
  });

  it("ignores non-payload or missing-messages input", () => {
    expect(normalizeAssistantContent(null)).toBeNull();
    expect(normalizeAssistantContent({no: "messages"})).toEqual({no: "messages"});
  });
});
