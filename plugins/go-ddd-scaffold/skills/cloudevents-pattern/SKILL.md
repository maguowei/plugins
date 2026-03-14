---
name: CloudEvents Pattern
description: 用户问"事件驱动怎么实现"、"领域事件怎么发布"、"CloudEvents 规范是什么"、"事件总线怎么设计"、"事件订阅怎么做"、"Kafka/NATS 怎么集成事件"时触发。涵盖 CloudEvents 标准、事件发布订阅、消息队列集成和 Event Sourcing。
version: 0.2.0
---

# CloudEvents 领域事件模式

## 概述

CloudEvents 是 CNCF 的云原生事件规范，提供统一的事件描述格式。在 DDD 中使用 CloudEvents 标准化领域事件，实现跨服务的事件驱动架构。

## CloudEvents 核心属性

| 属性 | 说明 | 示例 |
|-----|------|------|
| id | 事件唯一标识 | UUID |
| source | 事件来源 | "user-service" |
| type | 事件类型 | "com.example.user.created" |
| time | 事件发生时间 | RFC3339 |
| datacontenttype | 数据格式 | "application/json" |
| data | 事件负载数据 | JSON |

Go SDK: `github.com/cloudevents/sdk-go/v2`

## 领域事件定义

```go
// internal/app/domain/user/event/user_created.go
package event

import (
    "time"
    "github.com/google/uuid"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

type UserCreated struct {
    UserID    uuid.UUID `json:"user_id"`
    Email     string    `json:"email"`
    Name      string    `json:"name"`
    CreatedAt time.Time `json:"created_at"`
}

func (e UserCreated) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetID(uuid.New().String())
    event.SetSource("user-service")
    event.SetType("com.example.user.created")
    event.SetTime(e.CreatedAt)
    event.SetData(cloudevents.ApplicationJSON, e)
    return event
}

func NewUserCreated(userID uuid.UUID, email, name string) UserCreated {
    return UserCreated{
        UserID: userID, Email: email,
        Name: name, CreatedAt: time.Now(),
    }
}
```

**更多事件示例**:

```go
type UserEmailChanged struct {
    UserID    uuid.UUID `json:"user_id"`
    OldEmail  string    `json:"old_email"`
    NewEmail  string    `json:"new_email"`
    ChangedAt time.Time `json:"changed_at"`
}

func (e UserEmailChanged) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetID(uuid.New().String())
    event.SetSource("user-service")
    event.SetType("com.example.user.email.changed")
    event.SetTime(e.ChangedAt)
    event.SetData(cloudevents.ApplicationJSON, e)
    return event
}
```

## 事件总线

### 接口定义 (Domain Layer)

```go
// internal/app/domain/event/event_bus.go
type EventBus interface {
    Publish(event cloudevents.Event) error
    Subscribe(eventType string, handler EventHandler) error
}

type EventHandler interface {
    Handle(event cloudevents.Event) error
}
```

### 内存实现

```go
// internal/app/infrastructure/event/memory_event_bus.go
type MemoryEventBus struct {
    handlers map[string][]domainevent.EventHandler
    mu       sync.RWMutex
}

func NewMemoryEventBus() *MemoryEventBus {
    return &MemoryEventBus{
        handlers: make(map[string][]domainevent.EventHandler),
    }
}

func (b *MemoryEventBus) Publish(event cloudevents.Event) error {
    b.mu.RLock()
    defer b.mu.RUnlock()
    handlers, ok := b.handlers[event.Type()]
    if !ok {
        return nil
    }
    for _, handler := range handlers {
        if err := handler.Handle(event); err != nil {
            return err
        }
    }
    return nil
}

func (b *MemoryEventBus) Subscribe(eventType string, handler domainevent.EventHandler) error {
    b.mu.Lock()
    defer b.mu.Unlock()
    b.handlers[eventType] = append(b.handlers[eventType], handler)
    return nil
}
```

## 事件发布 (Application Layer)

```go
func (s *UserApplicationService) CreateUser(ctx context.Context, req CreateUserRequest) (*UserResponse, error) {
    email, _ := valueobject.NewEmail(req.Email)
    user, err := entity.NewUser(email, req.Name)
    if err != nil {
        return nil, err
    }

    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 发布领域事件 (失败不阻止主流程)
    evt := event.NewUserCreated(user.ID(), user.Email().Value(), user.Name())
    if err := s.eventBus.Publish(evt.ToCloudEvent()); err != nil {
        slog.Error("failed to publish event", "error", err)
    }

    return ToUserResponse(user), nil
}
```

## 事件订阅

### 事件处理器

