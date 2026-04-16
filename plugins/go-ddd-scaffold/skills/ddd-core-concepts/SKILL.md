---
name: DDD Core Concepts
description: 用户问"什么是实体"、"值对象怎么设计"、"聚合根是什么"、"仓储模式怎么用"、"领域服务和应用服务有什么区别"、"领域事件怎么定义"时触发。涵盖 DDD 六大构建块在 Go 中的实现模式。
version: 0.3.0
---

# DDD 核心概念

## 六大构建块速查

| 构建块 | 定义 | 关键特征 |
|--------|------|----------|
| Entity | 有唯一标识和生命周期 | 私有字段 + Getter，业务方法变更状态 |
| Value Object | 无 ID，基于值相等，不可变 | 构造函数验证，操作返回新对象 |
| Aggregate Root | 一致性边界的守护者 | 唯一入口，一个事务只改一个聚合 |
| Repository | 聚合根的持久化接口 | 接口在 Domain 层，实现在 Infrastructure 层 |
| Domain Service | 跨实体的无状态业务逻辑 | 不包含应用编排逻辑 |
| Domain Event | 领域中已发生的事件 | 过去时命名，不可变 |

## Entity vs Value Object

| 判断标准 | Entity | Value Object |
|---------|--------|-------------|
| 唯一标识 | 有 ID | 无 ID |
| 可变性 | 可变 | 不可变 |
| 相等性 | 基于 ID | 基于属性值 |
| 举例 | User, Order | Email, Money, Address |

## Domain Service 要点

**使用场景**: 操作跨越多个聚合、业务逻辑不属于任何单一实体、需要多个仓储协作。

| 对比 | Domain Service | Application Service |
|------|---------------|-------------------|
| 位置 | Domain Layer | Application Layer |
| 状态 | 无状态 | 可有状态 |
| 事务 | 不管理 | 管理事务 |
| DTO | 不使用 | 使用 DTO |

```go
// Domain Service: 跨实体的业务逻辑
type TransferDomainService struct {
    accountRepo repository.AccountRepository
}

func (s *TransferDomainService) Transfer(
    ctx context.Context, from, to *entity.Account, amount valueobject.Money,
) error {
    if from.Balance().LessThan(amount) { return errors.New("insufficient balance") }
    from.Debit(amount)
    to.Credit(amount)
    return nil
}
```

## 概念关系图

```
Aggregate (聚合)
  Aggregate Root (聚合根/入口实体)
    ├── Entity (聚合内实体)
    ├── Value Object (值对象)
    └── Domain Event (领域事件)

Repository (仓储接口)    Domain Service (领域服务)
  - 只为聚合根创建          - 跨实体逻辑
```

## 常见陷阱

1. **贫血模型**: 实体只有 getter/setter -> 将业务逻辑封装在实体方法中
2. **过度使用领域服务**: 单实体操作应在实体方法中
3. **值对象可变**: 提供 setter -> 值对象必须不可变
4. **聚合过大**: 包含过多实体 -> 重新划分聚合边界
5. **跨聚合事务**: 一个事务修改多个聚合 -> 使用领域事件实现最终一致性

## 参考文档

- `references/core-building-blocks.md` -- Entity、Value Object、Aggregate 的详细模式和代码示例
- `references/repository-patterns.md` -- Repository 接口设计、实现策略、性能优化
- `references/domain-events.md` -- 领域事件定义、发布订阅、Event Sourcing
