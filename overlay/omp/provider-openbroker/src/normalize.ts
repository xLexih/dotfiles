/**
 * OpenBroker forwards OpenAI-compatible requests to strict devshard schemas. The
 * MiniMax route requires every assistant and tool `content` to be a non-empty
 * array of non-empty `{name,type,text}` parts. Only MiniMax requests are routed
 * here (gated in index.ts); other models keep standard OpenAI content shapes.
 */

type ContentPart = {type: "text"; text: string; name: string};
// OpenBroker trims whitespace before validating text, so a newline is still empty.
// This content accompanies tool calls or otherwise-empty history entries and is not
// shown as a user-facing answer by OMP.
const EMPTY_CONTENT_PLACEHOLDER = "[empty]";

function nonEmptyText(value: unknown): string {
  return typeof value === "string" && value.length > 0 ? value : EMPTY_CONTENT_PLACEHOLDER;
}

function contentName(message: Record<string, unknown>): string {
  return typeof message.name === "string" && message.name.trim()
    ? message.name
    : message.role === "tool" ? "tool" : "assistant";
}

function normalizePart(value: unknown, name: string): ContentPart {
  const part = value && typeof value === "object" && !Array.isArray(value) ? value as Record<string, unknown> : {};
  return {
    type: "text",
    text: nonEmptyText(part.text),
    name: typeof part.name === "string" && part.name.trim() ? part.name : name,
  };
}

export function normalizeAssistantContent(payload: unknown): unknown {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) return payload;
  const record = payload as Record<string, unknown>;
  if (!Array.isArray(record.messages)) return payload;
  for (const message of record.messages) {
    if (!message || typeof message !== "object") continue;
    const msg = message as Record<string, unknown>;
    if (msg.role !== "assistant" && msg.role !== "tool") continue;
    const name = contentName(msg);
    msg.content = Array.isArray(msg.content)
      ? (msg.content.length ? msg.content : [{}]).map(part => normalizePart(part, name))
      : [{type: "text", text: nonEmptyText(msg.content), name}];
  }
  return payload;
}
