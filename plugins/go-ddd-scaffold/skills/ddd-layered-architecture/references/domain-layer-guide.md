# Domain Layer 完整实现指南

## Domain Layer 的角色

Domain Layer (领域层) 是 DDD 架构的核心，包含业务逻辑和业务规则。它是整个系统的心脏，代表业务领域的知识。

**核心职责**:
- 表达业务概念和业务规则
- 保护业务不变式
- 实现领域模型
- 定义仓储接口 (不实现)
- 发布领域事件

**不应包含**:
- 数据库访问细节
- 外部服务调用
- UI 逻辑
- 基础设施细节

**所有权**: Domain Layer 属于业务分析师和领域专家，技术人员只是将其转化为代码。

## 组织结构

### 推荐的目录结构

```
internal/app/domain/
└── {bounded-context}/          # 限界上下文 (如: user, order, payment)
    ├── entity/                 # 实体
    │   ├── user.go
    │   └── user_test.go
    ├── valueobject/            # 值对象
    │   ├── email.go
    │   ├── phone.go
    │   └── user_status.go
    ├── event/                  # 领域事件
    │   ├── user_created.go
    │   └── user_email_changed.go
    ├── repository/             # 仓储接口 (只定义接口)
    │   └── user_repository.go
    ├── service/                # 领域服务
    │   └── user_auth_service.go
    └── factory/                # 工厂 (可选)
        └── user_factory.go
```

### 包划分策略

```go
// 按聚合组织包
internal/app/domain/
├── user/                       # User 聚合
│   ├── entity/
│   ├── valueobject/
│   └── repository/
└── order/                      # Order 聚合
    ├── entity/
    ├── valueobject/
    └── repository/

// 好处:
// - 聚合边界清晰
// - 易于理解和维护
// - 避免循环依赖
```

## Entity 实现要点

### 私有字段 + 公开 Getter

```go
package entity

import (
    "errors"
    "time"
    "github.com/google/uuid"
    "myproject/internal/app/domain/user/valueobject"
)

// User 用户实体
type User struct {
    // 所有字段都是私有的
    id        uuid.UUID
    email     valueobject.Email
    name      string
    status    valueobject.UserStatus
    createdAt time.Time
    updatedAt time.Time
}

// ID 提供只读访问
func (u *User) ID() uuid.UUID { return u.id }

// Email 提供只读访问
func (u *User) Email() valueobject.Email { return u.email }

// Name 提供只读访问
func (u *User) Name() string { return u.name }

// Status 提供只读访问
func (u *User) Status() valueobject.UserStatus { return u.status }

// CreatedAt 提供只读访问
func (u *User) CreatedAt() time.Time { return u.createdAt }

// 好处:
// - 封装性强
// - 防止外部直接修改状态
// - 所有变更通过业务方法
```

### 业务方法暴露

```go
// ChangeName 修改用户名 (业务方法)
func (u *User) ChangeName(newName string) error {
    // 业务规则验证
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    if len(newName) > 100 {
        return errors.New("name too long")
    }
    if newName == u.name {
        return nil // 名称未变更
    }

    // 状态变更
    u.name = newName
    u.updatedAt = time.Now()

    return nil
}

// ChangeEmail 修改邮箱 (业务方法)
func (u *User) ChangeEmail(newEmail valueobject.Email) error {
    // 业务规则验证
    if u.status == valueobject.UserStatusSuspended {
        return errors.New("suspended user cannot change email")
    }

    // 状态变更
    u.email = newEmail
    u.updatedAt = time.Now()

    return nil
}

// Suspend 暂停用户 (业务方法)
func (u *User) Suspend() error {
    if u.status == valueobject.UserStatusSuspended {
        return nil // 已经暂停
    }

    u.status = valueobject.UserStatusSuspended
    u.updatedAt = time.Now()

    return nil
}

// Activate 激活用户 (业务方法)
func (u *User) Activate() error {
    if u.status == valueobject.UserStatusActive {
        return nil // 已经激活
    }

    u.status = valueobject.UserStatusActive
    u.updatedAt = time.Now()

    return nil
}
```

