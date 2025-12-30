---
name: DDD Core Concepts
description: This skill should be used when the user asks about "DDD concepts", "what is Entity", "what is Value Object", "Domain Event definition", "Repository pattern", "Domain Service", "Aggregate Root", "DDD building blocks", or needs to understand fundamental domain-driven design concepts for implementing Go projects.
version: 0.1.0
---

# DDD 核心概念 (Domain-Driven Design Core Concepts)

## 概述

领域驱动设计 (DDD) 提供了一套构建块 (building blocks) 来组织和表达业务逻辑。理解这些核心概念对于正确实现 DDD 架构至关重要。本技能详细解释六个核心构建块及其在 Go 语言中的实现方式。

## 核心构建块

### 1. Entity (实体)

**定义**: 具有唯一标识和生命周期的领域对象。

**核心特征**:
- **唯一标识**: 通过 ID 区分，即使属性值相同，只要 ID 不同就是不同的实体
- **可变性**: 实体的属性可以随时间变化
- **生命周期**: 实体有创建、修改、删除的完整生命周期
- **相等性判断**: 通过 ID 比较，而非属性值

**何时使用**:
- 对象需要跨时间或系统被追踪
- 对象的身份比属性更重要
- 对象有状态变化需要记录

**Go 实现模式**:

```go
// internal/app/domain/user/entity/user.go
package entity

import (
    "time"
    "github.com/google/uuid"
    "myproject/internal/app/domain/user/valueobject"
)

type User struct {
    id        uuid.UUID            // 唯一标识 (私有)
    email     valueobject.Email    // 值对象
    name      string
    createdAt time.Time
    updatedAt time.Time
}

// 构造函数: 确保实体创建时处于有效状态
func NewUser(email valueobject.Email, name string) (*User, error) {
    if name == "" {
        return nil, errors.New("name cannot be empty")
    }

    return &User{
        id:        uuid.New(),
        email:     email,
        name:      name,
        createdAt: time.Now(),
        updatedAt: time.Now(),
    }, nil
}

// Getter: 暴露只读访问
func (u *User) ID() uuid.UUID { return u.id }
func (u *User) Email() valueobject.Email { return u.email }
func (u *User) Name() string { return u.name }

// 业务方法: 封装状态变更逻辑
func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    u.name = newName
    u.updatedAt = time.Now()
    return nil
}

// 相等性判断: 基于 ID
func (u *User) Equals(other *User) bool {
    return u.id == other.id
}
```

**关键实践**:
- 使用私有字段 + 公开 Getter 保护封装
- 提供构造函数确保有效状态
- 业务操作通过方法实现，而非直接修改字段
- 基于 ID 判断相等性

详细模式和高级用法参见 `references/entity-patterns.md`。

### 2. Value Object (值对象)

**定义**: 无唯一标识，完全由属性值定义的不可变对象。

**核心特征**:
- **无标识**: 没有 ID，通过属性值识别
- **不可变性**: 创建后不能修改，需要修改时创建新对象
- **可替换性**: 相同属性值的值对象可以互相替换
- **封装规则**: 内置业务验证和规则

**何时使用**:
- 描述性概念 (颜色、金额、地址)
- 需要验证和规则的属性
- 可以共享的概念
- 概念的身份不重要

**Go 实现模式**:

```go
// internal/app/domain/user/valueobject/email.go
package valueobject

import (
    "errors"
    "regexp"
    "strings"
)

// Email 值对象 (不可变)
type Email struct {
    value string // 私有字段，确保不可变性
}

// 构造函数: 唯一创建方式，强制验证
func NewEmail(email string) (Email, error) {
    // 业务规则验证
    email = strings.TrimSpace(strings.ToLower(email))

    if email == "" {
        return Email{}, errors.New("email cannot be empty")
    }

    if !isValidEmail(email) {
        return Email{}, errors.New("invalid email format")
    }

    return Email{value: email}, nil
}

// Value: 访问器 (只读)
func (e Email) Value() string {
    return e.value
}

// Equals: 值对象相等性基于属性值
func (e Email) Equals(other Email) bool {
    return e.value == other.value
}

// String: 字符串表示
func (e Email) String() string {
    return e.value
}

// 私有验证方法
func isValidEmail(email string) bool {
    regex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
    return regex.MatchString(email)
}
```

