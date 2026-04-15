# go-ddd-scaffold 插件重构设计

**日期**: 2026-04-15
**状态**: 待实施

## 目标

将 go-ddd-scaffold 从当前的半成品状态重构为一个真正可复现的脚手架工具。生成的项目必须能编译、能测试、能启动、能跑通完整的 User CRUD 链路。

## 核心原则

**代码优先，模板其次**。模板只是已验证代码的参数化形式。每一个 `.tpl` 文件，都必须来自一个真实跑通的 Go 文件。

## 一、重构后插件结构

```
go-ddd-scaffold/
├── .claude-plugin/
│   └── plugin.json
├── README.md                  # ~80 行
├── TESTING.md                 # ~80 行
├── commands/
│   └── init-go-web.md         # ~80 行，交互式命令
├── tools/
│   └── scaffold/
│       └── main.go            # ~150 行，Go 渲染 CLI
├── scripts/
│   └── generate.sh            # ~100 行，主编排脚本
├── templates/
│   ├── vars.yaml              # 单一变量文件
│   └── [各层模板]/
└── skills/                    # 6 个 skills，适度精简
```

### 关键变化

| 当前 | 重构后 |
|------|--------|
| Python + Jinja2 + Go template 转换 | 纯 Go `text/template` CLI |
| 多层 YAML 变量合并（default.yaml + db_*.yaml + aggregates/*.yaml） | 单一 `vars.yaml` |
| 398 行 render.py | ~150 行 `tools/scaffold/main.go` |
| 258 行 generate.sh | ~100 行 generate.sh |
| 半成品模板 | 来自验证过代码的模板 |
| 需要 Python 3 + jinja2 + pyyaml | 只需要 Go 1.26 |

### 删除清单

- `scripts/render.py` — Python 渲染引擎
- `scripts/requirements.txt` — Python 依赖
- `templates/README.md` — 428 行内部文档
- `templates/vars/` 目录 — 多层 YAML 变量合并系统
- `templates/*/_manifest.yaml` — manifest 驱动系统

## 二、渲染引擎

### `tools/scaffold/main.go`

极简 Go CLI，做且仅做一件事：读取变量 + 渲染模板目录到目标目录。

```
用法：scaffold -vars vars.yaml -templates ./templates -output ./my-project
```

内部逻辑（~150 行）：

1. 解析命令行参数（-vars, -templates, -output）
2. 读取 vars.yaml → 解析为 `map[string]any`
3. 递归遍历 templates/ 目录
4. 对每个 .tpl 文件：用 `text/template` 渲染，去掉 .tpl 后缀，写入 output/ 对应路径
5. 对非 .tpl 文件：直接复制

### 变量文件

单一 `vars.yaml`，两级结构——项目级 + 示例聚合级：

```yaml
# 项目级（generate.sh 从用户输入生成）
project_name: "my-service"
go_module: "github.com/me/my-service"
database: "mysql"        # mysql | sqlite3
include_examples: true
go_version: "1.26"

# 示例聚合级（固定值，include_examples=true 时使用）
entity_name: "User"
entity_name_lower: "user"
entity_id_type: "uuid.UUID"
```

模板内直接用 `{{.project_name}}`、`{{.entity_name}}`，无命名转换。

### 模板语法

100% 原生 Go `text/template`，无任何转换层：

```go
package entity

type {{.entity_name}} struct {
    id    {{.entity_id_type}}
    email Email
}
```

### `include_examples` 文件跳过机制

scaffold CLI 遍历模板时，对文件名包含 `user` 的模板（如 `entity/user.go.tpl`、`handler/user.go.tpl`），当 `include_examples=false` 时直接跳过，不渲染。非 user 相关的基础设施文件（config、middleware 等）始终生成。

## 三、模板结构

按概念分包，依赖方向：`service` → `repository` → `entity` ← `event`，`valueobject` 被 `entity` 引用，无环。

```
templates/
├── base/
│   ├── go.mod.tpl
│   ├── .gitignore.tpl
│   ├── README.md.tpl
│   └── Makefile.tpl
├── cmd/
│   ├── server/main.go.tpl
│   └── migrate/main.go.tpl
├── internal/app/
│   ├── domain/
│   │   ├── entity/user.go.tpl
│   │   ├── valueobject/email.go.tpl
│   │   ├── event/user.go.tpl
│   │   ├── repository/user.go.tpl
│   │   └── service/user.go.tpl
│   ├── application/
│   │   ├── service/user.go.tpl
│   │   └── dto/user.go.tpl
│   └── infrastructure/
│       ├── repository/user.go.tpl
│       ├── config/config.go.tpl
│       ├── observability/
│       │   ├── logger.go.tpl
│       │   ├── metrics.go.tpl
│       │   └── sentry.go.tpl
│       └── event/eventbus.go.tpl
├── internal/ent/
│   └── schema/user.go.tpl
├── interface/http/
│   ├── handler/user.go.tpl
│   ├── dto/
│   │   ├── request.go.tpl
│   │   └── response.go.tpl
│   ├── middleware/
│   │   ├── cors.go.tpl
│   │   ├── logger.go.tpl
│   │   ├── metrics.go.tpl
│   │   └── recovery.go.tpl
│   └── router.go.tpl
├── configs/
│   └── config.yaml.tpl
└── docker/
    ├── Dockerfile.tpl
    └── docker-compose.yaml.tpl
