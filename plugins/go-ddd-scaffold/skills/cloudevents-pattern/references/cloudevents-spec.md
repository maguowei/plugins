# CloudEvents 完整规范

## CloudEvents 简介

CloudEvents 是 CNCF (Cloud Native Computing Foundation) 的云原生事件规范,旨在提供统一的事件描述格式,实现跨平台、跨语言的事件互操作性。

**官方网站**: https://cloudevents.io
**规范版本**: v1.0.2
**GitHub**: https://github.com/cloudevents/spec

**核心目标**:
- 统一事件格式,消除厂商锁定
- 简化事件声明和传递
- 促进跨服务、跨平台的互操作性
- 支持多种协议 (HTTP, AMQP, Kafka, NATS 等)

## 核心属性

### 必需属性 (Required)

```go
type CloudEvent struct {
    // id: 事件唯一标识
    // - 必须在事件来源的上下文中唯一
    // - 推荐使用 UUID
    ID string `json:"id"`

    // source: 事件来源
    // - 标识事件的生产者
    // - URI 引用格式
    // - 示例: "/myservice", "https://example.com/service"
    Source string `json:"source"`

    // specversion: CloudEvents 规范版本
    // - 当前固定为 "1.0"
    SpecVersion string `json:"specversion"`

    // type: 事件类型
    // - 描述事件的性质
    // - 反向 DNS 命名推荐: "com.example.object.action"
    // - 示例: "com.github.pull_request.opened"
    Type string `json:"type"`
}
```

**示例**:
```json
{
  "id": "A234-1234-1234",
  "source": "/myservice/users",
  "specversion": "1.0",
  "type": "com.example.user.created"
}
```

### 可选属性 (Optional)

```go
type CloudEvent struct {
    // datacontenttype: 数据内容类型
    // - MIME 类型 (如 "application/json", "text/xml")
    // - 默认: "application/json"
    DataContentType string `json:"datacontenttype,omitempty"`

    // dataschema: 数据 Schema URI
    // - 定义数据结构的 Schema
    // - 示例: "https://example.com/schema/user"
    DataSchema string `json:"dataschema,omitempty"`

    // subject: 事件主体
    // - 事件涉及的具体对象
    // - 示例: "user/123", "order/456"
    Subject string `json:"subject,omitempty"`

    // time: 事件发生时间
    // - RFC 3339 格式
    // - 示例: "2024-01-15T10:30:00Z"
    Time string `json:"time,omitempty"`

    // data: 事件负载数据
    // - 实际的事件内容
    Data interface{} `json:"data,omitempty"`

    // data_base64: Base64 编码的数据
    // - 用于二进制数据
    DataBase64 string `json:"data_base64,omitempty"`
}
```

**完整示例**:
```json
{
  "id": "A234-1234-1234",
  "source": "/myservice/users",
  "specversion": "1.0",
  "type": "com.example.user.created",
  "datacontenttype": "application/json",
  "dataschema": "https://example.com/schema/user",
  "subject": "user/123",
  "time": "2024-01-15T10:30:00Z",
  "data": {
    "user_id": "123",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

## Go SDK 使用

### 安装

```bash
go get github.com/cloudevents/sdk-go/v2
```

### 创建事件

```go
package main

