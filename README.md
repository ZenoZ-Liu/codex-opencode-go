# Codex × OpenCode Go

A single command connects the [OpenAI Codex CLI](https://github.com/openai/codex) to the [OpenCode Go](https://opencode.ai/docs/go/) subscription API — **no login prompt, no local proxy, Responses mode, model-switchable**. Available for **macOS / Linux (bash)** and **Windows (PowerShell)**.

## Features

- **No login** — authenticates with your OpenCode Go API key (`Authorization: Bearer`)
- **No proxy** — Codex CLI natively supports third-party endpoints via `[model_providers]`; nothing runs locally in between
- **Responses mode** — uses `wire_api = "responses"`, the protocol Codex speaks natively
- **Model switchable** — interactive model prompt with `deepseek-v4-flash` as default; pass any model from `https://opencode.ai/zen/go/v1/models`
- **Safe** — backs up your existing `~/.codex/config.toml` with a timestamp before overwriting
- **Validated** — checks TOML syntax when Python is available
- **Cross-platform** — `setup-codex-opencode.sh` (macOS/Linux, pure bash) and `setup-codex-opencode.ps1` (Windows, pure PowerShell), zero dependencies

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

- [Codex CLI](https://github.com/openai/codex) installed — macOS/Linux: `brew install codex` or `npm install -g @openai/codex`; Windows: `npm install -g @openai/codex`
- An [OpenCode Go](https://opencode.ai/auth) subscription and API key (`sk-...`)

## Quick start

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/ZenoZ-Liu/codex-opencode-go/main/setup-codex-opencode.sh -o setup-codex-opencode.sh
bash setup-codex-opencode.sh
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/ZenoZ-Liu/codex-opencode-go/main/setup-codex-opencode.ps1 -OutFile setup-codex-opencode.ps1
powershell -ExecutionPolicy Bypass -File .\setup-codex-opencode.ps1
```

Then **fully quit and restart Codex** (a new session is not enough). No login prompt anymore.

## Usage

### macOS / Linux

```bash
./setup-codex-opencode.sh                                # interactive: API key + model
./setup-codex-opencode.sh sk-xxxx                        # key given, model prompted
./setup-codex-opencode.sh sk-xxxx deepseek-v4-flash      # everything given
OPENCODE_GO_API_KEY=sk-xxxx OPENCODE_MODEL=deepseek-v4-flash ./setup-codex-opencode.sh
```

### Windows

```powershell
.\setup-codex-opencode.ps1                                # interactive: API key + model
.\setup-codex-opencode.ps1 -ApiKey sk-xxxx                # key given, model prompted
.\setup-codex-opencode.ps1 -ApiKey sk-xxxx -Model deepseek-v4-flash   # everything given
$env:OPENCODE_GO_API_KEY = "sk-xxxx"; $env:OPENCODE_MODEL = "deepseek-v4-flash"; .\setup-codex-opencode.ps1
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

| Platform | Path | Action |
|---|---|---|
| macOS / Linux | `~/.codex/config.toml` | Backed up as `config.toml.bak.<timestamp>` if present, then overwritten |
| Windows | `%USERPROFILE%\.codex\config.toml` | Same |

The `[marketplaces.*]` / `[plugins.*]` sections Codex manages itself are regenerated automatically on next start.

## Security

- Your API key is only written to `~/.codex/config.toml`. If you care about local secrecy on macOS/Linux, `chmod 600 ~/.codex/config.toml`.
- The script never logs or uploads the key anywhere.
- Do not commit a real key to a repository — the script prompts for it at runtime.

## License

[MIT](LICENSE)
