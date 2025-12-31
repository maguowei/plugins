# 事件驱动架构模式详解

## 事件驱动架构概述

事件驱动架构 (Event-Driven Architecture, EDA) 是一种以事件为中心的软件架构模式,通过事件的产生、传递和消费来实现系统间的松耦合通信。

**核心概念**:
- **事件 (Event)**: 系统中发生的状态变化
- **事件生产者 (Producer)**: 发布事件的组件
- **事件消费者 (Consumer)**: 订阅并处理事件的组件
- **事件总线 (Event Bus)**: 事件传递的中介

**优势**:
- 松耦合: 生产者和消费者相互独立
- 可扩展: 轻松添加新的事件消费者
- 异步处理: 提高系统响应性
- 审计能力: 事件流提供完整的操作历史

## 事件类型

### 1. 领域事件 (Domain Event)

**定义**: 领域内发生的有意义的业务变化

```go
package event

import (
    "time"
    "github.com/google/uuid"
)

// UserRegistered 用户注册事件
type UserRegistered struct {
    UserID       uuid.UUID `json:"user_id"`
    Email        string    `json:"email"`
    Name         string    `json:"name"`
    RegisteredAt time.Time `json:"registered_at"`
}

// OrderPlaced 订单提交事件
type OrderPlaced struct {
    OrderID     uuid.UUID `json:"order_id"`
    CustomerID  uuid.UUID `json:"customer_id"`
    Items       []OrderItem `json:"items"`
    TotalAmount int64     `json:"total_amount"`
    PlacedAt    time.Time `json:"placed_at"`
}

// PaymentCompleted 支付完成事件
type PaymentCompleted struct {
    PaymentID   uuid.UUID `json:"payment_id"`
    OrderID     uuid.UUID `json:"order_id"`
    Amount      int64     `json:"amount"`
    CompletedAt time.Time `json:"completed_at"`
}
```

### 2. 集成事件 (Integration Event)

**定义**: 跨系统边界的事件,用于系统间通信

```go
package event

// CustomerCreatedIntegrationEvent 客户创建集成事件
type CustomerCreatedIntegrationEvent struct {
    // 基础信息
    CustomerID   string    `json:"customer_id"`
    Email        string    `json:"email"`
    Name         string    `json:"name"`

    // 集成元数据
    EventID      string    `json:"event_id"`
    EventType    string    `json:"event_type"`
    Source       string    `json:"source"`
    Timestamp    time.Time `json:"timestamp"`
    CorrelationID string   `json:"correlation_id"`
}

// OrderPlacedIntegrationEvent 订单提交集成事件
type OrderPlacedIntegrationEvent struct {
    OrderID      string    `json:"order_id"`
    CustomerID   string    `json:"customer_id"`
    TotalAmount  float64   `json:"total_amount"`
    Currency     string    `json:"currency"`

    // 集成元数据
    EventID      string    `json:"event_id"`
    Source       string    `json:"source"`
    Timestamp    time.Time `json:"timestamp"`
}
```

### 3. 系统事件 (System Event)

**定义**: 技术层面的事件,如系统启动、关闭等

```go
package event

// ApplicationStarted 应用启动事件
type ApplicationStarted struct {
    AppName   string    `json:"app_name"`
    Version   string    `json:"version"`
    StartedAt time.Time `json:"started_at"`
}

// ApplicationShutdown 应用关闭事件
type ApplicationShutdown struct {
    AppName     string    `json:"app_name"`
    Reason      string    `json:"reason"`
    ShutdownAt  time.Time `json:"shutdown_at"`
}

// HealthCheckFailed 健康检查失败事件
type HealthCheckFailed struct {
    ServiceName string    `json:"service_name"`
    Error       string    `json:"error"`
    FailedAt    time.Time `json:"failed_at"`
}
```

## 事件模式

### 模式 1: 事件通知 (Event Notification)

**用途**: 通知其他系统发生了某件事,不包含详细数据

```go
package service

// 发布事件通知
func (s *UserService) RegisterUser(ctx context.Context, req RegisterUserRequest) error {
    // 1. 创建用户
    user := entity.NewUser(req.Email, req.Name)
    if err := s.userRepo.Save(ctx, user); err != nil {
        return err
    }

    // 2. 发布事件通知 (只包含 ID)
    event := event.UserRegistered{
        UserID:       user.ID(),
        RegisteredAt: time.Now(),
    }

    s.eventBus.Publish(event.ToCloudEvent())

    return nil
}

// 消费者需要查询获取详情
type WelcomeEmailHandler struct {
    userRepo UserRepository
    emailService EmailService
}

func (h *WelcomeEmailHandler) Handle(event cloudevents.Event) error {
    var data event.UserRegistered
    event.DataAs(&data)

    // 查询用户详细信息
    user, err := h.userRepo.FindByID(context.Background(), data.UserID)
    if err != nil {
        return err
    }

    // 发送欢迎邮件
    return h.emailService.SendWelcomeEmail(user.Email(), user.Name())
}
```

