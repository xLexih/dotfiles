# OMP zen-router provider

This extension exposes the local [opencode-free-router](../..) key-pool
(`http://127.0.0.1:2718`) as an OMP provider, so `/model` / `--model
zen-router/<id>` drives Zen's free models through your pooled keys instead
of a single login key.

| Field | Value |
|---|---|
| Provider ID | `zen-router` |
| Base URL | `http://127.0.0.1:2718/v1` (or `ZEN_ROUTER_BASE_URL`) |
| Authentication | Dummy `router` key (the router ignores client auth) |
| Login | None — keys live in the router's `keys.json` |

## Models

Dynamic, from the router's `GET /v1/models` (itself live-discovered from
Zen). Each entry carries the router's family annotation, so new `-free`
ids appear here with the right endpoint and zero catalog work. The static
table in `src/catalog.ts` (the eight current free ids, same numbers as
`provider-opencode-free`) is fallback only, used at registration time and
when the router is unreachable.

Unknown-but-annotated ids are synthesized with conservative 128k/8k limits
(mirroring Big Pickle's `UNCONFIRMED` defaults) and their family is learned
for stream dispatch.

## Request compatibility

Same plain-OpenAI policy as `provider-opencode-free` (`src/compat.ts`):
standard `tools`/`tool_calls`, OpenAI-standard `reasoning` field, no forced
reasoning replay. Dispatch is per model id — Spark ids go through pi-ai's
`streamOpenAIResponses`, everything else through
`streamOpenAICompletions` — against the shared router base URL. A 5-minute
inter-event watchdog with no first-event watchdog accommodates long silent
reasoning prefill on the free tier.

## The router must be running

The provider is a thin front: `node server.js` in the router repo first.
If the router is down, discovery falls back to the static list and
inference fails with a connection error. Router failover (key rotation,
per-model cooldowns, shortest-wait 429s) happens server-side and is
invisible here — OMP just sees one fast provider until every key for the
model is exhausted.

## Privacy

Same as Zen free tier: free/contributor models may train on your traffic
(see `provider-opencode-free/README.md`).
