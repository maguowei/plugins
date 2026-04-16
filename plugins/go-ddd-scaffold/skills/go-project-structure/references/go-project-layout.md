# Go 项目布局与命名规范

## 标准目录结构 (golang-standards/project-layout)

```
project-root/
  cmd/                  -- 应用程序入口 (每个应用一个子目录)
    server/main.go
    migrate/main.go
  internal/             -- 私有代码 (Go 编译器强制私有性)
    app/
      domain/           -- 领域层 (按聚合组织)
      application/      -- 应用层
      infrastructure/   -- 基础设施层
      interface/        -- 接口层
    ent/                -- Ent 生成的代码 (和 app 平级)
      schema/
  pkg/                  -- 可被外部使用的库 (谨慎使用)
  api/                  -- API 定义 (OpenAPI, Proto)
  configs/              -- 配置文件 (不含敏感信息)
  test/                 -- 集成测试、E2E 测试
  scripts/              -- 构建和部署脚本
  deployments/          -- Docker、K8s 配置
  docs/                 -- 文档
```

## DDD 分层目录

### Domain Layer
```
internal/app/domain/user/
  entity/user.go
  valueobject/email.go, user_status.go
  event/user_events.go
  repository/user_repository.go   -- 接口定义
  service/user_domain_service.go
```

### Application Layer
```
internal/app/application/
  service/user_application_service.go
  dto/user_dto.go
```

### Infrastructure Layer
```
internal/app/infrastructure/
  repository/user_repository_impl.go  -- 使用 internal/ent
  cache/redis_client.go
  config/config.go
  observability/logger.go
```

### Interface Layer
```
internal/app/interface/http/
  handler/user_handler.go
  dto/user_request.go, user_response.go
  middleware/auth.go, logger.go
  router.go
```

### Ent Layer
```
internal/ent/           -- 和 app 平级
  schema/user.go        -- Schema 定义
  user.go, user_create.go, user_query.go  -- 生成的代码
```

## 命名规范

### 包命名

```go
package user         // 小写、单数
package entity       // DDD 概念
package valueobject  // 单数
package repository   // 单数
```

避免: `user_service`, `users`, `UserRepository`, `common`, `util`

### 文件命名

```
user.go                     -- 实体
email.go                    -- 值对象
user_repository.go          -- 仓储接口
user_repository_impl.go     -- 仓储实现
user_application_service.go -- 应用服务
user_handler.go             -- Handler
user_test.go                -- 测试
```

### 类型命名

| 类别 | 命名规则 | 示例 |
|------|----------|------|
| Entity | 名词，无后缀 | `User`, `Order` |
| Value Object | 概念名词 | `Email`, `Money`, `Address` |
| 枚举 | 类型前缀 | `UserStatusActive`, `OrderStatusDraft` |
| Repository 接口 | +Repository | `UserRepository` |
| Repository 实现 | +RepositoryImpl 或存储前缀 | `EntUserRepository` |
| Domain Service | +DomainService | `TransferDomainService` |
| Application Service | +ApplicationService | `UserApplicationService` |
| DTO | +Request / +Response | `CreateUserRequest`, `UserResponse` |
| Event | 过去式 | `UserCreated`, `OrderSubmitted` |
| Error | Err 前缀 | `ErrUserNotFound` |

### 方法命名

```go
// Getter: 直接用字段名 (不用 Get 前缀)
func (u *User) ID() uuid.UUID { return u.id }

// Setter: 用业务语义
func (u *User) ChangeName(newName string) error { ... }

// Repository: 领域语言
FindByID, FindByEmail, FindActiveUsers, Save, Delete, ExistsByEmail

// 构造函数
NewUser, NewEmail, ReconstructUser
```

### 变量命名

```go
user := entity.NewUser(...)     // 清晰名称
users := []*entity.User{}       // 集合用复数
func (u *User) ...              // 接收者用类型首字母
```

## 不应有的目录

| 错误 | 正确 |
|------|------|
| `/src` | Go 不需要 src 目录 |
| `/models` | `/internal/app/domain` |
| `/controllers` | `/internal/app/interface/http/handler` |
