---
name: DDD Layered Architecture
description: This skill should be used when the user asks about "DDD four layers", "DDD layered architecture", "Domain layer", "Application layer", "Infrastructure layer", "Interface layer", "dependency rules", "how to organize DDD code", or needs guidance on structuring a DDD project with proper layer separation.
version: 0.1.0
---

# DDD 四层架构 (DDD Layered Architecture)

## 概述

DDD 采用分层架构将系统划分为四个层次,每层有明确的职责和依赖关系。这种分层确保核心业务逻辑独立于技术细节,提高了系统的可维护性和可测试性。

## 四层架构图

```
┌─────────────────────────────────────────────────────────┐
│  Interface Layer (接口层 / 用户界面层)                     │
│  - HTTP Handlers, gRPC Services                        │
│  - DTO (Data Transfer Objects)                         │
│  - Request/Response 转换                                 │
│  - 中间件 (认证、日志、错误处理)                           │
├─────────────────────────────────────────────────────────┤
│  Application Layer (应用层 / 应用服务层)                   │
│  - Application Services (用例编排)                       │
│  - 事务管理                                              │
│  - 调用 Domain Services 和 Repositories                 │
│  - DTO ↔ Domain Entity 转换                            │
├─────────────────────────────────────────────────────────┤
│  Domain Layer (领域层 / 核心业务逻辑层)                    │
│  - Entities, Value Objects                             │
│  - Domain Services                                     │
│  - Repository Interfaces (接口定义)                      │
│  - Domain Events                                       │
│  - 业务规则和不变式                                       │
├─────────────────────────────────────────────────────────┤
│  Infrastructure Layer (基础设施层 / 技术实现层)            │
│  - Repository Implementations (Ent, GORM)              │
│  - 外部服务集成 (Email, SMS, Payment)                    │
│  - 配置管理 (Viper)                                      │
│  - 可观测性 (日志, 监控, 追踪)                            │
│  - 消息队列, 缓存                                         │
└─────────────────────────────────────────────────────────┘
```

## 依赖规则 (Dependency Rule)

**核心原则**: 依赖关系只能由外向内,内层不能依赖外层。

```
Interface → Application → Domain ← Infrastructure
```

- ✅ **Interface Layer** 可以依赖 **Application Layer**
- ✅ **Application Layer** 可以依赖 **Domain Layer**
- ✅ **Infrastructure Layer** 实现 **Domain Layer** 定义的接口 (依赖倒置)
- ❌ **Domain Layer** 不能依赖任何其他层
- ❌ **Application Layer** 不能直接依赖 **Infrastructure Layer**

## 各层职责详解

### 1. Domain Layer (领域层)

**职责**: 表达业务概念、业务规则和业务逻辑的核心层。

**包含**:
- **Entities**: 有唯一标识的业务对象 (User, Order)
- **Value Objects**: 描述性概念 (Email, Money)
- **Domain Events**: 领域中发生的事件
- **Repository Interfaces**: 持久化接口定义
- **Domain Services**: 跨实体的业务逻辑
- **Aggregates**: 一致性边界

**目录结构**:
```
internal/app/domain/
└── user/                    # 按聚合组织
    ├── entity/
    │   └── user.go
    ├── valueobject/
    │   └── email.go
    ├── event/
    │   └── user_created.go
    ├── repository/
    │   └── user_repository.go   # 接口定义
    └── service/
        └── user_service.go
```

**示例代码**:

```go
// entity/user.go
package entity

type User struct {
    id    uuid.UUID
    email valueobject.Email
    name  string
}

func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    u.name = newName
    return nil
}

// repository/user_repository.go (接口定义)
package repository

type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
}
```

**关键原则**:
- 不依赖任何框架 (Gin, Ent, Viper)
- 使用纯 Go 代码表达业务逻辑
- 可以独立测试,无需数据库或 HTTP

详见 `references/domain-layer-guide.md`。

### 2. Application Layer (应用层)

**职责**: 编排领域对象完成业务用例,控制事务边界。

**包含**:
- **Application Services**: 用例实现
- **事务管理**: 开启、提交、回滚事务
- **DTO 转换**: Domain Entity ↔ DTO
- **调用编排**: 调用多个 Domain Services 或 Repositories

