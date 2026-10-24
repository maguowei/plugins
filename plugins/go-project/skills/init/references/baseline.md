# Go 项目基线摘要

> 提炼自 codego `69d3280b`（2026-10-23）的生成项目模板与 ADR。这里只写原则与选型，不是可复制的模板；与 codego 冲突时以 codego 为准。

基线覆盖两种**项目形态**：**HTTP 服务**（契约优先的 DDD 垂直模块服务，可选 PostgreSQL）与 **CLI**（Cobra 命令行应用）。基线只约束 Go module 根目录以内；monorepo 的根目录编排与前端栈不在其中。

## 1. 选型

| 关注点 | 选择 | 理由 |
| --- | --- | --- |
| Go | `go 1.27.1`，工具链跟随 `go.mod` | 与 codego 基线同版本；质量工具依赖 `go.mod` 的 tool directive |
| HTTP 路由 | `github.com/go-chi/chi/v5` | 中间件与 handler 保持标准 `net/http` 签名；`RoutePattern()` 给 metrics/日志提供路由模板，`chi.Walk` 支撑路由对账测试。gin 的 `*gin.Context` 会渗透到每一层；`http.ServeMux` 缺这两项能力 |
| API 契约 | `api/openapi.yaml` + `oapi-codegen/v2`（`chi-server` + `strict-server` + `models`），按 tag 生成到各模块 `adapter/http/oapi` | 契约优先：响应码与响应体由生成类型约束，handler 只做映射，不写手写 DTO |
| 请求校验 | `getkin/kin-openapi` 的 `openapi3filter`，作为全局中间件 | 格式约束写在 spec 里，边界一次校验，内部信任已校验输入 |
| 持久化 | PostgreSQL + `jackc/pgx/v5`（`pgxpool`）+ `sqlc` + `pressly/goose/v3`（纯 SQL 迁移） | SQL 显式可审，生成代码入库可 diff；ORM（ent、gorm）隐藏查询且迁移难审 |
| 配置 | `caarlos0/env/v11`，只读 `APP_*` 环境变量 | 十二要素；viper 与配置文件带来多套优先级与隐式合并 |
| 日志 | 标准库 `log/slog` | 零依赖、结构化、带 context |
| 观测 | `prometheus/client_golang`、OpenTelemetry（`otelhttp` + OTLP gRPC exporter）、`getsentry/sentry-go` | 指标、链路、错误三件套各用事实标准 |
| ID | UUIDv7，经注入的 `idgen.Generator` 生成；聚合 ID 用泛型强类型 `typedid.ID[K]` | 有序、可分布式生成；编译期区分不同聚合的 ID |
| CLI | `spf13/cobra` | 生态事实标准，自带补全与帮助 |
| 测试 | 标准 `testing` + `testify` 的 `require`/`assert`；手写内存 fake；`testcontainers-go` 跑 PostgreSQL 集成测试（`integration` build tag） | fake 断言最终状态而非调用序列，重构时测试更稳；mock 库（`testify/mock`、mockery）不进基线 |
| 架构规则 | `github.com/maguowei/codego/archrules v0.1.0`（含 `archcheck` 工具） | 命名、分层、SDK 归口、测试替身、时钟注入共 29 条规则可机械判定 |
| 质量工具 | `golangci-lint/v2`、`govulncheck`、`gitleaks`、`lefthook/v2`、`actionlint`、`pinact`、`ghalint`；HTTP 服务另加 `vacuum`（OpenAPI lint） | 全部写进 `go.mod` 的 `tool (...)`，以 `go tool <name>` 运行，版本随 `go.sum` 锁定 |

依赖大树的工具（`sqlc`、`oasdiff`）用独立 modfile `tools/<name>/go.mod`，以 `go tool -modfile=tools/<name>/go.mod <name>` 调用，不进主 `go.mod`。

**版本**：只固定 Go 与 archrules 的版本；其他库与工具按上表的 module path 和大版本（`/v5`、`/v11`、`/v2`）取当时最新的 minor/patch。

