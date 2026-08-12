# Codex × OpenCode Go

一个命令让 [OpenAI Codex CLI](https://github.com/openai/codex) 接入 [OpenCode Go](https://opencode.ai/docs/go/) 订阅 API —— **无需登录账号、无需本地代理、Responses 模式、可随时换模型**。

## 为什么有这个项目

如果把 `base_url`、`wire_api`、`experimental_bearer_token` 直接写在 `~/.codex/config.toml` 的**顶层**，Codex 会**静默忽略**这些键，回落到默认 OpenAI 端点并要求账号登录。这些字段只有放进 `[model_providers.<id>]` 块才会生效。

本脚本直接生成 Codex 真正认得的配置结构。

## 特性

- **免登录** —— 用你的 OpenCode Go API key 认证（`Authorization: Bearer`）
- **零代理** —— Codex CLI 原生支持第三方端点（`[model_providers]`），本地不跑任何中转
- **Responses 模式** —— `wire_api = "responses"`，Codex 的原生协议
- **可换模型** —— 交互式输入模型名，默认 `deepseek-v4-flash`；支持 `https://opencode.ai/zen/go/v1/models` 里的任意模型
- **安全备份** —— 覆盖前自动把旧配置备份为带时间戳的 `config.toml.bak.<时间戳>`
- **语法校验** —— 有 python3 时自动校验 TOML
- **跨平台** —— macOS / Linux 通用（纯 bash，零依赖）

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

- 已安装 [Codex CLI](https://github.com/openai/codex)（`brew install codex` 或 `npm install -g @openai/codex`）
- 已订阅 [OpenCode Go](https://opencode.ai/auth) 并拿到 API key（`sk-...`）

## 快速开始

```bash
curl -fsSL https://raw.githubusercontent.com/ZenoZ-Liu/codex-opencode-go/main/setup-codex-opencode.sh -o setup-codex-opencode.sh
bash setup-codex-opencode.sh
```

然后**完全退出并重启 Codex**（只开新会话不够）。之后不会再弹登录。

## 用法

```bash
./setup-codex-opencode.sh                                # 交互输入 API key 和模型名
./setup-codex-opencode.sh sk-xxxx                        # 传了 key，交互输入模型名
./setup-codex-opencode.sh sk-xxxx deepseek-v4-flash      # 全部直接传
OPENCODE_GO_API_KEY=sk-xxxx OPENCODE_MODEL=deepseek-v4-flash ./setup-codex-opencode.sh
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

| 路径 | 动作 |
|---|---|
| `~/.codex/config.toml` | 存在则先备份为 `config.toml.bak.<时间戳>`，再覆盖写入 |
| `~/.codex/` | 不存在则创建 |

Codex 自己管理的 `[marketplaces.*]` / `[plugins.*]` 段会在下次启动时自动重新生成。

## 常见问题排查

| 症状 | 原因 / 解决 |
|---|---|
| 仍然要求登录 | `base_url`/`wire_api`/`experimental_bearer_token` 放在了顶层 → 移进 `[model_providers.opencode]` 块（本脚本已正确处理） |
| 换新模型报 404/协议错误 | 试试 `wire_api = "chat"`；或该模型只走 Anthropic `/v1/messages` 端点 |
| 非流式 HTTP 请求返回 500 | 网关已知 bug（`stream: false` 请求）；Codex 始终走流式，不受影响 |
| 提示 "TOML check skipped" | 无害 —— 你的 python3 低于 3.11，配置照常写入 |

## 常见疑问

**为什么不需要本地代理？** Codex CLI 对第三方端点有一等支持（`[model_providers]` + `base_url`）。CC Switch 这类 GUI 切换器带本地代理，是因为它们主要服务 Claude Code（Anthropic 协议）以及需要把 Chat-Completions 端点翻译成 Responses——那是便利层，不是 Codex 的硬性要求。

**为什么 Responses 模式不用翻译？** DeepSeek 官方 API 原生实现了 Responses API（为 Codex 而生，模型 `deepseek-v4-flash`），OpenCode Go 网关也为这些模型开放了 `/v1/responses`。

## 安全说明

- API key 只写入 `~/.codex/config.toml`（默认权限 644）。在意本地私密性可执行 `chmod 600 ~/.codex/config.toml`。
- 脚本不会记录或上传 key 到任何地方。
- 不要把真实 key 提交进仓库——脚本运行时才输入。

## License

[MIT](LICENSE)
