# Codex × OpenCode Go

一个命令让 [OpenAI Codex CLI](https://github.com/openai/codex) 接入 [OpenCode Go](https://opencode.ai/docs/go/) 订阅 API —— **无需登录账号、无需本地代理、Responses 模式、可随时换模型**。支持 **macOS / Linux（bash）** 和 **Windows（PowerShell）**。

## 特性

- **免登录** —— 用你的 OpenCode Go API key 认证（`Authorization: Bearer`）
- **零代理** —— Codex CLI 原生支持第三方端点（`[model_providers]`），本地不跑任何中转
- **Responses 模式** —— `wire_api = "responses"`，Codex 的原生协议
- **可换模型** —— 交互式输入模型名，默认 `deepseek-v4-flash`；支持 `https://opencode.ai/zen/go/v1/models` 里的任意模型
- **安全备份** —— 覆盖前自动把旧配置备份为带时间戳的 `config.toml.bak.<时间戳>`
- **语法校验** —— 有 Python 时自动校验 TOML
- **跨平台** —— `setup-codex-opencode.sh`（macOS/Linux，纯 bash）和 `setup-codex-opencode.ps1`（Windows，纯 PowerShell），零依赖

## 原理

```
Codex CLI（Responses 协议）
   │  直连 HTTPS，无本地代理
   ▼
opencode.ai/zen/go/v1  （OpenCode Go 网关，/v1/responses）
   │
   ▼
上游模型供应商（如 DeepSeek 官方 API —— 其原生实现了面向 Codex 的 Responses API）
```

生成的 `~/.codex/config.toml`：

```toml
model = "deepseek-v4-flash"
model_provider = "opencode"

[model_providers.opencode]
name = "OpenCode Go"
base_url = "https://opencode.ai/zen/go/v1"
wire_api = "responses"
experimental_bearer_token = "sk-..."
```

## 前置要求

- 已安装 [Codex CLI](https://github.com/openai/codex) —— macOS/Linux：`brew install codex` 或 `npm install -g @openai/codex`；Windows：`npm install -g @openai/codex`
- 已订阅 [OpenCode Go](https://opencode.ai/auth) 并拿到 API key（`sk-...`）

## 快速开始

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/ZenoZ-Liu/codex-opencode-go/main/setup-codex-opencode.sh -o setup-codex-opencode.sh
bash setup-codex-opencode.sh
```

### Windows（PowerShell）

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/ZenoZ-Liu/codex-opencode-go/main/setup-codex-opencode.ps1 -OutFile setup-codex-opencode.ps1
powershell -ExecutionPolicy Bypass -File .\setup-codex-opencode.ps1
```

然后**完全退出并重启 Codex**（只开新会话不够）。之后不会再弹登录。

## 用法

### macOS / Linux

```bash
./setup-codex-opencode.sh                                # 交互输入 API key 和模型名
./setup-codex-opencode.sh sk-xxxx                        # 传了 key，交互输入模型名
./setup-codex-opencode.sh sk-xxxx deepseek-v4-flash      # 全部直接传
OPENCODE_GO_API_KEY=sk-xxxx OPENCODE_MODEL=deepseek-v4-flash ./setup-codex-opencode.sh
```

### Windows

```powershell
.\setup-codex-opencode.ps1                                # 交互输入 API key 和模型名
.\setup-codex-opencode.ps1 -ApiKey sk-xxxx                # 传了 key，交互输入模型名
.\setup-codex-opencode.ps1 -ApiKey sk-xxxx -Model deepseek-v4-flash   # 全部直接传
$env:OPENCODE_GO_API_KEY = "sk-xxxx"; $env:OPENCODE_MODEL = "deepseek-v4-flash"; .\setup-codex-opencode.ps1
```

### 换模型

查看可用模型：

```bash
curl -s https://opencode.ai/zen/go/v1/models -H "Authorization: Bearer sk-..."
```

然后重跑脚本选新模型，或直接改配置里的 `model = "..."` 一行：

```toml
model = "glm-5.2"
```

> 提示：走 Anthropic 风格 `/v1/messages` 端点的模型（MiniMax M 系列、部分 Qwen）可能无法直连 Codex。优先选 OpenAI 兼容的模型（DeepSeek V4、GLM、Kimi、MiMo、Grok、Hy3）。如果新模型报 404/协议错误，把 provider 块里的 `wire_api` 改为 `"chat"` 试试。

## 脚本会改动什么

| 平台 | 路径 | 动作 |
|---|---|---|
| macOS / Linux | `~/.codex/config.toml` | 存在则先备份为 `config.toml.bak.<时间戳>`，再覆盖写入 |
| Windows | `%USERPROFILE%\.codex\config.toml` | 同上 |

Codex 自己管理的 `[marketplaces.*]` / `[plugins.*]` 段会在下次启动时自动重新生成。

## 安全说明

- API key 只写入 `~/.codex/config.toml`。在意本地私密性的话，macOS/Linux 可执行 `chmod 600 ~/.codex/config.toml`。
- 脚本不会记录或上传 key 到任何地方。
- 不要把真实 key 提交进仓库——脚本运行时才输入。

## License

[MIT](LICENSE)