认证、RBAC、Redis、异步事件（outbox/inbox + worker）、Kafka、Kubernetes 不在本摘要的落地范围；需要时参考 codego 对应 module，或直接用 codego 生成。

## 2. 目录布局

### HTTP 服务

```text
cmd/server/            # 进程入口：signal、bootstrap、调用组合根，保持极薄
cmd/migrate/           # 启用数据库时：内嵌迁移，goose Provider + advisory lock 执行
api/openapi.yaml       # 唯一 HTTP 契约；api/openapi.go 用 go:embed 内嵌
internal/
  app/server/          # HTTP 组合根：创建外部资源，对每个模块调用 New + Mount
  app/bootstrap/       # 日志、tracing、Sentry 初始化与 Shutdown
  infra/               # 全局基础设施：config、metrics、sentry、pgdb（连接池/事务/迁移）
  pkg/                 # 跨模块共享内核：apperr、logger、httpx（middleware、response）、idgen、typedid、health、trace
  modules/<name>/
    module.go          # 模块装配入口：Deps、New(Deps)、Mount(r chi.Router, ...)
    domain/<agg>/      # 实体、值对象、聚合仓储接口 Repository、哨兵错误、领域事件
    application/       # command/、query/、result/ 三包 + service/；可选 port/ 放技术性出站端口
    infra/persistence/ # 仓储实现；queries/*.sql → sqlcgen/
    adapter/http/      # handler/（实现生成接口）、router/、oapi/（生成代码）
    <name>test/        # 内存 fake 与仓储契约
  architecture/        # architecture_test.go，只调用 archtest.RunProject
  integration/         # integration build tag 的集成测试
migrations/            # goose 纯 SQL 迁移，时间戳编号
sqlc.yaml
archrules.json         # archrules 项目配置与豁免清单
```

依赖方向：`adapter → application → domain ← infra`。`adapter` 是入站适配（协议 → 用例），`infra` 是出站适配（端口 → 技术）。

- domain 零外部依赖，按聚合分包，包边界即聚合边界；类型不带包名前缀（`todo.Todo`、`todo.Repository`、`todo.ErrNotFound`）。
- application 通过接口依赖基础设施；查询只读、不发布领域事件。
- handler 直接持有本模块 `*<能力>Service`，只在生成类型与 command/query/result 之间映射，不接触 domain。
- 模块之间只经 `internal/pkg` 的共享契约或领域事件协作；`internal/pkg` 不依赖 `internal/infra`。
- 第三方 SDK 各有唯一归口包（chi 只在组合根、`module.go` 与 `adapter/http/{router,oapi}`；otel SDK → `pkg/trace`；sentry-go → `infra/sentry`）；业务代码只依赖归口包。

### CLI

```text
cmd/cli/                # 进程入口：signal、bootstrap、Execute()、Shutdown
internal/app/cli/       # Cobra 命令组合根，命令只做协议适配、参数校验与输出格式
internal/app/bootstrap/ # 日志、tracing、Sentry 初始化
internal/infra/config/  # 配置加载与校验
internal/pkg/{logger,apperr,trace}/
```

命令逻辑通过构造函数注入；命令自身输出写到显式 `io.Writer`。CLI 形态不接入 archrules，分层规则按上述目录约定靠 review 维护。

## 3. 命名

能机械判定的命名与分层规则以 archrules 为准：`go tool archcheck list` 列出全部规则，`go tool archcheck explain <rule-id>` 给出判定细则与正反例。核心形状：

