---
name: DDD Layered Architecture
description: 用户问"代码该放哪一层"、"层之间怎么调用"、"DDD 四层架构是什么"、"Application Service 和 Domain Service 区别"、"接口层怎么写"、"依赖倒置怎么实现"时触发。涵盖 DDD 四层的职责、依赖规则和层间交互。
version: 0.2.0
---

# DDD 四层架构 (DDD Layered Architecture)

## 概述

DDD 采用分层架构将系统划分为四个层次,每层有明确的职责和依赖关系。核心业务逻辑独立于技术细节,提高可维护性和可测试性。

## 四层架构图

```
┌─────────────────────────────────────────────────────────┐
│  Interface Layer (接口层)                                 │
│  - HTTP Handlers, gRPC Services, DTO, 中间件             │
├─────────────────────────────────────────────────────────┤
│  Application Layer (应用层)                               │
│  - 用例编排, 事务管理, DTO ↔ Domain Entity 转换          │
├─────────────────────────────────────────────────────────┤
│  Domain Layer (领域层)                                    │
│  - Entities, Value Objects, Domain Services              │
│  - Repository Interfaces, Domain Events                  │
├─────────────────────────────────────────────────────────┤
│  Infrastructure Layer (基础设施层)                        │
│  - Repository 实现 (Ent, GORM), 外部服务, 配置, 可观测性  │
└─────────────────────────────────────────────────────────┘
```

## 依赖规则

**核心原则**: 依赖关系只能由外向内,内层不能依赖外层。

```
Interface → Application → Domain ← Infrastructure
```

- Interface Layer 可以依赖 Application Layer
- Application Layer 可以依赖 Domain Layer
- Infrastructure Layer 实现 Domain Layer 定义的接口 (依赖倒置)
- Domain Layer **不能**依赖任何其他层

## 各层职责

### 1. Domain Layer (领域层)

**职责**: 表达业务概念、规则和逻辑的核心层。

**目录结构**:
```
internal/app/domain/
└── user/
    ├── entity/          # 实体
    ├── valueobject/     # 值对象
    ├── event/           # 领域事件
    ├── repository/      # 仓储接口
    └── service/         # 领域服务
```

各构建块的详细设计模式参见 ddd-core-concepts skill。

**关键原则**:
- 不依赖任何框架 (Gin, Ent, Viper)
- 使用纯 Go 代码表达业务逻辑
- 可独立测试,无需数据库或 HTTP

### 2. Application Layer (应用层)

**职责**: 编排领域对象完成业务用例,控制事务边界。

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
type UserApplicationService struct {
    userRepo    repository.UserRepository
    domainSvc   *service.UserAuthenticationService
    eventBus    EventBus
    txManager   TransactionManager
}

func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    tx, err := s.txManager.Begin(ctx)
    if err != nil {
        return nil, err
    }
    defer tx.Rollback()

    // 1. 调用领域服务检查邮箱唯一性
    if err := s.domainSvc.CheckEmailUniqueness(ctx, req.Email); err != nil {
        return nil, err
    }

    // 2. 创建领域对象
    email, _ := valueobject.NewEmail(req.Email)
    user, err := entity.NewUser(email, req.Name)
    if err != nil {
        return nil, err
    }

    // 3. 持久化
    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 4. 发布领域事件
    s.eventBus.Publish(event.NewUserCreated(user.ID(), user.Email().Value(), user.Name()))

    // 5. 提交事务
    if err := tx.Commit(); err != nil {
        return nil, err
    }

    return dto.ToUserResponse(user), nil
}
```

**关键原则**:
- 不包含业务逻辑,只做编排
- 控制事务边界
- DTO 与 Domain Entity 转换在此层

### 3. Infrastructure Layer (基础设施层)

**职责**: 提供技术实现,支撑上层业务逻辑。

**目录结构**:
```
internal/app/infrastructure/
├── repository/          # Repository 实现
├── external/            # 外部服务
├── config/              # 配置管理
└── observability/       # 日志、监控、追踪
```

**Repository 实现示例**:

```go
// repository/user_repository_impl.go
type EntUserRepository struct {
    client *ent.Client
}

// 确保实现了接口
var _ domainrepo.UserRepository = (*EntUserRepository)(nil)

func NewEntUserRepository(client *ent.Client) domainrepo.UserRepository {
    return &EntUserRepository{client: client}
}

func (r *EntUserRepository) Save(ctx context.Context, user *entity.User) error {
    return r.client.User.Create().
        SetID(user.ID()).
        SetEmail(user.Email().Value()).
        SetName(user.Name()).
        OnConflict().UpdateNewValues().
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
- 隔离技术细节,可替换实现
- 返回领域对象，不返回 ORM 对象

各技术组件的集成方式详见 go-tech-stack-integration skill。

### 4. Interface Layer (接口层)

**职责**: 处理外部请求,转换为应用层调用。

**目录结构**:
```
internal/app/interface/
└── http/
    ├── handler/         # HTTP 处理器
    ├── dto/             # 请求/响应 DTO
    ├── middleware/       # 中间件
    └── router.go        # 路由配置
```

**示例代码**:

```go
// handler/user_handler.go
type UserHandler struct {
    appService *service.UserApplicationService
}

func (h *UserHandler) CreateUser(c *gin.Context) {
    var req dto.CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    resp, err := h.appService.CreateUser(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, resp)
}
```

**关键原则**:
- 只处理协议层 (HTTP/gRPC)
- 不包含业务逻辑
- 统一错误处理

## 层间交互流程

```
HTTP Request → Interface (Handler) → Application (Service) → Domain (Entity/Service)
                                          ↓
                                   Infrastructure (Repository)
                                          ↓
HTTP Response ← Interface (Handler) ← Application (DTO 转换)
```

## 依赖注入

使用构造函数注入实现依赖倒置:

```go
// main.go
func InitializeUserHandler(db *ent.Client) *handler.UserHandler {
    userRepo := repository.NewEntUserRepository(db)               // Infrastructure
    domainService := service.NewUserAuthenticationService(userRepo) // Domain
    appService := application.NewUserApplicationService(userRepo, domainService) // Application
    return handler.NewUserHandler(appService)                      // Interface
}
```

## 测试策略

| 层 | 测试类型 | 外部依赖 |
|---|---------|---------|
| Domain | 纯单元测试 | 无 |
| Application | Mock Repository | 无 |
| Infrastructure | 集成测试 | 数据库 |
| Interface | httptest | Mock Service |

```go
// Domain Layer 测试 - 无需外部依赖
func TestUser_ChangeName(t *testing.T) {
    email, _ := valueobject.NewEmail("test@example.com")
    user, _ := entity.NewUser(email, "OldName")
    err := user.ChangeName("NewName")
    assert.NoError(t, err)
    assert.Equal(t, "NewName", user.Name())
}
```

## 常见问题

### Application Service vs Domain Service

| 对比项 | Application Service | Domain Service |
|--------|-------------------|----------------|
| 职责 | 编排用例 | 纯业务逻辑 |
| 事务 | 控制事务 | 不控制事务 |
| DTO | 做 DTO 转换 | 不做 DTO 转换 |
| 依赖 | 可调用多个 Repository/Service | 只依赖 Repository |

### Infrastructure 能否直接返回 DTO?

不推荐。Repository 应返回领域对象，Application Service 负责转换为 DTO。

## 总结

DDD 四层架构的核心价值:

1. **关注点分离**: 每层职责明确
2. **依赖倒置**: Domain 不依赖技术细节
3. **可测试性**: 各层可独立测试
4. **可维护性**: 业务逻辑集中在 Domain 层
5. **灵活性**: 可替换技术实现
