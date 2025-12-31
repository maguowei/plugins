# Go DDD 命名规范

## Go 命名规范基础

Go 语言对命名有明确的规范和约定:

**核心原则**:
- 使用 CamelCase (不使用下划线)
- 公开标识符首字母大写 (Exported)
- 私有标识符首字母小写 (Unexported)
- 简洁明确,避免冗余
- 名称应表达意图,不需要注释补充

## 包命名规范

### 基础规则

```go
// ✅ 正确: 简洁、小写、单数
package user
package order
package repository

// ❌ 错误: 下划线、复数、大写
package user_service
package users
package UserRepository
```

### DDD 包命名

```go
// 领域层
package entity        // 实体
package valueobject   // 值对象 (单数)
package event         // 领域事件
package repository    // 仓储接口 (单数)
package service       // 领域服务

// 应用层
package service       // 应用服务
package dto           // 数据传输对象

// 基础设施层
package repository    // 仓储实现
package cache         // 缓存
package messaging     // 消息队列

// 接口层
package handler       // HTTP Handler
package middleware    // 中间件
```

**最佳实践**:
- 包名使用单数形式
- 避免 `common`、`util`、`base` 等通用名称
- 包名应该描述其提供的功能
- 避免包名和类型名重复

## 文件命名规范

### 基础规则

```bash
# ✅ 正确: 小写、下划线分隔
user.go
user_test.go
order_service.go
user_repository.go

# ❌ 错误: CamelCase、连字符
User.go
userTest.go
order-service.go
```

### DDD 文件命名

```bash
# 实体
user.go                    # User 实体
order.go                   # Order 实体

# 值对象
email.go                   # Email 值对象
money.go                   # Money 值对象
user_status.go             # UserStatus 枚举

# 领域事件
user_events.go             # 用户相关事件
order_events.go            # 订单相关事件

# 仓储
user_repository.go         # 仓储接口
user_repository_impl.go    # 仓储实现

# 服务
user_domain_service.go     # 领域服务
user_application_service.go # 应用服务

# Handler
user_handler.go            # 用户 Handler
order_handler.go           # 订单 Handler

# 测试
user_test.go               # 单元测试
user_repository_test.go    # 仓储测试
```

## 类型命名规范

### 实体 (Entity)

```go
// ✅ 正确: 简洁的名词
type User struct { }
type Order struct { }
type Product struct { }

// ❌ 错误: 冗余的后缀
type UserEntity struct { }
type OrderAggregate struct { }
```

### 值对象 (Value Object)

```go
// ✅ 正确: 表达概念的名词
type Email struct { }
type Money struct { }
type Address struct { }
type PhoneNumber struct { }

// ✅ 枚举类型
type UserStatus string
type OrderStatus string

const (
    UserStatusActive    UserStatus = "active"
    UserStatusSuspended UserStatus = "suspended"
)
```

### 聚合根 (Aggregate Root)

```go
// ✅ 正确: 直接使用聚合名称
type Order struct {
    id    uuid.UUID
    items []*OrderItem  // 聚合内实体
}

type OrderItem struct {  // 不需要 Aggregate 后缀
    id        uuid.UUID
    productID uuid.UUID
}
```

### 仓储 (Repository)

```go
// ✅ 正确: 接口名 + Repository 后缀
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*User, error)
    Save(ctx context.Context, user *User) error
}

// ✅ 实现类名 + Impl 后缀
type UserRepositoryImpl struct {
    db *sql.DB
}

// 或者使用存储类型后缀
type MySQLUserRepository struct { }
type RedisUserRepository struct { }
```

### 服务 (Service)

```go
// ✅ 领域服务: DomainService 后缀
type TransferDomainService struct { }
type PricingDomainService struct { }

// ✅ 应用服务: ApplicationService 后缀
type UserApplicationService struct { }
type OrderApplicationService struct { }
```

### DTO (Data Transfer Object)

```go
// ✅ 请求 DTO: Request 后缀
type CreateUserRequest struct {
    Email    string `json:"email"`
    Name     string `json:"name"`
    Password string `json:"password"`
}

// ✅ 响应 DTO: Response 后缀
type UserResponse struct {
    ID    string `json:"id"`
    Email string `json:"email"`
    Name  string `json:"name"`
}
```

### 事件 (Event)

```go
// ✅ 正确: 过去式 + Event 后缀
type UserCreatedEvent struct { }
type OrderSubmittedEvent struct { }
type PaymentCompletedEvent struct { }

// ❌ 错误: 现在式或进行式
type UserCreateEvent struct { }
type OrderSubmittingEvent struct { }
```

## 方法命名规范

### 构造函数

```go
// ✅ 正确: New + 类型名
func NewUser(email, name, password string) (*User, error) { }
func NewOrder(customerID uuid.UUID) *Order { }
func NewMoney(amount int64, currency string) Money { }

// ✅ 工厂方法: 描述性名称
func ReconstructUser(id uuid.UUID, email Email, ...) *User { }
func CreateOrderFromCart(cart *Cart) (*Order, error) { }
```

### Getter 方法

