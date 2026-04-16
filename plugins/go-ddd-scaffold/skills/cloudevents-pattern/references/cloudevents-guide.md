# CloudEvents 完整指南

## CloudEvents 规范

CloudEvents 是 CNCF 云原生事件规范 (v1.0.2)，提供统一的事件描述格式。

### 核心属性

| 属性 | 必需 | 说明 | 示例 |
|------|------|------|------|
| id | 是 | 事件唯一标识 | UUID |
| source | 是 | 事件来源 (URI) | "user-service" |
| specversion | 是 | 规范版本 | "1.0" |
| type | 是 | 事件类型 (反向 DNS) | "com.example.user.created" |
| datacontenttype | 否 | 数据格式 | "application/json" |
| subject | 否 | 事件主体 | "user/123" |
| time | 否 | 发生时间 (RFC3339) | "2024-01-15T10:30:00Z" |
| data | 否 | 事件负载 | JSON 对象 |

### Go SDK

```go
import cloudevents "github.com/cloudevents/sdk-go/v2"

event := cloudevents.NewEvent()
event.SetID(uuid.New().String())
event.SetSource("user-service")
event.SetType("com.example.user.created")
event.SetTime(time.Now())
event.SetData(cloudevents.ApplicationJSON, data)
```

### 类型命名约定

```
// 推荐: 反向 DNS + 过去式
"com.example.user.created"
"com.example.order.submitted"

// 集中定义常量
const TypeUserCreated = "com.example.user.created"
```

### 协议绑定

- **HTTP Binary Mode** (推荐): 属性映射到 `ce-*` Headers，数据作为 Body
- **HTTP Structured Mode**: 整个事件序列化为 `application/cloudevents+json`
- **Kafka**: 事件 JSON 序列化为消息 Value，`ce-type` 等放 Headers

### 扩展属性

```go
event.SetExtension("traceid", "trace-123")
event.SetExtension("userid", "user-789")
```

### 版本管理

```go
type UserCreatedV1 struct { UserID string; Email string }
type UserCreatedV2 struct { UserID string; Email string; Name string }

// 处理器按类型分发
switch event.Type() {
case "com.example.user.created.v1": ...
case "com.example.user.created.v2": ...
}
```

## 事件驱动架构模式

### 领域事件定义

```go
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
```

### 事件总线

```go
// Domain Layer 接口
type EventBus interface {
    Publish(event cloudevents.Event) error
    Subscribe(eventType string, handler EventHandler) error
}

// 内存实现
type MemoryEventBus struct {
    handlers map[string][]EventHandler
    mu       sync.RWMutex
}
```

### 事件发布 (Application Layer)

```go
func (s *UserApplicationService) CreateUser(ctx context.Context, req CreateUserRequest) (*UserResponse, error) {
    user, _ := entity.NewUser(email, req.Name)
    s.userRepo.Save(ctx, user)
    evt := event.NewUserCreated(user.ID(), user.Email().Value(), user.Name())
    if err := s.eventBus.Publish(evt.ToCloudEvent()); err != nil {
        slog.Error("failed to publish event", "error", err)
    }
    return ToUserResponse(user), nil
}
```

### 消息队列集成

**Kafka**:
```go
type KafkaEventBus struct { writer *kafka.Writer }

func (b *KafkaEventBus) Publish(event cloudevents.Event) error {
    data, _ := json.Marshal(event)
    return b.writer.WriteMessages(ctx, kafka.Message{
        Key: []byte(event.ID()), Value: data,
    })
}
```

**NATS**:
```go
func (b *NatsEventBus) Publish(event cloudevents.Event) error {
    data, _ := json.Marshal(event)
    return b.conn.Publish(event.Type(), data)
}
```

### 事件模式

| 模式 | 说明 |
|------|------|
| 事件通知 | 只含 ID，消费者需查询详情 |
| 事件携带状态 | 包含完整数据，消费者无需查询 (推荐) |
| Event Sourcing | 事件序列作为聚合状态的唯一真实来源 |
| CQRS | 命令写入事件，查询读模型，事件同步两者 |
| Saga | 协调分布式事务，失败时发布补偿事件 |

### 事件处理器模式

| 模式 | 说明 |
|------|------|
| 幂等处理 | 检查事件 ID 防止重复处理 |
| 重试机制 | RetryableHandler 装饰器 |
| 死信队列 | 超过最大重试次数后发送到 DLQ |
| 快照优化 | 定期保存聚合状态，加载时先恢复快照再重放事件 |

### 最终一致性

```go
// 订单服务发布事件
eventBus.Publish(OrderPlaced{OrderID: order.ID()}.ToCloudEvent())
// 库存服务订阅并处理
func (h *OrderPlacedHandler) Handle(event cloudevents.Event) error {
    return h.inventoryService.Reserve(data.Items)
}
```

## 最佳实践

1. 事件命名使用过去时 (UserCreated, OrderPlaced)
2. 事件包含完整上下文信息，不可变
3. 事件处理器支持幂等
4. 发布失败不阻止主流程
5. 使用版本化的事件类型
