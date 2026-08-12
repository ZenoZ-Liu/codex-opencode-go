# Codex × OpenCode Go

A single command connects the [OpenAI Codex CLI](https://github.com/openai/codex) to the [OpenCode Go](https://opencode.ai/docs/go/) subscription API — **no login prompt, no local proxy, Responses mode, model-switchable**.

## Why this exists

When you point Codex at a third-party API by adding `base_url`, `wire_api` and `experimental_bearer_token` at the **top level** of `~/.codex/config.toml`, Codex **silently ignores** those keys, falls back to the default OpenAI endpoint, and forces you to log in with an account. Those fields only take effect inside a `[model_providers.<id>]` block.

This script writes the config in the shape Codex actually understands.

## Features

- **No login** — authenticates with your OpenCode Go API key (`Authorization: Bearer`)
- **No proxy** — Codex CLI natively supports third-party endpoints via `[model_providers]`; nothing runs locally in between
- **Responses mode** — uses `wire_api = "responses"`, the protocol Codex speaks natively
- **Model switchable** — interactive model prompt with `deepseek-v4-flash` as default; pass any model from `https://opencode.ai/zen/go/v1/models`
- **Safe** — backs up your existing `~/.codex/config.toml` with a timestamp before overwriting
- **Validated** — checks TOML syntax when `python3` is available
- **Cross-platform** — macOS / Linux (pure bash, no dependencies)

## How it works

```
Codex CLI (Responses protocol)
   │  direct HTTPS, no local proxy
   ▼
opencode.ai/zen/go/v1  (OpenCode Go gateway, /v1/responses)
   │
   ▼
upstream model provider (e.g. DeepSeek official API, which natively
implements the Responses API for Codex)
```

Generated `~/.codex/config.toml`:

```toml
model = "deepseek-v4-flash"
model_provider = "opencode"

[model_providers.opencode]
name = "OpenCode Go"
base_url = "https://opencode.ai/zen/go/v1"
wire_api = "responses"
experimental_bearer_token = "sk-..."
```

## Prerequisites

- [Codex CLI](https://github.com/openai/codex) installed (`brew install codex` or `npm install -g @openai/codex`)
- An [OpenCode Go](https://opencode.ai/auth) subscription and API key (`sk-...`)

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/ZenoZ-Liu/codex-opencode-go/main/setup-codex-opencode.sh -o setup-codex-opencode.sh
bash setup-codex-opencode.sh
```

Then **fully quit and restart Codex** (a new session is not enough). No login prompt anymore.

## Usage

```bash
./setup-codex-opencode.sh                                # interactive: API key + model
./setup-codex-opencode.sh sk-xxxx                        # key given, model prompted
./setup-codex-opencode.sh sk-xxxx deepseek-v4-flash      # everything given
OPENCODE_GO_API_KEY=sk-xxxx OPENCODE_MODEL=deepseek-v4-flash ./setup-codex-opencode.sh
```

### Switching models

List available models:

```bash
curl -s https://opencode.ai/zen/go/v1/models -H "Authorization: Bearer sk-..."
```

Then rerun the script with the new model, or edit just the `model = "..."` line:

```toml
model = "glm-5.2"
```

> Tip: models served through Anthropic-style `/v1/messages` endpoints (MiniMax M-series, some Qwen) may not work with Codex directly. Prefer OpenAI-compatible models (DeepSeek V4, GLM, Kimi, MiMo, Grok, Hy3). If a model returns 404 / protocol errors, try `wire_api = "chat"` in the provider block.

## What the script changes

| Path | Action |
|---|---|
| `~/.codex/config.toml` | Backed up as `config.toml.bak.<timestamp>` if present, then overwritten |
| `~/.codex/` | Created if missing |

The `[marketplaces.*]` / `[plugins.*]` sections Codex manages itself are regenerated automatically on next start.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Still asks to log in | `base_url`/`wire_api`/`experimental_bearer_token` placed at top level → move them into `[model_providers.opencode]` (the script does this correctly) |
| `404` or protocol errors on a new model | Try `wire_api = "chat"`; or the model is only served via Anthropic `/v1/messages` |
| Non-streaming HTTP calls return `500` | Known gateway bug on `stream: false` requests; Codex always streams, so it is unaffected |
| "TOML check skipped" | Harmless — your `python3` is older than 3.11; config is still written |

## FAQ

**Why no local proxy?** Codex CLI has first-class support for third-party endpoints (`[model_providers]` + `base_url`). GUI switchers like CC Switch run a local proxy because they target Claude Code (Anthropic protocol) and/or translate Chat-Completions-only endpoints — a convenience layer, not a Codex requirement.

**Why does Responses mode work without translation?** DeepSeek's official API implements the Responses API natively (built for Codex, model `deepseek-v4-flash`), and the OpenCode Go gateway exposes `/v1/responses` for these models.

## Security

- Your API key is only written to `~/.codex/config.toml` (mode `644` by default). If you care about local secrecy, `chmod 600 ~/.codex/config.toml`.
- The script never logs or uploads the key anywhere.
- Do not commit a real key to a repository — the script prompts for it at runtime.

## License

[MIT](LICENSE)
