---
name: CloudEvents Pattern
description: This skill should be used when the user asks about "CloudEvents", "domain events protocol", "event-driven architecture", "how to publish domain events", "CloudEvents specification", "event sourcing", or needs guidance on implementing domain events using the CloudEvents standard.
version: 0.1.0
---

# CloudEvents 领域事件模式

## 概述

CloudEvents 是 CNCF 的云原生事件规范，提供统一的事件描述格式。在 DDD 中使用 CloudEvents 标准化领域事件，实现跨服务的事件驱动架构。

## CloudEvents 规范

### 核心属性

CloudEvents 定义了标准的事件元数据:

- **id**: 事件唯一标识
- **source**: 事件来源 (如 "user-service")
- **type**: 事件类型 (如 "com.example.user.created")
- **time**: 事件发生时间
- **datacontenttype**: 数据格式 (如 "application/json")
- **data**: 事件负载数据

### Go SDK

```go
import cloudevents "github.com/cloudevents/sdk-go/v2"
```

## 领域事件定义

### 事件结构

```go
// internal/app/domain/user/event/user_created.go
package event

import (
    "time"
    "github.com/google/uuid"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// UserCreated 用户创建事件
type UserCreated struct {
    UserID    uuid.UUID `json:"user_id"`
    Email     string    `json:"email"`
    Name      string    `json:"name"`
    CreatedAt time.Time `json:"created_at"`
}

// ToCloudEvent 转换为 CloudEvents 格式
func (e UserCreated) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()

    // 必需属性
    event.SetID(uuid.New().String())
    event.SetSource("user-service")
    event.SetType("com.example.user.created")
    event.SetTime(e.CreatedAt)

    // 数据负载
    event.SetData(cloudevents.ApplicationJSON, e)

    return event
}

// 构造函数
func NewUserCreated(userID uuid.UUID, email, name string) UserCreated {
    return UserCreated{
        UserID:    userID,
        Email:     email,
        Name:      name,
        CreatedAt: time.Now(),
    }
}
```

### 更多事件示例

```go
// UserEmailChanged 邮箱变更事件
type UserEmailChanged struct {
    UserID   uuid.UUID `json:"user_id"`
    OldEmail string    `json:"old_email"`
    NewEmail string    `json:"new_email"`
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

// UserDeleted 用户删除事件
type UserDeleted struct {
    UserID    uuid.UUID `json:"user_id"`
    DeletedAt time.Time `json:"deleted_at"`
}

func (e UserDeleted) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetID(uuid.New().String())
    event.SetSource("user-service")
    event.SetType("com.example.user.deleted")
    event.SetTime(e.DeletedAt)
    event.SetData(cloudevents.ApplicationJSON, e)
    return event
}
```

## 事件发布

### 事件总线接口

```go
// internal/app/domain/event/event_bus.go
package event

import cloudevents "github.com/cloudevents/sdk-go/v2"

// EventBus 事件总线接口 (定义在 Domain 层)
type EventBus interface {
    Publish(event cloudevents.Event) error
    Subscribe(eventType string, handler EventHandler) error
}

// EventHandler 事件处理器
type EventHandler interface {
    Handle(event cloudevents.Event) error
}
```

### 内存事件总线实现

```go
// internal/app/infrastructure/event/memory_event_bus.go
package event

import (
    "sync"
    cloudevents "github.com/cloudevents/sdk-go/v2"
    domainevent "myproject/internal/app/domain/event"
)

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

### 在应用服务中发布事件

```go
// internal/app/application/service/user_application_service.go
package service

type UserApplicationService struct {
    userRepo repository.UserRepository
    eventBus event.EventBus
}