- application：`command/<agg>_commands.go`、`query/<agg>_queries.go`、`result/<agg>_result.go`、`service/<agg>_service.go`；出入参为 `<动词><名词>Command` / `<动词><名词>Query` / `<名词>Result`，应用服务为 `<能力>Service`。
- domain 聚合包：`<agg>.go`、`id.go`、`errors.go`、`repository.go`、`events.go`、`doc.go`；领域事件为过去时 + `Event`（`todo.CreatedEvent`）。
- persistence：每聚合一个 `<agg>_repository.go`，模块共享 helper 用 `store.go`。
- adapter：直接子目录只允许入站协议名；handler 为 `<agg>_handler.go`，测试为 `<agg>_handler_test.go`；router 包必须有 `router.go`。
- 通用：包说明只写在 `doc.go`；包名等于目录名；模块根只放 `module.go`；测试文件按被测文件或场景命名。

archrules 判定不了、靠 review 维护的规则：

- 新文件用 snake_case 分词。
- 包名用完整单词，只用 Go 生态通用缩写（`apperr`、`httpx`、`idgen`、`pgdb`）。
- 封装外部 SDK 的包按能力命名（`objstore`、`cache`、`eventbus`），不按厂商或库命名。
- `queries/` 每张表一个 SQL 文件，用复数名词。
- application/adapter 层的 import 别名由 `.golangci.yml` 的 `importas` 统一（如 `todocmd`、`todoquery`、`todosvc`）。

## 4. 工程约定

- **错误**：`internal/pkg/apperr` 定义带 Kind 的应用错误，HTTP 层按 Kind 映射状态码；包装用 `fmt.Errorf("...: %w", err)`，比较用 `errors.Is` / `errors.As`；业务代码返回 error，不 panic。
- **响应包络**：HTTP JSON 统一为 `{code, message, data}`，成功时 `code` 为 0；统一由 `internal/pkg/httpx/response` 输出，strict server 的错误钩子同样接到该包。
- **配置**：`internal/infra/config` 是唯一读取环境变量的包。`defaults.go` 只有一套可直接用于生产的默认值；外部服务地址与密钥不给默认值，由 `Validate()` 在启用时要求注入；未知的 `APP_*` 变量让启动失败。`.env.example` 入库，`.env` 被 gitignore，Makefile 首次运行时从 example 复制。配置只在组合根读取，以 typed config 注入各层。
- **日志**：进程入口统一经 `internal/app/bootstrap`；业务代码用 `logger.FromContext(ctx)` 或构造注入取 logger，只用 `*Context` 系列方法；字段以 attr 传入；同一错误链路只记一次。
- **依赖注入**：依赖经构造函数显式传入；包级可变单例与绕过组合根的初始化都不进基线。时间经注入的时钟获取，测试用固定时钟。
- **进程生命周期**：入口用 `signal.NotifyContext`，HTTP 服务带超时 `Shutdown`；服务启动不自动迁移，迁移由 `cmd/migrate` 执行。
- **生成代码**：oapi-codegen 与 sqlc 的产物提交入库，由 `openapi-check` / `sqlc-check` 重新生成并逐字节比较以防漂移；生成物只经 `make generate` 更新。
- **数据库**：schema 不使用外键，跨聚合一致性由应用层与唯一索引保证；已执行的迁移保持原样，新迁移用 `make migration-new name=<snake_case>` 创建。
- **测试**：表驱动优先；应用层用 `<name>test` 包的内存 fake；仓储行为由 `Run<Agg>RepositoryContract` 契约测试同时约束 fake 与真实实现；接口层用 `httptest` 进程内测试；集成测试放 `internal/integration`。

## 5. 质量门禁

Makefile 是唯一命令入口，CI、Lefthook 与 agent 都复用 Make 目标；工具命令以 `GOLANGCI_LINT ?= go tool golangci-lint` 这类变量暴露。基线目标名：

| 目标 | 职责 |
| --- | --- |
| `check` | 迭代检查：build + vet + 单测（HTTP 服务另含架构测试），一分钟内完成 |
| `verify` | 交付门禁：generate/tidy、各类 lint、密钥、模块校验、漏洞、覆盖率（`-race`）、架构测试、build；每步一行结果，失败回显完整日志 |
| `test` / `test-race` / `test-architecture` / `coverage-check` | 测试与覆盖率 |
| `lint` / `lint-go` / `lint-openapi` / `lint-secrets` / `lint-actions` | golangci-lint、vacuum、gitleaks、pinact + actionlint + ghalint |
| `vuln-check` / `mod-verify` / `check-tidy` / `modernize-check` | 供应链与现代化 |
| `generate` / `openapi-check` / `sqlc-check` | 生成与防漂移 |
| `build` / `run` / `migrate` / `migration-new` | 构建与运行 |
| `lefthook-run` / `pin-actions` | 本地 hooks 与 Actions SHA 固定 |

