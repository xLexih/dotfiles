# OMP Opencode Free provider

`opencode-free/<id>` in OMP: the free-only view over
[OpenCode Zen](https://opencode.ai/docs/zen/), found in the picker,
`/model`, and roles config. The native `opencode-zen` provider owns
routing/compat/credentials — this extension only adds the free-model list
plus the two client-identity signals Zen's free tier gates on:

| Signal | Value |
|---|---|
| `User-Agent` | `opencode/1.18.30` (any `opencode/*` passes the `429 FreeUsageLimitError` gate) |
| `x-opencode-session` | `ses_` + 26 chars in opencode's own format (12 hex + 14 base62, e.g. `ses_f36bdb647ffeCD6SkW3nr4RoBL`), sha256-derived per OMP conversation |

| Field | Value |
|---|---|
| Provider ID | `opencode-free` |
| Base URL | `https://opencode.ai/zen/v1` |
| Login | `/login opencode-zen` (key from https://opencode.ai/auth; streaming runs as the native entry) |
| Select | `/model opencode-free/<id>` |

## Dynamic models

`fetchDynamicModels` intersects the live `GET /zen/v1/models` id list
(public, no key needed) with the free-chat rule (`big-pickle`/`*-free`,
minus the `jev-*` judge family and SystemOne), so new free ids appear and
retired ones drop out with no change here — this already picked up
`mimo-v2.6-flash-free` (2026-09-22: 76 live models, 9 free chat ids). Known
ids carry exact upstream-card windows (`src/models.ts`); unknown ids get
conservative 128k/8k synthesized defaults. Thinking levels (`xhigh` et al.)
are merged per id from models.dev's `opencode` slice at discovery time
(`src/thinking.ts`, 24h TTL + ETag, never throws) as the runtime's
`thinking: {mode: "effort", efforts: [...]}` shape — the field OMP 18.0.8's
`/thinking` picker gates on (a `thinkingLevelMap`-only entry is stored
without `xhigh`). So new reasoning scales appear with no code change —
e.g. Muse Spark advertises `minimal`–`xhigh` there.
A curated-only static list covers fetch failures (without thinking levels).

## How it works

Each `opencode-free` entry dispatches through the provider's custom api into
`opencodeFreeStream`, which re-executes the request as the matching native
`opencode-zen` entry (same id, curated endpoint family, native compat,
routing, and credentials) with a fetch wrapper setting the session header
and UA on Zen inference paths only (`chat/completions`, `responses`,
`messages`, `systemone`, Gemini `generateContent`/`streamGenerateContent`).
Paid models never appear in the list. Discovery (`GET /v1/models`) is public
and passes through untouched.

The `before_agent_start` hook applies the same shim to directly selected
`opencode-zen/<free-id>` models, so the identity is consistent regardless of
entry point.

The outer custom-API dispatch already holds the provider's concurrency
slot, so the inner `streamSimple` passes `maxInFlightRequests: {}`.

## Session ids

`src/session.ts:toZenSessionId` maps the OMP conversation id via sha256 to
`ses_` + 12 lowercase hex + 14 base62 — the same shape as opencode's
`Identifier.create("ses", "descending")`. Deterministic per conversation,
so cache affinity survives restarts with no persisted state, and separate
conversations never share a lineage.

## `/zen-judge`

`/zen-judge {"state":"...", "questions":{"id":{"type":"noul","instructions":"..."}}}`
judges with Jev 1.13 Free via the `typesafe` API through the same identity
wrapper. Needs an omp whose pi-ai ships `@oh-my-pi/pi-ai/judgment`; on
older runtimes it reports an error instead of breaking the shim.

## Breaking change (v0.2.0)

The static catalog, compat table, and bespoke `OPENCODE_ZEN_API_KEY` login
are gone: discovery is dynamic, streaming runs as the native entry
(bring your own `/login opencode-zen`), and windows for unknown ids are
conservative synthesized defaults rather than curated rows. `opencode-free/<id>`
selection and the `default` model role keep working unchanged.

## Privacy

Free/contributor models may train on your traffic: Meta's contributor tier
uses prompts/completions to train future models
(https://dev.meta.ai/docs/pricing-rate-limits#contributor-tier), and Zen
marks free endpoints as data-collecting during their free periods
(https://opencode.ai/docs/zen/#privacy).
