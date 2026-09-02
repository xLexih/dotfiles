# OMP OpenCode Zen free provider

This extension adds the free tier of [OpenCode Zen](https://opencode.ai/zen),
OpenCode's curated, agentic-coding model gateway, as a provider for Oh My Pi.
Zen exposes 66 models behind an OpenAI-compatible surface at
`https://opencode.ai/zen/v1`; this provider curates the `:free`-suffixed
roster that survived live probes on 2026-09-02 and exposes them as the
`opencode-free` provider id with no login required.

| Field | Value |
|---|---|
| Provider ID | `opencode-free` |
| Base URL | `https://opencode.ai/zen/v1` |
| Authentication | None required for the free models |
| Login | _(not needed — pick a model and chat)_ |
| Environment | `OPENCODE_API_KEY` (optional, currently unused) |

## Free models

| Model ID | Name | Context | Max output |
|---|---|---:|---:|
| `mimo-v2.5-free` | MiMo V2.5 Free | 32,000 | 8,192 |
| `muse-spark-1.3-contributor-free` | Muse Spark 1.3 Contributor Free | 200,000 | 8,192 |
| `muse-spark-1.2-contributor-free` | Muse Spark 1.2 Contributor Free | 200,000 | 8,192 |
| `nemotron-3-ultra-free` | Nemotron 3 Ultra Free | 1,048,576 | 16,384 |
| `nemotron-3.5-lightning-free` | Nemotron 3.5 Lightning Free | 1,048,576 | 16,384 |
| `ling-3.0-flash-fin-free` | Ling 3.0 Flash Fin Free | 32,000 | 8,192 |

`deepseek-v4-flash-free` was confirmed unavailable at probe time
(`{"error":{"type":"server_error","message":"Error from provider (Console): Upstream request failed: Model is unavailable."}}`)
and is dropped from the curated list. Re-add it by appending a row in
`src/catalog.ts` once Zen brings it back.

## No login required

The provider id is `opencode-free` and there is no `/login opencode-free`
flow. Zen's free models are anonymous-callable; a live probe against
`https://opencode.ai/zen/v1/chat-completions` on 2026-09-02 returned
`200 OK` with no `Authorization` header (`usage.prompt_tokens_details.cached_tokens: 192`
on the anonymous call). Just pick a model and chat.
## Request compatibility

Live probe on 2026-09-02 (`mimo-v2.5-free`):

- `choices[0].message.reasoning` is a string (not `reasoning_content`).
- `choices[0].message.content` is a plain string.
- `usage.prompt_tokens_details.cached_tokens` is accurate; anonymous
  callers get the full `cached_tokens: 192` budget.
- `finish_reason` is `"stop"`.

The compat policy branches on family:
- `nemotron-*` — same Kimi-style prefill exemption as OpenBroker.
- `mimo`, `muse` — standard OpenAI-compat; no `alwaysSendMaxTokens`.
- `ling-3.0-flash-fin-free` — plain instruct, no reasoning controls.