### 状态机模式

```go
// Order 订单实体 (展示状态机)
type Order struct {
    id         uuid.UUID
    status     valueobject.OrderStatus
    items      []*OrderItem
    totalAmount float64
    createdAt  time.Time
    updatedAt  time.Time
}

// Submit 提交订单 (状态转换)
func (o *Order) Submit() error {
    // 只有草稿状态可以提交
    if o.status != valueobject.OrderStatusDraft {
        return fmt.Errorf("cannot submit order in status: %s", o.status)
    }

    // 业务规则验证
    if len(o.items) == 0 {
        return errors.New("cannot submit empty order")
    }

    // 状态转换
    o.status = valueobject.OrderStatusSubmitted
    o.updatedAt = time.Now()

    return nil
}

// Confirm 确认订单
func (o *Order) Confirm() error {
    // 只有已提交的订单可以确认
    if o.status != valueobject.OrderStatusSubmitted {
        return fmt.Errorf("cannot confirm order in status: %s", o.status)
    }

    o.status = valueobject.OrderStatusConfirmed
    o.updatedAt = time.Now()

    return nil
}

// Cancel 取消订单
func (o *Order) Cancel() error {
    // 已完成的订单不能取消
    if o.status == valueobject.OrderStatusCompleted {
        return errors.New("cannot cancel completed order")
    }

    o.status = valueobject.OrderStatusCancelled
    o.updatedAt = time.Now()

    return nil
}

// Complete 完成订单
func (o *Order) Complete() error {
    if o.status != valueobject.OrderStatusConfirmed {
        return fmt.Errorf("cannot complete order in status: %s", o.status)
    }

    o.status = valueobject.OrderStatusCompleted
    o.updatedAt = time.Now()

    return nil
}
```

### 不变式检查

```go
// NewUser 构造函数确保初始有效状态
func NewUser(email valueobject.Email, name string) (*User, error) {
    // 不变式: name 不能为空
    if name == "" {
        return nil, errors.New("name is required")
    }

    // 不变式: name 长度限制
    if len(name) > 100 {
        return nil, errors.New("name too long")
    }

    return &User{
        id:        uuid.New(),
        email:     email,
        name:      name,
        status:    valueobject.UserStatusActive,
        createdAt: time.Now(),
        updatedAt: time.Now(),
    }, nil
}

// Order 聚合的不变式
func (o *Order) AddItem(productID uuid.UUID, quantity int, price float64) error {
    // 不变式: 只有草稿状态可以添加商品
    if o.status != valueobject.OrderStatusDraft {
        return errors.New("can only add items to draft order")
    }

    // 不变式: 数量必须大于 0
    if quantity <= 0 {
        return errors.New("quantity must be positive")
    }

    // 不变式: 价格必须大于等于 0
    if price < 0 {
        return errors.New("price cannot be negative")
    }

    // 添加订单项
    item := &OrderItem{
        productID: productID,
        quantity:  quantity,
        price:     price,
    }
    o.items = append(o.items, item)

    // 重新计算总额
    o.recalculateTotal()

    return nil
}

// recalculateTotal 重新计算总额 (私有方法)
func (o *Order) recalculateTotal() {
    var total float64
    for _, item := range o.items {
        total += item.price * float64(item.quantity)
    }
    o.totalAmount = total
}
```

## Value Object 实现要点

### 不可变性和验证

