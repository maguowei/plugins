# Go 项目目录结构

## golang-standards/project-layout

Go 社区广泛采用的项目目录结构标准,适用于中大型项目。

**项目地址**: https://github.com/golang-standards/project-layout

**核心原则**:
- 清晰的关注点分离
- 标准化的目录命名
- 易于理解和维护
- 支持大规模项目

## 标准目录结构

```
myproject/
├── cmd/                    # 主应用程序
│   └── server/
│       └── main.go
├── internal/               # 私有应用代码
│   ├── app/                # 应用业务代码
│   │   ├── domain/         # 领域层
│   │   ├── application/    # 应用层
│   │   ├── infrastructure/ # 基础设施层
│   │   └── interface/      # 接口层
│   └── ent/                # Ent 生成的代码 (和 app 平级)
├── pkg/                    # 公共库代码
├── api/                    # API 定义
├── configs/                # 配置文件
├── scripts/                # 脚本
├── build/                  # 打包和 CI
├── deployments/            # 部署配置
├── test/                   # 额外测试
├── docs/                   # 文档
├── tools/                  # 工具
├── vendor/                 # 依赖 (可选)
├── go.mod
├── go.sum
└── README.md
```

## 核心目录详解

### /cmd

**用途**: 项目的主要应用程序

```
cmd/
├── server/          # HTTP/gRPC 服务器
│   └── main.go
├── worker/          # 后台任务处理器
│   └── main.go
└── migration/       # 数据库迁移工具
    └── main.go
```

**最佳实践**:
- 每个应用一个子目录
- main.go 保持简洁 (< 100 行)
- 主要逻辑放在 `/internal` 或 `/pkg`
- 可执行文件名与目录名一致

**示例 main.go**:
```go
// cmd/server/main.go
package main

import (
    "log"
    "myproject/internal/app"
)

func main() {
    // 加载配置
    cfg := app.LoadConfig()

    // 初始化应用
    application, err := app.InitializeApp(cfg)
    if err != nil {
        log.Fatal(err)
    }

    // 运行应用
    if err := application.Run(); err != nil {
        log.Fatal(err)
    }
}
```

### /internal

**用途**: 私有应用和库代码

**Go 编译器特性**: `/internal` 目录中的代码只能被同一模块导入,不能被外部项目使用

```
internal/
├── app/                     # 应用业务代码
│   ├── domain/              # 领域层
│   │   └── user/
│   │       ├── entity/      # 实体
│   │       ├── valueobject/ # 值对象
│   │       ├── event/       # 领域事件
│   │       └── repository/  # 仓储接口
│   ├── application/         # 应用层
│   │   ├── service/         # 应用服务
│   │   └── dto/             # 数据传输对象
│   ├── infrastructure/      # 基础设施层
│   │   ├── repository/      # 仓储实现
│   │   ├── cache/           # 缓存
│   │   └── messaging/       # 消息队列
│   └── interface/           # 接口层
│       ├── http/            # HTTP 接口
│       └── grpc/            # gRPC 接口
└── ent/                     # Ent 生成的代码 (和 app 平级)
    ├── schema/              # Schema 定义
    ├── user.go              # 生成的 User 代码
    └── ...                  # 其他生成的代码
```

**最佳实践**:
- 按 DDD 分层组织 `/internal/app`
- Ent 生成的代码独立放在 `/internal/ent`
- 领域相关代码聚合在一起
- 明确依赖方向 (从外到内)

### /pkg

**用途**: 可被外部应用使用的库代码

```
pkg/
├── logger/          # 日志工具
├── config/          # 配置加载
├── validator/       # 验证器
└── utils/           # 通用工具
```

**使用场景**:
- 通用工具函数
- 可复用的组件
- 可能被其他项目导入的代码

**⚠️ 注意**: 只有确定代码会被外部使用时才放入 `/pkg`

### /api

**用途**: API 定义文件

```
api/
├── openapi/         # OpenAPI/Swagger 定义
│   └── api.yaml
├── proto/           # Protocol Buffer 定义
│   └── user.proto
└── graphql/         # GraphQL Schema
    └── schema.graphql
```

**最佳实践**:
- API 优先设计 (API First)
- 版本化 API 定义
- 生成代码放在 `/internal` 或 `/pkg`

### /configs

**用途**: 配置文件模板

```
configs/
├── config.yaml           # 默认配置
├── config.dev.yaml       # 开发环境
├── config.prod.yaml      # 生产环境
└── config.test.yaml      # 测试环境
```

**最佳实践**:
- 不提交敏感信息 (使用环境变量)
- 提供配置模板和示例
- 支持多环境配置

### /scripts

**用途**: 构建、安装、分析等脚本

```
scripts/
├── build.sh         # 构建脚本
├── test.sh          # 测试脚本
├── lint.sh          # 代码检查
└── migrate.sh       # 数据库迁移
```

### /build

**用途**: 打包和持续集成

```
build/
├── ci/              # CI 配置
│   └── .gitlab-ci.yml
├── package/         # 打包配置
│   └── Dockerfile
└── release/         # 发布脚本
```