**目录结构**:
```
internal/app/application/
├── service/
│   └── user_application_service.go
└── dto/
    ├── user_dto.go
    └── mapper.go
```

**示例代码**:

```go
// service/user_application_service.go
package service

import (
    "context"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/repository"
    "myproject/internal/app/domain/user/service"
    "myproject/internal/app/application/dto"
)

type UserApplicationService struct {
    userRepo    repository.UserRepository
    domainSvc   *service.UserAuthenticationService
    eventBus    EventBus
    txManager   TransactionManager
}

// CreateUser 用例: 创建用户
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    // 开启事务
    tx, err := s.txManager.Begin(ctx)
    if err != nil {
        return nil, err
    }
    defer tx.Rollback()

    // 1. 检查邮箱唯一性 (调用领域服务)
    if err := s.domainSvc.CheckEmailUniqueness(ctx, req.Email); err != nil {
        return nil, err
    }

    // 2. 创建领域对象
    email, _ := valueobject.NewEmail(req.Email)
    user, err := entity.NewUser(email, req.Name)
    if err != nil {
        return nil, err
    }

    // 3. 持久化 (调用仓储)
    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 4. 发布领域事件
    event := event.NewUserCreated(user.ID(), user.Email().Value(), user.Name())
    s.eventBus.Publish(event)

    // 5. 提交事务
    if err := tx.Commit(); err != nil {
        return nil, err
    }

    // 6. DTO 转换
    return dto.ToUserResponse(user), nil
}
```

**关键原则**:
- 不包含业务逻辑,只编排
- 控制事务边界
- DTO 与 Domain Entity 转换在此层
- 无状态,可并发调用

详见 `references/application-layer-guide.md`。

### 3. Infrastructure Layer (基础设施层)

**职责**: 提供技术实现,支撑上层业务逻辑。

**包含**:
- **Repository Implementations**: ORM 实现 (Ent, GORM)
- **外部服务集成**: 第三方 API 客户端
- **配置管理**: Viper 配置读取
- **可观测性**: 日志、监控、追踪
- **消息队列**: Kafka, RabbitMQ
- **缓存**: Redis

**目录结构**:
```
internal/app/infrastructure/
├── repository/
│   └── user_repository_impl.go  # 实现 domain 接口
├── external/
│   ├── email/
│   │   └── smtp_client.go
│   └── payment/
│       └── stripe_client.go
├── config/
│   └── config.go               # Viper 配置
└── observability/
    ├── logger.go               # slog
    ├── metrics.go              # Prometheus
    └── tracing.go              # OpenTelemetry
```

**示例代码**:

```go
// repository/user_repository_impl.go
package repository

import (
    "context"
    "myproject/internal/app/domain/user/entity"
    domainrepo "myproject/internal/app/domain/user/repository"
    "myproject/pkg/ent"
)

// EntUserRepository Ent ORM 实现
type EntUserRepository struct {
    client *ent.Client
}

// 确保实现了接口
var _ domainrepo.UserRepository = (*EntUserRepository)(nil)

func NewEntUserRepository(client *ent.Client) domainrepo.UserRepository {
    return &EntUserRepository{client: client}
}

func (r *EntUserRepository) Save(ctx context.Context, user *entity.User) error {
    return r.client.User.
        Create().
        SetID(user.ID()).
        SetEmail(user.Email().Value()).
        SetName(user.Name()).
        OnConflict().
        UpdateNewValues().
        Exec(ctx)
}

func (r *EntUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    entUser, err := r.client.User.Get(ctx, id)
    if err != nil {
        if ent.IsNotFound(err) {
            return nil, domainrepo.ErrUserNotFound
        }
        return nil, err
    }
    return r.toDomain(entUser), nil
}

// ORM 对象转领域对象
func (r *EntUserRepository) toDomain(u *ent.User) *entity.User {
    email, _ := valueobject.NewEmail(u.Email)
    user, _ := entity.NewUser(email, u.Name)
    return user
}
```

**关键原则**:
- 实现 Domain 层定义的接口
- 隔离技术细节
- 可替换实现 (Ent → GORM)
- 通过接口与上层交互

