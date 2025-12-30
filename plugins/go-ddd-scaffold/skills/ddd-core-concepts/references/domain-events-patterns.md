# 领域事件高级模式

## 领域事件概述

领域事件 (Domain Event) 是 DDD 中表示领域中发生的重要业务事实的对象。事件是过去已经发生的事情，因此应该使用过去时命名，并且是不可变的。

**核心特征**:
- **过去时命名**: UserCreated, OrderSubmitted, PaymentCompleted
- **不可变性**: 事件一旦创建就不能修改
- **包含充分上下文**: 事件应包含足够的信息供消费者使用
- **时间戳**: 记录事件发生的时间

**何时使用**:
- 需要解耦不同聚合之间的操作
- 需要记录领域中发生的重要变化
- 需要异步处理某些操作
- 需要实现最终一致性

## 事件发布订阅机制

### 事件发布器接口

```go
package event

import "context"

// DomainEvent 领域事件接口
type DomainEvent interface {
    // OccurredAt 事件发生时间
    OccurredAt() time.Time
    // EventType 事件类型
    EventType() string
    // AggregateID 聚合根 ID
    AggregateID() string
}

// EventPublisher 事件发布器接口
type EventPublisher interface {
    // Publish 发布单个事件
    Publish(ctx context.Context, event DomainEvent) error
    // PublishBatch 批量发布事件
    PublishBatch(ctx context.Context, events []DomainEvent) error
}
```

### 事件订阅器接口

```go
package event

import "context"

// EventHandler 事件处理器函数类型
type EventHandler func(ctx context.Context, event DomainEvent) error

// EventSubscriber 事件订阅器接口
type EventSubscriber interface {
    // Subscribe 订阅特定类型的事件
    Subscribe(eventType string, handler EventHandler) error
    // Unsubscribe 取消订阅
    Unsubscribe(eventType string, handler EventHandler) error
}

// EventBus 事件总线 (同时实现发布和订阅)
type EventBus interface {
    EventPublisher
    EventSubscriber
}
```

### 内存事件总线实现

```go
package event

import (
    "context"
    "fmt"
    "sync"
)

// InMemoryEventBus 内存事件总线实现
type InMemoryEventBus struct {
    // handlers 存储事件类型到处理器的映射
    handlers map[string][]EventHandler
    mu       sync.RWMutex
}

func NewInMemoryEventBus() *InMemoryEventBus {
    return &InMemoryEventBus{
        handlers: make(map[string][]EventHandler),
    }
}

// Publish 发布事件
func (bus *InMemoryEventBus) Publish(ctx context.Context, event DomainEvent) error {
    bus.mu.RLock()
    handlers, exists := bus.handlers[event.EventType()]
    bus.mu.RUnlock()

    if !exists {
        return nil // 没有订阅者，静默返回
    }

    // 顺序执行所有处理器
    for _, handler := range handlers {
        if err := handler(ctx, event); err != nil {
            return fmt.Errorf("handler failed for event %s: %w", event.EventType(), err)
        }
    }

    return nil
}

// PublishBatch 批量发布事件
func (bus *InMemoryEventBus) PublishBatch(ctx context.Context, events []DomainEvent) error {
    for _, event := range events {
        if err := bus.Publish(ctx, event); err != nil {
            return err
        }
    }
    return nil
}

// Subscribe 订阅事件
func (bus *InMemoryEventBus) Subscribe(eventType string, handler EventHandler) error {
    bus.mu.Lock()
    defer bus.mu.Unlock()

    bus.handlers[eventType] = append(bus.handlers[eventType], handler)
    return nil
}

// Unsubscribe 取消订阅 (简化实现)
func (bus *InMemoryEventBus) Unsubscribe(eventType string, handler EventHandler) error {
    bus.mu.Lock()
    defer bus.mu.Unlock()

    delete(bus.handlers, eventType)
    return nil
}
```

## 事件收集与发布策略

### 在实体内部收集事件

