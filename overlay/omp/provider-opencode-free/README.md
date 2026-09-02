# OMP OpenCode Free provider

This extension adds [OpenCode Zen's free models](https://opencode.ai/docs/zen/)
as a provider for Oh My Pi behind a single login.

| Field | Value |
|---|---|
| Provider ID | `opencode-free` |
| Base URL | `https://opencode.ai/zen/v1` |
| Authentication | `Authorization: Bearer <zen-key>` |
| Login | `/login opencode-free` (key from https://opencode.ai/auth) |
| Environment | `OPENCODE_ZEN_API_KEY` |

## Models

Zen serves free models behind **two** endpoint families on the same host.
This provider registers one `opencode-free` id and dispatches per model, so
`/login opencode-free` unlocks all of them:

| Model ID | Name | Endpoint | Context | Max output |
|---|---|---|---:|---:|
| `muse-spark-1.3-contributor-free` | Muse Spark 1.3 Contributor Free | `/responses` | 1,048,576 | 32,768 |
| `muse-spark-1.2-contributor-free` | Muse Spark 1.2 Contributor Free | `/responses` | 1,048,576 | 32,768 |
| `mimo-v2.5-free` | MiMo V2.5 Free | `/chat/completions` | 1,000,000 | 16,384 |
| `ling-3.0-flash-fin-free` | Ling 3.0 Flash Fin Free | `/chat/completions` | 262,144 | 16,384 |
| `nemotron-3-ultra-free` | Nemotron 3 Ultra Free | `/chat/completions` | 1,048,576 | 16,384 |
| `nemotron-3.5-lightning-free` | Nemotron 3.5 Lightning Free | `/chat/completions` | 1,048,576 | 16,384 |
| `deepseek-v4-flash-free` | DeepSeek V4 Flash Free | `/chat/completions` | 128,000 | 8,192 |
| `big-pickle` | Big Pickle | `/chat/completions` | 128,000 | 8,192 |

All entries are zero-cost. Context windows come from upstream model cards
(Meta, Xiaomi, InclusionAI/HF, NVIDIA family); `deepseek-v4-flash-free` and
`big-pickle` are conservative 128k defaults (marked `UNCONFIRMED` in
`src/catalog.ts`) because neither has a public card. The 16,384/8,192 output
caps are verbosity brakes, mirroring
`overlay/omp/provider-openbroker/src/catalog.ts:32-33`.

`laguna-s-2.1-free` is intentionally excluded: Poolside Laguna has no
tool-call support (same reason
`overlay/omp/provider-cline/src/catalog.ts` skips `poolside/laguna*`), so an
OMP coding agent cannot drive it.

## Why the 500s on Muse Spark (and how this fixes them)

`muse-spark-*-contributor-free` is Responses-only
(`https://opencode.ai/zen/v1/responses`, `@ai-sdk/openai`). Driving it with a
Chat Completions request shape (`/chat/completions`) makes the Zen gateway
return 500. This provider dispatches by curated model id: Spark ids go
through pi-ai's `streamOpenAIResponses`, everything else through
`streamOpenAICompletions`, both against the shared base URL
`https://opencode.ai/zen/v1`.

## Request compatibility

Plain OpenAI surface on both families — standard `tools`/`tool_calls`,
standard `content: string | null`, no DSML/inband envelopes, no forced
reasoning replay. The reasoning field is the OpenAI-standard `reasoning`.
The compat policy mirrors TokenRouter's
(`overlay/omp/provider-tokenrouter/src/compat.ts`), with one Responses-only
difference: `includeEncryptedReasoning` is off, because pi-ai's
endpoint-constraints doc warns third-party `/v1/responses` proxies may
reject encrypted-reasoning replay (stateless `store: false` likewise keeps
`previous_response_id` chaining off). A 5-minute inter-event watchdog with
no first-event watchdog accommodates long silent reasoning prefill on the
free tier.

## Why dynamic discovery, not a static catalog

The static table above is the *fallback*. The primary path is
`fetchDynamicModels`, which asks Zen for the live model list (`GET
/zen/v1/models`, public) and intersects it with the curated descriptors, so
retired free models drop out and new `-free` ids become one-descriptor-row
additions in `src/catalog.ts`. Note `GET /v1/models` is public, so login
validation only proves reachability — a wrong key surfaces on first
inference.

## Privacy

Free/contributor models may train on your traffic: Meta's contributor tier
uses prompts/completions to train future models
(https://dev.meta.ai/docs/pricing-rate-limits#contributor-tier), and Zen
marks Big Pickle / MiMo / Ling / Nemotron free endpoints as data-collecting
during their free periods (https://opencode.ai/docs/zen/#privacy).
