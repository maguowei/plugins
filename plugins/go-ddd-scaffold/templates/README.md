# Go DDD Scaffold 模板系统文档

## 概述

go-ddd-scaffold 插件采用**模板驱动架构**，通过 45+ 个专业模板文件生成符合 DDD 四层架构和 Clean Architecture 原则的 Go Web 项目。

### 核心优势

- ✅ **可维护性**: 从 580 行硬编码 Agent 简化到 282 行 + 45 个清晰的模板文件
- ✅ **一致性**: 所有生成的代码遵循统一的模式和最佳实践
- ✅ **可扩展性**: 轻松添加新的聚合、数据库、中间件
- ✅ **质量保证**: 模板经过精心设计，包含完整的注释和错误处理

## 目录结构

```
templates/
├── vars/                          # 变量配置目录
│   ├── default.yaml               # 默认变量（项目、路径、技术栈）
│   ├── db_mysql.yaml              # MySQL 特定变量
│   ├── db_sqlite.yaml             # SQLite 特定变量
│   └── aggregates/
│       └── user.yaml              # User 聚合完整配置
│
├── base/                          # 基础模板（Batch 1）
│   ├── _manifest.yaml             # 生成清单
│   ├── gitignore.tpl
│   ├── go_mod.tpl
│   ├── README.tpl
│   └── Makefile.tpl
│
├── domain/                        # 领域层模板（Batch 2）
│   ├── _manifest.yaml
│   ├── entity/                    # Entity 模板
│   ├── valueobject/               # Value Object 模板
│   ├── event/                     # Domain Event 模板
│   ├── repository/                # Repository 接口模板
│   └── service/                   # Domain Service 模板
│
├── application/                   # 应用层模板（Batch 3）
│   ├── _manifest.yaml
│   ├── service/                   # Application Service 模板
│   └── dto/                       # DTO 模板
│
├── infrastructure/                # 基础设施层模板（Batch 4）
│   ├── _manifest.yaml
│   ├── repository/                # Repository 实现模板
│   ├── config/                    # Config 模板
│   ├── observability/             # 可观测性模板（Logger, Metrics, Sentry）
│   └── event/                     # Event Bus 模板
│
├── interface/                     # 接口层模板（Batch 5）
│   ├── _manifest.yaml
│   └── http/
│       ├── handler/               # HTTP Handler 模板
│       ├── dto/                   # HTTP DTO 模板
│       ├── middleware/            # Middleware 模板
│       └── router.go.tpl          # Router 模板
│
├── ent/                           # Ent Schema 模板（Batch 6）
│   ├── _manifest.yaml
│   └── schema/
│       └── schema.go.tpl
│
├── cmd/                           # 命令行入口模板（Batch 6）
│   ├── _manifest.yaml
│   ├── server_main.go.tpl         # 服务器入口
│   └── migrate_main.go.tpl        # 迁移入口
│
├── configs/                       # 配置文件模板（Batch 7）
│   ├── _manifest.yaml
│   └── config.yaml.tpl
│
├── docker/                        # Docker 模板（Batch 7）
│   ├── _manifest.yaml
│   ├── Dockerfile.tpl
│   └── docker_compose.yaml.tpl
│
├── docs/                          # 文档模板（Batch 8）
│   ├── _manifest.yaml
│   ├── architecture.md.tpl
│   ├── development.md.tpl
│   └── deployment.md.tpl
│
├── api/                           # API 文档模板（Batch 8）
│   ├── _manifest.yaml
│   └── openapi.yaml.tpl
│
└── scripts/                       # 脚本模板（Batch 8）
    ├── _manifest.yaml
    ├── build.sh.tpl
    ├── migrate.sh.tpl
    └── lint.sh.tpl
```

## 变量系统

### 变量合并策略

Agent 按以下顺序读取并合并变量：
1. `vars/default.yaml` - 基础变量
2. `vars/db_${database}.yaml` - 数据库特定变量
3. `vars/aggregates/user.yaml` - 聚合配置（如果 `include_examples=yes`）

### 变量结构示例