import (
    "time"
    "github.com/google/uuid"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// 创建简单事件
func CreateSimpleEvent() cloudevents.Event {
    event := cloudevents.NewEvent()

    // 设置必需属性
    event.SetID(uuid.New().String())
    event.SetSource("myservice/users")
    event.SetType("com.example.user.created")

    return event
}

// 创建完整事件
func CreateFullEvent() cloudevents.Event {
    event := cloudevents.NewEvent()

    // 必需属性
    event.SetID(uuid.New().String())
    event.SetSource("myservice/users")
    event.SetType("com.example.user.created")

    // 可选属性
    event.SetSubject("user/123")
    event.SetTime(time.Now())
    event.SetDataContentType("application/json")

    // 设置数据
    data := map[string]interface{}{
        "user_id": "123",
        "email":   "user@example.com",
        "name":    "John Doe",
    }
    event.SetData(cloudevents.ApplicationJSON, data)

    return event
}
```

### 解析事件

```go
package main

import (
    "encoding/json"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// UserCreatedData 用户创建数据
type UserCreatedData struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Name   string `json:"name"`
}

// 从 JSON 解析事件
func ParseEventFromJSON(jsonData []byte) (cloudevents.Event, error) {
    var event cloudevents.Event
    err := json.Unmarshal(jsonData, &event)
    return event, err
}

// 解析事件数据
func ParseEventData(event cloudevents.Event) (*UserCreatedData, error) {
    var data UserCreatedData
    if err := event.DataAs(&data); err != nil {
        return nil, err
    }
    return &data, nil
}

// 使用示例
func HandleEvent(jsonData []byte) error {
    // 1. 解析事件
    event, err := ParseEventFromJSON(jsonData)
    if err != nil {
        return err
    }

    // 2. 检查事件类型
    if event.Type() != "com.example.user.created" {
        return nil // 忽略其他类型
    }

    // 3. 解析数据
    data, err := ParseEventData(event)
    if err != nil {
        return err
    }

    // 4. 处理事件
    log.Printf("User created: %s (%s)", data.Name, data.Email)
    return nil
}
```

### 验证事件

```go
package main

import (
    "fmt"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// ValidateEvent 验证事件
func ValidateEvent(event cloudevents.Event) error {
    // 验证必需属性
    if event.ID() == "" {
        return fmt.Errorf("missing required attribute: id")
    }
    if event.Source() == "" {
        return fmt.Errorf("missing required attribute: source")
    }
    if event.Type() == "" {
        return fmt.Errorf("missing required attribute: type")
    }
    if event.SpecVersion() == "" {
        return fmt.Errorf("missing required attribute: specversion")
    }

    // 使用 SDK 内置验证
    if err := event.Validate(); err != nil {
        return fmt.Errorf("invalid event: %w", err)
    }

    return nil
}
```

## 协议绑定

### HTTP 协议绑定

#### Binary Content Mode (推荐)

```go
package main

import (
    "net/http"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// 发送事件 (Binary Mode)
func SendEventBinary(event cloudevents.Event) error {
    client := &http.Client{}

    req, err := http.NewRequest("POST", "https://example.com/events", nil)
    if err != nil {
        return err
    }

    // 将事件属性映射到 HTTP Headers
    req.Header.Set("ce-id", event.ID())
    req.Header.Set("ce-source", event.Source())
    req.Header.Set("ce-type", event.Type())
    req.Header.Set("ce-specversion", event.SpecVersion())

    // 可选属性
    if event.Subject() != "" {
        req.Header.Set("ce-subject", event.Subject())
    }
    if event.Time().IsZero() == false {
        req.Header.Set("ce-time", event.Time().Format(time.RFC3339))
    }

    // 数据作为 Body
    req.Header.Set("Content-Type", event.DataContentType())
    // req.Body = event data

    resp, err := client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    return nil
}

// 接收事件 (Binary Mode)
func ReceiveEventBinary(r *http.Request) (cloudevents.Event, error) {
    event := cloudevents.NewEvent()

    // 从 Headers 读取事件属性
    event.SetID(r.Header.Get("ce-id"))
    event.SetSource(r.Header.Get("ce-source"))
    event.SetType(r.Header.Get("ce-type"))
    event.SetSpecVersion(r.Header.Get("ce-specversion"))

    // 可选属性
    if subject := r.Header.Get("ce-subject"); subject != "" {
        event.SetSubject(subject)
    }

    // 从 Body 读取数据
    // ...

    return event, nil
}
```

#### Structured Content Mode

```go
// 发送事件 (Structured Mode)
func SendEventStructured(event cloudevents.Event) error {
    // 序列化整个事件为 JSON
    data, err := json.Marshal(event)
    if err != nil {
        return err
    }

    req, err := http.NewRequest("POST", "https://example.com/events", bytes.NewBuffer(data))
    if err != nil {
        return err
    }

    // Content-Type 必须是 application/cloudevents+json
    req.Header.Set("Content-Type", "application/cloudevents+json")

    // 发送请求
    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    return nil
}
```

### Kafka 协议绑定

```go
package main

import (
    "encoding/json"
    "github.com/segmentio/kafka-go"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// 发送事件到 Kafka
func SendEventToKafka(event cloudevents.Event, topic string) error {
    writer := &kafka.Writer{
        Addr:     kafka.TCP("localhost:9092"),
        Topic:    topic,
        Balancer: &kafka.LeastBytes{},
    }
    defer writer.Close()

    // 序列化事件
    data, err := json.Marshal(event)
    if err != nil {
        return err
    }

    // 发送消息
    return writer.WriteMessages(context.Background(),
        kafka.Message{
            Key:   []byte(event.ID()),
            Value: data,
            Headers: []kafka.Header{
                {Key: "ce-type", Value: []byte(event.Type())},
                {Key: "ce-source", Value: []byte(event.Source())},
            },
        },
    )
}

// 从 Kafka 读取事件
func ConsumeEventsFromKafka(topic string, handler func(cloudevents.Event) error) error {
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers: []string{"localhost:9092"},
        Topic:   topic,
    })
    defer reader.Close()

    for {
        msg, err := reader.ReadMessage(context.Background())
        if err != nil {
            return err
        }

        // 反序列化事件
        var event cloudevents.Event
        if err := json.Unmarshal(msg.Value, &event); err != nil {
            log.Printf("failed to unmarshal event: %v", err)
            continue
        }

        // 处理事件
        if err := handler(event); err != nil {
            log.Printf("handler error: %v", err)
        }
    }
}
```

## 扩展属性

### 自定义扩展

```go
package main

// 添加自定义扩展属性
func AddCustomExtensions(event cloudevents.Event) {
    // 扩展属性以小写字母开头
    event.SetExtension("traceid", "trace-123")
    event.SetExtension("spanid", "span-456")
    event.SetExtension("userid", "user-789")
    event.SetExtension("environment", "production")
}

// 读取扩展属性
func ReadCustomExtensions(event cloudevents.Event) {
    traceID, ok := event.Extensions()["traceid"]
    if ok {
        log.Printf("Trace ID: %v", traceID)
    }

    // 或者使用类型断言
    if userID, ok := event.Extensions()["userid"].(string); ok {
        log.Printf("User ID: %s", userID)
    }
}
```

### 分布式追踪扩展

```go
package main

import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

// 添加分布式追踪信息
func AddTracingContext(event cloudevents.Event, span trace.Span) {
    spanCtx := span.SpanContext()

    event.SetExtension("traceparent", formatTraceParent(spanCtx))
    event.SetExtension("tracestate", spanCtx.TraceState().String())
}

// W3C Trace Context 格式
func formatTraceParent(spanCtx trace.SpanContext) string {
    return fmt.Sprintf("00-%s-%s-%02x",
        spanCtx.TraceID().String(),
        spanCtx.SpanID().String(),
        spanCtx.TraceFlags(),
    )
}

// 从事件提取追踪上下文
func ExtractTracingContext(event cloudevents.Event) trace.SpanContext {
    if traceparent, ok := event.Extensions()["traceparent"].(string); ok {
        // 解析 traceparent
        // ...
    }
    return trace.SpanContext{}
}
```

## 事件类型规范

### 类型命名约定

```go
// ✅ 推荐: 反向 DNS 命名
"com.example.user.created"
"com.github.pull_request.opened"
"io.kubernetes.pod.scheduled"

// ✅ 推荐: 分层命名
"organization.service.object.action"
"mycompany.userservice.user.created"
"mycompany.orderservice.order.submitted"

// ❌ 避免: 过于简单
"created"
"updated"

// ❌ 避免: 使用现在时
"create"
"update"
```

### 事件类型注册

```go
package event

// 集中定义事件类型常量
const (
    TypeUserCreated       = "com.example.user.created"
    TypeUserUpdated       = "com.example.user.updated"
    TypeUserDeleted       = "com.example.user.deleted"
    TypeOrderPlaced       = "com.example.order.placed"
    TypeOrderCancelled    = "com.example.order.cancelled"
    TypePaymentProcessed  = "com.example.payment.processed"
)

// 事件类型注册表
var EventTypeRegistry = map[string]interface{}{
    TypeUserCreated:      &UserCreatedData{},
    TypeUserUpdated:      &UserUpdatedData{},
    TypeOrderPlaced:      &OrderPlacedData{},
    TypePaymentProcessed: &PaymentProcessedData{},
}

// 根据类型创建数据结构
func NewDataByType(eventType string) interface{} {
    if prototype, ok := EventTypeRegistry[eventType]; ok {
        // 返回新实例
        return reflect.New(reflect.TypeOf(prototype).Elem()).Interface()
    }
    return nil
}
```

## 事件版本管理

### 版本化策略

```go
package event

// V1: 初始版本
const TypeUserCreatedV1 = "com.example.user.created.v1"

type UserCreatedV1 struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
}

// V2: 添加字段
const TypeUserCreatedV2 = "com.example.user.created.v2"

type UserCreatedV2 struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Name   string `json:"name"` // 新增字段
}