func (s *UserApplicationService) CreateUser(ctx context.Context, req CreateUserRequest) (*UserResponse, error) {
    // 1. 创建用户实体
    email, _ := valueobject.NewEmail(req.Email)
    user, err := entity.NewUser(email, req.Name)
    if err != nil {
        return nil, err
    }

    // 2. 持久化
    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 3. 发布领域事件
    event := event.NewUserCreated(user.ID(), user.Email().Value(), user.Name())
    if err := s.eventBus.Publish(event.ToCloudEvent()); err != nil {
        // 记录错误但不阻止主流程
        log.Error("failed to publish event", "error", err)
    }

    return ToUserResponse(user), nil
}
```

## 事件订阅

### 事件处理器实现

```go
// internal/app/application/event/user_created_handler.go
package event

import (
    "context"
    "log"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// UserCreatedHandler 处理用户创建事件
type UserCreatedHandler struct {
    emailService EmailService
}

func NewUserCreatedHandler(emailService EmailService) *UserCreatedHandler {
    return &UserCreatedHandler{emailService: emailService}
}

func (h *UserCreatedHandler) Handle(event cloudevents.Event) error {
    // 解析事件数据
    var data UserCreatedEventData
    if err := event.DataAs(&data); err != nil {
        return err
    }

    // 发送欢迎邮件
    err := h.emailService.SendWelcomeEmail(data.Email, data.Name)
    if err != nil {
        log.Printf("failed to send welcome email: %v", err)
        return err
    }

    log.Printf("welcome email sent to user %s", data.UserID)
    return nil
}

type UserCreatedEventData struct {
    UserID uuid.UUID `json:"user_id"`
    Email  string    `json:"email"`
    Name   string    `json:"name"`
}
```

### 注册事件处理器

```go
// main.go
func main() {
    // 初始化事件总线
    eventBus := event.NewMemoryEventBus()

    // 注册事件处理器
    emailService := initEmailService()
    userCreatedHandler := event.NewUserCreatedHandler(emailService)

    eventBus.Subscribe("com.example.user.created", userCreatedHandler)

    // ... 其他初始化
}
```

## 消息队列集成

### Kafka 事件总线

```go
// internal/app/infrastructure/event/kafka_event_bus.go
package event

import (
    "github.com/segmentio/kafka-go"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

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
    // 序列化事件
    data, err := json.Marshal(event)
    if err != nil {
        return err
    }

    // 发送到 Kafka
    return b.writer.WriteMessages(context.Background(),
        kafka.Message{
            Key:   []byte(event.ID()),
            Value: data,
        },
    )
}
```

### NATS 事件总线

```go
// internal/app/infrastructure/event/nats_event_bus.go
package event

import (
    "github.com/nats-io/nats.go"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

type NatsEventBus struct {
    conn *nats.Conn
}

func NewNatsEventBus(url string) (*NatsEventBus, error) {
    conn, err := nats.Connect(url)
    if err != nil {
        return nil, err
    }

    return &NatsEventBus{conn: conn}, nil
}

func (b *NatsEventBus) Publish(event cloudevents.Event) error {
    data, err := json.Marshal(event)
    if err != nil {
        return err
    }

    return b.conn.Publish(event.Type(), data)
}

func (b *NatsEventBus) Subscribe(eventType string, handler EventHandler) error {
    _, err := b.conn.Subscribe(eventType, func(msg *nats.Msg) {
        var event cloudevents.Event
        if err := json.Unmarshal(msg.Data, &event); err != nil {
            log.Printf("failed to unmarshal event: %v", err)
            return
        }

        if err := handler.Handle(event); err != nil {
            log.Printf("handler error: %v", err)
        }
    })

    return err
}
```

## 事件存储 (Event Sourcing)

### 事件存储接口

```go
// internal/app/domain/event/event_store.go
package event

import (
    "context"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// EventStore 事件存储接口
type EventStore interface {
    Append(ctx context.Context, aggregateID uuid.UUID, events []cloudevents.Event) error
    Load(ctx context.Context, aggregateID uuid.UUID) ([]cloudevents.Event, error)
}
```

### 数据库事件存储实现

```go
// internal/app/infrastructure/event/db_event_store.go
package event

type DBEventStore struct {
    db *sql.DB
}

func (s *DBEventStore) Append(ctx context.Context, aggregateID uuid.UUID, events []cloudevents.Event) error {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    for _, event := range events {
        data, _ := json.Marshal(event)

        _, err := tx.ExecContext(ctx,
            `INSERT INTO events (aggregate_id, event_type, event_data, occurred_at)
             VALUES (?, ?, ?, ?)`,
            aggregateID, event.Type(), data, event.Time(),
        )
        if err != nil {
            return err
        }
    }

    return tx.Commit()
}

func (s *DBEventStore) Load(ctx context.Context, aggregateID uuid.UUID) ([]cloudevents.Event, error) {
    rows, err := s.db.QueryContext(ctx,
        `SELECT event_data FROM events WHERE aggregate_id = ? ORDER BY occurred_at`,
        aggregateID,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var events []cloudevents.Event
    for rows.Next() {
        var data []byte
        if err := rows.Scan(&data); err != nil {
            return nil, err
        }

        var event cloudevents.Event
        if err := json.Unmarshal(data, &event); err != nil {
            return nil, err
        }

        events = append(events, event)
    }

    return events, nil
}
```

## 事件版本管理

### 事件版本化

```go
// V1 事件
type UserCreatedV1 struct {
    UserID uuid.UUID `json:"user_id"`
    Email  string    `json:"email"`
}

func (e UserCreatedV1) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetType("com.example.user.created.v1")
    // ...
}

// V2 事件 (添加新字段)
type UserCreatedV2 struct {
    UserID uuid.UUID `json:"user_id"`
    Email  string    `json:"email"`
    Name   string    `json:"name"`  // 新增字段
}

func (e UserCreatedV2) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetType("com.example.user.created.v2")
    // ...
}
```

## 最佳实践

1. **事件命名**: 使用过去时,描述已发生的事实
   - ✅ UserCreated, OrderPlaced, PaymentProcessed
   - ❌ CreateUser, PlaceOrder, ProcessPayment

2. **事件粒度**: 事件应该表示有意义的业务变化

3. **事件不可变**: 一旦发布,事件不应修改

4. **幂等性**: 事件处理器应该支持幂等处理

5. **错误处理**: 发布失败不应阻止主流程

6. **版本管理**: 使用版本化的事件类型

## 常见模式

### 最终一致性

```go
// 订单服务发布事件
orderEvent := OrderPlaced{OrderID: order.ID(), UserID: user.ID()}
eventBus.Publish(orderEvent.ToCloudEvent())

// 库存服务订阅事件
type OrderPlacedHandler struct {
    inventoryService InventoryService
}

func (h *OrderPlacedHandler) Handle(event cloudevents.Event) error {
    // 减少库存
    return h.inventoryService.Reserve(data.Items)
}
```

### Saga 模式

```go
// 编排多个服务的事务
type OrderSaga struct {
    eventBus EventBus
}

func (s *OrderSaga) CreateOrder(order Order) error {
    // 1. 创建订单
    s.eventBus.Publish(OrderCreated{...})

    // 2. 扣减库存
    s.eventBus.Publish(ReserveInventory{...})

    // 3. 处理支付
    s.eventBus.Publish(ProcessPayment{...})

    // 如果任何步骤失败,发布补偿事件
}
```

## 总结

CloudEvents 在 DDD 中的价值:

- ✅ 统一的事件格式
- ✅ 跨服务互操作性
- ✅ 事件驱动架构
- ✅ 最终一致性
- ✅ 审计和事件溯源

## 额外资源

- **`references/cloudevents-spec.md`** - CloudEvents 完整规范
- **`references/event-patterns.md`** - 事件模式详解
- **`examples/event-driven-saga/`** - Saga 模式完整示例
