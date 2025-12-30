---
name: Go Project Structure
description: This skill should be used when the user asks about "Go project structure", "golang-standards/project-layout", "Go directory layout", "cmd directory", "internal directory", "pkg directory", "how to organize Go project", or needs guidance on structuring a Go application following standard conventions.
version: 0.1.0
---

# Go 标准项目布局 (Go Standard Project Layout)

## 概述

遵循 golang-standards/project-layout 规范组织 Go 项目,确保项目结构清晰、易于维护。本技能详细说明各目录的用途和最佳实践。

## 标准目录结构

```
project-root/
├── cmd/                  # 应用程序入口
│   ├── server/          # HTTP 服务器
│   │   └── main.go
│   └── migrate/         # 数据库迁移工具
│       └── main.go
├── internal/            # 私有应用代码
│   ├── app/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── interface/
│   └── ent/            # Ent Schema（私有）
│       └── schema/
├── api/                 # API 定义
│   └── openapi.yaml    # OpenAPI 规范
├── configs/             # 配置文件
│   └── config.yaml
├── test/                # 额外的测试应用和测试数据
├── docs/                # 设计和用户文档
├── scripts/             # 构建、安装、分析等脚本
├── deployments/         # 部署配置
│   ├── docker/
│   └── k8s/
├── go.mod
├── go.sum
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## 核心目录详解

### /cmd

**用途**: 项目的主要应用程序入口。

**规则**:
- 每个应用一个子目录
- 目录名应匹配可执行文件名
- main.go 保持精简,只做初始化
- 业务逻辑放在 /internal

**示例**:

```go
// cmd/server/main.go
package main

import (
    "log"
    "myproject/internal/app/interface/http"
    "myproject/internal/app/infrastructure/config"
)

func main() {
    // 加载配置
    cfg, err := config.Load()
    if err != nil {
        log.Fatal(err)
    }

    // 初始化依赖
    handler := InitializeHandler(cfg)

    // 启动服务器
    router := http.NewRouter(handler)
    router.Run(cfg.Server.Port)
}
```

### /internal

**用途**: 私有应用和库代码,不对外暴露。

**规则**:
- Go 编译器强制执行私有性
- 其他项目无法导入 internal/ 下的包
- 核心业务逻辑放这里

**DDD 组织方式**:

```
internal/
├── app/
│   ├── domain/          # 领域层
│   │   └── user/
│   │       ├── entity/
│   │       ├── valueobject/
│   │       ├── event/
│   │       ├── repository/
│   │       └── service/
│   ├── application/     # 应用层
│   │   ├── service/
│   │   └── dto/
│   ├── infrastructure/  # 基础设施层
│   │   ├── repository/
│   │   ├── config/
│   │   ├── external/
│   │   └── observability/
│   └── interface/       # 接口层
│       └── http/
│           ├── handler/
│           ├── dto/
│           ├── middleware/
│           └── router.go
└── ent/                 # Ent Schema（私有）
    └── schema/
```

### /pkg

**用途**: 可以被外部应用使用的库代码。

**规则**:
- 明确表示代码可对外使用
- 需要维护稳定的 API
- 示例: 工具函数, 常量定义

**示例**:

```
pkg/
├── constants/        # 常量
│   └── status.go
└── errors/           # 错误定义
    └── errors.go
```

**注意**: Ent schema 不应放在 pkg/ 下，应放在 internal/ent/schema/

### /api

**用途**: OpenAPI/Swagger 规范、Protocol Buffers 定义。

**示例**:

```
api/
├── openapi.yaml      # OpenAPI 3.1 规范
├── proto/            # gRPC 定义 (如果使用)
│   └── user.proto
└── swagger/          # Swagger UI 资源
```

### /configs

**用途**: 配置文件模板或默认配置。

**规则**:
- 提供配置模板
- 不包含敏感信息
- 敏感配置通过环境变量

**示例**:

```yaml
# configs/config.yaml
server:
  port: 8080
  mode: debug

database:
  driver: mysql
  dsn: "${DATABASE_DSN}"  # 从环境变量读取

sentry:
  dsn: "${SENTRY_DSN}"
```

### /scripts

**用途**: 构建、安装、分析、部署等脚本。

**示例**:

```bash
# scripts/build.sh
#!/bin/bash
go build -o bin/server ./cmd/server

# scripts/migrate.sh
#!/bin/bash
go run ./cmd/migrate up