```go
package valueobject

import (
    "errors"
    "regexp"
    "strings"
)

// Email 值对象
type Email struct {
    value string
}

var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

// NewEmail 创建邮箱值对象 (验证在构造器中)
func NewEmail(email string) (Email, error) {
    // 标准化
    email = strings.TrimSpace(strings.ToLower(email))

    // 验证
    if !emailRegex.MatchString(email) {
        return Email{}, errors.New("invalid email format")
    }

    return Email{value: email}, nil
}

// Value 获取值
func (e Email) Value() string {
    return e.value
}

// Domain 获取邮箱域名
func (e Email) Domain() string {
    parts := strings.Split(e.value, "@")
    if len(parts) == 2 {
        return parts[1]
    }
    return ""
}

// Equals 比较相等性
func (e Email) Equals(other Email) bool {
    return e.value == other.value
}
```

### 语义相等性

```go
package valueobject

// Money 金额值对象
type Money struct {
    amount   int64  // 以分为单位
    currency string
}

// NewMoney 创建金额
func NewMoney(amount int64, currency string) (Money, error) {
    if currency == "" {
        return Money{}, errors.New("currency required")
    }
    return Money{amount: amount, currency: currency}, nil
}

// Amount 获取金额
func (m Money) Amount() int64 {
    return m.amount
}

// Currency 获取货币
func (m Money) Currency() string {
    return m.currency
}

// Add 加法 (返回新对象，保持不可变性)
func (m Money) Add(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, errors.New("currency mismatch")
    }
    return Money{
        amount:   m.amount + other.amount,
        currency: m.currency,
    }, nil
}

// Subtract 减法
func (m Money) Subtract(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, errors.New("currency mismatch")
    }
    return Money{
        amount:   m.amount - other.amount,
        currency: m.currency,
    }, nil
}

// Equals 相等性比较
func (m Money) Equals(other Money) bool {
    return m.amount == other.amount && m.currency == other.currency
}
```

## Repository 接口定义

### 使用领域语言

```go
package repository

import (
    "context"
    "github.com/google/uuid"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/valueobject"
)

// UserRepository 用户仓储接口 (在 Domain 层定义)
type UserRepository interface {
    // 查询方法使用领域语言
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
    FindByEmail(ctx context.Context, email valueobject.Email) (*entity.User, error)
    FindActiveUsers(ctx context.Context) ([]*entity.User, error)

    // 持久化方法
    Save(ctx context.Context, user *entity.User) error
    Delete(ctx context.Context, id uuid.UUID) error

    // 批量操作
    SaveBatch(ctx context.Context, users []*entity.User) error

    // 存在性检查
    Exists(ctx context.Context, id uuid.UUID) (bool, error)
    ExistsByEmail(ctx context.Context, email valueobject.Email) (bool, error)
}

// 注意:
// - 不暴露 SQL 细节 (如: ExecuteQuery, PrepareStatement)
// - 使用领域术语 (FindActiveUsers 而非 FindByStatus)
// - 返回领域对象而非数据库行
```

### 只为聚合根创建仓储

```go
// ✅ 正确: 只为聚合根 Order 创建仓储
type OrderRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*entity.Order, error)
    Save(ctx context.Context, order *entity.Order) error
}

// ❌ 错误: 不要为聚合内实体创建仓储
// OrderItemRepository 不应该存在
// OrderItem 通过 Order 聚合根访问
```

## Domain Service 实现

### 跨实体的业务逻辑

```go
package service

import (
    "context"
    "errors"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/repository"
)

// UserAuthService 用户认证领域服务 (无状态)
type UserAuthService struct {
    userRepo repository.UserRepository
}

// NewUserAuthService 创建领域服务
func NewUserAuthService(userRepo repository.UserRepository) *UserAuthService {
    return &UserAuthService{
        userRepo: userRepo,
    }
}

// AuthenticateUser 认证用户 (跨实体的业务逻辑)
func (s *UserAuthService) AuthenticateUser(ctx context.Context, email string, password string) (*entity.User, error) {
    // 1. 查找用户
    emailVO, err := valueobject.NewEmail(email)
    if err != nil {
        return nil, err
    }

    user, err := s.userRepo.FindByEmail(ctx, emailVO)
    if err != nil {
        return nil, errors.New("invalid credentials")
    }

    // 2. 验证密码 (简化示例)
    if !user.VerifyPassword(password) {
        return nil, errors.New("invalid credentials")
    }

    // 3. 检查用户状态
    if user.Status() == valueobject.UserStatusSuspended {
        return nil, errors.New("user suspended")
    }

    return user, nil
}

// IsEmailUnique 检查邮箱唯一性 (领域服务)
func (s *UserAuthService) IsEmailUnique(ctx context.Context, email valueobject.Email) (bool, error) {
    exists, err := s.userRepo.ExistsByEmail(ctx, email)
    if err != nil {
        return false, err
    }
    return !exists, nil
}
```