**default.yaml**:
```yaml
project:
  name: ""                    # 从参数获取
  go_module: ""               # 从参数获取
  database: "mysql"           # 从参数获取
  include_examples: true      # 从参数获取

go:
  version: "1.21"
  dependencies:
    - {name: "github.com/gin-gonic/gin", version: "latest"}
    - {name: "entgo.io/ent", version: "latest"}

paths:                        # DDD 四层路径约束
  domain: "internal/app/domain"
  application: "internal/app/application"
  infrastructure: "internal/app/infrastructure"
  interface: "internal/app/interface"
  ent_schema: "internal/ent/schema"

server:
  port: "8080"
  mode: "debug"
```

**db_mysql.yaml**:
```yaml
database:
  driver: "mysql"
  dsn: "root:password@tcp(localhost:3306)/dbname?parseTime=true"
  max_open_conns: 25
  max_idle_conns: 25
```

**aggregates/user.yaml**:
```yaml
aggregate:
  name: "user"
  name_pascal: "User"

entity:
  name: "User"
  fields:
    - {name: "email", type: "valueobject.Email", comment: "用户邮箱"}
    - {name: "name", type: "string", comment: "用户名称"}

events:
  - name: "UserCreated"
    cloud_event_type: "com.example.user.created"
```

## 模板语法

模板使用 Go `text/template` 标准语法：

### 基本变量

```go
// 简单变量
{{ .ProjectName }}
{{ .GoModule }}

// 嵌套变量
{{ .Paths.Domain }}
{{ .Server.Port }}
```

### 条件语句

```go
{{- if .IncludeExamples }}
// 只在包含示例时生成
{{ end }}

{{- if eq .Database.Driver "mysql" }}
// MySQL 特定代码
{{- else if eq .Database.Driver "sqlite3" }}
// SQLite 特定代码
{{- end }}
```

### 循环

```go
{{- range .Entity.Fields }}
{{ .Name }} {{ .Type }} `json:"{{ .JSONTag }}"` // {{ .Comment }}
{{- end }}

{{- range .Go.Dependencies }}
go get -u {{ .Name }}
{{- end }}
```

### 完整示例

```go
package entity

import (
    "github.com/google/uuid"
    "{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/valueobject"
)

// {{ .Entity.Name }} {{ .Entity.NameCN }}实体
type {{ .Entity.Name }} struct {
    id        uuid.UUID
    {{- range .Entity.Fields }}
    {{ .Name }}  {{ .Type }}  // {{ .Comment }}
    {{- end }}
}

func New{{ .Entity.Name }}({{ range $i, $p := .ConstructorParams }}{{ if $i }}, {{ end }}{{ .Name }} {{ .Type }}{{ end }}) (*{{ .Entity.Name }}, error) {
    return &{{ .Entity.Name }}{
        id: uuid.New(),
        {{- range .Entity.Fields }}
        {{ .Name }}: {{ .Name }},
        {{- end }}
    }, nil
}
```

## Manifest 文件格式

每个模板目录都包含 `_manifest.yaml`，定义生成规则：

```yaml
# 基本信息
name: "Domain Layer"
description: "领域层模板"
output_base: "{{ .Paths.Domain }}"
batch: 2

# 文件列表
files:
  - template: "entity/entity.go.tpl"
    output: "{{ .AggregateName }}/entity/{{ .EntityFileName }}.go"
    description: "Entity for {{ .EntityNameCN }}"
    condition: "{{ .IncludeExamples }}"

  - template: "valueobject/email.go.tpl"
    output: "{{ .AggregateName }}/valueobject/email.go"
    description: "Email Value Object"
    condition: "{{ and .IncludeExamples (eq .AggregateName \"user\") }}"
```

### 字段说明

- **name**: 清单名称
- **output_base**: 输出基础路径（支持变量）
- **batch**: 批次编号（1-8）
- **files**: 文件列表
  - **template**: 模板文件路径（相对于当前目录）
  - **output**: 输出文件路径（支持变量）
  - **description**: 文件描述
  - **condition**: 生成条件（可选，Go template 条件表达式）

## 添加新模板

### 1. 为新聚合添加模板

假设要添加 `Product` 聚合：

**步骤 1**: 创建聚合配置
```bash
cp templates/vars/aggregates/user.yaml templates/vars/aggregates/product.yaml
```

