# Clean Architecture 与 SOLID 原则

## SOLID 原则

### 1. Single Responsibility (单一职责)

一个模块只有一个引起它变化的原因。

```go
// 违反: User 包含业务逻辑 + DB 操作 + 序列化 + 邮件发送
// 遵循: User (业务), UserRepository (持久化), EmailService (通知)
```

### 2. Open-Closed (开闭原则)

对扩展开放，对修改关闭 -- 使用接口实现。

```go
type NotificationSender interface { Send(message string) error }
// EmailSender, SMSSender, SlackSender -- 新增无需改现有代码
```

**实现方式**: 策略模式 (PricingStrategy)、装饰器模式 (TimestampLogger)。

### 3. Liskov Substitution (里氏替换)

接口的所有实现都可以互相替换。

```go
type UserRepository interface { FindByID(...); Save(...) }
// EntUserRepo, GormUserRepo, MockUserRepo -- 对应用层透明
```

### 4. Interface Segregation (接口隔离)

客户端不依赖不需要的接口 -- 使用小接口。

```go
// Go 标准库示例: io.Reader, io.Writer, io.Closer
// DDD 示例:
type UserRepository interface { Save(...); FindByID(...) }
type UserQueryRepository interface { FindByEmail(...); List(...) }
```

### 5. Dependency Inversion (依赖倒置)

高层不依赖低层，两者都依赖抽象。

```go
// Domain 定义接口
type UserRepository interface { Save(ctx, user) error }
// Infrastructure 实现接口
type EntUserRepository struct { client *ent.Client }
// Application 依赖接口
type UserApplicationService struct { repo domain.UserRepository }
```

## Clean Architecture 核心

### 依赖规则

```
外层 -> 内层 (只能单向依赖)
Interface -> Application -> Domain <- Infrastructure
```

### 三大独立性

| 独立性 | 含义 |
|--------|------|
| Framework Independent | Domain 不依赖 Gin, Ent, Viper |
| Testable | Domain 无需数据库即可测试 |
| Database Independent | Repository 接口不暴露 DB 细节 |

### 各层约束

| 层 | 允许 | 禁止 |
|---|------|------|
| Domain | 纯 Go、业务规则 | 框架依赖、HTTP/DB 代码 |
| Application | 调用 Domain、事务管理 | 业务逻辑、直接操作 DB |
| Infrastructure | ORM、外部服务 | 业务逻辑 |
| Interface | HTTP/gRPC、DTO 转换 | 业务逻辑 |

### DTO 分层

```
HTTP Request
  -> Interface DTO (带 binding 校验)
  -> ToApplicationDTO() 转换
  -> Application DTO (纯数据)
  -> Application Service
  -> Domain Entity
```

### 边界抽象

```go
// Domain 定义
type EmailSender interface { Send(to, subject, body string) error }
// Infrastructure 实现
type SMTPEmailSender struct { host string; port int }
```

### 事件驱动

```go
// Domain: 定义事件
type UserCreated struct { UserID uuid.UUID; Email string }
// Application: 发布事件
s.eventPublisher.PublishBatch(ctx, user.DomainEvents())
// Infrastructure: 订阅处理
func (h *UserEventHandler) Handle(evt) { h.emailService.SendWelcome(...) }
```

## 常见陷阱

1. **Domain 依赖框架** -- Domain 只依赖标准库和领域概念
2. **贫血模型** -- Entity 应包含业务行为
3. **绕过应用层** -- Handler 不应直接调用 Repository
4. **基础设施渗透** -- Domain 不返回 SQL 错误，应转换为领域错误

## 测试优势

```go
// DIP 使测试简单: 注入 Mock
mockRepo := &MockUserRepository{users: map[uuid.UUID]*User{}}
svc := service.NewUserApplicationService(mockRepo)
// 无需数据库即可测试应用逻辑
```