# scripts/lint.sh
#!/bin/bash
golangci-lint run
```

### /deployments

**用途**: IaaS、PaaS、容器编排部署配置。

**示例**:

```
deployments/
├── docker/
│   ├── Dockerfile.prod
│   └── Dockerfile.dev
└── k8s/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

### /test

**用途**: 额外的外部测试应用和测试数据。

**规则**:
- 单元测试放在对应包的 _test.go 文件
- 集成测试、E2E 测试放这里

**示例**:

```
test/
├── integration/
│   └── user_test.go
├── e2e/
│   └── api_test.go
└── testdata/
    └── fixtures.json
```

### /docs

**用途**: 设计文档和用户文档。

**示例**:

```
docs/
├── architecture.md   # 架构设计
├── development.md    # 开发指南
├── deployment.md     # 部署文档
└── api.md           # API 文档
```

## 不应该有的目录

❌ `/src` - Go 项目不需要 src 目录
❌ `/models` - 领域模型应在 /internal/app/domain
❌ `/controllers` - 应使用 /internal/app/interface/http/handler
❌ `/lib` - 使用 /pkg 或 /internal

## 文件命名规范

**Go 文件**:
- 使用小写 + 下划线: `user_service.go`
- 测试文件: `user_service_test.go`
- 避免驼峰命名

**目录**:
- 使用小写单数: `user` 不是 `users`
- DDD 概念除外: `entity`, `valueobject`, `repository`

## 依赖管理

### go.mod

```go
module github.com/myorg/myproject

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    entgo.io/ent v0.12.4
    github.com/spf13/viper v1.16.0
)
```

### 版本固定

使用 `go.sum` 锁定依赖版本,确保构建可重现。

## 完整示例

实际 Go Web 项目结构:

```
my-service/
├── cmd/
│   ├── server/
│   │   └── main.go
│   └── migrate/
│       └── main.go
├── internal/
│   ├── app/
│   │   ├── domain/
│   │   │   └── user/
│   │   │       ├── entity/
│   │   │       │   ├── user.go
│   │   │       │   └── user_test.go
│   │   │       ├── valueobject/
│   │   │       │   ├── email.go
│   │   │       │   └── email_test.go
│   │   │       ├── repository/
│   │   │       │   └── user_repository.go
│   │   │       └── service/
│   │   │           └── user_service.go
│   │   ├── application/
│   │   │   └── service/
│   │   │       ├── user_application_service.go
│   │   │       └── user_application_service_test.go
│   │   ├── infrastructure/
│   │   │   ├── repository/
│   │   │   │   └── user_repository_impl.go
│   │   │   ├── config/
│   │   │   │   └── config.go
│   │   │   └── observability/
│   │   │       ├── logger.go
│   │   │       └── metrics.go
│   │   └── interface/
│   │       └── http/
│   │           ├── handler/
│   │           │   └── user_handler.go
│   │           ├── middleware/
│   │           │   └── auth.go
│   │           └── router.go
│   └── ent/
│       └── schema/
│           └── user.go
├── api/
│   └── openapi.yaml
├── configs/
│   └── config.yaml
├── test/
│   └── integration/
│       └── user_test.go
├── docs/
│   ├── architecture.md
│   └── development.md
├── scripts/
│   ├── build.sh
│   └── migrate.sh
├── deployments/
│   ├── docker/
│   │   └── Dockerfile
│   └── k8s/
│       └── deployment.yaml
├── go.mod
├── go.sum
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## 最佳实践

1. **保持 cmd/ 精简**: main.go 只做初始化,业务逻辑在 internal/
2. **使用 internal/**: 私有代码不暴露给外部
3. **明智使用 pkg/**: 只有确定对外暴露的代码放这里
4. **按领域组织**: internal/ 下按 DDD 聚合组织
5. **测试就近**: 单元测试与代码在同一目录
6. **文档化**: 提供 README 和 docs/

## 总结

标准项目布局的优势:
- ✅ 清晰的代码组织
- ✅ 明确的公私边界 (internal vs pkg)
- ✅ 符合 Go 社区规范
- ✅ 易于新成员理解
- ✅ 支持大型项目扩展

## 额外资源

详细指南参见:
- **`references/directory-purposes.md`** - 各目录详细用途
- **`references/naming-conventions.md`** - 命名规范
- **`examples/full-project/`** - 完整项目示例
