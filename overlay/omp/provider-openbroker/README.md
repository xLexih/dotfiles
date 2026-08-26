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

OMP's provider API supports either static `models` or `fetchDynamicModels`; this
extension uses the former. The effective limits below come from the public Gonka
Broker `GET /v1/models` catalog and reflect broker/deployment caps, which can be lower
than native model-card limits:

| Model ID | Context | Max output |
|---|---:|---:|
| `MiniMaxAI/MiniMax-M2.7` | 204,800 | 16,384 |
| `moonshotai/Kimi-K2.6` | 262,144 | 8,192 |
| `deepseek-ai/DeepSeek-V4-Flash-0731` | 400,000 | 16,384 |

All three models are reasoning-capable. MiniMax always reasons, Kimi reasons by
default but can be disabled, and DeepSeek reasoning is off by default but can be
enabled with the broker's reasoning controls.

The extension performs a bounded, non-blocking refresh of these limits from the public
broker model catalog at session start and every five minutes; when a change is observed,
the provider re-registers so the new limits take effect. If that endpoint is
unavailable, the verified static snapshot above remains active. There are no governance,
CoinGecko, or balance requests on startup. OMP only has a USD-per-million-token cost
field; until OpenBroker exposes an authoritative USD quote, models report no synthetic
USD cost rather than incorrect cost totals.

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
