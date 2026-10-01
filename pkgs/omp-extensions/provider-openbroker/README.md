# OMP OpenBroker provider

This extension adds [OpenBroker](https://openbroker.gonka.gg), Gonka devshard
inference behind its OpenAI-compatible `POST /v1/chat/completions` endpoint.

| Field | Value |
|---|---|
| Provider ID | `openbroker` |
| Base URL | `https://api.openbroker.gonka.gg/v1` |
| Authentication | `Authorization: Bearer obk-…` |
| Login | `/login openbroker` |
| Environment | `OPENBROKER_API_KEY` |

Interactive login validates a newly entered key once with OpenBroker's documented
`GET /v1/balance` endpoint. It does not poll balance during startup or while a session
is open. OMP supplies saved credentials to the provider itself, so the extension never
tries to reconstruct them from an empty environment variable.

## Models and startup

The extension uses OMP's `fetchDynamicModels` to discover chat models from the public
`https://api.openbroker.gonka.gg/v1/models` catalog with a five-second request timeout.
That endpoint returns bare `{id}` entries with no context/output metadata, so serving
limits come from a curated table in `src/catalog.ts` (Gonka devshard serving profile
for MiniMax/DeepSeek/GLM, upstream model card for Qwen), with conservative
128k/16k defaults for unknown ids so new models register instead of disappearing.
When the broker does publish rich `context_length`/`max_output_length` fields, those
take precedence over the table. New models are included and absent models are omitted
on each successful discovery.

Entries require positive integer context/output limits and text input/output support
when modalities are supplied. Embedding-only and malformed entries are skipped.
Supported text/image inputs and the `reasoning` feature are read from broker metadata;
missing reasoning metadata is treated as false, even for previously known models.
Missing names fall back to the model ID, and missing modalities default to text.

OMP owns discovery scheduling; the extension no longer polls or re-registers on a timer.
Failed or empty discovery raises an error rather than substituting hard-coded models;
initial availability therefore depends on the catalog endpoint. Local high-context
warnings and model recommendations have also been removed. Request compatibility
handling remains unchanged.

There are no governance, CoinGecko, or balance requests on startup. OMP only has a
USD-per-million-token cost field; until OpenBroker exposes an authoritative USD quote,
models report no synthetic USD cost rather than incorrect cost totals.

## Strict request compatibility

OpenBroker's documentation describes a standard OpenAI chat-completions API, but its
served MiniMax route additionally rejects assistant and tool content that is not a
non-empty array of non-empty `{name,type,text}` objects. The extension retains a small,
provider-scoped `streamSimple` wrapper: immediately before OMP sends a request, it
normalizes only assistant and tool content into that strict form, and only for MiniMax
requests — other models keep standard OpenAI content shapes. Empty content
becomes a `[empty]` placeholder (whitespace is rejected too), names are always
non-empty, and tool-call fields are preserved.

The wrapper delegates all streaming, function calling, reasoning, and response handling
to OMP's built-in `openai-completions` handler. It also uses OpenBroker's documented
`max_tokens` request field.
