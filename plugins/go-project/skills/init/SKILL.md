---
name: init
description: 不依赖 codego 脚手架，按 codego 基线初始化一个 AI Coding 友好的新 Go 项目（HTTP 服务或 CLI）：选型、目录布局、质量门禁与 agent 资产。用户要新建、初始化、起一个 Go 服务或 Go 命令行项目时使用。
---

# 初始化 Go 项目

按 [基线摘要](references/baseline.md) 在空目录里从零写出一个能通过自身质量门禁的 Go 项目。开始前通读基线摘要；本文件只写步骤，选型、布局、命名、约定、门禁与 agent 资产的内容都以摘要为准。

基线摘要是原则，不是模板：每个文件由你按原则现场编写，正确性由项目自己的 `make verify` 与 archrules 证明。

## 1. 收集参数

用 AskUserQuestion 只问用户没给出的项：

- **项目形态**：HTTP 服务 / CLI。用户要的是 library、gRPC 服务、worker-only 等其他形态时，说明本 skill 只覆盖这两种，建议改用 codego 或手工搭建，然后结束。
- **module path**：如 `github.com/acme/order-service`。
- **服务名**：默认取 module path 末段。
- **数据库**（仅 HTTP 服务）：是否包含 PostgreSQL（pgx + sqlc + goose + testcontainers + 本地 Docker Compose），默认包含。

用户要求认证、异步事件、Redis、Kubernetes 等摘要范围外的能力时，说明这些不在初始化范围内，先按基线完成骨架，之后参考 codego 对应 module 再加。

完成标准：四项参数全部确定。

## 2. 预检

- 目标目录（默认 `./<服务名>`）必须不存在或为空。已有文件时列出这些文件并停止；初始化只写空目录，往现有项目补齐基线是 `go-project:audit` 之后的事。
- `go version` 不低于基线摘要写明的 Go 版本；版本不够时报告并停止。
- 受限环境先导出 `GOCACHE=$TMPDIR/go-build-cache`、`GOMODCACHE=$TMPDIR/go-mod-cache`，后续所有 Go 与 Make 命令沿用。

完成标准：目标目录可写且为空，Go 版本满足。

## 3. 写骨架

按以下顺序写，每组写完就 `go build ./...` 确认能编译，再写下一组：

1. **module 与依赖**：`go mod init`，`go.mod` 写基线 Go 版本。库用 `go get <path>@latest`（保持摘要给出的大版本），质量工具用 `go get -tool`，archrules 固定 `v0.1.0`（CLI 不接入 archrules）。
2. **共享内核与基础设施**：`internal/infra/config`（含 `defaults.go`、`Validate()` 与对应测试）、`internal/pkg/logger`、`internal/pkg/apperr`、`internal/pkg/trace`、`internal/infra/sentry`、`internal/app/bootstrap`。
3. **形态专属部分**：
   - HTTP 服务：`api/openapi.yaml`（只含 `system` 模块的 health/readiness 接口）与 `api/openapi.go`；`internal/pkg/httpx`（`response` 包络，request ID、recover、访问日志、metrics、OpenAPI 校验中间件）、`internal/pkg/{idgen,typedid,health}`、`internal/infra/metrics`；`internal/modules/system`（`module.go`、`adapter/http/{oapi,handler,router}` 与 handler 测试）；`internal/app/server` 组合根与路由对账测试；`cmd/server`。
   - HTTP 服务含数据库：再加 `internal/infra/pgdb`（连接池、事务、迁移）、`migrations/`、`sqlc.yaml`、`tools/sqlc/go.mod`、`cmd/migrate`、`internal/integration`、`docker-compose.yml`。
   - CLI：`internal/app/cli` 根命令与测试、`cmd/cli`。
4. **架构测试**（仅 HTTP 服务）：`internal/architecture/architecture_test.go` 调用 `archtest.RunProject(t, root)`，root 由 `runtime.Caller(0)` 推出项目根；项目根放 `archrules.json`，内容为 `{"exemptions": []}`。写代码前先跑 `go tool archcheck list`，命名与分层不确定时用 `go tool archcheck explain <rule-id>` 查。
5. **门禁**：`Makefile`（摘要第 5 节的目标名，按形态裁剪；CLI 没有 openapi/sqlc/架构类目标）、`.golangci.yml`、`lefthook.yml` 与 `.lefthook/` 脚本、`.gitleaks.toml`、`.github/workflows/ci.yml`、`.editorconfig`、`.gitignore`（含 `.env`、`.cache/`、`bin/`）、`.env.example`；HTTP 服务另加 `vacuum` 规则集。
6. **agent 资产**：按摘要第 6 节写 `CLAUDE.md`、`AGENTS.md`、`.claude/rules/*.md`、`.claude/settings.json`、`.claude/hooks/post-tool-use-quality.sh`（加可执行权限）；HTTP 服务再写 `.claude/skills/add-module/SKILL.md` 与 `.claude/skills/add-http-endpoint/SKILL.md`，以 `system` 模块为范例。启用数据库时，`add-module` 的 domain 与 persistence 步骤要写清楚聚合包与 `<agg>_repository.go` 的写法，因为 `system` 模块没有这两层。
7. **README.md**：项目简介、本地运行、常用 Make 目标、上线前必须注入的 `APP_*` 配置。

完成标准：上述文件都已写出，`go build ./...` 通过。

## 4. 验证

依次运行，失败就修，直到全部通过：

```bash
go mod tidy
go generate ./...   # HTTP 服务：生成 oapi 接口（及 sqlc 代码）
make check
make verify
```

再逐项对账：

- `CLAUDE.md` 与 `.claude/` 下提到的每个路径、Make 目标、规则文件都真实存在；路径规则索引表与 `.claude/rules/` 下的文件一一对应。
- HTTP 服务：`go tool archcheck check` 通过，`archrules.json` 豁免清单为空。
- 用 hook 的输入格式手动调用一次质量 hook，确认它能检出一个故意制造的 `gofmt` 问题，然后把这个问题改回去。

缺少 Docker、网络等条件导致某项无法运行时（如 `pin-actions` 需要 GitHub API、集成测试需要 Docker），记录缺失项并运行可用的最强子集。

完成标准：`make verify` 退出码为 0，或每一项未通过的检查都有具体原因与替代证据；对账项全部满足。

## 5. 收尾

- 目录还不是 git 仓库时运行 `git init`；不暂存、不提交，提交留给用户。
- 向用户报告：项目形态与参数、生成的顶层目录、验证命令与结果、无法验证的项与原因、上线前需要注入的配置，以及基线之外后续可加的能力。
