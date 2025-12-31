# Ent ORM 高级实践

## Ent 简介

Ent 是一个简单但强大的 Go 实体框架，用于建模和查询数据。它具有代码生成、类型安全、灵活的查询 API 等特性。

**核心特性**:
- 代码生成 (Schema as Code)
- 类型安全的查询构建器
- 支持多种数据库 (MySQL, PostgreSQL, SQLite, Gremlin)
- 自动迁移管理
- 强大的边 (Edges) 和关系建模
- Hooks 和 Interceptors 支持

**与 DDD 结合**:
- Schema → Entity/Aggregate
- Edge → 聚合关系
- Hook → 领域事件触发点
- Transaction → 聚合一致性保证

## Schema 定义

### 基础 Schema

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "time"
)

// User Schema 定义
type User struct {
    ent.Schema
}

// Fields 字段定义
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("id").
            MaxLen(36).
            NotEmpty().
            Immutable().
            Unique(),

        field.String("email").
            MaxLen(255).
            NotEmpty().
            Unique(),

        field.String("name").
            MaxLen(100).
            NotEmpty(),

        field.String("password_hash").
            Sensitive(), // 敏感字段，不会在日志中打印

        field.Enum("status").
            Values("active", "suspended", "deleted").
            Default("active"),

        field.Time("created_at").
            Default(time.Now).
            Immutable(),

        field.Time("updated_at").
            Default(time.Now).
            UpdateDefault(time.Now),
    }
}
```

### 高级字段类型

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
)

// Order Schema 订单
type Order struct {
    ent.Schema
}

func (Order) Fields() []ent.Field {
    return []ent.Field{
        // UUID 字段
        field.UUID("id", uuid.UUID{}).
            Default(uuid.New).
            Immutable(),

        // JSON 字段 (存储值对象)
        field.JSON("shipping_address", &Address{}).
            Optional(),

        // 数组字段
        field.JSON("tags", []string{}).
            Optional(),

        // 枚举字段
        field.Enum("status").
            NamedValues(
                "Draft", "DRAFT",
                "Submitted", "SUBMITTED",
                "Completed", "COMPLETED",
                "Cancelled", "CANCELLED",
            ).
            Default("DRAFT"),

        // 金额字段 (分为单位)
        field.Int64("total_amount").
            NonNegative().
            Default(0),

        // 可选字段
        field.String("note").
            Optional().
            Nillable(),

        // 带默认值的字段
        field.Int("version").
            Default(1).
            Positive(),
    }
}

// Address 值对象
type Address struct {
    Street  string `json:"street"`
    City    string `json:"city"`
    Country string `json:"country"`
    ZipCode string `json:"zip_code"`
}
```

### 字段验证器

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "regexp"
    "errors"
)

// User Schema 带验证器
func (User) Fields() []ent.Field {
    return []ent.Field{
        // 正则验证
        field.String("email").
            Validate(func(s string) error {
                emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
                if !emailRegex.MatchString(s) {
                    return errors.New("invalid email format")
                }
                return nil
            }),

        // 长度验证
        field.String("name").
            MinLen(1).
            MaxLen(100),

        // 范围验证
        field.Int("age").
            Min(0).
            Max(150),

        // 自定义验证
        field.String("phone").
            Validate(func(s string) error {
                phoneRegex := regexp.MustCompile(`^1[3-9]\d{9}$`)
                if !phoneRegex.MatchString(s) {
                    return errors.New("invalid phone number")
                }
                return nil
            }),
    }
}
```

## 边 (Edges) 和关系

### 一对多关系

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/edge"
)

// User Schema
type User struct {
    ent.Schema
}

func (User) Edges() []ent.Edge {
    return []ent.Edge{
        // User 拥有多个 Order (一对多)
        edge.To("orders", Order.Type),
    }
}

// Order Schema
type Order struct {
    ent.Schema
}

func (Order) Edges() []ent.Edge {
    return []ent.Edge{
        // Order 属于一个 User (多对一)
        edge.From("user", User.Type).
            Ref("orders").
            Unique().       // 一个订单只属于一个用户
            Required(),     // 订单必须有用户
    }
}
```

### 聚合根与聚合内实体

```go
package schema

// Order 聚合根
type Order struct {
    ent.Schema
}

func (Order) Edges() []ent.Edge {
    return []ent.Edge{
        // 聚合内实体: OrderItem (通过 Order 级联删除)
        edge.To("items", OrderItem.Type).
            Annotations(entgql.Bind()),
    }
}

func (Order) Annotations() []schema.Annotation {
    return []schema.Annotation{
        // 级联删除配置
        entsql.Annotation{
            OnDelete: entsql.Cascade,
        },
    }
}

// OrderItem 聚合内实体
type OrderItem struct {
    ent.Schema
}

func (OrderItem) Edges() []ent.Edge {
    return []ent.Edge{
        // 反向引用 Order
        edge.From("order", Order.Type).
            Ref("items").
            Unique().
            Required(),
    }
}
```

