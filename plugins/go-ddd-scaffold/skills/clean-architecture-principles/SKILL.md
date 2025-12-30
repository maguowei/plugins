---
name: Clean Architecture Principles
description: This skill should be used when the user asks about "Clean Architecture", "SOLID principles", "dependency inversion", "single responsibility", "open-closed principle", "Uncle Bob architecture", "hexagonal architecture", or needs guidance on applying clean architecture and SOLID principles in Go projects.
version: 0.1.0
---

# 整洁架构与 SOLID 原则

## 概述

整洁架构 (Clean Architecture) 和 SOLID 原则是构建可维护、可测试软件的基石。本技能解释如何在 Go DDD 项目中应用这些原则。

## SOLID 原则

### 1. Single Responsibility Principle (单一职责原则)

**定义**: 一个类(或模块)应该只有一个引起它变化的原因。

**Go 实践**:

```go
// ❌ 违反 SRP: UserService 职责过多
type UserService struct {}

func (s *UserService) CreateUser() {}
func (s *UserService) SendEmail() {}
func (s *UserService) LogActivity() {}
func (s *UserService) ValidateInput() {}

// ✅ 遵循 SRP: 职责分离
type UserService struct {
    emailService *EmailService
    logger       *Logger
    validator    *Validator
}

type EmailService struct {}
func (s *EmailService) Send() {}

type Logger struct {}
func (l *Logger) Log() {}
```

### 2. Open-Closed Principle (开闭原则)

**定义**: 软件实体应该对扩展开放，对修改关闭。

**Go 实践**:

```go
// ✅ 使用接口实现扩展
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

### 3. Liskov Substitution Principle (里氏替换原则)

**定义**: 子类型必须能够替换掉它们的基类型。

**Go 实践**:

```go
// Repository 接口的所有实现都可互相替换
type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
}

// Ent 实现
type EntUserRepository struct { client *ent.Client }

// GORM 实现
type GormUserRepository struct { db *gorm.DB }

// Mock 实现 (用于测试)
type MockUserRepository struct { mock.Mock }

// 应用服务可以使用任何实现
type UserApplicationService struct {
    repo UserRepository  // 可以是上述任何实现
}
```

### 4. Interface Segregation Principle (接口隔离原则)

**定义**: 客户端不应该依赖它不需要的接口。

**Go 实践**:

```go
// ❌ 违反 ISP: 臃肿接口
type UserRepository interface {
    Save(user *User) error
    FindByID(id uuid.UUID) (*User, error)
    FindByEmail(email string) (*User, error)
    Delete(id uuid.UUID) error
    Authenticate(email, password string) (*User, error)
    ResetPassword(email string) error
    UpdateProfile(id uuid.UUID, profile Profile) error
}

// ✅ 遵循 ISP: 细分接口
type UserRepository interface {
    Save(user *User) error
    FindByID(id uuid.UUID) (*User, error)
}

type UserQueryRepository interface {
    FindByEmail(email string) (*User, error)
    List(offset, limit int) ([]*User, error)
}

type UserAuthRepository interface {
    Authenticate(email, password string) (*User, error)
}
```

### 5. Dependency Inversion Principle (依赖倒置原则)

**定义**: 高层模块不应该依赖低层模块，两者都应该依赖抽象。

**Go 实践**:

```go
// ✅ 接口在高层定义 (Domain Layer)
// internal/app/domain/user/repository/user_repository.go
package repository

type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
}

// ✅ 实现在低层 (Infrastructure Layer)
// internal/app/infrastructure/repository/user_repository_impl.go
package repository

type EntUserRepository struct {
    client *ent.Client
}

func (r *EntUserRepository) Save(ctx context.Context, user *entity.User) error {
    // Ent 实现细节
}

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

**关键点**:
- Domain Layer 是核心，不依赖任何层
- Infrastructure 实现 Domain 定义的接口
- 所有依赖指向内层