## Event 定义

### 过去时命名和不可变性

```go
package event

import (
    "time"
    "github.com/google/uuid"
)

// UserCreated 用户创建事件 (过去时命名)
type UserCreated struct {
    userID     uuid.UUID
    email      string
    name       string
    occurredAt time.Time
}

// NewUserCreated 创建事件
func NewUserCreated(userID uuid.UUID, email, name string) UserCreated {
    return UserCreated{
        userID:     userID,
        email:      email,
        name:       name,
        occurredAt: time.Now(),
    }
}

// UserID 获取用户 ID
func (e UserCreated) UserID() uuid.UUID { return e.userID }

// Email 获取邮箱
func (e UserCreated) Email() string { return e.email }

// Name 获取名称
func (e UserCreated) Name() string { return e.name }

// OccurredAt 事件发生时间
func (e UserCreated) OccurredAt() time.Time { return e.occurredAt }

// EventType 事件类型
func (e UserCreated) EventType() string { return "UserCreated" }

// AggregateID 聚合 ID
func (e UserCreated) AggregateID() string { return e.userID.String() }

// 注意:
// - 所有字段私有，提供只读 Getter
// - 不提供任何修改方法 (不可变)
// - 过去时命名 (UserCreated 而非 CreateUser)
```

## Factory 工厂模式

### 复杂对象创建

```go
package factory

import (
    "myproject/internal/app/domain/order/entity"
    "myproject/internal/app/domain/order/valueobject"
)

// OrderFactory 订单工厂
type OrderFactory struct{}

// CreateOrder 创建订单 (封装复杂的创建逻辑)
func (f *OrderFactory) CreateOrder(customerID uuid.UUID, items []OrderItemRequest) (*entity.Order, error) {
    // 1. 创建订单
    order := entity.NewOrder(customerID)

    // 2. 添加订单项
    for _, itemReq := range items {
        if err := order.AddItem(itemReq.ProductID, itemReq.Quantity, itemReq.Price); err != nil {
            return nil, err
        }
    }

    // 3. 应用优惠券 (如果有)
    if itemReq.CouponCode != "" {
        if err := f.applyCoupon(order, itemReq.CouponCode); err != nil {
            return nil, err
        }
    }

    return order, nil
}

// CreateDraftOrder 创建草稿订单
func (f *OrderFactory) CreateDraftOrder(customerID uuid.UUID) *entity.Order {
    return entity.NewOrder(customerID)
}

// applyCoupon 应用优惠券 (私有方法)
func (f *OrderFactory) applyCoupon(order *entity.Order, couponCode string) error {
    // 优惠券逻辑
    return nil
}
```

## 包管理与循环依赖

### 避免包间循环

```go
// ❌ 错误: 循环依赖
// domain/user/entity/user.go
package entity

import "myproject/domain/order/entity" // 导入 order

type User struct {
    orders []*orderentity.Order // 引用 Order
}

// domain/order/entity/order.go
package entity

import "myproject/domain/user/entity" // 导入 user

type Order struct {
    user *userentity.User // 引用 User
}

// 问题: user 和 order 包相互依赖，导致循环
```

### 正确的解决方案