```

### `include_examples` 控制

- `true`：所有 user 相关模板生成，完整 CRUD 链路可用
- `false`：只生成骨架（main、config、middleware 等），无业务代码

### 数据库条件

模板内用 `{{if eq .database "mysql"}}` 切换驱动和 DSN，无需独立配置文件。

## 四、命令设计

### `commands/init-go-web.md`（~80 行）

交互流程：

1. 询问项目名称 → `project_name`
2. 询问 Go module 路径 → `go_module`
3. 询问数据库类型 → `database`（mysql / sqlite3）
4. 询问是否含示例代码 → `include_examples`（yes / no）
5. 确认信息
6. 调用 `generate.sh`
7. 显示后续步骤

前置依赖检查统一放在 `generate.sh` 里，命令只负责收集信息。

### `scripts/generate.sh`（~100 行）

```
1. 验证 Go 1.26 已安装
2. 创建目标目录
3. go build -o /tmp/scaffold ./tools/scaffold
4. 生成 vars.yaml（从用户输入）
5. /tmp/scaffold -vars vars.yaml -templates ./templates -output $TARGET
6. cd $TARGET && go mod init && go mod tidy
7. go generate ./...  （触发 ent generate）
8. go build ./...     （验证编译）
9. 提示成功 + 后续步骤
```

## 五、技术栈

生成的项目保留完整技术栈：

| 组件 | 用途 |
|------|------|
| Gin | HTTP 路由和中间件 |
| Ent | 类型安全 ORM |
| Viper | 配置管理 |
| slog | 结构化日志 |
| Prometheus | 性能指标 |
| Sentry | 错误追踪 |
| CloudEvents | 领域事件标准格式 |
| testify | 测试断言和 Mock |

## 六、Skills 精简

保留 6 个 skills，每个只保留最核心的 1-2 份参考文档：

| Skill | 当前文档数 | 精简后 | 处理方式 |
|-------|-----------|--------|---------|
| ddd-core-concepts | 6 | 2 | 合并 entity/value-object/aggregate 为一份；保留 repository + domain-events |
| ddd-layered-architecture | 5 | 2 | 合并四层指南为一份；保留 dependency-injection |
| go-project-structure | 2 | 1 | 合并为一份 |
| go-tech-stack-integration | 3 | 2 | 保留 gin + ent；删除 observability-setup |
| clean-architecture-principles | 2 | 1 | 合并为一份 |
| cloudevents-pattern | 2 | 1 | 合并为一份 |

总计：20+ 份 → 9 份

每个 SKILL.md 从 ~200 行精简到 ~80 行：保留触发短语和关键概念速查表，去掉大段解释性文字。

## 七、文档精简

| 文件 | 当前行数 | 目标行数 |
|------|---------|---------|
| README.md | 319 | ~80（只讲"这是什么、前置依赖、如何使用"）|
| TESTING.md | 414 | ~80（只讲"如何验证生成的项目"）|
| templates/README.md | 428 | 删除 |

## 八、实施顺序

```
阶段 1: 黄金参考实现
├── 手写一个完整可运行的 Go DDD 项目（不带模板语法）
├── 包含 User CRUD 全链路（HTTP → Application → Domain → Infra → DB）
├── go build / go test / 启动服务 / curl 测试全部通过
└── 这就是"真理来源"

阶段 2: 提取模板
├── 将参考实现中的具体值替换为 {{.variable}}
├── 每替换一步都用 scaffold CLI 生成并验证
└── 确保模板输出 === 参考实现

阶段 3: 工具链
├── 编写 tools/scaffold/main.go
├── 精简 scripts/generate.sh
└── 端到端测试: generate.sh → 生成项目 → go build → go test

阶段 4: 插件收尾
├── 精简 skills 和参考文档
├── 精简 README.md / TESTING.md
├── 更新 commands/init-go-web.md
└── 最终验证
```

## 九、验收标准

以下全部通过才算完成：

1. `generate.sh` 生成的 MySQL 项目：`go build ./...` 通过
2. `generate.sh` 生成的 SQLite 项目：`go build ./...` 通过
3. `include_examples=yes` 时：User CRUD HTTP 接口可用
4. `include_examples=no` 时：空骨架项目可编译启动
5. `go test ./...` 全部通过
6. `docker-compose up` 可启动服务（MySQL 配置）
