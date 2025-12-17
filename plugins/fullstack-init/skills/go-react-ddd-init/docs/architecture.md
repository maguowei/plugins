# 项目架构说明

本项目采用**领域驱动设计（DDD）**分层架构，清晰地分离了业务逻辑和技术实现。

## 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                    Interfaces 层                         │
│              (HTTP Handlers, Middleware)                 │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                   Application 层                         │
│           (Use Cases, Application Services)              │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                     Domain 层                            │
│        (Entities, Value Objects, Domain Services)        │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                 Infrastructure 层                        │
│      (Database, External APIs, Message Queues)           │
└─────────────────────────────────────────────────────────┘
```

## 分层说明

### 1. Domain 层（领域层）

**位置：** `backend/internal/domain/`

**职责：** 核心业务逻辑，系统的心脏

**包含：**
- **Entity（实体）**：具有唯一标识的对象
- **Value Object（值对象）**：无唯一标识，由属性定义
- **Domain Service（领域服务）**：跨实体的业务逻辑
- **Repository Interface（仓储接口）**：数据访问抽象

**原则：**
- ✅ 纯净：不依赖外部框架和库
- ✅ 稳定：变化最少的层
- ✅ 独立：可以独立测试
- ❌ 不包含技术细节（数据库、HTTP等）

**示例：**

```go
// domain/entity/user.go
package entity

type User struct {
    ID        string
    Email     string
    Name      string
    CreatedAt time.Time
}

func (u *User) Validate() error {
    if u.Email == "" {
        return errors.New("email is required")
    }
    return nil
}

// domain/repository/user.go
package repository

type UserRepository interface {
    Get(ctx context.Context, id string) (*entity.User, error)
    Save(ctx context.Context, user *entity.User) error
}
```

### 2. Application 层（应用层）

**位置：** `backend/internal/application/`

**职责：** 协调领域对象完成用户用例

**包含：**
- **Use Case（用例）**：特定业务流程的实现
- **DTO（数据传输对象）**：跨层数据传输
- **Application Service（应用服务）**：协调多个领域服务

**原则：**
- ✅ 薄层：不包含业务逻辑
- ✅ 编排：协调领域对象和仓储
- ✅ 事务管理
- ❌ 不包含 HTTP、数据库等技术细节

**示例：**

```go
// application/usecase/user/create_user.go
package user

type CreateUserUseCase struct {
    repo repository.UserRepository
}

func (uc *CreateUserUseCase) Execute(ctx context.Context, dto *CreateUserDTO) (*UserDTO, error) {
    // 1. 创建领域对象
    user := &entity.User{
        ID:    generateID(),
        Email: dto.Email,
        Name:  dto.Name,
    }

    // 2. 验证
    if err := user.Validate(); err != nil {
        return nil, err
    }

    // 3. 持久化
    if err := uc.repo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 4. 返回 DTO
    return toDTO(user), nil
}
```

### 3. Infrastructure 层（基础设施层）

**位置：** `backend/internal/infrastructure/`

**职责：** 提供技术实现

**包含：**
- **Persistence（持久化）**：数据库实现
- **HTTP Client**：外部 API 调用
- **Message Queue**：消息队列
- **Cache**：缓存实现

**原则：**
- ✅ 实现 Domain 层定义的接口
- ✅ 处理技术细节
- ✅ 可替换：容易切换实现

**示例：**

```go
// infrastructure/persistence/repository/user_repository.go
package repository

type userRepository struct {
    db *ent.Client
}

func NewUserRepository(db *ent.Client) repository.UserRepository {
    return &userRepository{db: db}
}

func (r *userRepository) Get(ctx context.Context, id string) (*entity.User, error) {
    u, err := r.db.User.Get(ctx, id)
    if err != nil {
        return nil, err
    }
    return toDomain(u), nil
}
```

### 4. Interfaces 层（接口层）

**位置：** `backend/internal/interfaces/`

**职责：** 处理外部通信

**包含：**
- **Handler（处理器）**：HTTP 请求处理
- **Middleware（中间件）**：跨切面关注点
- **Router（路由）**：URL 路由配置

**原则：**
- ✅ 转换：HTTP 请求 ↔ DTO
- ✅ 验证请求数据
- ✅ 处理响应格式

**示例：**

```go
// interfaces/handler/user_handler.go
package handler

