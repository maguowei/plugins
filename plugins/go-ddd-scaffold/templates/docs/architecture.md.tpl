# {{ .Project.Name }} 架构文档

## 目录

- [架构概览](#架构概览)
- [DDD 四层架构](#ddd-四层架构)
- [目录结构](#目录结构)
- [依赖规则](#依赖规则)
- [数据流转](#数据流转)

## 架构概览

本项目采用 **领域驱动设计（DDD）** 的四层架构，结合 **Clean Architecture** 和 **SOLID 原则**，确保代码的可维护性、可测试性和可扩展性。

### 核心理念

1. **依赖倒置**：高层模块不依赖于低层模块，两者都依赖于抽象
2. **单一职责**：每个层次、每个组件只负责一件事情
3. **业务逻辑隔离**：业务逻辑集中在领域层，不受技术细节影响

## DDD 四层架构

```
┌─────────────────────────────────────────────────────────┐
│                    Interface Layer                       │
│                     (接口层)                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ Handler  │  │   DTO    │  │Middleware│              │
│  └──────────┘  └──────────┘  └──────────┘              │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  Application Layer                       │
│                    (应用层)                               │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │   Service    │  │     DTO      │                    │
│  └──────────────┘  └──────────────┘                    │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    Domain Layer                          │
│                     (领域层)                              │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐          │
│  │ Entity │ │  Value │ │  Event │ │  Repo  │          │
│  │        │ │ Object │ │        │ │Interface│         │
│  └────────┘ └────────┘ └────────┘ └────────┘          │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                Infrastructure Layer                      │
│                   (基础设施层)                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │   Repo   │  │  Config  │  │   Event  │              │
│  │   Impl   │  │          │  │   Bus    │              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

### 1. 接口层 (Interface Layer)

**位置**: `{{ .Paths.Interface }}/`

**职责**:
- 处理 HTTP 请求和响应
- 参数验证和转换
- 调用应用层服务
- 返回格式化的响应

**组件**:
- **Handler**: HTTP 处理器，处理路由请求
- **DTO**: 请求和响应的数据传输对象
- **Middleware**: 中间件（日志、恢复、CORS、指标）
- **Router**: 路由配置

### 2. 应用层 (Application Layer)

**位置**: `{{ .Paths.Application }}/`

**职责**:
- 用例编排（Use Case Orchestration）
- 事务管理
- 调用领域服务和仓储
- 发布领域事件
- DTO 转换

**组件**:
- **Application Service**: 应用服务，编排业务流程
- **DTO**: 应用层的数据传输对象

**示例**:
```go
func (s *UserApplicationService) CreateUser(ctx context.Context, dto CreateUserDTO) (*UserResponse, error) {
    // 1. 创建领域实体
    user, err := entity.NewUser(email, name)

    // 2. 调用仓储保存
    if err := s.repo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 3. 发布领域事件
    event := domainEvent.NewUserCreated(user)
    s.eventBus.Publish(event)

    // 4. 返回 DTO
    return ToUserResponse(user), nil
}
```

### 3. 领域层 (Domain Layer)

**位置**: `{{ .Paths.Domain }}/`

**职责**:
- 核心业务逻辑
- 业务规则验证
- 领域事件定义
- 定义仓储接口（不实现）

**组件**:
- **Entity**: 实体，有唯一标识的对象
- **Value Object**: 值对象，不可变的值
- **Domain Event**: 领域事件，表示业务状态变化
- **Repository Interface**: 仓储接口
- **Domain Service**: 领域服务，跨实体的业务逻辑

**示例**:
```go
type User struct {
    id        uuid.UUID
    email     Email
    name      string
    createdAt time.Time
    updatedAt time.Time
}

func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("名称不能为空")
    }
    u.name = newName
    u.updatedAt = time.Now()
    return nil
}
```

### 4. 基础设施层 (Infrastructure Layer)

**位置**: `{{ .Paths.Infrastructure }}/`

**职责**:
- 实现仓储接口
- 数据库访问
- 配置管理
- 第三方服务集成
- 可观测性（日志、指标、追踪）

**组件**:
- **Repository Impl**: 仓储实现（Ent ORM）
- **Config**: 配置加载
- **Event Bus**: 事件总线实现
- **Observability**: 日志、指标、Sentry

## 目录结构

```
{{ .Project.Name }}/
├── cmd/                          # 命令行入口
│   ├── server/                   # HTTP 服务器
│   └── migrate/                  # 数据库迁移
│
├── {{ .Paths.Domain }}/          # 领域层
│   └── user/                     # User 聚合
│       ├── entity/               # 实体
│       ├── valueobject/          # 值对象
│       ├── event/                # 领域事件
│       ├── repository/           # 仓储接口
│       └── service/              # 领域服务
│
├── {{ .Paths.Application }}/     # 应用层
│   └── user/
│       ├── service/              # 应用服务
│       └── dto/                  # DTO
│
├── {{ .Paths.Infrastructure }}/  # 基础设施层
│   ├── repository/               # 仓储实现
│   ├── config/                   # 配置
│   ├── event/                    # 事件总线
│   └── observability/            # 可观测性
│
├── {{ .Paths.Interface }}/       # 接口层
│   └── http/
│       ├── handler/              # HTTP 处理器
│       ├── dto/                  # HTTP DTO
│       ├── middleware/           # 中间件
│       └── router.go             # 路由
│
├── {{ .Paths.EntSchema }}/       # Ent Schema
│   └── user.go
│
├── configs/                      # 配置文件
│   └── config.yaml
│
└── docs/                         # 文档
    ├── architecture.md
    ├── development.md
    └── deployment.md
```

## 依赖规则

依赖方向：**从外向内，单向依赖**

```
Interface → Application → Domain ← Infrastructure
```

**严格规则**:
1. **领域层**不依赖任何其他层（核心，最稳定）
2. **应用层**只依赖领域层
3. **接口层**依赖应用层和领域层（不直接调用基础设施层）
4. **基础设施层**依赖领域层（实现领域层定义的接口）

**示例**:
```go
// ✅ 正确：Repository 接口定义在领域层
// internal/app/domain/user/repository/repository.go
type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
}

// ✅ 正确：Repository 实现在基础设施层
// internal/app/infrastructure/repository/user_repository.go
type UserRepositoryImpl struct {
    client *ent.Client
}

func (r *UserRepositoryImpl) Save(ctx context.Context, user *entity.User) error {
    // 实现
}
```

## 数据流转

### 请求流程

```
HTTP Request
    ↓
[Interface Layer] Handler
    ↓ (调用)
[Application Layer] Application Service
    ↓ (调用)
[Domain Layer] Entity / Domain Service
    ↓ (通过接口调用)
[Infrastructure Layer] Repository Impl
    ↓
Database
```

### 响应流程

```
Database
    ↓
[Infrastructure Layer] Repository Impl → Domain Entity
    ↓
[Application Layer] Application Service → Application DTO
    ↓
[Interface Layer] Handler → HTTP Response DTO
    ↓
HTTP Response (JSON)
```

## 技术栈

- **Web 框架**: Gin
- **ORM**: Ent
- **配置管理**: Viper
- **日志**: slog (Go 标准库)
- **指标监控**: Prometheus
- **错误追踪**: Sentry
- **领域事件**: CloudEvents

## 最佳实践

1. **不要跨层调用**：每一层只能调用相邻的下一层
2. **接口在领域层定义**：Repository、Domain Service 的接口都在领域层定义
3. **DTO 分层**：HTTP DTO、Application DTO、Domain Entity 是不同的对象
4. **事务在应用层管理**：应用服务负责事务的开始和提交
5. **业务逻辑在领域层**：验证、计算等业务逻辑都在 Entity 或 Domain Service 中
