# 领域事件模式

## 概述

领域事件 (Domain Event) 表示领域中已发生的重要业务事实，不可变，使用过去时命名。

## 事件定义

```go
type DomainEvent interface {
    OccurredAt() time.Time
    EventType() string
    AggregateID() string
}

type UserCreated struct {
    userID     uuid.UUID
    email      string
    occurredAt time.Time
}
```

**命名规范**: `<聚合名><动作过去式>` -- `UserCreated`, `OrderSubmitted`, `PaymentCompleted`

## 事件收集与发布

### 实体内收集

```go
type User struct {
    id           uuid.UUID
    domainEvents []DomainEvent
}

func NewUser(email, name string) (*User, error) {
    user := &User{id: uuid.New(), ...}
    user.domainEvents = append(user.domainEvents, UserCreated{...})
    return user, nil
}

func (u *User) DomainEvents() []DomainEvent { return u.domainEvents }
func (u *User) ClearDomainEvents()           { u.domainEvents = nil }
```

### 应用层统一发布

```go
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) error {
    user, _ := entity.NewUser(email, name)
    s.userRepo.Save(ctx, user)                            // 持久化
    s.eventPublisher.PublishBatch(ctx, user.DomainEvents()) // 事务后发布
    user.ClearDomainEvents()
    return nil
}
```

**关键**: 在事务提交成功后发布事件，发布失败不阻止主流程。

## 事件总线

| 组件 | 职责 |
|------|------|
| EventPublisher | `Publish(event)`, `PublishBatch(events)` |
| EventSubscriber | `Subscribe(eventType, handler)` |
| EventBus | 同时实现发布和订阅 |

内存实现: `InMemoryEventBus` 使用 `map[string][]EventHandler` + `sync.RWMutex`。

## 事件处理器模式

| 模式 | 说明 |
|------|------|
| 同步处理 | 事件发布后立即执行处理器 |
| 异步处理 | 通过 channel 或消息队列异步执行 |
| 重试机制 | `RetryableHandler` 装饰器，支持指数退避 |
| 幂等保证 | `IdempotentHandler` 检查事件 ID 防止重复处理 |

## Event Sourcing 简介

以事件序列作为聚合状态的唯一真实来源:

```go
type EventStore interface {
    Append(ctx context.Context, aggregateID string, events []DomainEvent) error
    Load(ctx context.Context, aggregateID string) ([]DomainEvent, error)
}

// 从事件重建状态
func (a *BankAccount) RebuildFromEvents(events []DomainEvent) {
    for _, event := range events { a.ApplyEvent(event) }
}
```

快照机制: 定期保存聚合状态快照，加载时先恢复快照再重放后续事件。

## 领域事件 vs 系统事件

| 维度 | 领域事件 | 系统事件 |
|------|---------|---------|
| 命名 | 业务语言 (OrderSubmitted) | 技术术语 (DBConnectionLost) |
| 定义位置 | Domain Layer | Infrastructure Layer |
| 消费者 | 其他聚合、应用服务 | 运维工具、监控系统 |

## 事件版本管理

```go
type UserCreatedV1 struct { userID uuid.UUID; email string }
type UserCreatedV2 struct { userID uuid.UUID; email string; name string }

func (e UserCreatedV2) EventType() string { return "UserCreated/v2" }
```
