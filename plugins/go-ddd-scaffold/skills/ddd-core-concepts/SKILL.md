---
name: DDD Core Concepts
description: 用户问"什么是实体"、"值对象怎么设计"、"聚合根是什么"、"仓储模式怎么用"、"领域服务和应用服务有什么区别"、"领域事件怎么定义"时触发。涵盖 DDD 六大构建块在 Go 中的实现模式。
version: 0.2.0
---

# DDD 核心概念 (Domain-Driven Design Core Concepts)

## 概述

领域驱动设计 (DDD) 提供了一套构建块来组织和表达业务逻辑。本技能详细解释六个核心构建块及其在 Go 中的实现方式。

## 核心构建块

### 1. Entity (实体)

**定义**: 具有唯一标识和生命周期的领域对象。

**核心特征**:
- 通过 ID 区分，即使属性值相同，ID 不同就是不同实体
- 属性可以随时间变化
- 有创建、修改、删除的完整生命周期

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
    id        uuid.UUID
    email     valueobject.Email
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
func (u *User) ID() uuid.UUID          { return u.id }
func (u *User) Email() valueobject.Email { return u.email }
func (u *User) Name() string            { return u.name }

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
- 私有字段 + 公开 Getter 保护封装
- 构造函数确保有效状态
- 业务操作通过方法实现，不直接修改字段

### 2. Value Object (值对象)

**定义**: 无唯一标识，完全由属性值定义的不可变对象。

**核心特征**:
- 没有 ID，通过属性值识别
- 创建后不能修改
- 内置业务验证规则

**Go 实现模式**:

```go
// internal/app/domain/user/valueobject/email.go
package valueobject

// Email 值对象 (不可变)
type Email struct {
    value string
}

// 构造函数: 唯一创建方式，强制验证
func NewEmail(email string) (Email, error) {
    email = strings.TrimSpace(strings.ToLower(email))
    if email == "" {
        return Email{}, errors.New("email cannot be empty")
    }
    if !isValidEmail(email) {
        return Email{}, errors.New("invalid email format")
    }
    return Email{value: email}, nil
}

func (e Email) Value() string         { return e.value }
func (e Email) Equals(other Email) bool { return e.value == other.value }
func (e Email) String() string         { return e.value }
```

**更多值对象示例**:

```go
// Money 值对象 - 操作返回新对象
type Money struct {
    amount   int64
    currency string
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

### 3. Domain Event (领域事件)

**定义**: 表示领域中已发生的重要业务事件的不可变对象。

**核心特征**:
- 使用过去时命名 (UserCreated, OrderPlaced)
- 事件不可变
- 包含事件发生时间和相关数据

**Go 实现** (遵循 CloudEvents 规范，详见 cloudevents-pattern skill):

```go
// internal/app/domain/user/event/user_created.go
package event

type UserCreated struct {
    UserID    uuid.UUID `json:"user_id"`
    Email     string    `json:"email"`
    Name      string    `json:"name"`
    CreatedAt time.Time `json:"created_at"`
}

func (e UserCreated) ToCloudEvent() cloudevents.Event {
    event := cloudevents.NewEvent()
    event.SetID(uuid.New().String())
    event.SetSource("user-service")
    event.SetType("com.example.user.created")
    event.SetTime(e.CreatedAt)
    event.SetData(cloudevents.ApplicationJSON, e)
    return event
}
```

**关键实践**:
- 在事务成功后发布事件
- 包含足够的上下文信息
- 发布失败不应阻止主流程

### 4. Repository (仓储)

**定义**: 领域对象的持久化和检索接口，提供类似集合的操作。

**核心特征**:
- 接口定义在领域层，实现在基础设施层 (依赖倒置)
- 只为聚合根提供仓储
- 使用领域语言定义方法

**接口定义 (Domain Layer)**:

```go
// internal/app/domain/user/repository/user_repository.go
package repository

type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
    FindByEmail(ctx context.Context, email string) (*entity.User, error)
    List(ctx context.Context, offset, limit int) ([]*entity.User, int, error)
    Delete(ctx context.Context, id uuid.UUID) error
    ExistsByEmail(ctx context.Context, email string) (bool, error)
}
```

Repository 的基础设施层实现详见 ddd-layered-architecture skill。

**关键实践**:
- 接口使用领域术语，不暴露技术细节
- 返回领域对象，不返回 ORM 对象
- 使用依赖倒置原则

### 5. Domain Service (领域服务)

**定义**: 不属于任何实体或值对象的领域逻辑。

**核心特征**:
- 无状态，只包含行为
- 处理跨实体的核心业务规则
- 使用领域语言命名

**实现模式**:

```go
// internal/app/domain/user/service/user_authentication_service.go
package service

type UserAuthenticationService struct {
    userRepo repository.UserRepository
}

func NewUserAuthenticationService(repo repository.UserRepository) *UserAuthenticationService {
    return &UserAuthenticationService{userRepo: repo}
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
```

**关键实践**:
- 通过构造函数注入依赖
- 只包含领域逻辑，不包含应用编排逻辑
- 单实体操作应放在实体方法中，而非领域服务

### 6. Aggregate Root (聚合根)

**定义**: 聚合的入口实体，保证聚合内部的一致性边界。

**核心特征**:
- 外部只能通过聚合根访问聚合内实体
- 一个事务只修改一个聚合
- 管理聚合内其他对象的生命周期

**实现模式**:

```go
// Order 聚合根
type Order struct {
    id         uuid.UUID
    customerID uuid.UUID
    items      []*OrderItem
    status     OrderStatus
    total      Money
}

// 通过聚合根操作内部实体
func (o *Order) AddItem(productID uuid.UUID, quantity int, price Money) error {
    if o.status != OrderStatusPending {
        return errors.New("cannot add items to non-pending order")
    }
    item := &OrderItem{
        id: uuid.New(), productID: productID,
        quantity: quantity, price: price,
    }
    o.items = append(o.items, item)
    o.recalculateTotal()
    return nil
}

func (o *Order) recalculateTotal() {
    total := Money{amount: 0, currency: "CNY"}
    for _, item := range o.items {
        itemTotal, _ := item.price.Multiply(item.quantity)
        total, _ = total.Add(itemTotal)
    }
    o.total = total
}
```

**关键实践**:
- 外部不直接访问聚合内实体
- 聚合根控制所有变更，保证不变式
- 仓储只为聚合根创建

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
└──────────────────┘   └──────────────────┘
```

## 实践指南

### 识别 Entity vs Value Object

| 判断标准 | Entity | Value Object |
|---------|--------|-------------|
| 唯一标识 | 有 ID | 无 ID |
| 可变性 | 可变 | 不可变 |
| 相等性 | 基于 ID | 基于属性值 |
| 举例 | User, Order | Email, Money, Address |

### 常见陷阱

1. **贫血模型**: 实体只有 getter/setter → 将业务逻辑封装在实体方法中
2. **过度使用领域服务**: 所有逻辑都在服务层 → 单实体操作应在实体方法中
3. **值对象可变**: 提供 setter 方法 → 值对象必须不可变
4. **聚合过大**: 包含过多实体 → 重新划分聚合边界
5. **跨聚合事务**: 一个事务修改多个聚合 → 使用领域事件实现最终一致性

## 总结

六个核心构建块:

- **Entity**: 有唯一标识和生命周期
- **Value Object**: 不可变、基于值相等
- **Domain Event**: 领域中已发生的事件 (详见 cloudevents-pattern)
- **Repository**: 持久化抽象 (详见 ddd-layered-architecture)
- **Domain Service**: 跨实体的领域逻辑
- **Aggregate Root**: 一致性边界的守护者