```go
package entity

import (
    "time"
    "github.com/google/uuid"
)

// UserCreated 用户创建事件
type UserCreated struct {
    userID     uuid.UUID
    email      string
    occurredAt time.Time
}

func (e UserCreated) OccurredAt() time.Time { return e.occurredAt }
func (e UserCreated) EventType() string     { return "UserCreated" }
func (e UserCreated) AggregateID() string   { return e.userID.String() }

// User 实体
type User struct {
    id           uuid.UUID
    email        string
    name         string
    domainEvents []event.DomainEvent // 收集的事件
}

// NewUser 创建新用户
func NewUser(email, name string) (*User, error) {
    if email == "" || name == "" {
        return nil, errors.New("email and name required")
    }

    user := &User{
        id:    uuid.New(),
        email: email,
        name:  name,
    }

    // 收集事件，但不立即发布
    user.domainEvents = append(user.domainEvents, UserCreated{
        userID:     user.id,
        email:      email,
        occurredAt: time.Now(),
    })

    return user, nil
}

// DomainEvents 获取领域事件
func (u *User) DomainEvents() []event.DomainEvent {
    return u.domainEvents
}

// ClearDomainEvents 清空领域事件
func (u *User) ClearDomainEvents() {
    u.domainEvents = nil
}
```

### 在应用层统一发布

```go
package application

import (
    "context"
)

// UserApplicationService 用户应用服务
type UserApplicationService struct {
    userRepo      repository.UserRepository
    eventPublisher event.EventPublisher
}

// CreateUser 创建用户用例
func (s *UserApplicationService) CreateUser(ctx context.Context, email, name string) error {
    // 1. 创建实体 (事件在实体内部收集)
    user, err := entity.NewUser(email, name)
    if err != nil {
        return err
    }

    // 2. 持久化实体
    if err := s.userRepo.Save(ctx, user); err != nil {
        return err
    }

    // 3. 发布领域事件 (在事务提交后)
    if err := s.eventPublisher.PublishBatch(ctx, user.DomainEvents()); err != nil {
        // 记录日志，但不影响主流程
        log.Printf("failed to publish events: %v", err)
    }

    // 4. 清空已发布的事件
    user.ClearDomainEvents()

    return nil
}
```

### 事务边界管理

```go
package application

import (
    "context"
    "database/sql"
)

// CreateUserWithTransaction 在事务中创建用户
func (s *UserApplicationService) CreateUserWithTransaction(ctx context.Context, email, name string) error {
    // 开启事务
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback() // 确保异常时回滚

    // 1. 创建实体
    user, err := entity.NewUser(email, name)
    if err != nil {
        return err
    }

    // 2. 在事务中保存
    if err := s.userRepo.SaveWithTx(ctx, tx, user); err != nil {
        return err
    }

    // 3. 提交事务
    if err := tx.Commit(); err != nil {
        return err
    }

    // 4. 事务提交成功后发布事件 (关键: 在事务外)
    if err := s.eventPublisher.PublishBatch(ctx, user.DomainEvents()); err != nil {
        // 记录但不回滚
        log.Printf("event publishing failed: %v", err)
    }

    user.ClearDomainEvents()
    return nil
}
```

## 事件处理器设计

### 同步处理

```go
package handler

import (
    "context"
    "log"
)

// SendWelcomeEmailHandler 发送欢迎邮件处理器
type SendWelcomeEmailHandler struct {
    emailService EmailService
}

// Handle 同步处理事件
func (h *SendWelcomeEmailHandler) Handle(ctx context.Context, event event.DomainEvent) error {
    userCreated, ok := event.(entity.UserCreated)
    if !ok {
        return fmt.Errorf("unexpected event type: %T", event)
    }

    // 发送欢迎邮件 (同步)
    return h.emailService.SendWelcomeEmail(ctx, userCreated.Email())
}
```

### 异步处理

```go
package handler

import (
    "context"
    "log"
)

// AsyncEventProcessor 异步事件处理器
type AsyncEventProcessor struct {
    eventQueue chan event.DomainEvent
    handlers   map[string]event.EventHandler
}

func NewAsyncEventProcessor() *AsyncEventProcessor {
    processor := &AsyncEventProcessor{
        eventQueue: make(chan event.DomainEvent, 100), // 缓冲队列
        handlers:   make(map[string]event.EventHandler),
    }

    // 启动后台工作协程
    go processor.processEvents()

    return processor
}

// Publish 异步发布事件
func (p *AsyncEventProcessor) Publish(ctx context.Context, event event.DomainEvent) error {
    select {
    case p.eventQueue <- event:
        return nil
    case <-ctx.Done():
        return ctx.Err()
    }
}

// processEvents 后台处理事件
func (p *AsyncEventProcessor) processEvents() {
    for event := range p.eventQueue {
        handler, exists := p.handlers[event.EventType()]
        if !exists {
            continue
        }

        // 异步处理，错误只记录日志
        if err := handler(context.Background(), event); err != nil {
            log.Printf("async event handler failed: %v", err)
        }
    }
}
```