**更多值对象示例**:

```go
// Money 值对象
type Money struct {
    amount   int64  // 以分为单位存储，避免浮点精度问题
    currency string
}

func NewMoney(amount int64, currency string) (Money, error) {
    if amount < 0 {
        return Money{}, errors.New("amount cannot be negative")
    }
    if currency == "" {
        return Money{}, errors.New("currency is required")
    }
    return Money{amount: amount, currency: currency}, nil
}

func (m Money) Add(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, errors.New("cannot add different currencies")
    }
    return Money{amount: m.amount + other.amount, currency: m.currency}, nil
}
```

**关键实践**:
- 所有字段私有，确保不可变性
- 只通过构造函数创建，强制验证
- 操作返回新对象，不修改原对象
- 值相等性基于属性值比较

详见 `references/value-object-patterns.md` 了解更多模式。

### 3. Domain Event (领域事件)

**定义**: 表示领域中已发生的重要业务事件的不可变对象。

**核心特征**:
- **过去时**: 描述已发生的事实 (UserCreated, OrderPlaced)
- **不可变**: 事件一旦创建不可修改
- **包含上下文**: 事件发生时间、相关实体 ID、重要数据
- **解耦机制**: 不同聚合或服务间的异步通信

**何时使用**:
- 某个业务操作完成需要通知其他部分
- 需要记录业务操作历史
- 实现最终一致性
- 触发后续业务流程

**CloudEvents 规范实现**:

```go
// internal/app/domain/user/event/user_created.go
package event

import (
    "time"
    "github.com/google/uuid"
    cloudevents "github.com/cloudevents/sdk-go/v2"
)

// UserCreated 领域事件
type UserCreated struct {
    UserID    uuid.UUID `json:"user_id"`
    Email     string    `json:"email"`
    Name      string    `json:"name"`
    CreatedAt time.Time `json:"created_at"`
}

// ToCloudEvent: 转换为 CloudEvents 标准格式
func (e UserCreated) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetID(uuid.New().String())
    event.SetSource("user-service")
    event.SetType("com.example.user.created")
    event.SetTime(e.CreatedAt)
    event.SetData(cloudevents.ApplicationJSON, e)
    return event
}

// NewUserCreated: 构造函数
func NewUserCreated(userID uuid.UUID, email, name string) UserCreated {
    return UserCreated{
        UserID:    userID,
        Email:     email,
        Name:      name,
        CreatedAt: time.Now(),
    }
}
```

**事件发布模式**:

```go
// 在实体或领域服务中发布事件
func (s *UserService) CreateUser(email valueobject.Email, name string) (*entity.User, error) {
    user, err := entity.NewUser(email, name)
    if err != nil {
        return nil, err
    }

    // 保存实体
    if err := s.repo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 发布领域事件
    event := event.NewUserCreated(user.ID(), user.Email().Value(), user.Name())
    s.eventBus.Publish(event.ToCloudEvent())

    return user, nil
}
```

**关键实践**:
- 使用过去时命名
- 包含足够的上下文信息
- 遵循 CloudEvents 规范便于跨服务通信
- 在事务成功后发布事件

详见 `references/domain-events-patterns.md`。

### 4. Repository (仓储)

**定义**: 领域对象的持久化和检索接口，提供类似集合的操作。

**核心特征**:
- **接口在领域层**: 使用领域语言定义
- **实现在基础设施层**: 隔离技术细节
- **聚合根仓储**: 只为聚合根提供仓储
- **集合语义**: 类似内存集合的操作方式

**何时使用**:
- 需要持久化和检索实体
- 需要隔离数据访问细节
- 提供领域语言的查询接口

**接口定义 (Domain Layer)**:

```go
// internal/app/domain/user/repository/user_repository.go
package repository

import (
    "context"
    "github.com/google/uuid"
    "myproject/internal/app/domain/user/entity"
)

// UserRepository 仓储接口 (使用领域语言)
type UserRepository interface {
    // 保存用户 (创建或更新)
    Save(ctx context.Context, user *entity.User) error

    // 根据 ID 查找
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)

    // 根据邮箱查找
    FindByEmail(ctx context.Context, email string) (*entity.User, error)

    // 列表查询 (分页)
    List(ctx context.Context, offset, limit int) ([]*entity.User, int, error)

    // 删除用户
    Delete(ctx context.Context, id uuid.UUID) error

    // 检查邮箱是否存在
    ExistsByEmail(ctx context.Context, email string) (bool, error)
}
```

