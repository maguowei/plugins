# DDD 四层架构完整指南

## 四层概览

```
Interface Layer  -- HTTP/gRPC 处理、DTO、中间件
Application Layer -- 用例编排、事务管理、DTO 转换
Domain Layer     -- Entity、VO、Domain Service、Repo 接口、Event
Infrastructure Layer -- Repo 实现、外部服务、缓存、可观测性
```

依赖规则: `Interface -> Application -> Domain <- Infrastructure`

## Domain Layer (领域层)

**职责**: 核心业务逻辑，不依赖任何框架。

**目录结构**:
```
internal/app/domain/{bounded-context}/
  entity/       -- 实体 (私有字段 + Getter + 业务方法)
  valueobject/  -- 值对象 (不可变，构造函数验证)
  event/        -- 领域事件 (过去时命名，不可变)
  repository/   -- 仓储接口 (只定义，不实现)
  service/      -- 领域服务 (无状态，跨实体逻辑)
```

**关键约束**:
- 不依赖 Gin、Ent、Viper 等框架
- 使用 ID 引用避免包间循环依赖
- 定义领域错误: `var ErrUserNotFound = errors.New("user not found")`

## Application Layer (应用层)

**职责**: 编排领域对象完成业务用例。

**目录结构**:
```
internal/app/application/
  service/  -- 应用服务 (一个用例一个方法)
  dto/      -- 数据传输对象 (Request/Response)
```

**典型流程**:
```go
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    // 1. 参数验证
    // 2. 转换为值对象 / 创建领域对象
    // 3. 调用领域服务 (可选)
    // 4. 持久化 (通过 Repository)
    // 5. 发布领域事件
    // 6. 提交事务
    // 7. 返回 DTO
}
```

**关键约束**:
- 不包含业务逻辑 (委托给 Domain)
- 控制事务边界
- DTO 与 Domain Entity 转换在此层

### DTO 设计

```go
type CreateUserRequest struct {
    Email    string `json:"email"`
    Name     string `json:"name"`
    Password string `json:"password"`
}

type UserResponse struct {
    ID        string `json:"id"`
    Email     string `json:"email"`
    Name      string `json:"name"`
    Status    string `json:"status"`
    CreatedAt string `json:"created_at"`
}

func NewUserResponse(user *entity.User) *UserResponse {
    return &UserResponse{
        ID: user.ID().String(), Email: user.Email().Value(),
        Name: user.Name(), Status: user.Status().String(),
        CreatedAt: user.CreatedAt().Format(time.RFC3339),
    }
}
```

### 事务管理

- Unit of Work 模式: `Begin -> 操作 -> Commit/Rollback`
- 事务装饰器: `WithTransaction(ctx, func(ctx, tx) error)`
- 事件在事务提交后发布

## Infrastructure Layer (基础设施层)

**职责**: 技术实现，支撑上层业务逻辑。

**目录结构**:
```
internal/app/infrastructure/
  repository/    -- Repository 实现 (Ent/GORM)
  external/      -- 外部服务 (邮件、支付)
  cache/         -- 缓存 (Redis)
  messagequeue/  -- 消息队列 (Kafka)
  observability/ -- 日志、监控、追踪
  config/        -- 配置管理
```

**Repository 实现要点**:
```go
type EntUserRepository struct { client *ent.Client }
var _ domainrepo.UserRepository = (*EntUserRepository)(nil) // 编译时检查

func (r *EntUserRepository) toDomain(u *ent.User) *entity.User {
    email, _ := valueobject.NewEmail(u.Email)
    return entity.ReconstructUser(u.ID, email, u.Name, ...)
}
```

**关键约束**:
- 实现 Domain 层定义的接口
- ORM 模型与领域模型分离 (`toDomain` 转换)
- 数据库错误转换为领域错误

## Interface Layer (接口层)

**职责**: 处理外部请求，转换为应用层调用。

**目录结构**:
```
internal/app/interface/http/
  handler/     -- HTTP 处理器
  dto/         -- 请求/响应 DTO (带校验 binding tag)
  middleware/  -- 中间件 (Auth, Logger, CORS, RateLimit)
  router.go    -- 路由配置
```

**Handler 模式**:
```go
func (h *UserHandler) CreateUser(c *gin.Context) {
    var req dto.CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()}); return
    }
    resp, err := h.appService.CreateUser(c.Request.Context(), req)
    if err != nil { h.handleError(c, err); return }
    c.JSON(201, resp)
}
```

## 测试策略

| 层 | 测试类型 | 外部依赖 |
|---|---------|---------|
| Domain | 纯单元测试 | 无 |
| Application | Mock Repository | 无 |
| Infrastructure | 集成测试 | 数据库 (testcontainers) |
| Interface | httptest | Mock Service |