编辑 `product.yaml`：
```yaml
aggregate:
  name: "product"
  name_pascal: "Product"

entity:
  name: "Product"
  fields:
    - {name: "name", type: "string", comment: "产品名称"}
    - {name: "price", type: "float64", comment: "产品价格"}
```

**步骤 2**: 模板自动支持
现有的模板文件会自动使用新的变量配置生成 Product 聚合的代码。

### 2. 添加新的数据库支持

假设要添加 PostgreSQL 支持：

**步骤 1**: 创建数据库配置
```bash
# templates/vars/db_postgres.yaml
database:
  driver: "postgres"
  dsn: "host=localhost user=postgres password=password dbname=mydb sslmode=disable"
  max_open_conns: 25
  max_idle_conns: 25
```

**步骤 2**: 更新相关模板
在需要区分数据库的模板中添加条件判断：
```go
{{- if eq .Database.Driver "postgres" }}
// PostgreSQL 特定代码
{{- end }}
```

### 3. 添加新的中间件模板

**步骤 1**: 创建模板文件
```bash
# templates/interface/http/middleware/auth.go.tpl
package middleware

import "github.com/gin-gonic/gin"

// Auth 认证中间件
func Auth() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 认证逻辑
        c.Next()
    }
}
```

**步骤 2**: 更新 Manifest
编辑 `templates/interface/_manifest.yaml`：
```yaml
files:
  # ... 其他文件 ...

  - template: "http/middleware/auth.go.tpl"
    output: "http/middleware/auth.go"
    description: "Authentication middleware"
```

## 最佳实践

### 模板编写规范

1. **注释清晰**: 每个模板文件顶部添加用途说明
2. **变量命名**: 使用有意义的变量名，遵循 Go 命名规范
3. **格式化**: 生成的代码应符合 `gofmt` 标准
4. **错误处理**: 包含适当的错误处理逻辑
5. **类型安全**: 使用强类型，避免 `interface{}`

### 变量设计原则

1. **层次清晰**: 使用嵌套结构组织变量（如 `Paths.Domain`）
2. **避免重复**: 相同的配置应该复用
3. **易于扩展**: 设计时考虑未来可能的扩展
4. **类型明确**: 在 YAML 中使用明确的类型

### Manifest 设计原则

1. **批次合理**: 每个批次 8-12 个文件，避免 token 溢出
2. **条件明确**: 使用清晰的条件表达式
3. **路径正确**: 确保输出路径符合 DDD 约束
4. **描述完整**: 为每个文件提供清晰的描述

## 调试技巧

### 验证变量合并

在 Agent 中添加日志输出，查看合并后的变量：
```
1. 读取 default.yaml
2. 读取 db_${database}.yaml
3. 读取 aggregates/user.yaml
4. 打印合并后的数据结构
```

### 验证模板渲染

单独测试模板渲染：
```bash
# 使用 Go text/template 工具测试
go run test_template.go entity.go.tpl vars.yaml
```

### 检查输出路径

确保所有生成的文件路径符合约束：
- ✅ `internal/app/domain/...`
- ✅ `internal/app/application/...`
- ❌ `internal/domain/...` （缺少 app 层）

## 故障排除

### 常见问题

**问题 1**: 模板渲染失败
- **原因**: 变量缺失或类型不匹配
- **解决**: 检查变量配置，确保所有必需变量都已定义

**问题 2**: 生成的代码路径错误
- **原因**: output_base 或 output 路径配置错误
- **解决**: 检查 _manifest.yaml 中的路径配置

**问题 3**: 条件判断不生效
- **原因**: condition 表达式语法错误
- **解决**: 使用正确的 Go template 条件语法

## 贡献指南

欢迎贡献新的模板！请遵循以下步骤：

1. Fork 项目仓库
2. 在 `templates/` 目录下添加新模板
3. 更新相应的 `_manifest.yaml`
4. 测试模板生成
5. 提交 Pull Request

## 参考资源

- [Go text/template 文档](https://pkg.go.dev/text/template)
- [DDD 参考架构](./docs/architecture.md)
- [Go 项目布局标准](https://github.com/golang-standards/project-layout)
- [Clean Architecture 原则](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

**通过模板驱动，确保每个生成的项目都遵循最佳实践！** 🚀