### 独立性

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
// Domain 层可以无需数据库测试
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
    Save(ctx context.Context, user *User) error  // 不返回 SQL 错误
}
```

## 在 DDD 中应用

### 层次与职责

**Domain Layer** (核心业务逻辑):
- ✅ 纯 Go 代码
- ✅ 业务规则
- ❌ 不依赖框架
- ❌ 不包含 HTTP/DB 代码

**Application Layer** (用例编排):
- ✅ 调用 Domain Services
- ✅ 事务管理
- ❌ 不包含业务逻辑
- ❌ 不直接操作数据库

**Infrastructure Layer** (技术实现):
- ✅ ORM实现
- ✅ 外部服务集成
- ✅ 实现 Domain 接口

**Interface Layer** (外部接口):
- ✅ HTTP/gRPC 处理
- ✅ DTO 转换
- ❌ 不包含业务逻辑

### 依赖注入示例

```go
// main.go - 组装依赖
func main() {
    // Infrastructure
    dbClient := initDatabase()
    userRepo := repository.NewEntUserRepository(dbClient)

    // Domain
    domainService := service.NewUserDomainService(userRepo)

    // Application
    appService := application.NewUserApplicationService(userRepo, domainService)

    // Interface
    handler := handler.NewUserHandler(appService)
    router := http.NewRouter(handler)

    router.Run(":8080")
}
```

## 边界和抽象

### 使用接口定义边界

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

### DTO 隔离层

```go
// Interface Layer DTO
type CreateUserRequest struct {
    Email string `json:"email"`
    Name  string `json:"name"`
}

// Application Layer DTO
type CreateUserCommand struct {
    Email string
    Name  string
}

// Domain Entity
type User struct {
    id    uuid.UUID
    email Email
    name  string
}
```

## 测试策略

### Domain Layer 测试

```go
// 纯单元测试，无外部依赖
func TestUser_ChangeEmail(t *testing.T) {
    user := NewUser(Email{"old@example.com"}, "Test")
    newEmail := Email{"new@example.com"}

    err := user.ChangeEmail(newEmail)

    assert.NoError(t, err)
    assert.Equal(t, newEmail, user.Email())
}
```

### Application Layer 测试

```go
// 使用 Mock Repository
func TestCreateUser(t *testing.T) {
    mockRepo := new(MockUserRepository)
    mockRepo.On("Save", mock.Anything, mock.Anything).Return(nil)

    service := NewUserApplicationService(mockRepo, nil)

    cmd := CreateUserCommand{Email: "test@example.com", Name: "Test"}
    result, err := service.CreateUser(context.Background(), cmd)

    assert.NoError(t, err)
    assert.NotNil(t, result)
    mockRepo.AssertExpectations(t)
}
```

### Infrastructure Layer 测试

```go
// 集成测试
func TestEntUserRepository_Save(t *testing.T) {
    client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
    defer client.Close()

    repo := NewEntUserRepository(client)
    user := NewUser(Email{"test@example.com"}, "Test")

    err := repo.Save(context.Background(), user)

    assert.NoError(t, err)
}
```

## 常见陷阱

1. **Domain 层依赖框架**
   - ❌ `import "github.com/gin-gonic/gin"` in domain
   - ✅ Domain 层只依赖标准库和领域概念

2. **贫血模型**
   - ❌ Entity 只有 getter/setter
   - ✅ Entity 包含业务行为

3. **绕过应用层**
   - ❌ Handler 直接调用 Repository
   - ✅ Handler → Application Service → Domain

4. **基础设施层渗透**
   - ❌ 在 Domain 返回 SQL 错误
   - ✅ 转换为领域错误

## 总结

Clean Architecture + SOLID 的核心价值:

- **可维护性**: 清晰的职责分离
- **可测试性**: 每层独立测试
- **灵活性**: 可替换技术实现
- **业务聚焦**: 核心逻辑独立于技术

## 额外资源

- **`references/solid-examples.md`** - SOLID 详细示例
- **`references/clean-architecture-guide.md`** - Clean Architecture 完整指南