- **golangci-lint 下限**：在 `errcheck`、`govet`、`staticcheck`、`unused`、`ineffassign` 之上启用 `bodyclose`、`contextcheck`、`errorlint`、`exhaustive`、`forbidigo`、`forcetypeassert`、`gocognit`（阈值 20）、`gocritic`、`gosec`、`importas`、`nilerr`、`nilnil`、`noctx`、`sloglint`、`testifylint`、`usetesting`；formatter 用 `gofmt` + `goimports`。`forbidigo` 禁止 `fmt.Print*`、`panic` 与 config 包以外的 `os.Getenv`。告警在源头修复，确属误报时写带理由的路径级 exclusion。
- **Lefthook**：pre-commit 先 `gofmt` 再并行跑 lint、密钥扫描（`gitleaks git --pre-commit --staged`）、Actions SHA 校验、单测与架构测试；commit-msg 校验 Conventional Commits；pre-push 跑 `verify`（命中缓存时跳过）。
- **CI**：GitHub Actions 调用 `make verify`；`uses:` 全部固定到 commit SHA（`pinact`），job 级最小权限、`persist-credentials: false`（`ghalint`）。HTTP 服务另有 OpenAPI breaking change 检查。

## 6. AI 友好资产

目标：agent 进入项目后，从一个入口文件就能找到命令、边界和本次改动该读的规则，每次编辑都有即时反馈。

- **`CLAUDE.md`**：常用 Make 目标与职责、agent 工作流（先测后改、API 先改契约再生成、迭代 `check` 交付 `verify`、受限环境用 `GOCACHE=$TMPDIR/go-build-cache GOMODCACHE=$TMPDIR/go-mod-cache`）、路径规则索引表、架构分层与开发规范摘要、提交规范。`AGENTS.md` 是指向 `CLAUDE.md` 的兼容入口，正文只维护一处。
- **`.claude/rules/`**：一个无 `paths` 的默认规则 `project-workflow.md`（工作流、lint 约定、命名规则表），其余按路径拆分并写 `paths` frontmatter。HTTP 服务：`domain-layer`、`application-layer`、`http-interface`、`openapi-contract`、`configuration`、`logging`、`tracing`、`observability-bootstrap`、`testing`、`runtime-verification`，启用数据库再加 `persistence`、`database-migrations`。CLI：`cli-interface`、`configuration`、`logging`、`tracing`、`testing`、`runtime-verification`。每条规则写该路径下的约束与理由，能机械判定的指向 archrules 规则 ID。
- **`.claude/settings.json`**：`permissions.allow` 放行 Make 目标、`go test`/`go build`/`go generate`/`go mod tidy` 与 `go tool archcheck*`；`PostToolUse` 挂质量 hook；sandbox 放行 Go build/module 缓存目录。
- **质量 hook** `.claude/hooks/post-tool-use-quality.sh`：从 hook 输入取被编辑文件，Go 文件做 `gofmt` 与所在包的 `go vet`（失败输出 `file:line`），并校验 JSON、OpenAPI 与 Lefthook 配置；只检查被编辑文件所在包，带超时，缓存放项目 `.cache/`。完整门禁交给 `make check` / `make verify`。
- **项目内 skill**（仅 HTTP 服务）：`add-module` 按「契约 → 生成 → domain → application → fake 与仓储契约 → adapter → persistence → 模块装配 → 冒烟」逐步新增业务模块；`add-http-endpoint` 给已有模块加接口。每步写明要跑的验证命令。