详见 `references/infrastructure-layer-guide.md`。

### 4. Interface Layer (接口层)

**职责**: 处理外部请求,转换为应用层调用。

**包含**:
- **HTTP Handlers**: Gin handlers
- **gRPC Services**: gRPC 实现
- **DTO**: 请求响应数据结构
- **Middleware**: 认证、日志、错误处理
- **路由配置**: 路由注册

**目录结构**:
```
internal/app/interface/
├── http/
│   ├── handler/
│   │   └── user_handler.go
│   ├── dto/
│   │   ├── user_request.go
│   │   └── user_response.go
│   ├── middleware/
│   │   ├── auth.go
│   │   └── logger.go
│   └── router.go
└── grpc/
    └── user_service.go
```

**示例代码**:

```go
// handler/user_handler.go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "myproject/internal/app/application/service"
    "myproject/internal/app/interface/http/dto"
)

type UserHandler struct {
    appService *service.UserApplicationService
}

func NewUserHandler(appService *service.UserApplicationService) *UserHandler {
    return &UserHandler{appService: appService}
}

// CreateUser HTTP 处理器
func (h *UserHandler) CreateUser(c *gin.Context) {
    // 1. 解析请求
    var req dto.CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // 2. 调用应用层
    resp, err := h.appService.CreateUser(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // 3. 返回响应
    c.JSON(http.StatusCreated, resp)
}

// dto/user_request.go
type CreateUserRequest struct {
    Email string `json:"email" binding:"required,email"`
    Name  string `json:"name" binding:"required,min=1,max=100"`
}

// dto/user_response.go
type UserResponse struct {
    ID    string `json:"id"`
    Email string `json:"email"`
    Name  string `json:"name"`
}
```

**关键原则**:
- 只处理 HTTP/gRPC 协议层
- 不包含业务逻辑
- DTO 与 Application DTO 分离
- 统一错误处理

详见 `references/interface-layer-guide.md`。

## 层间交互流程

### 典型请求流程

```
1. HTTP Request
   ↓
2. Interface Layer (Handler)
   - 解析请求
   - 验证参数
   - DTO → Application DTO
   ↓
3. Application Layer (Application Service)
   - 开启事务
   - 调用 Domain Services
   - 调用 Repositories
   - 发布 Domain Events
   - 提交事务
   - Domain Entity → Response DTO
   ↓
4. Domain Layer
   - 执行业务逻辑
   - 保证不变式
   ↓
5. Infrastructure Layer (Repository)
   - 持久化数据
   - Domain Entity → ORM Entity
   ↓
6. Interface Layer (Handler)
   - Response DTO → HTTP Response
   ↓
7. HTTP Response
```

### 完整示例

创建用户的完整调用链:

```go
// 1. Interface Layer
func (h *UserHandler) CreateUser(c *gin.Context) {
    var req dto.CreateUserRequest
    c.ShouldBindJSON(&req)

    // 转换为应用层 DTO
    appReq := application.CreateUserRequest{
        Email: req.Email,
        Name:  req.Name,
    }

    // 调用应用层
    resp, err := h.appService.CreateUser(c.Request.Context(), appReq)
    c.JSON(200, resp)
}

// 2. Application Layer
func (s *UserApplicationService) CreateUser(ctx context.Context, req CreateUserRequest) (*UserResponse, error) {
    tx, _ := s.txManager.Begin(ctx)
    defer tx.Rollback()

    // 调用领域层
    email, _ := valueobject.NewEmail(req.Email)
    user, _ := entity.NewUser(email, req.Name)

    // 调用基础设施层
    s.userRepo.Save(ctx, user)

    tx.Commit()
    return ToUserResponse(user), nil
}

// 3. Domain Layer
func NewUser(email valueobject.Email, name string) (*User, error) {
    // 业务验证
    if name == "" {
        return nil, errors.New("name required")
    }
    return &User{id: uuid.New(), email: email, name: name}, nil
}

// 4. Infrastructure Layer
func (r *EntUserRepository) Save(ctx context.Context, user *entity.User) error {
    return r.client.User.Create().
        SetID(user.ID()).
        SetEmail(user.Email().Value()).
        SetName(user.Name()).
        Exec(ctx)
}
```