```go
// ✅ 正确: 使用 ID 引用，避免循环依赖

// domain/user/entity/user.go
package entity

type User struct {
    id uuid.UUID
    // 不直接引用 Order 实体
}

// domain/order/entity/order.go
package entity

type Order struct {
    id         uuid.UUID
    customerID uuid.UUID // 只存储 User 的 ID
}

// 如果需要加载关联对象，通过仓储
func (s *OrderService) GetOrderWithCustomer(ctx context.Context, orderID uuid.UUID) (*Order, *User, error) {
    order, err := s.orderRepo.FindByID(ctx, orderID)
    if err != nil {
        return nil, nil, err
    }

    user, err := s.userRepo.FindByID(ctx, order.CustomerID())
    if err != nil {
        return nil, nil, err
    }

    return order, user, nil
}
```

## 错误处理

### 领域错误定义

```go
package entity

import "errors"

// 领域错误 (定义在 Domain 层)
var (
    ErrUserNotFound       = errors.New("user not found")
    ErrInvalidEmail       = errors.New("invalid email")
    ErrNameTooLong        = errors.New("name too long")
    ErrUserSuspended      = errors.New("user suspended")
    ErrDuplicateEmail     = errors.New("email already exists")
    ErrOrderAlreadySubmitted = errors.New("order already submitted")
    ErrEmptyOrder         = errors.New("cannot submit empty order")
)

// ChangeName 返回领域错误
func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    if len(newName) > 100 {
        return ErrNameTooLong
    }

    u.name = newName
    return nil
}
```

## 完整示例: User 聚合实现

```go
package entity

import (
    "errors"
    "time"
    "github.com/google/uuid"
    "golang.org/x/crypto/bcrypt"
    "myproject/internal/app/domain/user/event"
    "myproject/internal/app/domain/user/valueobject"
)

// User 用户聚合根
type User struct {
    // 基本属性
    id             uuid.UUID
    email          valueobject.Email
    name           string
    passwordHash   string
    status         valueobject.UserStatus

    // 审计字段
    createdAt time.Time
    updatedAt time.Time

    // 领域事件
    domainEvents []event.DomainEvent
}

// NewUser 创建新用户
func NewUser(email valueobject.Email, name, password string) (*User, error) {
    // 验证
    if name == "" {
        return nil, errors.New("name is required")
    }
    if password == "" {
        return nil, errors.New("password is required")
    }

    // 密码哈希
    passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    if err != nil {
        return nil, err
    }

    user := &User{
        id:           uuid.New(),
        email:        email,
        name:         name,
        passwordHash: string(passwordHash),
        status:       valueobject.UserStatusActive,
        createdAt:    time.Now(),
        updatedAt:    time.Now(),
    }

    // 记录领域事件
    user.domainEvents = append(user.domainEvents, event.NewUserCreated(
        user.id,
        email.Value(),
        name,
    ))

    return user, nil
}

// Getter 方法
func (u *User) ID() uuid.UUID                   { return u.id }
func (u *User) Email() valueobject.Email        { return u.email }
func (u *User) Name() string                    { return u.name }
func (u *User) Status() valueobject.UserStatus  { return u.status }
func (u *User) CreatedAt() time.Time            { return u.createdAt }
func (u *User) UpdatedAt() time.Time            { return u.updatedAt }

// ChangeName 修改名称
func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    if len(newName) > 100 {
        return errors.New("name too long")
    }

    u.name = newName
    u.updatedAt = time.Now()

    return nil
}

// ChangeEmail 修改邮箱
func (u *User) ChangeEmail(newEmail valueobject.Email) error {
    if u.status == valueobject.UserStatusSuspended {
        return errors.New("suspended user cannot change email")
    }

    oldEmail := u.email
    u.email = newEmail
    u.updatedAt = time.Now()

    // 记录领域事件
    u.domainEvents = append(u.domainEvents, event.NewUserEmailChanged(
        u.id,
        oldEmail.Value(),
        newEmail.Value(),
    ))

    return nil
}

// ChangePassword 修改密码
func (u *User) ChangePassword(oldPassword, newPassword string) error {
    // 验证旧密码
    if !u.VerifyPassword(oldPassword) {
        return errors.New("invalid old password")
    }

    // 生成新密码哈希
    passwordHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
    if err != nil {
        return err
    }

    u.passwordHash = string(passwordHash)
    u.updatedAt = time.Now()

    return nil
}

// VerifyPassword 验证密码
func (u *User) VerifyPassword(password string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(u.passwordHash), []byte(password))
    return err == nil
}

// Suspend 暂停用户
func (u *User) Suspend() error {
    if u.status == valueobject.UserStatusSuspended {
        return nil
    }

    u.status = valueobject.UserStatusSuspended
    u.updatedAt = time.Now()

    return nil
}

// Activate 激活用户
func (u *User) Activate() error {
    if u.status == valueobject.UserStatusActive {
        return nil
    }

    u.status = valueobject.UserStatusActive
    u.updatedAt = time.Now()

    return nil
}

// DomainEvents 获取领域事件
func (u *User) DomainEvents() []event.DomainEvent {
    return u.domainEvents
}

// ClearDomainEvents 清空领域事件
func (u *User) ClearDomainEvents() {
    u.domainEvents = nil
}
```

