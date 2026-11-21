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

The extension uses OMP's `fetchDynamicModels` to discover the live catalog. It fetches
two public endpoints in parallel, each with a five-second timeout:

- `https://api.openbroker.gonka.gg/v1/models` lists the active chat ids.
- `https://rpc.gonka.gg/chain-api/productscience/inference/inference/models_all`
  publishes each model's serving `model_args`.

Serving behavior comes from the chain args, not from a curated table. `--max-model-len`
sets `contextWindow`; `--reasoning-parser` selects the reasoning profile;
`--tool-call-parser` is retained as serving metadata. There are no fallback limits.
Discovery fails loudly when a live broker id is absent from the chain, when
`--max-model-len` is missing or invalid, or when a reasoning parser is unknown. The
error leaves the model unavailable so another model can be selected manually.

The chain publishes no served output-token ceiling. The extension therefore sets
`omitMaxOutputTokens` and does not send a `max_tokens` request field. A local 16k
output budget remains only for OMP's accounting.

Broker entries require a non-empty id. Text input/output support is checked when
modalities are supplied; malformed or non-chat entries are skipped. Missing names use
the model id, and missing input modalities default to text.

OMP owns discovery scheduling; the extension no longer polls or re-registers on a timer.
Local high-context warnings and model recommendations have also been removed.

There are no governance, CoinGecko, or balance requests on startup. OMP only has a
USD-per-million-token cost field; until OpenBroker exposes an authoritative USD quote,
models report no synthetic USD cost rather than incorrect cost totals.

## Reasoning

The chain `--reasoning-parser` is the single source of truth:

| Parser | Profile |
|---|---|
| `deepseek_v4` | Separate reasoning stream; off sends `none`; efforts low/high/max; 300s idle timeout |
| `glm45` | Separate reasoning stream; off maps to low; efforts low/high/max, default max |
| `kimi_k2` | Separate reasoning stream; Kimi markup healing and Moonshot tool schema; 300s idle timeout |
| `minimax_m2_append_think` | Thinking is inline in `content`; no reasoning field or switch |
| absent | Non-reasoning model; no effort fields |

An unknown parser fails discovery. OpenBroker can wait up to 20 minutes for response
headers, so the provider uses that first-event budget for every model.

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
to OMP's built-in `openai-completions` handler. Output caps are omitted because the
chain does not publish a served output ceiling.
