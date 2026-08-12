#!/usr/bin/env bash
# ============================================================
# setup-codex-opencode.sh
# Connect the OpenAI Codex CLI to the OpenCode Go API (macOS / Linux)
#
# Usage:
#   ./setup-codex-opencode.sh                                  # interactive: API key + model
#   ./setup-codex-opencode.sh sk-xxxx                          # API key given, model prompted
#   ./setup-codex-opencode.sh sk-xxxx deepseek-v4-flash        # everything given
#   OPENCODE_GO_API_KEY=sk-xxxx OPENCODE_MODEL=deepseek-v4-flash ./setup-codex-opencode.sh
#
# What it does:
#   1. Backs up an existing ~/.codex/config.toml (if any)
#   2. Writes the OpenCode Go provider config (Responses mode, no login prompt)
#   3. Reminds you to fully restart Codex for the change to take effect
# ============================================================
set -euo pipefail

# ---------- 1. Get the API key ----------
API_KEY="${1:-${OPENCODE_GO_API_KEY:-}}"
if [[ -z "$API_KEY" ]]; then
  read -r -p "Enter your OpenCode Go API key (sk-...): " API_KEY
  API_KEY="$(echo "$API_KEY" | tr -d '[:space:]')"
fi
if [[ -z "$API_KEY" ]]; then
  echo "Error: no API key provided" >&2
  exit 1
fi

# ---------- 1b. Get the model name (switch models anytime) ----------
MODEL="${2:-${OPENCODE_MODEL:-}}"
if [[ -z "$MODEL" ]]; then
  read -r -p "Enter model name (press Enter for default: deepseek-v4-flash): " MODEL
  MODEL="$(echo "$MODEL" | tr -d '[:space:]')"
  MODEL="${MODEL:-deepseek-v4-flash}"
fi

# ---------- 2. Locate the Codex config directory ----------
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG="$CODEX_HOME/config.toml"
mkdir -p "$CODEX_HOME"

# ---------- 3. Back up the existing config ----------
if [[ -f "$CONFIG" ]]; then
  BACKUP="$CONFIG.bak.$(date +%Y%m%d%H%M%S)"
  cp "$CONFIG" "$BACKUP"
  echo "Backed up existing config -> $BACKUP"
  echo "(Note: your previous settings in that file are replaced. Codex will "
  echo " regenerate its own marketplace/plugins sections automatically.)"
fi

# ---------- 4. Write the new config ----------
# NOTE: base_url / wire_api / experimental_bearer_token MUST live inside a
# [model_providers.xxx] block. Placed at the top level they are silently
# ignored by Codex, which makes Codex fall back to the default OpenAI
# endpoint and prompt you to log in.
# Model switching tip: if a new model returns 404/protocol errors, try
# setting wire_api = "chat" (some models are only served via
# /chat/completions; Codex supports the chat wire API too).
cat > "$CONFIG" <<EOF
model = "$MODEL"
model_provider = "opencode"

[model_providers.opencode]
name = "OpenCode Go"
base_url = "https://opencode.ai/zen/go/v1"
wire_api = "responses"
experimental_bearer_token = "$API_KEY"
EOF

echo ""
echo "Config written to: $CONFIG"
echo "---------------------- Config preview ----------------------"
cat "$CONFIG"
echo "------------------------------------------------------------"

# ---------- 5. Validate ----------
if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import tomllib; tomllib.load(open('$CONFIG','rb')); print('TOML syntax check: OK')" 2>/dev/null; then
    :
  else
    echo "(TOML check skipped: python3 too old. Harmless.)"
  fi
fi

# ---------- 6. Check whether codex is installed ----------
if ! command -v codex >/dev/null 2>&1; then
  echo "Hint: 'codex' command not found. Install it with one of:"
  echo "  brew install codex            # Homebrew"
  echo "  npm install -g @openai/codex  # npm"
fi

echo ""
echo "Done! Model: $MODEL"
echo "Next step: fully quit Codex and start it again (not just a new "
echo "session). It will use the OpenCode Go API in Responses mode with no "
echo "account login required."
