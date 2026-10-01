# OMP Cline provider

This extension adds [Cline](https://app.cline.bot) free-tier models as a
provider for Oh My Pi.

| Field | Value |
|---|---|
| Provider ID | `cline` |
| Base URL | `https://api.cline.bot/api/v1` |
| Authentication | OAuth browser login (`/login cline`) or `CLINE_API_KEY` env |
| Login | `/login cline` (opens the Cline authorization URL in a browser) |
| Environment | `CLINE_API_KEY` |

## Authentication

`/login cline` starts a browser OAuth flow: a local callback server
listens on `127.0.0.1:48801-48811` (`/auth`), the Cline authorization URL
is fetched from `GET /api/v1/auth/authorize?client_type=extension`, and the
returned code is exchanged at `POST /api/v1/auth/token`. Tokens refresh via
`POST /api/v1/auth/refresh`; chat requests send the access token as
`Authorization: Bearer workos:<access-token>`.

Requests carry the Cline VSCode-extension client headers (`X-CLIENT-TYPE`,
`X-CLIENT-VERSION`, `X-CORE-VERSION`, `X-PLATFORM`, …) plus a per-registration
`X-Task-ID`.

Alternatively, set `CLINE_API_KEY` to skip login.

## Models

The free roster is discovered dynamically — `fetchDynamicModels` unions two
live sources, because the curated list is only a subset:

1. the curated `free` array from `GET /api/v1/ai/cline/recommended-models`
   (curated order first), and
2. every `:free`-suffixed route in `GET /api/v1/ai/cline/models`
   (deduped, guardrail/moderation routes excluded).

Limits come from live per-model metadata (`context_length`,
`top_provider.max_completion_tokens`, `supported_parameters`,
`architecture.input_modalities`). Every returned entry is a complete model

## Commands

`/cline-free [status|models|update|test]` — show the registered catalog,
refresh it live from Cline (`update`), or print a one-shot probe command
(`test`).
