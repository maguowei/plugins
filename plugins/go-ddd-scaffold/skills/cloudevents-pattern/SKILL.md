---
name: CloudEvents Pattern
description: 用户问"事件驱动怎么实现"、"领域事件怎么发布"、"CloudEvents 规范是什么"、"事件总线怎么设计"、"事件订阅怎么做"、"Kafka/NATS 怎么集成事件"时触发。涵盖 CloudEvents 标准、事件发布订阅、消息队列集成和 Event Sourcing。
version: 0.3.0
---

# CloudEvents 领域事件模式

## CloudEvents 核心属性

| 属性 | 必需 | 说明 | 示例 |
|------|------|------|------|
| id | 是 | 事件唯一标识 | UUID |
| source | 是 | 事件来源 | "user-service" |
| type | 是 | 事件类型 | "com.example.user.created" |
| time | 否 | 事件发生时间 | RFC3339 |
| data | 否 | 事件负载 | JSON |

Go SDK: `github.com/cloudevents/sdk-go/v2`

## 领域事件定义

```go
type UserCreated struct {
    UserID uuid.UUID `json:"user_id"`
    Email  string    `json:"email"`
    Name   string    `json:"name"`
}

func (e UserCreated) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetID(uuid.New().String())
    event.SetSource("user-service")
    event.SetType("com.example.user.created")
    event.SetData(cloudevents.ApplicationJSON, e)
    return event
}
```

## 事件总线

```go
// Domain Layer 接口
type EventBus interface {
    Publish(event cloudevents.Event) error
    Subscribe(eventType string, handler EventHandler) error
}
```

实现: MemoryEventBus (开发), KafkaEventBus (生产), NatsEventBus

## 事件发布 (Application Layer)

```go
func (s *UserApplicationService) CreateUser(ctx context.Context, req CreateUserRequest) (*UserResponse, error) {
    user, _ := entity.NewUser(email, req.Name)
    s.userRepo.Save(ctx, user)
    evt := event.NewUserCreated(user.ID(), user.Email().Value(), user.Name())
    s.eventBus.Publish(evt.ToCloudEvent()) // 失败不阻止主流程
    return ToUserResponse(user), nil
}
```

## 事件模式速查

| 模式 | 说明 |
|------|------|
| 事件携带状态 | 事件含完整数据，消费者无需查询 (推荐) |
| Event Sourcing | 事件序列作为聚合状态唯一真实来源 |
| CQRS | 分离读写模型，事件同步 |
| Saga | 协调分布式事务，补偿事件 |
| 最终一致性 | 跨聚合通过事件实现一致性 |

## 最佳实践

1. **事件命名**: 过去时 (UserCreated, OrderPlaced)
2. **事件粒度**: 表示有意义的业务变化
3. **事件不可变**: 一旦发布不修改
4. **幂等处理**: 检查事件 ID 防重复
5. **错误处理**: 发布失败不阻止主流程
6. **版本管理**: `com.example.user.created.v2`

## 参考文档

- `references/cloudevents-guide.md` -- CloudEvents 规范详解、Go SDK 用法、消息队列集成、事件模式、处理器模式