```go
// ✅ 正确: 直接使用字段名 (不需要 Get 前缀)
func (u *User) ID() uuid.UUID { return u.id }
func (u *User) Email() Email { return u.email }
func (u *User) Name() string { return u.name }

// ❌ 错误: 使用 Get 前缀 (不符合 Go 习惯)
func (u *User) GetID() uuid.UUID { }
func (u *User) GetEmail() Email { }
```

### Setter 方法 (尽量避免)

```go
// ✅ 正确: 使用业务语义的方法名
func (u *User) ChangeName(newName string) error { }
func (u *User) UpdateEmail(newEmail Email) error { }
func (u *User) Activate() error { }
func (u *User) Suspend() error { }

// ❌ 错误: 使用 Set 前缀 (违反封装)
func (u *User) SetName(name string) { }
func (u *User) SetStatus(status UserStatus) { }
```

### 仓储方法

```go
// ✅ 正确: 清晰的业务语言
func (r *UserRepository) FindByID(ctx context.Context, id uuid.UUID) (*User, error)
func (r *UserRepository) FindByEmail(ctx context.Context, email Email) (*User, error)
func (r *UserRepository) FindActiveUsers(ctx context.Context) ([]*User, error)
func (r *UserRepository) Save(ctx context.Context, user *User) error
func (r *UserRepository) Delete(ctx context.Context, id uuid.UUID) error

// ❌ 错误: SQL 味道太重
func (r *UserRepository) SelectByID(id uuid.UUID) (*User, error)
func (r *UserRepository) Insert(user *User) error
func (r *UserRepository) Update(user *User) error
```

### 领域服务方法

```go
// ✅ 正确: 动词开头,表达业务操作
func (s *TransferDomainService) Transfer(from, to *Account, amount Money) error
func (s *PricingDomainService) CalculatePrice(items []*OrderItem) (Money, error)
func (s *InventoryDomainService) ReserveInventory(productID uuid.UUID, quantity int) error
```

### 应用服务方法

```go
// ✅ 正确: 用例名称
func (s *UserApplicationService) CreateUser(ctx context.Context, req CreateUserRequest) (*UserResponse, error)
func (s *OrderApplicationService) SubmitOrder(ctx context.Context, orderID uuid.UUID) error
func (s *OrderApplicationService) CancelOrder(ctx context.Context, orderID uuid.UUID) error
```

## 变量命名规范

### 局部变量

```go
// ✅ 简短、清晰
user := entity.NewUser(...)
order := entity.NewOrder(...)
ctx := context.Background()

// 集合使用复数
users := []*entity.User{}
orders := []*entity.Order{}

// ❌ 避免单字母变量 (除了循环)
u := entity.NewUser(...)  // 不够清晰
```

### 接收者命名

```go
// ✅ 正确: 类型首字母缩写 (1-2 个字母)
func (u *User) ChangeName(name string) error { }
func (o *Order) AddItem(item *OrderItem) error { }
func (ur *UserRepository) Save(ctx context.Context, user *User) error { }

// ❌ 错误: 使用 this、self
func (this *User) ChangeName(name string) error { }
func (self *Order) AddItem(item *OrderItem) error { }
```

### 常量命名

```go
// ✅ 正确: CamelCase,类型前缀
const (
    UserStatusActive    UserStatus = "active"
    UserStatusSuspended UserStatus = "suspended"

    OrderStatusDraft      OrderStatus = "draft"
    OrderStatusSubmitted  OrderStatus = "submitted"
)

// ❌ 错误: 全大写 + 下划线 (非 Go 风格)
const (
    USER_STATUS_ACTIVE = "active"
    ORDER_STATUS_DRAFT = "draft"
)
```

## 接口命名规范

```go
// ✅ 单方法接口: 方法名 + er
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// ✅ 多方法接口: 描述性名词
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*User, error)
    Save(ctx context.Context, user *User) error
}

type EventPublisher interface {
    Publish(ctx context.Context, event DomainEvent) error
    PublishBatch(ctx context.Context, events []DomainEvent) error
}
```

## 错误命名规范

```go
// ✅ 正确: Err 前缀
var (
    ErrUserNotFound      = errors.New("user not found")
    ErrInvalidEmail      = errors.New("invalid email")
    ErrInsufficientFunds = errors.New("insufficient funds")
)

// ✅ 自定义错误类型: Error 后缀
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("%s: %s", e.Field, e.Message)
}
```

## 总结

Go DDD 命名的关键实践:
- ✅ 遵循 Go 命名规范 (CamelCase)
- ✅ 包名简洁、小写、单数
- ✅ 文件名小写、下划线分隔
- ✅ 实体/值对象直接用名词,不加后缀
- ✅ 仓储接口 + Repository 后缀
- ✅ 仓储实现 + Impl 后缀
- ✅ 服务分类: DomainService / ApplicationService
- ✅ DTO 分类: Request / Response
- ✅ 事件使用过去式 + Event
- ✅ Getter 不使用 Get 前缀
- ✅ 使用业务语义的方法名
- ✅ 错误变量 Err 前缀,类型 Error 后缀
