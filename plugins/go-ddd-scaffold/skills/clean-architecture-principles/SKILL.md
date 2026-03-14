---
name: Clean Architecture Principles
description: 用户问"代码怎么解耦"、"怎么设计接口"、"SOLID 原则是什么"、"依赖倒置怎么做"、"单一职责怎么理解"、"Clean Architecture 和 DDD 什么关系"时触发。涵盖 SOLID 原则和整洁架构在 Go DDD 中的应用。
version: 0.2.0
---

# 整洁架构与 SOLID 原则

## 概述

整洁架构 (Clean Architecture) 和 SOLID 原则是构建可维护、可测试软件的基石。本技能聚焦如何在 Go DDD 项目中应用这些原则。

## SOLID 原则

### 1. Single Responsibility Principle (单一职责)

一个类/模块应该只有一个引起它变化的原因。

```go
// 违反: UserService 职责过多
type UserService struct {}
func (s *UserService) CreateUser() {}
func (s *UserService) SendEmail() {}
func (s *UserService) LogActivity() {}

// 遵循: 职责分离
type UserService struct {
    emailService *EmailService
    logger       *Logger
}
type EmailService struct {}
type Logger struct {}
```

### 2. Open-Closed Principle (开闭原则)

对扩展开放，对修改关闭。

```go
// 使用接口实现扩展
type NotificationSender interface {
    Send(message string) error
}

type EmailSender struct {}
func (e *EmailSender) Send(message string) error { /* ... */ }

type SMSSender struct {}
func (s *SMSSender) Send(message string) error { /* ... */ }

// 新增通知方式无需修改现有代码
type SlackSender struct {}
func (s *SlackSender) Send(message string) error { /* ... */ }
```

### 3. Liskov Substitution Principle (里氏替换)

接口的所有实现都可以互相替换。

```go
type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
}

// 以下实现可互相替换
type EntUserRepository struct { client *ent.Client }
type GormUserRepository struct { db *gorm.DB }
type MockUserRepository struct { mock.Mock }

// 应用服务不关心具体实现
type UserApplicationService struct {
    repo UserRepository
}
```

### 4. Interface Segregation Principle (接口隔离)

客户端不应该依赖它不需要的接口。

```go
// 违反: 臃肿接口
type UserRepository interface {
    Save(user *User) error
    FindByID(id uuid.UUID) (*User, error)
    Authenticate(email, password string) (*User, error)
    ResetPassword(email string) error
}

// 遵循: 细分接口
type UserRepository interface {
    Save(user *User) error
    FindByID(id uuid.UUID) (*User, error)
}

type UserQueryRepository interface {
    FindByEmail(email string) (*User, error)
    List(offset, limit int) ([]*User, error)
}
```

### 5. Dependency Inversion Principle (依赖倒置)

高层模块不依赖低层模块，两者都依赖抽象。

```go
// 接口在高层定义 (Domain Layer)
// internal/app/domain/user/repository/user_repository.go
type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
}

// 实现在低层 (Infrastructure Layer)
// internal/app/infrastructure/repository/user_repository_impl.go
type EntUserRepository struct { client *ent.Client }

// Application Layer 依赖接口，不依赖实现
type UserApplicationService struct {
    repo domain.UserRepository  // 依赖抽象
}
```

## Clean Architecture 核心概念

### 依赖规则

```
外层 → 内层 (只能单向依赖)
Interface → Application → Domain ← Infrastructure
```

Domain Layer 是核心，不依赖任何层。Infrastructure 实现 Domain 定义的接口。

### 三大独立性

**Framework Independent (框架独立)**:
```go
// Domain Layer 不依赖 Gin, Ent, Viper
type User struct {
    id    uuid.UUID
    email Email
    name  string
}
```

**Testable (可测试)**:
```go
// Domain 层无需数据库即可测试
func TestUser_ChangeName(t *testing.T) {
    user := NewUser(email, "Old Name")
    user.ChangeName("New Name")
    assert.Equal(t, "New Name", user.Name())
}
```

**Database Independent (数据库独立)**:
```go
// Repository 接口不暴露数据库细节
type UserRepository interface {
    Save(ctx context.Context, user *User) error
}
```

### 在 DDD 中应用

各层的 Clean Architecture 约束:

| 层 | 允许 | 禁止 |
|---|------|------|
| Domain | 纯 Go 代码、业务规则 | 框架依赖、HTTP/DB 代码 |
| Application | 调用 Domain Services、事务管理 | 业务逻辑、直接操作数据库 |
| Infrastructure | ORM 实现、外部服务集成 | 业务逻辑 |
| Interface | HTTP/gRPC 处理、DTO 转换 | 业务逻辑 |

层的详细职责和代码示例参见 ddd-layered-architecture skill。

### 边界和抽象

使用接口定义层间边界:

```go
// Domain 层定义接口
type EmailSender interface {
    Send(to, subject, body string) error
}

// Infrastructure 层实现
type SMTPEmailSender struct {
    host string
    port int
}

func (s *SMTPEmailSender) Send(to, subject, body string) error {
    // SMTP 实现细节
}
```

### DTO 隔离

每层有独立的数据结构:

```go
// 接口层 DTO
type CreateUserRequest struct {
    Email string `json:"email"`
    Name  string `json:"name"`
}

// 应用层 DTO
type CreateUserCommand struct {
    Email string
    Name  string
}

// 领域实体
type User struct {
    id    uuid.UUID
    email Email
    name  string
}
```

## 常见陷阱

1. **Domain 层依赖框架**: Domain 层只依赖标准库和领域概念
2. **贫血模型**: Entity 应包含业务行为，不只有 getter/setter
3. **绕过应用层**: Handler 不应直接调用 Repository
4. **基础设施层渗透**: Domain 不返回 SQL 错误，应转换为领域错误

## 总结

Clean Architecture + SOLID 的核心价值:

- **可维护性**: 清晰的职责分离
- **可测试性**: 每层独立测试
- **灵活性**: 可替换技术实现
- **业务聚焦**: 核心逻辑独立于技术
