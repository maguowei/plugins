---
name: Go Project Structure
description: 用户问"Go 项目怎么组织"、"目录该怎么命名"、"cmd 目录放什么"、"internal 和 pkg 有什么区别"、"Go 标准项目布局是什么"时触发。涵盖 golang-standards/project-layout 规范和 DDD 目录组织。
version: 0.2.0
---

# Go 标准项目布局 (Go Standard Project Layout)

## 概述

遵循 golang-standards/project-layout 规范组织 Go 项目,确保项目结构清晰、易于维护。

## 标准目录结构

```
project-root/
├── cmd/                  # 应用程序入口
│   ├── server/           # HTTP 服务器
│   │   └── main.go
│   └── migrate/          # 数据库迁移工具
│       └── main.go
├── internal/             # 私有应用代码
│   ├── app/
│   │   ├── domain/       # 领域层 (详见 ddd-layered-architecture)
│   │   ├── application/  # 应用层
│   │   ├── infrastructure/ # 基础设施层
│   │   └── interface/    # 接口层
│   └── ent/              # Ent Schema (私有)
│       └── schema/
├── api/                  # API 定义 (OpenAPI, Proto)
├── configs/              # 配置文件
├── test/                 # 集成测试和测试数据
├── docs/                 # 文档
├── scripts/              # 构建和部署脚本
├── deployments/          # 部署配置 (Docker, K8s)
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
- 每个应用一个子目录,目录名匹配可执行文件名
- main.go 保持精简,只做初始化
- 业务逻辑放在 /internal

```go
// cmd/server/main.go
package main

func main() {
    cfg, err := config.Load()
    if err != nil {
        log.Fatal(err)
    }
    handler := InitializeHandler(cfg)
    router := http.NewRouter(handler)
    router.Run(cfg.Server.Port)
}
```

### /internal

**用途**: 私有应用和库代码,Go 编译器强制执行私有性。

**DDD 组织方式**:

```
internal/app/
├── domain/              # 领域层
│   └── user/
│       ├── entity/
│       ├── valueobject/
│       ├── event/
│       ├── repository/  # 接口定义
│       └── service/
├── application/         # 应用层
│   ├── service/
│   └── dto/
├── infrastructure/      # 基础设施层
│   ├── repository/      # 接口实现
│   ├── config/
│   └── observability/
└── interface/           # 接口层
    └── http/
        ├── handler/
        ├── dto/
        ├── middleware/
        └── router.go
```

### /pkg

**用途**: 可以被外部应用使用的库代码。

- 明确表示代码可对外使用,需要维护稳定的 API
- 示例: 工具函数、常量定义、错误定义

### /api

**用途**: OpenAPI/Swagger 规范、Protocol Buffers 定义。

### /configs

**用途**: 配置文件模板或默认配置。不包含敏感信息,敏感配置通过环境变量。

```yaml
# configs/config.yaml
server:
  port: 8080
database:
  driver: mysql
  dsn: "${DATABASE_DSN}"
```

### /scripts

**用途**: 构建、安装、分析、部署等脚本。

### /deployments

**用途**: Docker、Kubernetes 等部署配置。

### /test

**用途**: 集成测试、E2E 测试和测试数据。单元测试放在对应包的 `_test.go` 文件。

### /docs

**用途**: 设计文档和用户文档。

## 不应该有的目录

| 错误做法 | 正确做法 |
|---------|---------|
| `/src` | Go 项目不需要 src 目录 |
| `/models` | 领域模型放在 `/internal/app/domain` |
| `/controllers` | 使用 `/internal/app/interface/http/handler` |
| `/lib` | 使用 `/pkg` 或 `/internal` |

## 文件命名规范

**Go 文件**: 使用小写 + 下划线 `user_service.go`，测试文件 `user_service_test.go`

**目录**: 使用小写单数 `user` (不是 `users`)。DDD 概念除外: `entity`, `valueobject`, `repository`

## 完整示例

```
my-service/
├── cmd/
│   ├── server/main.go
│   └── migrate/main.go
├── internal/
│   ├── app/
│   │   ├── domain/user/
│   │   │   ├── entity/user.go
│   │   │   ├── valueobject/email.go
│   │   │   ├── repository/user_repository.go
│   │   │   └── service/user_service.go
│   │   ├── application/service/user_application_service.go
│   │   ├── infrastructure/
│   │   │   ├── repository/user_repository_impl.go
│   │   │   ├── config/config.go
│   │   │   └── observability/logger.go
│   │   └── interface/http/
│   │       ├── handler/user_handler.go
│   │       ├── middleware/auth.go
│   │       └── router.go
│   └── ent/schema/user.go
├── api/openapi.yaml
├── configs/config.yaml
├── test/integration/user_test.go
├── docs/architecture.md
├── scripts/build.sh
├── deployments/docker/Dockerfile
├── go.mod
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## 最佳实践

1. **保持 cmd/ 精简**: main.go 只做初始化
2. **使用 internal/**: 私有代码不暴露给外部
3. **明智使用 pkg/**: 只有确定对外暴露的代码放这里
4. **按领域组织**: internal/ 下按 DDD 聚合组织
5. **测试就近**: 单元测试与代码在同一目录
