---
name: Clean Architecture Principles
description: 用户问"代码怎么解耦"、"怎么设计接口"、"SOLID 原则是什么"、"依赖倒置怎么做"、"单一职责怎么理解"、"Clean Architecture 和 DDD 什么关系"时触发。涵盖 SOLID 原则和整洁架构在 Go DDD 中的应用。
version: 0.3.0
---

# 整洁架构与 SOLID 原则

## SOLID 速查

| 原则 | 含义 | Go DDD 应用 |
|------|------|------------|
| SRP | 一个模块只有一个变化原因 | Entity 只含业务逻辑，Repository 只做持久化 |
| OCP | 对扩展开放，对修改关闭 | 使用接口扩展 (NotificationSender) |
| LSP | 子类型可替换父类型 | 任何 Repository 实现可互换 |
| ISP | 不依赖不需要的接口 | 小接口: Reader, Writer, Closer |
| DIP | 依赖抽象不依赖实现 | Domain 定义接口，Infrastructure 实现 |

## Clean Architecture 依赖规则

```
Interface -> Application -> Domain <- Infrastructure
```

- Domain 不依赖任何层，不依赖框架
- Infrastructure 实现 Domain 定义的接口 (DIP)

## 三大独立性

| 独立性 | 说明 |
|--------|------|
| 框架独立 | Domain 不依赖 Gin, Ent, Viper |
| 可测试 | Domain 无需数据库即可测试 |
| 数据库独立 | Repository 接口不暴露 DB 细节 |

## 各层约束

| 层 | 允许 | 禁止 |
|---|------|------|
| Domain | 纯 Go、业务规则 | 框架依赖、HTTP/DB 代码 |
| Application | 编排用例、事务管理 | 业务逻辑、直接操作 DB |
| Infrastructure | ORM 实现、外部服务 | 业务逻辑 |
| Interface | HTTP/gRPC、DTO 转换 | 业务逻辑 |

## DIP 示例

```go
// Domain 层定义接口
type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
}

// Infrastructure 层实现
type EntUserRepository struct { client *ent.Client }

// Application 层依赖接口
type UserApplicationService struct {
    repo domain.UserRepository  // 依赖抽象
}
```

## 常见陷阱

1. **Domain 依赖框架** -- Domain 只依赖标准库
2. **贫血模型** -- Entity 应包含业务行为
3. **绕过应用层** -- Handler 不应直接调用 Repository
4. **基础设施渗透** -- Domain 不返回 SQL 错误

## 参考文档

- `references/clean-architecture-and-solid.md` -- SOLID 五原则详解、Clean Architecture 四层实现、DTO 分层、事件驱动、测试策略