### 模式 2: 事件携带状态 (Event-Carried State Transfer)

**用途**: 事件包含完整数据,消费者无需查询

```go
package service

// 发布完整状态事件
func (s *UserService) RegisterUser(ctx context.Context, req RegisterUserRequest) error {
    user := entity.NewUser(req.Email, req.Name)
    if err := s.userRepo.Save(ctx, user); err != nil {
        return err
    }

    // 事件包含完整用户信息
    event := event.UserRegistered{
        UserID:       user.ID(),
        Email:        user.Email().Value(),
        Name:         user.Name(),
        Status:       string(user.Status()),
        RegisteredAt: time.Now(),
    }

    s.eventBus.Publish(event.ToCloudEvent())

    return nil
}

// 消费者直接使用事件数据,无需查询
type WelcomeEmailHandler struct {
    emailService EmailService
}

func (h *WelcomeEmailHandler) Handle(event cloudevents.Event) error {
    var data event.UserRegistered
    event.DataAs(&data)

    // 直接使用事件中的数据
    return h.emailService.SendWelcomeEmail(data.Email, data.Name)
}
```

### 模式 3: 事件溯源 (Event Sourcing)

**用途**: 以事件序列作为数据的唯一真实来源

```go
package entity

// Order 聚合根 (事件溯源)
type Order struct {
    id       uuid.UUID
    events   []interface{} // 未提交的事件
    version  int
}

// 事件定义
type OrderCreated struct {
    OrderID    uuid.UUID
    CustomerID uuid.UUID
    CreatedAt  time.Time
}

type OrderItemAdded struct {
    OrderID   uuid.UUID
    ProductID uuid.UUID
    Quantity  int
    Price     int64
}

type OrderSubmitted struct {
    OrderID     uuid.UUID
    SubmittedAt time.Time
}

// NewOrder 创建订单 (生成事件)
func NewOrder(customerID uuid.UUID) *Order {
    order := &Order{
        id:      uuid.New(),
        events:  make([]interface{}, 0),
        version: 0,
    }

    // 应用事件
    order.apply(OrderCreated{
        OrderID:    order.id,
        CustomerID: customerID,
        CreatedAt:  time.Now(),
    })

    return order
}

// AddItem 添加订单项 (生成事件)
func (o *Order) AddItem(productID uuid.UUID, quantity int, price int64) error {
    o.apply(OrderItemAdded{
        OrderID:   o.id,
        ProductID: productID,
        Quantity:  quantity,
        Price:     price,
    })
    return nil
}

// apply 应用事件到聚合
func (o *Order) apply(event interface{}) {
    switch e := event.(type) {
    case OrderCreated:
        o.id = e.OrderID
        // 更新状态...

    case OrderItemAdded:
        // 添加订单项...

    case OrderSubmitted:
        // 更新状态为已提交...
    }

    o.events = append(o.events, event)
    o.version++
}

// GetUncommittedEvents 获取未提交的事件
func (o *Order) GetUncommittedEvents() []interface{} {
    return o.events
}

// 从事件重建聚合
func ReconstructOrder(events []interface{}) *Order {
    order := &Order{
        events:  make([]interface{}, 0),
        version: 0,
    }

    for _, event := range events {
        order.apply(event)
    }

    return order
}
```

### 模式 4: CQRS (命令查询职责分离)

**用途**: 分离读写模型,通过事件同步

```go
package cqrs

// 命令模型 (写)
type OrderCommandModel struct {
    eventStore EventStore
}

func (m *OrderCommandModel) PlaceOrder(cmd PlaceOrderCommand) error {
    // 1. 加载聚合
    events, _ := m.eventStore.Load(cmd.OrderID)
    order := ReconstructOrder(events)

    // 2. 执行命令
    order.Submit()

    // 3. 保存事件
    return m.eventStore.Append(cmd.OrderID, order.GetUncommittedEvents())
}

// 查询模型 (读)
type OrderQueryModel struct {
    db *sql.DB
}

func (m *OrderQueryModel) GetOrdersByCustomer(customerID uuid.UUID) ([]*OrderDTO, error) {
    // 直接查询读模型数据库
    rows, err := m.db.Query(`
        SELECT id, total_amount, status, created_at
        FROM order_read_model
        WHERE customer_id = ?
    `, customerID)
    // ...
}

// 事件处理器 (同步读模型)
type OrderEventHandler struct {
    db *sql.DB
}

func (h *OrderEventHandler) Handle(event cloudevents.Event) error {
    switch event.Type() {
    case "com.example.order.created":
        var data OrderCreated
        event.DataAs(&data)
        return h.handleOrderCreated(data)

    case "com.example.order.item.added":
        var data OrderItemAdded
        event.DataAs(&data)
        return h.handleOrderItemAdded(data)
    }
    return nil
}

func (h *OrderEventHandler) handleOrderCreated(data OrderCreated) error {
    _, err := h.db.Exec(`
        INSERT INTO order_read_model (id, customer_id, status, created_at)
        VALUES (?, ?, 'draft', ?)
    `, data.OrderID, data.CustomerID, data.CreatedAt)
    return err
}
```

