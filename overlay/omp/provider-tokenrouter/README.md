# OMP TokenRouter provider

This extension adds [TokenRouter](https://www.tokenrouter.com), an OpenAI-compatible
multi-model gateway, as a provider for Oh My Pi.

| Field | Value |
|---|---|
| Provider ID | `tokenrouter` |
| Base URL | `https://api.tokenrouter.com/v1` |
| Authentication | `Authorization: Bearer tr_…` (or `sk_…` if your key uses the legacy prefix) |
| Login | `/login tokenrouter` |
| Environment | `TOKENROUTER_API_KEY` |

## Models

TokenRouter exposes 130+ models, but only two are registered here — both
GLM-5.3 variants — because TokenRouter's per-model context/output metadata is
not published for free routes and the curated entries below use the upstream
Z.AI model card (1,048,576-token architectural max). The OMP registry reads
the static catalog at boot and refreshes it from `GET /v1/models` after
`/login`, intersecting the live list with the curated descriptors so retired
or renamed models are dropped.

| Model ID | Name | Context | Max output | Cost (USD/1M) |
|---|---|---:|---:|---|
| `z-ai/glm-5.3-free` | GLM 5.3 Free | 1,048,576 | 16,384 | 0 / 0 |
| `z-ai/glm-5.3-flash` | GLM 5.3 Flash | 1,048,576 | 16,384 | 0.075 / 0.250 |

The `glm-5.3-free` route is upstream GLM-5.3 served through TokenRouter's
free tier, which is currently free of charge through 2026-09-04. After that
date the route may switch to standard pricing; the model id stays the same.

Both routes use the same architectural limits because they serve the same
upstream weights. The 16,384-token `maxTokens` cap is a verbosity brake:
GLM-5.3 can self-correct into 12k-character rambles on free/cheap tiers, and
the cap mirrors the same rationale used in
`overlay/omp/provider-openbroker/src/catalog.ts:32-33` for OpenBroker's
DeepSeek.

## Request compatibility

`/v1/chat/completions` is a clean OpenAI surface — standard `messages`,
`tools`, `tool_calls`, and `tool_choice`; standard `content: string` or
`content: null`; standard `finish_reason: "stop" | "length" | "tool_calls"`.
The reasoning field is the OpenAI-standard `choices[].message.reasoning`
(verified against a live probe on 2026-09-02; not `reasoning_content`).
Reasoning effort is accepted as `low | high | max`.

The compat policy is the same as OpenBroker's Kimi branch
(`overlay/omp/provider-openbroker/src/compat.ts:34-39`): a 5-minute
inter-event idle watchdog and a disabled first-event watchdog, both to
accommodate the long silent prefill that GLM-5.3 occasionally produces on
its first reasoning turn.

## Why dynamic discovery, not a static catalog

The static catalog above is the *fallback* — used at registration time and
re-asserted if `GET /v1/models` fails. The primary path is `fetchDynamicModels`,
which asks TokenRouter for the live model list and intersects it with the
curated descriptor table. This way:

- retired models are dropped automatically,
- new GLM-5.3 point releases (e.g. `glm-5.3.1-free`) can be added by
  appending a single descriptor row in `src/catalog.ts` without touching
  any other code, and
- the per-model context/output/cost numbers stay grounded in upstream
  model cards rather than in TokenRouter's free-tier page.