### 多对多关系

```go
package schema

// User 和 Role 多对多关系
type User struct {
    ent.Schema
}

func (User) Edges() []ent.Edge {
    return []ent.Edge{
        edge.To("roles", Role.Type),
    }
}

type Role struct {
    ent.Schema
}

func (Role) Edges() []ent.Edge {
    return []ent.Edge{
        edge.From("users", User.Type).
            Ref("roles"),
    }
}
```

## 查询高级用法

### 基础查询

```go
package repository

import (
    "context"
    "myproject/internal/app/infrastructure/ent"
)

// UserRepositoryImpl Ent 实现
type UserRepositoryImpl struct {
    client *ent.Client
}

// FindByID 根据 ID 查询
func (r *UserRepositoryImpl) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    user, err := r.client.User.
        Query().
        Where(user.ID(id)).
        Only(ctx)

    if err != nil {
        if ent.IsNotFound(err) {
            return nil, ErrUserNotFound
        }
        return nil, err
    }

    return r.toDomain(user)
}

// FindByEmail 根据邮箱查询
func (r *UserRepositoryImpl) FindByEmail(ctx context.Context, email string) (*entity.User, error) {
    user, err := r.client.User.
        Query().
        Where(user.EmailEQ(email)).
        Only(ctx)

    if err != nil {
        return nil, err
    }

    return r.toDomain(user)
}

// FindActiveUsers 查询活跃用户
func (r *UserRepositoryImpl) FindActiveUsers(ctx context.Context) ([]*entity.User, error) {
    users, err := r.client.User.
        Query().
        Where(user.StatusEQ(user.StatusActive)).
        All(ctx)

    if err != nil {
        return nil, err
    }

    return r.toDomainList(users)
}
```

### 复杂查询

```go
package repository

// FindOrders 复杂查询示例
func (r *OrderRepositoryImpl) FindOrders(
    ctx context.Context,
    customerID uuid.UUID,
    status string,
    startDate, endDate time.Time,
) ([]*entity.Order, error) {
    query := r.client.Order.Query()

    // 条件 1: 客户 ID
    if customerID != uuid.Nil {
        query = query.Where(order.CustomerIDEQ(customerID))
    }

    // 条件 2: 状态
    if status != "" {
        query = query.Where(order.StatusEQ(status))
    }

    // 条件 3: 日期范围
    if !startDate.IsZero() {
        query = query.Where(order.CreatedAtGTE(startDate))
    }
    if !endDate.IsZero() {
        query = query.Where(order.CreatedAtLTE(endDate))
    }

    // 条件 4: 金额范围
    query = query.Where(order.TotalAmountGT(0))

    // 排序
    query = query.Order(ent.Desc(order.FieldCreatedAt))

    // 分页
    query = query.Limit(100).Offset(0)

    orders, err := query.All(ctx)
    if err != nil {
        return nil, err
    }

    return r.toDomainList(orders)
}
```

### 预加载关联数据

```go
package repository

// FindOrderWithItems 预加载订单项
func (r *OrderRepositoryImpl) FindOrderWithItems(ctx context.Context, id uuid.UUID) (*entity.Order, error) {
    order, err := r.client.Order.
        Query().
        Where(order.IDEQ(id)).
        WithItems().  // 预加载订单项
        Only(ctx)

    if err != nil {
        return nil, err
    }

    return r.toDomain(order)
}

// FindOrdersWithUser 预加载用户信息
func (r *OrderRepositoryImpl) FindOrdersWithUser(ctx context.Context) ([]*entity.Order, error) {
    orders, err := r.client.Order.
        Query().
        WithUser().  // 预加载用户
        All(ctx)

    if err != nil {
        return nil, err
    }

    return r.toDomainList(orders)
}
```

### 聚合查询

```go
package repository

import "entgo.io/ent/dialect/sql"

// GetOrderStatistics 聚合统计
func (r *OrderRepositoryImpl) GetOrderStatistics(ctx context.Context, customerID uuid.UUID) (*OrderStats, error) {
    var stats struct {
        TotalOrders int
        TotalAmount int64
    }

    err := r.client.Order.
        Query().
        Where(order.CustomerIDEQ(customerID)).
        Aggregate(
            ent.Count(),
            ent.Sum(order.FieldTotalAmount),
        ).
        Scan(ctx, &stats.TotalOrders, &stats.TotalAmount)

    if err != nil {
        return nil, err
    }

    return &OrderStats{
        TotalOrders: stats.TotalOrders,
        TotalAmount: stats.TotalAmount,
    }, nil
}

// GroupByStatus 按状态分组统计
func (r *OrderRepositoryImpl) GroupByStatus(ctx context.Context) (map[string]int, error) {
    var results []struct {
        Status string `json:"status"`
        Count  int    `json:"count"`
    }

    err := r.client.Order.
        Query().
        GroupBy(order.FieldStatus).
        Aggregate(ent.Count()).
        Scan(ctx, &results)

    if err != nil {
        return nil, err
    }

    stats := make(map[string]int)
    for _, result := range results {
        stats[result.Status] = result.Count
    }

    return stats, nil
}
```