## Domain Layer 测试策略

### 纯单元测试 (不需要数据库)

```go
package entity_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/valueobject"
)

func TestUser_ChangeName(t *testing.T) {
    // Arrange
    email, _ := valueobject.NewEmail("test@example.com")
    user, _ := entity.NewUser(email, "Old Name", "password123")

    // Act
    err := user.ChangeName("New Name")

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, "New Name", user.Name())
}

func TestUser_ChangeName_EmptyName(t *testing.T) {
    // Arrange
    email, _ := valueobject.NewEmail("test@example.com")
    user, _ := entity.NewUser(email, "Old Name", "password123")

    // Act
    err := user.ChangeName("")

    // Assert
    assert.Error(t, err)
    assert.Equal(t, "Old Name", user.Name()) // 名称未变更
}

func TestUser_ChangeEmail_SuspendedUser(t *testing.T) {
    // Arrange
    email, _ := valueobject.NewEmail("test@example.com")
    user, _ := entity.NewUser(email, "User Name", "password123")
    user.Suspend()

    newEmail, _ := valueobject.NewEmail("new@example.com")

    // Act
    err := user.ChangeEmail(newEmail)

    // Assert
    assert.Error(t, err)
    assert.Equal(t, email, user.Email()) // 邮箱未变更
}
```

### 测试不变式

```go
func TestOrder_AddItem_NonDraftOrder(t *testing.T) {
    // Arrange
    order := entity.NewOrder(uuid.New())
    order.AddItem(uuid.New(), 1, 100.0)
    order.Submit() // 提交订单

    // Act: 尝试向已提交的订单添加商品
    err := order.AddItem(uuid.New(), 1, 50.0)

    // Assert: 应该失败
    assert.Error(t, err)
}

func TestOrder_Submit_EmptyOrder(t *testing.T) {
    // Arrange
    order := entity.NewOrder(uuid.New())

    // Act: 尝试提交空订单
    err := order.Submit()

    // Assert: 应该失败
    assert.Error(t, err)
}
```

## 总结

Domain Layer 的关键实践:
- ✅ 使用私有字段 + 公开 Getter 保护封装
- ✅ 业务逻辑通过实体方法实现
- ✅ 构造函数确保对象初始有效状态
- ✅ 值对象不可变
- ✅ 仓储接口在 Domain 层定义
- ✅ 领域服务处理跨实体逻辑
- ✅ 使用 ID 引用避免循环依赖
- ✅ 纯单元测试，不依赖数据库