```go
// internal/app/application/event/user_created_handler.go
type UserCreatedHandler struct {
    emailService EmailService
}

func (h *UserCreatedHandler) Handle(event cloudevents.Event) error {
    var data struct {
        UserID uuid.UUID `json:"user_id"`
        Email  string    `json:"email"`
        Name   string    `json:"name"`
    }
    if err := event.DataAs(&data); err != nil {
        return err
    }
    return h.emailService.SendWelcomeEmail(data.Email, data.Name)
}
```

### 注册处理器

```go
// main.go
eventBus := event.NewMemoryEventBus()
eventBus.Subscribe("com.example.user.created", event.NewUserCreatedHandler(emailService))
```

## 消息队列集成

### Kafka 事件总线

```go
type KafkaEventBus struct {
    writer *kafka.Writer
}

func NewKafkaEventBus(brokers []string, topic string) *KafkaEventBus {
    return &KafkaEventBus{
        writer: &kafka.Writer{
            Addr:     kafka.TCP(brokers...),
            Topic:    topic,
            Balancer: &kafka.LeastBytes{},
        },
    }
}

func (b *KafkaEventBus) Publish(event cloudevents.Event) error {
    data, err := json.Marshal(event)
    if err != nil {
        return err
    }
    return b.writer.WriteMessages(context.Background(),
        kafka.Message{Key: []byte(event.ID()), Value: data},
    )
}
```

### NATS 事件总线

```go
type NatsEventBus struct {
    conn *nats.Conn
}

func (b *NatsEventBus) Publish(event cloudevents.Event) error {
    data, _ := json.Marshal(event)
    return b.conn.Publish(event.Type(), data)
}

func (b *NatsEventBus) Subscribe(eventType string, handler EventHandler) error {
    _, err := b.conn.Subscribe(eventType, func(msg *nats.Msg) {
        var event cloudevents.Event
        json.Unmarshal(msg.Data, &event)
        handler.Handle(event)
    })
    return err
}
```

## Event Sourcing

### 事件存储接口

```go
type EventStore interface {
    Append(ctx context.Context, aggregateID uuid.UUID, events []cloudevents.Event) error
    Load(ctx context.Context, aggregateID uuid.UUID) ([]cloudevents.Event, error)
}
```

### 数据库实现

```go
func (s *DBEventStore) Append(ctx context.Context, aggregateID uuid.UUID, events []cloudevents.Event) error {
    tx, _ := s.db.BeginTx(ctx, nil)
    defer tx.Rollback()
    for _, event := range events {
        data, _ := json.Marshal(event)
        tx.ExecContext(ctx,
            `INSERT INTO events (aggregate_id, event_type, event_data, occurred_at) VALUES (?, ?, ?, ?)`,
            aggregateID, event.Type(), data, event.Time(),
        )
    }
    return tx.Commit()
}
```

## 事件版本管理

```go
// V1 事件
type UserCreatedV1 struct {
    UserID uuid.UUID `json:"user_id"`
    Email  string    `json:"email"`
}

// V2 事件 (添加新字段)
type UserCreatedV2 struct {
    UserID uuid.UUID `json:"user_id"`
    Email  string    `json:"email"`
    Name   string    `json:"name"`
}
```

## 最佳实践

1. **事件命名**: 使用过去时 (UserCreated, OrderPlaced)
2. **事件粒度**: 表示有意义的业务变化
3. **事件不可变**: 一旦发布不应修改
4. **幂等处理**: 事件处理器支持幂等
5. **错误处理**: 发布失败不阻止主流程
6. **版本管理**: 使用版本化的事件类型

## 常见模式

### 最终一致性

```go
// 订单服务发布事件
eventBus.Publish(OrderPlaced{OrderID: order.ID()}.ToCloudEvent())

// 库存服务订阅并处理
func (h *OrderPlacedHandler) Handle(event cloudevents.Event) error {
    return h.inventoryService.Reserve(data.Items)
}
```

### Saga 模式

```go
type OrderSaga struct { eventBus EventBus }

func (s *OrderSaga) CreateOrder(order Order) error {
    s.eventBus.Publish(OrderCreated{...})     // 1. 创建订单
    s.eventBus.Publish(ReserveInventory{...}) // 2. 扣减库存
    s.eventBus.Publish(ProcessPayment{...})   // 3. 处理支付
    // 任何步骤失败发布补偿事件
}
```

## 总结

CloudEvents 在 DDD 中的价值:
- 统一的事件格式，跨服务互操作
- 事件驱动架构，实现松耦合
- 支持最终一致性和事件溯源
