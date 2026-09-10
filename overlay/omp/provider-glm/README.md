# OMP GLM provider

This extension adds the local [GLM bridge](https://github.com/izaart95-jpg/GLM-Free-API) —
an OpenAI-compatible proxy over `chat.z.ai` — as a provider for Oh My Pi.

| Field | Value |
:|---|---|
| Provider ID | `glm-local` |
| Base URL | `http://127.0.0.1:3001/v1` (override with `GLM_BRIDGE_URL`) |
| Authentication | `Authorization: Bearer <AUTH_TOKEN>` (default `Waguri`; override with `GLM_BRIDGE_API_KEY`) |
| Login | `/login glm-local` (validates the token against `GET /v1/models`) |
| Environment | `GLM_BRIDGE_URL`, `GLM_BRIDGE_API_KEY` |

Point `GLM_BRIDGE_URL` at the hosted instance (`https://glm.cognix.sryze.cc/v1`)
to use it instead of a local bridge — same auth scheme.

## Bridge prerequisites

1. The bridge must be **running** (`go run .` in the GLM-Free-API checkout).
2. The bridge must run with **agent mode on** (`--agent-mode` / `AGENT_MODE=true`).
   Without it the bridge ignores `tools` in the request body, so OMP tool calls
   silently never happen. Agent mode also starts the background captcha cache.
3. `tokens.sqlite` must be seeded (`go run ./cmd/token-collector`) — each
   request burns device tokens on the captcha path.

Guest sessions (no `ZAI_TOKEN`) only serve `glm-4.7` — verified 2026-09-09:
`glm-5.2` returns a clean `403 Model not available for current user level`.
Set `ZAI_TOKEN` on the bridge (real account JWT from `chat.z.ai`
localStorage `token`) for all models and vision uploads. Note the flash
model's real id is `x-preview-l` — requesting `glm-5.3-flash` 500s on any
session because the bridge forwards the id verbatim and Z.AI has no such id.

## Models

Static fallback catalog (live `GET /v1/models` replaces it at discovery time;
unknown new ids are admitted with conservative defaults, vision detected from
`architecture.input_modalities`):

| Model ID | Name | Context | Max output | Cost (USD/1M) |
|---|---|---:|---:|---|
| `x-preview-l` | GLM 5.3 Flash | 1,048,576 | 16,384 | 0 / 0 |
| `glm-5.3` | GLM 5.3 | 1,048,576 | 16,384 | 0 / 0 |
| `glm-5.2` | GLM 5.2 | 1,048,576 | 16,384 | 0 / 0 |
| `GLM-5.1` | GLM 5.1 | 1,048,576 | 16,384 | 0 / 0 |
| `GLM-5-Turbo` | GLM 5 Turbo | 1,048,576 | 16,384 | 0 / 0 |
| `GLM-5v-Turbo` | GLM 5V Turbo (vision) | 1,048,576 | 16,384 | 0 / 0 |
| `glm-4.7` | GLM 4.7 | 131,072 | 16,384 | 0 / 0 |
| `glm-5` | GLM 5 (bridge default) | 1,048,576 | 16,384 | 0 / 0 |

The 16,384-token `maxTokens` cap is a verbosity brake, mirroring
`overlay/omp/provider-tokenrouter/README.md`.

## Request compatibility

Key difference from TokenRouter's GLM routes: the bridge emits the
DeepSeek-style **`reasoning_content`** field (streaming deltas and
non-streaming messages; `internal/zbridge/format.go:66`,
`handlers.go:241`), not the OpenAI-standard `reasoning` field — the compat
policy reflects this, or thinking text would be silently dropped. Deltas are
incremental. `reasoning_effort: "high" | "max"` is forwarded (forces
`enable_thinking=true`). Standard `tools` / `tool_calls` / `tool_choice`
when the bridge runs in agent mode. Watchdogs match the TokenRouter policy
(5-minute idle, no first-event watchdog) for captcha/cold-start silence.