### 模式 5: Saga 模式

**用途**: 协调分布式事务

```go
package saga

// OrderSaga 订单 Saga
type OrderSaga struct {
    eventBus EventBus
    state    SagaState
}

type SagaState struct {
    OrderID       uuid.UUID
    InventoryOK   bool
    PaymentOK     bool
    ShippingOK    bool
}

// Execute 执行 Saga
func (s *OrderSaga) Execute(orderID uuid.UUID) error {
    s.state.OrderID = orderID

    // 步骤 1: 预留库存
    if err := s.reserveInventory(); err != nil {
        return err
    }

    // 步骤 2: 处理支付
    if err := s.processPayment(); err != nil {
        // 补偿: 释放库存
        s.releaseInventory()
        return err
    }

    // 步骤 3: 安排配送
    if err := s.arrangeShipping(); err != nil {
        // 补偿: 退款和释放库存
        s.refundPayment()
        s.releaseInventory()
        return err
    }

    return nil
}

func (s *OrderSaga) reserveInventory() error {
    event := InventoryReserveRequested{
        OrderID: s.state.OrderID,
    }
    return s.eventBus.Publish(event.ToCloudEvent())
}

func (s *OrderSaga) releaseInventory() error {
    event := InventoryReleaseRequested{
        OrderID: s.state.OrderID,
    }
    return s.eventBus.Publish(event.ToCloudEvent())
}
```

### 模式 6: 事件版本管理

**用途**: 支持事件结构演化

```go
package event

// V1: 初始版本
type UserCreatedV1 struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
}

// V2: 添加字段
type UserCreatedV2 struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Name   string `json:"name"` // 新增
}

// 向上转换器
type EventUpconverter interface {
    Upconvert(event interface{}) (interface{}, error)
}

type UserCreatedV1ToV2 struct{}

func (u *UserCreatedV1ToV2) Upconvert(event interface{}) (interface{}, error) {
    v1, ok := event.(*UserCreatedV1)
    if !ok {
        return event, nil
    }

    // V1 → V2 转换
    return &UserCreatedV2{
        UserID: v1.UserID,
        Email:  v1.Email,
        Name:   "", // 默认值
    }, nil
}

// 版本化事件处理器
type VersionedEventHandler struct {
    upconverters []EventUpconverter
}

func (h *VersionedEventHandler) Handle(event cloudevents.Event) error {
    var data interface{}

    // 根据类型解析
    switch event.Type() {
    case "com.example.user.created.v1":
        var v1 UserCreatedV1
        event.DataAs(&v1)
        data = &v1

    case "com.example.user.created.v2":
        var v2 UserCreatedV2
        event.DataAs(&v2)
        data = &v2
    }

    // 向上转换到最新版本
    for _, upconverter := range h.upconverters {
        var err error
        data, err = upconverter.Upconvert(data)
        if err != nil {
            return err
        }
    }

    // 使用最新版本处理
    v2 := data.(*UserCreatedV2)
    return h.processUserCreatedV2(v2)
}
```

## 事件存储模式

### 模式 1: 追加日志 (Append-Only Log)

```go
package eventstore

// EventStore 事件存储接口
type EventStore interface {
    Append(aggregateID uuid.UUID, events []Event) error
    Load(aggregateID uuid.UUID) ([]Event, error)
    LoadFrom(aggregateID uuid.UUID, version int) ([]Event, error)
}

// PostgreSQL 实现
type PostgreSQLEventStore struct {
    db *sql.DB
}

func (s *PostgreSQLEventStore) Append(aggregateID uuid.UUID, events []Event) error {
    tx, _ := s.db.Begin()
    defer tx.Rollback()

    // 获取当前版本
    var currentVersion int
    err := tx.QueryRow(`
        SELECT COALESCE(MAX(version), 0)
        FROM events
        WHERE aggregate_id = $1
    `, aggregateID).Scan(&currentVersion)
    if err != nil {
        return err
    }

    // 追加事件 (乐观锁)
    for i, event := range events {
        version := currentVersion + i + 1
        data, _ := json.Marshal(event)

        _, err := tx.Exec(`
            INSERT INTO events (aggregate_id, version, event_type, event_data, occurred_at)
            VALUES ($1, $2, $3, $4, $5)
        `, aggregateID, version, event.Type(), data, event.Time())

        if err != nil {
            return err
        }
    }

    return tx.Commit()
}

func (s *PostgreSQLEventStore) Load(aggregateID uuid.UUID) ([]Event, error) {
    rows, err := s.db.Query(`
        SELECT event_data FROM events
        WHERE aggregate_id = $1
        ORDER BY version
    `, aggregateID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var events []Event
    for rows.Next() {
        var data []byte
        rows.Scan(&data)

        var event Event
        json.Unmarshal(data, &event)
        events = append(events, event)
    }

    return events, nil
}
```

