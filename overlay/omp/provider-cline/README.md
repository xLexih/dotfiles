# OMP Cline provider

This extension adds [Cline](https://app.cline.bot), the AI coding tool's
public OpenAI-compatible API, as a provider for Oh My Pi. Cline exposes
425+ models through `https://api.cline.bot/api/v1`; this provider curates
the free `:free` tier that survived live probes on 2026-09-02.

| Field | Value |
|---|---|
| Provider ID | `cline` |
| Base URL | `https://api.cline.bot/api/v1` |
| Authentication | `Authorization: Bearer sk_…` |
| Login | `/login cline` |
| Environment | `CLINE_API_KEY` |

## Models

Live status verified 2026-09-03 (all tested with the user's own Cline key
against `https://api.cline.bot/api/v1/chat/completions`):

| Status | Model ID | Context | Max output | Hint |
|---|---|---:|---:|---|
| ✅ | `minimax/minimax-m3:free` | 1,000,000 | 65,536 | preferred |
| ✅ | `nvidia/nemotron-3-super-120b-a12b:free` | 1,000,000 | 32,768 | preferred |
| ✅ | `nvidia/nemotron-3-ultra-550b-a55b:free` | 1,048,576 | 16,384 | acceptable |
| ✅ | `nvidia/nemotron-3.5-lightning:free` | 1,048,576 | 16,384 | acceptable |
| ✅ | `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free` | 262,144 | 16,384 | acceptable |
| ✅ | `google/gemma-4-31b-it:free` | 32,000 | 8,192 | acceptable |
| ✅ | `google/gemma-4-26b-a4b-it:free` | 32,000 | 8,192 | acceptable |
| ⚠️ | `z-ai/glm-5.2:free` | 1,048,576 | 16,384 | avoid (Decart 429) |
| ⚠️ | `minimax/minimax-m2.7:free` | 204,800 | 16,384 | acceptable (intermittent) |
| ⚠️ | `cohere/north-mini-code:free` | 128,000 | 8,192 | acceptable (intermittent) |

### `z-ai/glm-5.2:free` is currently rate-limited upstream

Cline/OpenRouter returns HTTP 429 for this model id with:

```json
{
  "provider_name": "Decart",
  "is_byok": false,
  "provider_error_code": "upstream_429",
  "limit_source": "upstream_provider_shared_pool",
  "remedy_hint": "Retry shortly, add your own provider key (https://openrouter.ai/settings/integrations), or route to another provider with provider routing: https://openrouter.ai/docs/features/provider-routing"
}
```

Decart is throttling Cline's shared free pool for this model. The Cline
recommendation is an OpenRouter BYOK key — see the link above. Without
it, the public bucket stays throttled. Marked `hint: "avoid"` in the
curated catalog so OMP doesn't surface it as a primary suggestion, but
kept in the list so it re-appears when Decart restores capacity.

Context windows come from the upstream model card (Z.AI's Hugging Face
configs, NVIDIA's NIM model cards, MiniMax's hosted API docs). Output
caps are conservative verbosity brakes on the free tier — m3 gets a larger
65k cap because it's the flagship and a coding agent benefits from longer
completions on free quota.

Models that returned `empty response content` or are too small / guardrail-only
were excluded from the curated list (`inclusionai/ling-3.0-flash-fin:free`,
`thinkingmachines/inkling*`, `nvidia/nemotron-3.5-content-safety:free`,
`poolside/laguna*`, `liquid/lfm-2.5-2.6b:free`,
`dots-studio/dots-3-note-preview:free`).

## Request compatibility

Cline is an OpenRouter-shaped proxy. Live probes on 2026-09-02 confirmed:

- `choices[0].message.reasoning` (string) is the reasoning field, not
  `reasoning_content`.
- `choices[0].message.reasoning_details` may also be present as an array;
  OMP's `openai-completions` handler reads the flat string and drops the
  array.
- `choices[0].native_finish_reason` is alongside the OpenAI `finish_reason`.
- Standard `tool_calls` envelope; `m3:free` returned
  `finish_reason: "tool_calls"` on a calculator prompt.
- Standard `content: string | null`; `m2.7:free` returned reasoning +
  `content: "OK"`.

The compat policy branches on model family:
- `minimax/*` — MiniMax-style: always-on thinking, `max_tokens` required,
  `reasoning_effort` rejected.
- `kimi/*` — same exemption.
- `nemotron/*` — accepts `reasoning_effort`; long prefill exempt from
  first-event watchdog.
- `z-ai/glm*` — accepts `reasoning_effort`; long prefill exempt.
- `gemma/*`, `cohere/*` — plain instruct, no reasoning controls.

## Why dynamic discovery

Cline's `/v1/models` returns a standard OpenAI payload with no per-model
context/output metadata, so we use the live id list and intersect it with
the curated descriptors. The boot-time `models` field is the *fallback*;
once `fetchDynamicModels` succeeds, OMP replaces it with the live
intersection.