### 错误重试机制

```go
package handler

import (
    "context"
    "time"
)

// RetryableHandler 支持重试的处理器装饰器
type RetryableHandler struct {
    handler    event.EventHandler
    maxRetries int
    retryDelay time.Duration
}

func NewRetryableHandler(handler event.EventHandler, maxRetries int) *RetryableHandler {
    return &RetryableHandler{
        handler:    handler,
        maxRetries: maxRetries,
        retryDelay: time.Second,
    }
}

// Handle 处理事件，失败时重试
func (h *RetryableHandler) Handle(ctx context.Context, event event.DomainEvent) error {
    var lastErr error

    for attempt := 0; attempt <= h.maxRetries; attempt++ {
        if attempt > 0 {
            // 等待后重试
            select {
            case <-time.After(h.retryDelay):
            case <-ctx.Done():
                return ctx.Err()
            }
        }

        if err := h.handler(ctx, event); err != nil {
            lastErr = err
            log.Printf("handler failed (attempt %d/%d): %v", attempt+1, h.maxRetries+1, err)
            continue
        }

        return nil // 成功
    }

    return fmt.Errorf("handler failed after %d attempts: %w", h.maxRetries+1, lastErr)
}
```

### 幂等性保证

```go
package handler

import (
    "context"
)

// IdempotentHandler 幂等性处理器装饰器
type IdempotentHandler struct {
    handler       event.EventHandler
    processedRepo ProcessedEventRepository // 存储已处理的事件 ID
}

// Handle 幂等处理事件
func (h *IdempotentHandler) Handle(ctx context.Context, event event.DomainEvent) error {
    eventID := event.AggregateID() + "/" + event.EventType()

    // 检查是否已处理
    processed, err := h.processedRepo.IsProcessed(ctx, eventID)
    if err != nil {
        return err
    }
    if processed {
        log.Printf("event %s already processed, skipping", eventID)
        return nil // 已处理，跳过
    }

    // 执行处理
    if err := h.handler(ctx, event); err != nil {
        return err
    }

    // 标记为已处理
    return h.processedRepo.MarkAsProcessed(ctx, eventID)
}
```

## Event Sourcing 模式

### 事件存储

```go
package eventsourcing

import (
    "context"
    "time"
)

// EventStore 事件存储接口
type EventStore interface {
    // Append 追加事件
    Append(ctx context.Context, aggregateID string, events []event.DomainEvent) error
    // Load 加载聚合的所有事件
    Load(ctx context.Context, aggregateID string) ([]event.DomainEvent, error)
    // LoadAfter 加载某个时间点之后的事件
    LoadAfter(ctx context.Context, aggregateID string, after time.Time) ([]event.DomainEvent, error)
}

// StoredEvent 存储的事件
type StoredEvent struct {
    ID          int64
    AggregateID string
    EventType   string
    EventData   []byte    // JSON 序列化的事件数据
    OccurredAt  time.Time
    CreatedAt   time.Time
}
```

### 状态重建

```go
package eventsourcing

import (
    "context"
)

// BankAccount 银行账户聚合 (Event Sourcing)
type BankAccount struct {
    id      string
    balance int64
    version int
}

// NewBankAccount 创建新账户
func NewBankAccount(id string) *BankAccount {
    return &BankAccount{
        id:      id,
        balance: 0,
        version: 0,
    }
}

// ApplyEvent 应用事件到聚合
func (a *BankAccount) ApplyEvent(event event.DomainEvent) {
    switch e := event.(type) {
    case *AccountOpened:
        a.balance = e.InitialDeposit
    case *MoneyDeposited:
        a.balance += e.Amount
    case *MoneyWithdrawn:
        a.balance -= e.Amount
    }
    a.version++
}

// RebuildFromEvents 从事件历史重建状态
func (a *BankAccount) RebuildFromEvents(events []event.DomainEvent) {
    for _, event := range events {
        a.ApplyEvent(event)
    }
}

// BankAccountRepository Event Sourcing 仓储
type BankAccountRepository struct {
    eventStore EventStore
}

// Load 从事件存储加载聚合
func (r *BankAccountRepository) Load(ctx context.Context, id string) (*BankAccount, error) {
    events, err := r.eventStore.Load(ctx, id)
    if err != nil {
        return nil, err
    }

    account := NewBankAccount(id)
    account.RebuildFromEvents(events)

    return account, nil
}
```