type UserHandler struct {
    createUserUC *usecase.CreateUserUseCase
}

func (h *UserHandler) Create(c *gin.Context) {
    var req CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    dto := &CreateUserDTO{
        Email: req.Email,
        Name:  req.Name,
    }

    user, err := h.createUserUC.Execute(c.Request.Context(), dto)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(201, user)
}
```

## 依赖方向

```
Interfaces  →  Application  →  Domain
Infrastructure  →  Domain
```

**规则：**
- 外层依赖内层
- 内层不知道外层的存在
- Domain 层不依赖任何外层

## 数据流

### 请求流

```
HTTP Request
    ↓
Handler (Interfaces)
    ↓
Use Case (Application)
    ↓
Domain Service / Entity (Domain)
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Infrastructure)
    ↓
Database
```

### 响应流

```
Database
    ↓
Repository Implementation
    ↓
Domain Entity
    ↓
Use Case
    ↓
DTO
    ↓
Handler
    ↓
HTTP Response
```

## 目录结构

```
backend/
├── cmd/
│   └── api/
│       └── main.go                    # 程序入口
├── internal/
│   ├── domain/                        # 领域层
│   │   ├── entity/                    # 实体
│   │   ├── repository/                # 仓储接口
│   │   └── service/                   # 领域服务
│   ├── application/                   # 应用层
│   │   ├── usecase/                   # 用例
│   │   └── dto/                       # DTO
│   ├── infrastructure/                # 基础设施层
│   │   ├── persistence/               # 持久化
│   │   ├── http/                      # HTTP 客户端
│   │   └── websocket/                 # WebSocket
│   └── interfaces/                    # 接口层
│       ├── handler/                   # HTTP 处理器
│       ├── middleware/                # 中间件
│       └── router/                    # 路由
└── pkg/                               # 可复用包
    ├── logger/
    ├── validator/
    └── response/
```

## 前端架构

```
frontend/
├── src/
│   ├── components/                    # UI 组件
│   │   ├── ui/                        # 基础 UI 组件
│   │   └── layout/                    # 布局组件
│   ├── pages/                         # 页面组件
│   ├── hooks/                         # 自定义 Hooks
│   ├── services/                      # API 服务
│   ├── types/                         # TypeScript 类型
│   ├── lib/                           # 工具函数
│   └── store/                         # 状态管理
```

### 前端数据流

```
Component
    ↓
Service (API Call)
    ↓
Backend API
    ↓
Component Update
    ↓
Re-render
```

## 最佳实践

### Domain 层

1. **保持纯净**
   - 不导入外部框架
   - 只使用标准库和领域相关的包

2. **明确边界**
   - 实体：有标识的对象
   - 值对象：无标识的对象
   - 服务：跨实体的逻辑

3. **接口定义**
   - 在 Domain 层定义接口
   - 在 Infrastructure 层实现

### Application 层

1. **薄层**
   - 不包含业务逻辑
   - 只协调和编排

2. **使用 DTO**
   - 隔离内部模型和外部接口
   - 方便版本控制

3. **事务管理**
   - 在 Use Case 中管理事务
   - 确保数据一致性

### Infrastructure 层

1. **依赖注入**
   - 通过构造函数注入依赖
   - 便于测试和替换

2. **错误处理**
   - 将基础设施错误转换为领域错误
   - 添加上下文信息

### Interfaces 层

1. **请求验证**
   - 验证所有输入
   - 使用验证器库

2. **错误响应**
   - 统一的错误响应格式
   - 不泄露内部信息

3. **中间件**
   - CORS
   - 日志
   - 认证/授权
   - 限流

## 测试策略

### 单元测试

- Domain 层：测试业务逻辑
- Application 层：使用 mock 仓储
- Infrastructure 层：集成测试

### 集成测试

- 端到端 API 测试
- 数据库集成测试

### 测试金字塔

```
      /\
     /  \     E2E Tests
    /____\
   /      \   Integration Tests
  /________\
 /          \  Unit Tests
/____________\
```

## 参考资源

- [Domain-Driven Design](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Go 标准布局](https://github.com/golang-standards/project-layout)