### 模式 2: 快照 (Snapshot)

```go
package eventstore

// 快照
type Snapshot struct {
    AggregateID uuid.UUID
    Version     int
    State       interface{}
    CreatedAt   time.Time
}

// EventStoreWithSnapshot 支持快照的事件存储
type EventStoreWithSnapshot struct {
    eventStore    EventStore
    snapshotStore SnapshotStore
    snapshotFreq  int // 快照频率
}

// Load 加载聚合 (使用快照优化)
func (s *EventStoreWithSnapshot) Load(aggregateID uuid.UUID) (*Order, error) {
    // 1. 加载最新快照
    snapshot, err := s.snapshotStore.LoadLatest(aggregateID)
    if err != nil && err != ErrSnapshotNotFound {
        return nil, err
    }

    var order *Order
    var fromVersion int

    if snapshot != nil {
        // 从快照恢复
        order = snapshot.State.(*Order)
        fromVersion = snapshot.Version
    } else {
        // 从头开始
        order = &Order{}
        fromVersion = 0
    }

    // 2. 加载快照之后的事件
    events, err := s.eventStore.LoadFrom(aggregateID, fromVersion)
    if err != nil {
        return nil, err
    }

    // 3. 重放事件
    for _, event := range events {
        order.apply(event)
    }

    return order, nil
}

// Save 保存聚合 (创建快照)
func (s *EventStoreWithSnapshot) Save(order *Order) error {
    events := order.GetUncommittedEvents()

    // 1. 保存事件
    if err := s.eventStore.Append(order.ID(), events); err != nil {
        return err
    }

    // 2. 检查是否需要创建快照
    if order.version%s.snapshotFreq == 0 {
        snapshot := &Snapshot{
            AggregateID: order.ID(),
            Version:     order.version,
            State:       order,
            CreatedAt:   time.Now(),
        }
        s.snapshotStore.Save(snapshot)
    }

    return nil
}
```

## 事件处理模式

### 模式 1: 至少一次 (At-Least-Once)

```go
package handler

// 幂等事件处理器
type IdempotentEventHandler struct {
    processedEvents map[string]bool // 已处理事件 ID
    mu              sync.RWMutex
}

func (h *IdempotentEventHandler) Handle(event cloudevents.Event) error {
    h.mu.RLock()
    processed := h.processedEvents[event.ID()]
    h.mu.RUnlock()

    if processed {
        log.Printf("Event %s already processed, skipping", event.ID())
        return nil
    }

    // 处理事件
    if err := h.process(event); err != nil {
        return err
    }

    // 标记为已处理
    h.mu.Lock()
    h.processedEvents[event.ID()] = true
    h.mu.Unlock()

    return nil
}
```

### 模式 2: 死信队列 (Dead Letter Queue)

```go
package handler

// DeadLetterHandler 死信处理器
type DeadLetterHandler struct {
    maxRetries int
    dlqPublisher EventPublisher
}

func (h *DeadLetterHandler) Handle(event cloudevents.Event) error {
    retries := h.getRetryCount(event)

    // 处理事件
    err := h.process(event)
    if err == nil {
        return nil
    }

    // 检查重试次数
    if retries >= h.maxRetries {
        // 发送到死信队列
        return h.sendToDeadLetterQueue(event, err)
    }

    // 增加重试计数并重新发布
    h.incrementRetryCount(event)
    return err
}

func (h *DeadLetterHandler) sendToDeadLetterQueue(event cloudevents.Event, err error) error {
    dlqEvent := cloudevents.NewEvent()
    dlqEvent.SetType("dlq." + event.Type())
    dlqEvent.SetSource("dead-letter-queue")
    dlqEvent.SetData(cloudevents.ApplicationJSON, map[string]interface{}{
        "original_event": event,
        "error":          err.Error(),
        "failed_at":      time.Now(),
    })

    return h.dlqPublisher.Publish(dlqEvent)
}
```

## 总结

事件驱动架构模式的关键实践:
- ✅ 事件通知 vs 事件携带状态
- ✅ 事件溯源 (Event Sourcing)
- ✅ CQRS 分离读写
- ✅ Saga 分布式事务
- ✅ 事件版本管理
- ✅ 快照优化性能
- ✅ 幂等处理保证一致性
- ✅ 死信队列处理失败