### 快照机制

```go
package eventsourcing

import (
    "context"
    "time"
)

// Snapshot 状态快照
type Snapshot struct {
    AggregateID string
    Version     int
    State       []byte    // 序列化的聚合状态
    CreatedAt   time.Time
}

// SnapshotStore 快照存储
type SnapshotStore interface {
    Save(ctx context.Context, snapshot *Snapshot) error
    Load(ctx context.Context, aggregateID string) (*Snapshot, error)
}

// LoadWithSnapshot 使用快照加速加载
func (r *BankAccountRepository) LoadWithSnapshot(ctx context.Context, id string) (*BankAccount, error) {
    // 1. 尝试加载快照
    snapshot, err := r.snapshotStore.Load(ctx, id)
    if err != nil {
        return nil, err
    }

    // 2. 从快照重建
    account := &BankAccount{}
    if snapshot != nil {
        if err := json.Unmarshal(snapshot.State, account); err != nil {
            return nil, err
        }
    } else {
        account = NewBankAccount(id)
    }

    // 3. 加载快照之后的事件
    var events []event.DomainEvent
    if snapshot != nil {
        events, err = r.eventStore.LoadAfter(ctx, id, snapshot.CreatedAt)
    } else {
        events, err = r.eventStore.Load(ctx, id)
    }
    if err != nil {
        return nil, err
    }

    // 4. 应用后续事件
    account.RebuildFromEvents(events)

    return account, nil
}
```

## 领域事件 vs 系统事件

### 领域事件 (Domain Event)

```go
// 领域事件: 表达业务含义
type OrderSubmitted struct {
    orderID    uuid.UUID
    customerID uuid.UUID
    totalAmount int64
    occurredAt time.Time
}

// 特征:
// - 业务语言命名
// - 包含业务上下文
// - 由领域专家定义
// - 在 Domain Layer 定义
```

### 系统事件 (System Event)

```go
// 系统事件: 技术性事件
type DatabaseConnectionLost struct {
    connectionID string
    errorMessage string
    occurredAt   time.Time
}

// 特征:
// - 技术术语命名
// - 关注技术细节
// - 由技术人员定义
// - 在 Infrastructure Layer 定义
```

**对比表格**:

| 维度 | 领域事件 | 系统事件 |
|------|---------|---------|
| 命名语言 | 业务语言 | 技术术语 |
| 定义者 | 领域专家 | 技术人员 |
| 定义位置 | Domain Layer | Infrastructure Layer |
| 消费者 | 其他聚合、应用服务 | 运维工具、监控系统 |
| 持久化 | 通常需要 | 可选 |

## 事件命名规范

### 过去时命名

```go
// ✅ 正确: 使用过去时
type UserCreated struct { ... }
type OrderSubmitted struct { ... }
type PaymentCompleted struct { ... }
type EmailSent struct { ... }

// ❌ 错误: 使用现在时或将来时
type CreateUser struct { ... }
type SubmitOrder struct { ... }
type CompletePayment struct { ... }
```

### 包含聚合名称

```go
// ✅ 正确: 明确聚合名称
type UserCreated struct { ... }
type UserEmailChanged struct { ... }
type OrderSubmitted struct { ... }
type OrderCancelled struct { ... }

// ❌ 错误: 缺少聚合名称
type Created struct { ... }
type EmailChanged struct { ... }
```

### 版本化事件

```go
package event

// UserCreatedV1 用户创建事件 v1
type UserCreatedV1 struct {
    userID uuid.UUID
    email  string
}

// UserCreatedV2 用户创建事件 v2 (添加了新字段)
type UserCreatedV2 struct {
    userID uuid.UUID
    email  string
    name   string // 新增字段
}

// EventType 返回事件类型 (包含版本)
func (e UserCreatedV2) EventType() string {
    return "UserCreated/v2"
}
```

### 事件命名最佳实践

```go
// 规范: <聚合名><动作过去式>[/v版本号]

// 示例:
"UserCreated"           // 用户已创建
"UserCreated/v2"        // 用户已创建 (版本2)
"OrderSubmitted"        // 订单已提交
"OrderItemAdded"        // 订单项已添加
"PaymentCompleted"      // 支付已完成
"InventoryReserved"     // 库存已预留
"EmailVerified"         // 邮箱已验证
```