**实现 (Infrastructure Layer)**:

```go
// internal/app/infrastructure/repository/user_repository_impl.go
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
    u, err := r.client.User.Get(ctx, id)
    if err != nil {
        return nil, err
    }
    return r.toDomain(u), nil
}

// 领域模型转换
func (r *EntUserRepository) toDomain(u *ent.User) *entity.User {
    email, _ := valueobject.NewEmail(u.Email)
    user, _ := entity.NewUser(email, u.Name)
    return user
}
```

**关键实践**:
- 接口使用领域术语，不暴露技术细节
- 只为聚合根创建仓储
- 返回领域对象，不返回 ORM 对象
- 使用依赖倒置 (接口在领域层，实现在基础设施层)

详见 `references/repository-patterns.md`。

### 5. Domain Service (领域服务)

**定义**: 不属于任何实体或值对象的领域逻辑。

**核心特征**:
- **无状态**: 只包含行为，无内部状态
- **领域逻辑**: 处理核心业务规则
- **跨实体操作**: 协调多个实体的行为
- **领域语言命名**: 使用业务术语

**何时使用**:
- 操作涉及多个实体
- 逻辑不自然属于某个实体
- 需要访问多个仓储
- 复杂的业务规则计算

**实现模式**:

```go
// internal/app/domain/user/service/user_authentication_service.go
package service

import (
    "context"
    "errors"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/repository"
    "myproject/internal/app/domain/user/valueobject"
)

// UserAuthenticationService 领域服务
type UserAuthenticationService struct {
    userRepo repository.UserRepository
}

func NewUserAuthenticationService(repo repository.UserRepository) *UserAuthenticationService {
    return &UserAuthenticationService{userRepo: repo}
}

// Authenticate: 用户认证业务逻辑
func (s *UserAuthenticationService) Authenticate(ctx context.Context, email string, password string) (*entity.User, error) {
    // 验证邮箱格式
    emailVO, err := valueobject.NewEmail(email)
    if err != nil {
        return nil, err
    }

    // 查找用户
    user, err := s.userRepo.FindByEmail(ctx, emailVO.Value())
    if err != nil {
        return nil, errors.New("authentication failed")
    }

    // 验证密码 (示例)
    if !s.verifyPassword(user, password) {
        return nil, errors.New("authentication failed")
    }

    return user, nil
}

// CheckEmailUniqueness: 检查邮箱唯一性
func (s *UserAuthenticationService) CheckEmailUniqueness(ctx context.Context, email string) error {
    exists, err := s.userRepo.ExistsByEmail(ctx, email)
    if err != nil {
        return err
    }
    if exists {
        return errors.New("email already registered")
    }
    return nil
}

func (s *UserAuthenticationService) verifyPassword(user *entity.User, password string) bool {
    // 密码验证逻辑
    return true
}
```

**关键实践**:
- 服务无状态，可以安全共享
- 使用领域语言命名方法
- 只包含领域逻辑，不包含应用逻辑
- 通过构造函数注入依赖

详见 `references/domain-service-patterns.md`。

### 6. Aggregate Root (聚合根)

**定义**: 聚合的入口实体，保证聚合内部的一致性边界。

**核心特征**:
- **一致性边界**: 聚合内数据一起变更
- **唯一访问点**: 外部只能通过聚合根访问聚合
- **事务边界**: 一个事务修改一个聚合
- **生命周期管理**: 管理聚合内其他对象

**何时使用**:
- 定义事务一致性边界
- 多个实体需要一起保证不变式
- 需要控制对象图的访问

**实现模式**:

```go
// Order 聚合根示例
type Order struct {
    id         uuid.UUID
    customerID uuid.UUID
    items      []*OrderItem  // 聚合内实体
    status     OrderStatus
    total      Money
}

// AddItem: 通过聚合根操作
func (o *Order) AddItem(productID uuid.UUID, quantity int, price Money) error {
    // 验证业务规则
    if o.status != OrderStatusPending {
        return errors.New("cannot add items to non-pending order")
    }

    // 创建订单项
    item := &OrderItem{
        id:        uuid.New(),
        productID: productID,
        quantity:  quantity,
        price:     price,
    }

    o.items = append(o.items, item)
    o.recalculateTotal()  // 保证聚合内一致性

    return nil
}

// 聚合根保证不变式
func (o *Order) recalculateTotal() {
    total := Money{amount: 0, currency: "CNY"}
    for _, item := range o.items {
        itemTotal, _ := item.price.Multiply(item.quantity)
        total, _ = total.Add(itemTotal)
    }
    o.total = total
}

// OrderItem: 聚合内实体 (不是聚合根)
type OrderItem struct {
    id        uuid.UUID
    productID uuid.UUID
    quantity  int
    price     Money
}
```

**关键实践**:
- 外部不直接访问聚合内实体
- 聚合根控制所有变更
- 仓储只为聚合根创建
- 一个事务只修改一个聚合

详见 `references/aggregate-patterns.md`。

## DDD 概念关系图

```
┌─────────────────────────────────────────────┐
│         Aggregate (聚合)                     │
│  ┌──────────────────────────────────┐       │
│  │   Aggregate Root (聚合根)          │       │
│  │   - Entity (实体)                  │       │
│  │   - 唯一访问入口                    │       │
│  └──────────────────────────────────┘       │
│               │                              │
│               ├── Entity (聚合内实体)         │
│               ├── Value Object (值对象)       │
│               └── Domain Event (领域事件)     │
└─────────────────────────────────────────────┘
         │                    │
         ↓                    ↓
┌──────────────────┐   ┌──────────────────┐
│  Repository      │   │  Domain Service  │
│  (仓储接口)       │   │  (领域服务)       │
│  - 持久化         │   │  - 跨实体逻辑     │
│  - 检索           │   │  - 无状态         │
└──────────────────┘   └──────────────────┘
```

## 实践指南

### 识别 Entity vs Value Object

**使用 Entity 如果**:
- 需要跟踪对象的生命周期
- 对象有唯一标识
- 对象状态会变化

**使用 Value Object 如果**:
- 描述性概念
- 可以共享
- 相同属性值可替换

### 何时发布领域事件

- 重要业务操作完成时
- 需要触发其他聚合的业务逻辑
- 需要记录操作历史
- 实现最终一致性

### 仓储设计原则

- 只为聚合根创建仓储
- 接口使用领域语言
- 返回领域对象
- 隔离技术细节

### 领域服务使用场景

- 逻辑跨越多个实体
- 不自然属于任何一个实体
- 需要协调多个聚合

## 常见陷阱

1. **贫血模型**: 实体只有 getter/setter，业务逻辑在服务层
   - 解决: 将业务逻辑封装在实体方法中

2. **过度使用领域服务**: 所有逻辑都在服务层
   - 解决: 单实体操作应该在实体方法中

3. **值对象可变**: 值对象提供 setter 方法
   - 解决: 值对象必须不可变

4. **聚合过大**: 聚合包含过多实体
   - 解决: 重新划分聚合边界

5. **跨聚合事务**: 一个事务修改多个聚合
   - 解决: 使用领域事件实现最终一致性

## 总结

理解并正确应用这六个核心构建块是实现 DDD 的基础:

- **Entity**: 有唯一标识和生命周期
- **Value Object**: 不可变、基于值相等
- **Domain Event**: 领域中已发生的事件
- **Repository**: 持久化抽象
- **Domain Service**: 跨实体的领域逻辑
- **Aggregate Root**: 一致性边界的守护者

## 额外资源

### 参考文件

详细模式和高级用法:
- **`references/entity-patterns.md`** - Entity 高级模式
- **`references/value-object-patterns.md`** - 更多值对象示例
- **`references/domain-events-patterns.md`** - 事件发布订阅模式
- **`references/repository-patterns.md`** - 仓储高级模式
- **`references/domain-service-patterns.md`** - 领域服务最佳实践
- **`references/aggregate-patterns.md`** - 聚合设计指南

### 示例代码

完整的 Go 实现示例:
- **`examples/user-aggregate/`** - 完整 User 聚合示例
- **`examples/order-aggregate/`** - 完整 Order 聚合示例
