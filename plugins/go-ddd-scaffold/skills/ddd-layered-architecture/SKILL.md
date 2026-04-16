---
name: DDD Layered Architecture
description: 用户问"代码该放哪一层"、"层之间怎么调用"、"DDD 四层架构是什么"、"Application Service 和 Domain Service 区别"、"接口层怎么写"、"依赖倒置怎么实现"时触发。涵盖 DDD 四层的职责、依赖规则和层间交互。
version: 0.3.0
---

# DDD 四层架构

## 架构总览

```
Interface Layer   -- HTTP Handler, gRPC, DTO, 中间件
Application Layer -- 用例编排, 事务管理, DTO 转换
Domain Layer      -- Entity, VO, Domain Service, Repo 接口, Event
Infrastructure    -- Repo 实现 (Ent), 外部服务, 配置, 可观测性
```

## 依赖规则

```
Interface -> Application -> Domain <- Infrastructure
```

- Domain Layer **不依赖**任何其他层
- Infrastructure 实现 Domain 定义的接口 (依赖倒置)

## 各层职责速查

| 层 | 职责 | 禁止 |
|---|------|------|
| Domain | 业务规则、领域模型、仓储接口 | 框架依赖、HTTP/DB 代码 |
| Application | 用例编排、事务、DTO 转换、事件发布 | 业务逻辑、直接操作数据库 |
| Infrastructure | ORM 实现、外部服务、缓存、可观测性 | 业务逻辑 |
| Interface | 协议处理、参数验证、路由、中间件 | 业务逻辑 |

## Application Service vs Domain Service

| 对比项 | Application Service | Domain Service |
|--------|-------------------|----------------|
| 职责 | 编排用例 | 纯业务逻辑 |
| 事务 | 控制事务 | 不控制事务 |
| DTO | 做 DTO 转换 | 不做 DTO 转换 |
| 依赖 | 可调用多个 Repo/Service | 只依赖 Repo 接口 |

## 层间交互流程

```
HTTP Request -> Handler -> Application Service -> Domain Entity/Service
                                  |
                           Infrastructure (Repository)
                                  |
HTTP Response <- Handler <- Application (DTO 转换)
```

## 依赖注入

```go
func InitializeUserHandler(db *ent.Client) *handler.UserHandler {
    userRepo := repository.NewEntUserRepository(db)
    domainSvc := service.NewUserAuthService(userRepo)
    appSvc := application.NewUserApplicationService(userRepo, domainSvc)
    return handler.NewUserHandler(appSvc)
}
```

## 测试策略

| 层 | 测试类型 | 外部依赖 |
|---|---------|---------|
| Domain | 纯单元测试 | 无 |
| Application | Mock Repository | 无 |
| Infrastructure | 集成测试 | 数据库 |
| Interface | httptest | Mock Service |

## 参考文档

- `references/layered-architecture-guide.md` -- 四层的详细目录结构、代码示例、DTO 设计、事务管理
- `references/dependency-injection.md` -- 手动 DI 实践、构造函数注入、完整 main.go 示例
