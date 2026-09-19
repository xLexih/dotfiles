# OMP OpenCode IPRotate provider

This extension drives [OpenCode Zen's free models](https://opencode.ai/docs/zen/)
through the local **zenproxy gateway** (`http://127.0.0.1:8787`), so Zen sees
rotating proxy exits instead of your own IP.

| Field | Value |
|---|---|
| Provider ID | `opencode-iprotate` |
| Base URL | `http://127.0.0.1:8787/v1` (override: `IPROTATE_BASE_URL`) |
| Authentication | `Authorization: Bearer <zen-key>` (forwarded to Zen) |
| Login | none (by design — see Auth) |
| Environment | `OPENCODE_ZEN_API_KEY` (OMP side or gateway side) |
| Prerequisite | `zenproxy.py serve` running (see opencode-ip-rotate project) |

## Auth (pick one)

1. **Gateway env (simplest):** put the key in opencode-ip-rotate's `.env`,
   run `just run`. The gateway injects it for keyless clients — OMP needs
   no setup at all.
2. **OMP env:** export `OPENCODE_ZEN_API_KEY` where OMP runs. Sent as the
   `Bearer` header, forwarded untouched.

There is deliberately no `/login` flow: the gateway's `GET /v1/models` is
public, so a login prompt could never validate the key — a wrong key would
pass and surface on first inference instead.

## Setup

```bash
# 1. Build a proxy pool (one-off, refreshes itself afterwards via auto-refill)
python3 zenproxy.py scrape --limit 800 --workers 60
# 2. Serve the gateway
python3 zenproxy.py serve
# 3. In OMP
/login opencode-iprotate
/model opencode-iprotate/mimo-v2.5-free
```

If no key is sent, the gateway injects one from its own `OPENCODE_API_KEY`
env — but prefer login so the key stays yours.

## Models

Same eight free ids as `provider-opencode-free`, suffixed `(via iprotate)`.
Dispatch is per model id: Muse Spark ids go through pi-ai's
`streamOpenAIResponses`, everything else through `streamOpenAICompletions`.

The static table is the *fallback*. The primary path is `fetchDynamicModels`,
which asks the gateway for its live free allowlist (`GET /v1/models`) and
synthesizes unknown ids by pattern (Muse Spark → Responses, else Chat), so
Zen lineup changes need no update here.

## Privacy

Same as Zen free tier: free/contributor models may train on your traffic
(see `provider-opencode-free/README.md`). Additionally, free public proxy
exits can observe TLS SNI (not bodies) — never route paid/non-free models
through this provider; the gateway allowlists free-tier ids only.