## 依赖注入

使用构造函数注入实现依赖倒置:

```go
// main.go 或 wire.go
func InitializeUserHandler(db *ent.Client) *handler.UserHandler {
    // Infrastructure Layer
    userRepo := repository.NewEntUserRepository(db)

    // Domain Layer
    domainService := service.NewUserAuthenticationService(userRepo)

    // Application Layer
    appService := application.NewUserApplicationService(userRepo, domainService)

    // Interface Layer
    userHandler := handler.NewUserHandler(appService)

    return userHandler
}
```

## 测试策略

### Domain Layer 测试

纯单元测试,无需外部依赖:

```go
func TestUser_ChangeName(t *testing.T) {
    email, _ := valueobject.NewEmail("test@example.com")
    user, _ := entity.NewUser(email, "OldName")

    err := user.ChangeName("NewName")

    assert.NoError(t, err)
    assert.Equal(t, "NewName", user.Name())
}
```

### Application Layer 测试

使用 Mock Repository:

```go
func TestCreateUser(t *testing.T) {
    mockRepo := new(MockUserRepository)
    mockRepo.On("Save", mock.Anything, mock.Anything).Return(nil)

    service := NewUserApplicationService(mockRepo, nil)

    req := CreateUserRequest{Email: "test@example.com", Name: "Test"}
    resp, err := service.CreateUser(context.Background(), req)

    assert.NoError(t, err)
    assert.NotNil(t, resp)
}
```

### Interface Layer 测试

使用 httptest:

```go
func TestUserHandler_CreateUser(t *testing.T) {
    mockAppService := new(MockUserApplicationService)
    handler := NewUserHandler(mockAppService)

    router := gin.Default()
    router.POST("/users", handler.CreateUser)

    req := httptest.NewRequest("POST", "/users", bytes.NewBuffer([]byte(`{"email":"test@example.com","name":"Test"}`)))
    w := httptest.NewRecorder()

    router.ServeHTTP(w, req)

    assert.Equal(t, 201, w.Code)
}
```

## 常见问题

### Q: Application Layer 和 Domain Service 的区别?

**Application Service**:
- 编排用例
- 控制事务
- DTO 转换
- 可以调用多个 Domain Services 和 Repositories

**Domain Service**:
- 纯业务逻辑
- 无状态
- 不控制事务
- 不做 DTO 转换

### Q: 何时使用 Application Service vs Direct Repository?

**使用 Application Service**:
- 需要事务管理
- 需要调用多个仓储或领域服务
- 复杂业务流程

**直接使用 Repository**:
- 简单 CRUD 查询
- 只读操作

### Q: Infrastructure 能否直接返回 DTO?

❌ **不推荐**:
```go
func (r *Repository) FindUsers() ([]UserDTO, error) { ... }
```

✅ **正确做法**:
```go
// Repository 返回领域对象
func (r *Repository) FindUsers() ([]*entity.User, error) { ... }

// Application Service 转换为 DTO
func (s *Service) GetUsers() ([]UserDTO, error) {
    users, _ := s.repo.FindUsers()
    return ToDTO(users), nil
}
```

## 总结

DDD 四层架构的核心价值:

1. **关注点分离**: 每层职责明确
2. **依赖倒置**: Domain 不依赖技术细节
3. **可测试性**: 各层可独立测试
4. **可维护性**: 业务逻辑集中在 Domain 层
5. **灵活性**: 可替换技术实现

## 额外资源

### 参考文件

详细的层实现指南:
- **`references/domain-layer-guide.md`** - Domain Layer 完整指南
- **`references/application-layer-guide.md`** - Application Layer 详解
- **`references/infrastructure-layer-guide.md`** - Infrastructure Layer 实现
- **`references/interface-layer-guide.md`** - Interface Layer 模式
- **`references/dependency-injection.md`** - 依赖注入最佳实践

### 示例代码

完整的四层架构示例:
- **`examples/user-feature/`** - 完整 User 功能四层实现
- **`examples/order-feature/`** - Order 聚合的四层示例