## 事务管理

### 基础事务

```go
package repository

// CreateUserWithOrder 事务示例
func (r *UserRepositoryImpl) CreateUserWithOrder(
    ctx context.Context,
    user *entity.User,
    order *entity.Order,
) error {
    // 开始事务
    tx, err := r.client.Tx(ctx)
    if err != nil {
        return err
    }

    // 延迟回滚
    defer func() {
        if v := recover(); v != nil {
            tx.Rollback()
            panic(v)
        }
    }()

    // 1. 创建用户
    _, err = tx.User.Create().
        SetID(user.ID()).
        SetEmail(user.Email().Value()).
        SetName(user.Name()).
        SetPasswordHash(user.PasswordHash()).
        Save(ctx)

    if err != nil {
        return rollback(tx, err)
    }

    // 2. 创建订单
    _, err = tx.Order.Create().
        SetID(order.ID()).
        SetCustomerID(user.ID()).
        SetTotalAmount(order.TotalAmount().Amount()).
        SetStatus(string(order.Status())).
        Save(ctx)

    if err != nil {
        return rollback(tx, err)
    }

    // 提交事务
    return tx.Commit()
}

// rollback 辅助函数
func rollback(tx *ent.Tx, err error) error {
    if rerr := tx.Rollback(); rerr != nil {
        err = fmt.Errorf("%w: rolling back transaction: %v", err, rerr)
    }
    return err
}
```

### 事务传播

```go
package repository

// WithTx 支持事务传播
func (r *UserRepositoryImpl) WithTx(tx *ent.Tx) *UserRepositoryImpl {
    return &UserRepositoryImpl{
        client: tx.Client(),
    }
}

// Save 保存用户 (支持事务)
func (r *UserRepositoryImpl) Save(ctx context.Context, user *entity.User) error {
    _, err := r.client.User.Create().
        SetID(user.ID()).
        SetEmail(user.Email().Value()).
        SetName(user.Name()).
        Save(ctx)

    return err
}

// 使用示例
func CreateUserAndOrder(
    userRepo *UserRepositoryImpl,
    orderRepo *OrderRepositoryImpl,
    user *entity.User,
    order *entity.Order,
) error {
    ctx := context.Background()

    // 开始事务
    tx, err := userRepo.client.Tx(ctx)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    // 传递事务给仓储
    userRepoTx := userRepo.WithTx(tx)
    orderRepoTx := orderRepo.WithTx(tx)

    // 在事务中保存
    if err := userRepoTx.Save(ctx, user); err != nil {
        return err
    }

    if err := orderRepoTx.Save(ctx, order); err != nil {
        return err
    }

    // 提交事务
    return tx.Commit()
}
```

## Hooks 和拦截器

### 创建 Hook

```go
package schema

import (
    "context"
    "entgo.io/ent"
    "time"
)

// User Hooks
func (User) Hooks() []ent.Hook {
    return []ent.Hook{
        // 创建前 Hook
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return ent.MutateFunc(func(ctx context.Context, m ent.Mutation) (ent.Value, error) {
                    if userMutation, ok := m.(*ent.UserMutation); ok {
                        // 设置创建时间
                        userMutation.SetCreatedAt(time.Now())
                        userMutation.SetUpdatedAt(time.Now())
                    }
                    return next.Mutate(ctx, m)
                })
            },
            ent.OpCreate,
        ),

        // 更新前 Hook
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return ent.MutateFunc(func(ctx context.Context, m ent.Mutation) (ent.Value, error) {
                    if userMutation, ok := m.(*ent.UserMutation); ok {
                        // 更新修改时间
                        userMutation.SetUpdatedAt(time.Now())
                    }
                    return next.Mutate(ctx, m)
                })
            },
            ent.OpUpdate | ent.OpUpdateOne,
        ),
    }
}
```

### 领域事件 Hook