### /deployments

**用途**: 部署配置和模板

```
deployments/
├── docker-compose.yml
├── kubernetes/
│   ├── deployment.yaml
│   └── service.yaml
└── terraform/
```

## DDD 分层目录组织

### Domain Layer (领域层)

```
internal/app/domain/
├── user/                    # User 聚合
│   ├── entity/
│   │   └── user.go         # User 实体
│   ├── valueobject/
│   │   ├── email.go        # Email 值对象
│   │   └── user_status.go  # 用户状态
│   ├── event/
│   │   └── user_events.go  # 用户领域事件
│   ├── repository/
│   │   └── user_repository.go  # 仓储接口
│   └── service/
│       └── user_domain_service.go  # 领域服务
└── order/                   # Order 聚合
    ├── entity/
    │   ├── order.go
    │   └── order_item.go
    ├── valueobject/
    │   └── money.go
    └── repository/
        └── order_repository.go
```

### Application Layer (应用层)

```
internal/app/application/
├── service/
│   ├── user_application_service.go
│   └── order_application_service.go
└── dto/
    ├── user_dto.go
    └── order_dto.go
```

### Infrastructure Layer (基础设施层)

```
internal/app/infrastructure/
├── repository/
│   ├── user_repository_impl.go   # 使用 internal/ent
│   └── order_repository_impl.go
├── cache/
│   └── redis_client.go
└── messaging/
    └── kafka_producer.go
```

### Ent Layer (Ent 生成的代码)

```
internal/ent/                # 和 app 平级
├── schema/
│   ├── user.go             # User Schema 定义
│   └── order.go            # Order Schema 定义
├── user.go                 # 生成的 User 代码
├── order.go                # 生成的 Order 代码
├── user_create.go          # 生成的创建代码
├── user_query.go           # 生成的查询代码
└── ...                     # 其他生成的代码
```

### Interface Layer (接口层)

```
internal/app/interface/
├── http/
│   ├── handler/
│   │   ├── user_handler.go
│   │   └── order_handler.go
│   ├── middleware/
│   │   ├── auth.go
│   │   └── logger.go
│   └── router.go
└── grpc/
    ├── server/
    └── pb/                  # protobuf 生成的代码
```

## 测试目录组织

### 单元测试 (同目录)

```go
// internal/app/domain/user/entity/user_test.go
package entity_test

import "testing"

func TestUser_ChangeName(t *testing.T) {
    // 单元测试
}
```

### 集成测试 (/test)

```
test/
├── integration/
│   ├── user_repository_test.go
│   └── order_service_test.go
└── e2e/
    └── user_flow_test.go
```

## 完整项目示例

```
myproject/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── app/                         # 业务代码
│   │   ├── domain/
│   │   │   ├── user/
│   │   │   │   ├── entity/
│   │   │   │   ├── valueobject/
│   │   │   │   ├── event/
│   │   │   │   ├── repository/
│   │   │   │   └── service/
│   │   │   └── order/
│   │   ├── application/
│   │   │   ├── service/
│   │   │   └── dto/
│   │   ├── infrastructure/
│   │   │   ├── repository/          # 使用 internal/ent
│   │   │   ├── cache/
│   │   │   └── messaging/
│   │   └── interface/
│   │       ├── http/
│   │       └── grpc/
│   └── ent/                         # Ent 生成的代码 (和 app 平级)
│       ├── schema/
│       │   ├── user.go
│       │   └── order.go
│       └── ...
├── pkg/
│   ├── logger/
│   ├── config/
│   └── validator/
├── api/
│   ├── openapi/
│   └── proto/
├── configs/
├── scripts/
├── build/
├── deployments/
├── test/
├── docs/
├── go.mod
├── go.sum
└── README.md
```

## 最佳实践

### ✅ 推荐做法

1. **遵循标准布局**: 使用 golang-standards/project-layout
2. **按层级组织**: Domain → Application → Infrastructure → Interface
3. **Ent 独立目录**: `/internal/ent` 和 `/internal/app` 平级
4. **聚合内聚**: 相关文件放在同一个聚合目录下
5. **测试就近**: 单元测试放在被测试代码同目录
6. **接口在领域**: Repository 接口定义在 Domain Layer

### ❌ 避免做法

1. **避免 `/src` 目录**: Go 项目不需要 src 目录
2. **避免过深嵌套**: 目录层级不超过 4-5 层
3. **避免循环依赖**: 明确依赖方向 (外层依赖内层)
4. **避免混放生成代码**: Ent 生成的代码单独放在 `/internal/ent`

## 总结

Go 项目目录组织的关键实践:
- ✅ 遵循 golang-standards/project-layout
- ✅ `/cmd` 放可执行程序入口
- ✅ `/internal` 放私有代码
- ✅ `/internal/app` 按 DDD 分层组织
- ✅ `/internal/ent` 放 Ent 生成的代码 (和 app 平级)
- ✅ `/pkg` 放可复用库 (谨慎使用)
- ✅ 按聚合组织领域代码
- ✅ 测试文件就近放置
- ✅ 配置、脚本、文档分离