// 向后兼容的处理器
func HandleUserCreated(event cloudevents.Event) error {
    switch event.Type() {
    case TypeUserCreatedV1:
        var data UserCreatedV1
        event.DataAs(&data)
        return processUserCreatedV1(data)

    case TypeUserCreatedV2:
        var data UserCreatedV2
        event.DataAs(&data)
        return processUserCreatedV2(data)

    default:
        return fmt.Errorf("unsupported event type: %s", event.Type())
    }
}
```

## 最佳实践

### 1. 事件设计原则

```go
// ✅ 正确: 事件表示过去发生的事实
type UserCreated struct {
    UserID    string    `json:"user_id"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
}

// ❌ 错误: 事件包含命令意图
type CreateUser struct {
    Email    string `json:"email"`
    Password string `json:"password"`
}
```

### 2. 事件粒度

```go
// ✅ 正确: 细粒度事件
type UserEmailChanged struct {
    UserID   string `json:"user_id"`
    OldEmail string `json:"old_email"`
    NewEmail string `json:"new_email"`
}

type UserNameChanged struct {
    UserID  string `json:"user_id"`
    OldName string `json:"old_name"`
    NewName string `json:"new_name"`
}

// ❌ 错误: 粗粒度事件
type UserUpdated struct {
    UserID string                 `json:"user_id"`
    Fields map[string]interface{} `json:"fields"`
}
```

### 3. 事件不可变性

```go
// ✅ 正确: 事件包含完整信息,不依赖外部状态
type OrderPlaced struct {
    OrderID     string        `json:"order_id"`
    UserID      string        `json:"user_id"`
    Items       []OrderItem   `json:"items"`
    TotalAmount int64         `json:"total_amount"`
    PlacedAt    time.Time     `json:"placed_at"`
}

// ❌ 错误: 事件只包含 ID,需要查询获取详情
type OrderPlaced struct {
    OrderID string `json:"order_id"`
}
```

## 总结

CloudEvents 规范的关键要点:
- ✅ 统一的事件格式标准
- ✅ 跨平台、跨语言互操作性
- ✅ 支持多种协议绑定
- ✅ 扩展属性机制
- ✅ 版本化支持
- ✅ 分布式追踪集成
- ✅ 事件类型注册表
- ✅ 向后兼容的版本管理