```go
package schema

// Order Hooks 触发领域事件
func (Order) Hooks() []ent.Hook {
    return []ent.Hook{
        // 订单创建后发布事件
        hook.On(
            func(next ent.Mutator) ent.Mutator {
                return ent.MutateFunc(func(ctx context.Context, m ent.Mutation) (ent.Value, error) {
                    value, err := next.Mutate(ctx, m)
                    if err != nil {
                        return nil, err
                    }

                    // 获取创建的订单
                    if orderMutation, ok := m.(*ent.OrderMutation); ok {
                        id, _ := orderMutation.ID()
                        customerID, _ := orderMutation.CustomerID()

                        // 发布领域事件
                        eventBus := ctx.Value("event_bus").(EventPublisher)
                        eventBus.Publish(OrderCreatedEvent{
                            OrderID:    id,
                            CustomerID: customerID,
                        })
                    }

                    return value, nil
                })
            },
            ent.OpCreate,
        ),
    }
}
```

## 迁移管理

### 自动迁移

```go
package main

import (
    "context"
    "log"
    "myproject/internal/app/infrastructure/ent"
)

func main() {
    client, err := ent.Open("mysql", "user:pass@tcp(localhost:3306)/db?parseTime=true")
    if err != nil {
        log.Fatal(err)
    }
    defer client.Close()

    // 自动迁移
    if err := client.Schema.Create(context.Background()); err != nil {
        log.Fatalf("failed creating schema resources: %v", err)
    }
}
```

### 版本化迁移

```bash
# 生成迁移文件
atlas migrate diff migration_name \
  --dir "file://ent/migrate/migrations" \
  --to "ent://ent/schema" \
  --dev-url "docker://mysql/8/ent"

# 应用迁移
atlas migrate apply \
  --dir "file://ent/migrate/migrations" \
  --url "mysql://user:pass@localhost:3306/db"
```

## 与 DDD 集成

### 仓储实现

```go
package repository

// UserRepositoryImpl 用户仓储实现
type UserRepositoryImpl struct {
    client *ent.Client
}

// FindByID 查询用户
func (r *UserRepositoryImpl) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    entUser, err := r.client.User.Get(ctx, id)
    if err != nil {
        return nil, err
    }

    return r.toDomain(entUser)
}

// Save 保存用户
func (r *UserRepositoryImpl) Save(ctx context.Context, user *entity.User) error {
    return r.client.User.Create().
        SetID(user.ID()).
        SetEmail(user.Email().Value()).
        SetName(user.Name()).
        SetPasswordHash(user.PasswordHash()).
        SetStatus(string(user.Status())).
        OnConflictColumns(user.FieldID).
        UpdateNewValues().
        Exec(ctx)
}

// toDomain 转换为领域对象
func (r *UserRepositoryImpl) toDomain(entUser *ent.User) (*entity.User, error) {
    email, err := valueobject.NewEmail(entUser.Email)
    if err != nil {
        return nil, err
    }

    return entity.ReconstructUser(
        entUser.ID,
        email,
        entUser.Name,
        entUser.PasswordHash,
        valueobject.UserStatus(entUser.Status),
        entUser.CreatedAt,
        entUser.UpdatedAt,
    ), nil
}
```

### 聚合保存

```go
package repository

// SaveOrderWithItems 保存订单聚合 (包括订单项)
func (r *OrderRepositoryImpl) SaveOrderWithItems(ctx context.Context, order *entity.Order) error {
    // 开始事务
    tx, err := r.client.Tx(ctx)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    // 1. 保存订单
    _, err = tx.Order.Create().
        SetID(order.ID()).
        SetCustomerID(order.CustomerID()).
        SetTotalAmount(order.TotalAmount().Amount()).
        SetStatus(string(order.Status())).
        SetShippingAddress(order.ShippingAddress()).
        OnConflict().
        UpdateNewValues().
        Save(ctx)

    if err != nil {
        return err
    }

    // 2. 删除旧订单项
    _, err = tx.OrderItem.Delete().
        Where(orderitem.HasOrderWith(orderitem.IDEQ(order.ID()))).
        Exec(ctx)

    if err != nil {
        return err
    }

    // 3. 保存新订单项
    for _, item := range order.Items() {
        _, err = tx.OrderItem.Create().
            SetID(item.ID()).
            SetOrderID(order.ID()).
            SetProductID(item.ProductID()).
            SetProductName(item.ProductName()).
            SetQuantity(item.Quantity()).
            SetPrice(item.Price().Amount()).
            Save(ctx)

        if err != nil {
            return err
        }
    }

    // 提交事务
    return tx.Commit()
}
```

## 总结

Ent ORM 的关键实践:
- ✅ 使用 Schema 定义领域模型
- ✅ 边 (Edges) 建模聚合关系
- ✅ 类型安全的查询构建器
- ✅ 事务保证聚合一致性
- ✅ Hooks 触发领域事件
- ✅ 自动/版本化迁移管理
- ✅ 与 DDD 仓储模式集成
- ✅ 预加载避免 N+1 查询
