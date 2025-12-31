# Repository 高级模式

## Repository 本质

Repository（仓储）是 DDD 中的关键模式，它提供了一个集合式的接口来访问聚合根，隔离了领域层与数据访问细节。

**核心概念**:
- **集合抽象**: Repository 像一个内存中的集合，屏蔽持久化细节
- **聚合根导向**: 只为聚合根创建 Repository
- **领域语言**: 使用业务术语而非技术术语
- **持久化无关**: 领域层不关心数据如何存储

**Repository vs DAO**:

| 维度 | Repository | DAO |
|------|-----------|-----|
| 层次 | Domain Layer 定义接口 | 数据访问层 |
| 抽象级别 | 集合抽象 | 表/文档抽象 |
| 命名 | 领域语言 (FindActiveUsers) | 技术术语 (SelectByStatus) |
| 返回类型 | 领域对象 | 数据库记录 |
| 职责 | 管理聚合生命周期 | CRUD 操作 |

## 仓储接口设计

### 只为聚合根创建仓储

```go
package repository

import (
    "context"
    "github.com/google/uuid"
    "myproject/internal/app/domain/order/entity"
)

// ✅ 正确: 只为聚合根 Order 创建仓储
type OrderRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*entity.Order, error)
    Save(ctx context.Context, order *entity.Order) error
    Delete(ctx context.Context, id uuid.UUID) error
}

// ❌ 错误: 不要为聚合内实体创建仓储
// OrderItemRepository 不应该存在
// OrderItem 是聚合内实体，通过 Order 访问

// 访问订单项的正确方式
func GetOrderItems(order *entity.Order) []*entity.OrderItem {
    return order.Items() // 通过聚合根访问
}
```

### 使用领域概念命名

```go
package repository

// ✅ 正确: 使用领域语言
type UserRepository interface {
    // 领域概念: "活跃用户"
    FindActiveUsers(ctx context.Context) ([]*entity.User, error)

    // 领域概念: "按邮箱查找"
    FindByEmail(ctx context.Context, email valueobject.Email) (*entity.User, error)

    // 领域概念: "邮箱是否已存在"
    ExistsByEmail(ctx context.Context, email valueobject.Email) (bool, error)
}

// ❌ 错误: 暴露技术细节
type UserRepository interface {
    // 技术术语: SQL 味道太重
    SelectByStatus(ctx context.Context, status string) ([]*entity.User, error)

    // 技术术语: 暴露查询细节
    ExecuteQuery(ctx context.Context, sql string, args ...interface{}) ([]*entity.User, error)
}
```

### 避免 SQL 语言泄漏

```go
package repository

// ✅ 正确: 封装查询逻辑
type OrderRepository interface {
    // 业务语言
    FindRecentOrders(ctx context.Context, customerID uuid.UUID, limit int) ([]*entity.Order, error)

    // 业务语言
    FindPendingOrders(ctx context.Context) ([]*entity.Order, error)
}

// 实现层处理 SQL 细节
func (r *OrderRepositoryImpl) FindPendingOrders(ctx context.Context) ([]*entity.Order, error) {
    // SQL 在实现层，不暴露给领域层
    query := `SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at DESC`
    // ...
}
```

## Repository 实现策略

### 策略 1: 单一存储实现

```go
package repository

import (
    "context"
    "database/sql"
)

// MySQLUserRepository MySQL 实现
type MySQLUserRepository struct {
    db *sql.DB
}

func NewMySQLUserRepository(db *sql.DB) *MySQLUserRepository {
    return &MySQLUserRepository{db: db}
}

func (r *MySQLUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    query := `SELECT id, email, name, status, created_at, updated_at FROM users WHERE id = ?`

    row := r.db.QueryRowContext(ctx, query, id.String())

    var dbUser struct {
        ID        string
        Email     string
        Name      string
        Status    string
        CreatedAt time.Time
        UpdatedAt time.Time
    }

    if err := row.Scan(&dbUser.ID, &dbUser.Email, &dbUser.Name, &dbUser.Status, &dbUser.CreatedAt, &dbUser.UpdatedAt); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, err
    }

    return r.toDomain(&dbUser)
}

func (r *MySQLUserRepository) Save(ctx context.Context, user *entity.User) error {
    query := `INSERT INTO users (id, email, name, status, created_at, updated_at)
              VALUES (?, ?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE
              email = VALUES(email), name = VALUES(name), status = VALUES(status), updated_at = VALUES(updated_at)`

    _, err := r.db.ExecContext(ctx, query,
        user.ID().String(),
        user.Email().Value(),
        user.Name(),
        user.Status().String(),
        user.CreatedAt(),
        user.UpdatedAt(),
    )

    return err
}
```

### 策略 2: 多存储实现 (读写分离)

```go
package repository

// ReadWriteUserRepository 读写分离仓储
type ReadWriteUserRepository struct {
    readDB  *sql.DB  // 只读数据库（从库）
    writeDB *sql.DB  // 写数据库（主库）
}

func NewReadWriteUserRepository(readDB, writeDB *sql.DB) *ReadWriteUserRepository {
    return &ReadWriteUserRepository{
        readDB:  readDB,
        writeDB: writeDB,
    }
}

// FindByID 从只读库查询
func (r *ReadWriteUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    query := `SELECT * FROM users WHERE id = ?`
    row := r.readDB.QueryRowContext(ctx, query, id.String())
    // 扫描并返回
    return r.scanUser(row)
}

// Save 写入主库
func (r *ReadWriteUserRepository) Save(ctx context.Context, user *entity.User) error {
    query := `INSERT INTO users (...) VALUES (...) ON DUPLICATE KEY UPDATE ...`
    _, err := r.writeDB.ExecContext(ctx, query, /* args */)
    return err
}
```

### 策略 3: 缓存分层

```go
package repository

import (
    "context"
    "fmt"
    "time"
)

// CachedUserRepository 带缓存的仓储
type CachedUserRepository struct {
    base  UserRepository
    cache Cache
    ttl   time.Duration
}

func NewCachedUserRepository(base UserRepository, cache Cache, ttl time.Duration) *CachedUserRepository {
    return &CachedUserRepository{
        base:  base,
        cache: cache,
        ttl:   ttl,
    }
}

// FindByID 先查缓存，再查数据库
func (r *CachedUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    cacheKey := fmt.Sprintf("user:%s", id.String())

    // 1. 尝试从缓存获取
    var user *entity.User
    if err := r.cache.Get(ctx, cacheKey, &user); err == nil {
        return user, nil // 缓存命中
    }

    // 2. 从数据库查询
    user, err := r.base.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // 3. 写入缓存
    _ = r.cache.Set(ctx, cacheKey, user, r.ttl)

    return user, nil
}

// Save 保存并清除缓存
func (r *CachedUserRepository) Save(ctx context.Context, user *entity.User) error {
    // 1. 保存到数据库
    if err := r.base.Save(ctx, user); err != nil {
        return err
    }

    // 2. 清除缓存
    cacheKey := fmt.Sprintf("user:%s", user.ID().String())
    _ = r.cache.Delete(ctx, cacheKey)

    return nil
}
```

### 策略 4: Query Object 模式

```go
package repository

// UserQuery 查询对象
type UserQuery struct {
    Email  *string
    Status *valueobject.UserStatus
    Limit  int
    Offset int
}

// NewUserQuery 创建查询对象
func NewUserQuery() *UserQuery {
    return &UserQuery{}
}

// WithEmail 设置邮箱条件
func (q *UserQuery) WithEmail(email string) *UserQuery {
    q.Email = &email
    return q
}

// WithStatus 设置状态条件
func (q *UserQuery) WithStatus(status valueobject.UserStatus) *UserQuery {
    q.Status = &status
    return q
}

// WithPagination 设置分页
func (q *UserQuery) WithPagination(limit, offset int) *UserQuery {
    q.Limit = limit
    q.Offset = offset
    return q
}

// UserRepository 支持 Query Object
type UserRepository interface {
    Find(ctx context.Context, query *UserQuery) ([]*entity.User, error)
}

// 使用示例
func FindActiveUsersWithEmail(repo UserRepository, email string) ([]*entity.User, error) {
    query := NewUserQuery().
        WithEmail(email).
        WithStatus(valueobject.UserStatusActive).
        WithPagination(10, 0)

    return repo.Find(context.Background(), query)
}
```

### 策略 5: Specification 模式

```go
package specification

import "context"

// Specification 规约接口
type Specification interface {
    IsSatisfiedBy(user *entity.User) bool
    ToSQL() (string, []interface{})
}

// ActiveUserSpec 活跃用户规约
type ActiveUserSpec struct{}

func (s *ActiveUserSpec) IsSatisfiedBy(user *entity.User) bool {
    return user.Status() == valueobject.UserStatusActive
}

func (s *ActiveUserSpec) ToSQL() (string, []interface{}) {
    return "status = ?", []interface{}{"active"}
}

// EmailSpec 邮箱规约
type EmailSpec struct {
    email string
}

func NewEmailSpec(email string) *EmailSpec {
    return &EmailSpec{email: email}
}

func (s *EmailSpec) IsSatisfiedBy(user *entity.User) bool {
    return user.Email().Value() == s.email
}

func (s *EmailSpec) ToSQL() (string, []interface{}) {
    return "email = ?", []interface{}{s.email}
}

// AndSpec 组合规约 (AND)
type AndSpec struct {
    specs []Specification
}

func And(specs ...Specification) *AndSpec {
    return &AndSpec{specs: specs}
}

func (s *AndSpec) IsSatisfiedBy(user *entity.User) bool {
    for _, spec := range s.specs {
        if !spec.IsSatisfiedBy(user) {
            return false
        }
    }
    return true
}

func (s *AndSpec) ToSQL() (string, []interface{}) {
    var conditions []string
    var args []interface{}

    for _, spec := range s.specs {
        sql, specArgs := spec.ToSQL()
        conditions = append(conditions, sql)
        args = append(args, specArgs...)
    }

    return strings.Join(conditions, " AND "), args
}

// UserRepository 支持 Specification
type UserRepository interface {
    FindBySpec(ctx context.Context, spec Specification) ([]*entity.User, error)
}

// 使用示例
func FindActiveUserByEmail(repo UserRepository, email string) (*entity.User, error) {
    spec := And(
        &ActiveUserSpec{},
        NewEmailSpec(email),
    )

    users, err := repo.FindBySpec(context.Background(), spec)
    if err != nil {
        return nil, err
    }

    if len(users) == 0 {
        return nil, ErrUserNotFound
    }

    return users[0], nil
}
```

## 事务管理

### Unit of Work 模式

```go
package repository

import (
    "context"
    "database/sql"
)

// UnitOfWork 工作单元
type UnitOfWork struct {
    db *sql.DB
    tx *sql.Tx
}

func NewUnitOfWork(db *sql.DB) *UnitOfWork {
    return &UnitOfWork{db: db}
}

// Begin 开始事务
func (uow *UnitOfWork) Begin(ctx context.Context) error {
    tx, err := uow.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    uow.tx = tx
    return nil
}

// Commit 提交事务
func (uow *UnitOfWork) Commit() error {
    if uow.tx == nil {
        return errors.New("no active transaction")
    }
    return uow.tx.Commit()
}

// Rollback 回滚事务
func (uow *UnitOfWork) Rollback() error {
    if uow.tx == nil {
        return nil
    }
    return uow.tx.Rollback()
}

// GetTx 获取事务对象
func (uow *UnitOfWork) GetTx() *sql.Tx {
    return uow.tx
}

// UserRepository 支持事务
type UserRepository interface {
    SaveWithTx(ctx context.Context, tx *sql.Tx, user *entity.User) error
}

// 使用示例
func CreateUserWithOrder(uow *UnitOfWork, userRepo UserRepository, orderRepo OrderRepository) error {
    ctx := context.Background()

    // 开始事务
    if err := uow.Begin(ctx); err != nil {
        return err
    }
    defer uow.Rollback()

    // 创建用户
    user := entity.NewUser(...)
    if err := userRepo.SaveWithTx(ctx, uow.GetTx(), user); err != nil {
        return err
    }

    // 创建订单
    order := entity.NewOrder(user.ID())
    if err := orderRepo.SaveWithTx(ctx, uow.GetTx(), order); err != nil {
        return err
    }

    // 提交事务
    return uow.Commit()
}
```

## 缓存策略

### Cache-Aside 模式

```go
package repository

// FindByID 缓存旁路模式
func (r *CachedUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    cacheKey := fmt.Sprintf("user:%s", id.String())

    // 1. 读缓存
    var user *entity.User
    if err := r.cache.Get(ctx, cacheKey, &user); err == nil {
        return user, nil
    }

    // 2. 缓存未命中，读数据库
    user, err := r.base.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // 3. 写缓存
    _ = r.cache.Set(ctx, cacheKey, user, r.ttl)

    return user, nil
}
```

### 缓存失效策略

```go
package repository

// Save 写穿策略 (Write-Through)
func (r *CachedUserRepository) Save(ctx context.Context, user *entity.User) error {
    // 1. 写数据库
    if err := r.base.Save(ctx, user); err != nil {
        return err
    }

    // 2. 更新缓存
    cacheKey := fmt.Sprintf("user:%s", user.ID().String())
    _ = r.cache.Set(ctx, cacheKey, user, r.ttl)

    return nil
}

// Delete 删除时清除缓存
func (r *CachedUserRepository) Delete(ctx context.Context, id uuid.UUID) error {
    // 1. 删除数据库
    if err := r.base.Delete(ctx, id); err != nil {
        return err
    }

    // 2. 清除缓存
    cacheKey := fmt.Sprintf("user:%s", id.String())
    _ = r.cache.Delete(ctx, cacheKey)

    return nil
}
```

### 防止缓存穿透、击穿、雪崩

```go
package repository

import (
    "sync"
    "time"
)

// CachedUserRepositoryAdvanced 高级缓存仓储
type CachedUserRepositoryAdvanced struct {
    base          UserRepository
    cache         Cache
    ttl           time.Duration
    mu            sync.Mutex
    loadingKeys   map[string]*sync.Mutex // 防止缓存击穿
}

// FindByID 防止缓存问题
func (r *CachedUserRepositoryAdvanced) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    cacheKey := fmt.Sprintf("user:%s", id.String())

    // 1. 读缓存
    var user *entity.User
    if err := r.cache.Get(ctx, cacheKey, &user); err == nil {
        return user, nil
    }

    // 2. 防止缓存击穿 (同一时间只有一个请求查询数据库)
    keyMutex := r.getKeyMutex(cacheKey)
    keyMutex.Lock()
    defer keyMutex.Unlock()

    // 3. 再次尝试读缓存 (可能已被其他 goroutine 填充)
    if err := r.cache.Get(ctx, cacheKey, &user); err == nil {
        return user, nil
    }

    // 4. 从数据库查询
    user, err := r.base.FindByID(ctx, id)
    if err != nil {
        if errors.Is(err, ErrUserNotFound) {
            // 防止缓存穿透: 缓存空值
            _ = r.cache.Set(ctx, cacheKey, nil, 1*time.Minute)
        }
        return nil, err
    }

    // 5. 写缓存 (添加随机过期时间，防止缓存雪崩)
    ttl := r.ttl + time.Duration(rand.Intn(60))*time.Second
    _ = r.cache.Set(ctx, cacheKey, user, ttl)

    return user, nil
}

func (r *CachedUserRepositoryAdvanced) getKeyMutex(key string) *sync.Mutex {
    r.mu.Lock()
    defer r.mu.Unlock()

    if r.loadingKeys[key] == nil {
        r.loadingKeys[key] = &sync.Mutex{}
    }

    return r.loadingKeys[key]
}
```

## 性能优化

### 解决 N+1 查询问题

```go
package repository

// ❌ 错误: N+1 查询
func GetOrdersWithCustomers(orderRepo OrderRepository, userRepo UserRepository) ([]*OrderWithCustomer, error) {
    orders, _ := orderRepo.FindAll(context.Background())

    results := make([]*OrderWithCustomer, len(orders))
    for i, order := range orders {
        // 每个订单都查询一次用户 (N+1 问题)
        customer, _ := userRepo.FindByID(context.Background(), order.CustomerID())
        results[i] = &OrderWithCustomer{
            Order:    order,
            Customer: customer,
        }
    }

    return results, nil
}

// ✅ 正确: 批量查询
func GetOrdersWithCustomersBatch(orderRepo OrderRepository, userRepo UserRepository) ([]*OrderWithCustomer, error) {
    orders, _ := orderRepo.FindAll(context.Background())

    // 1. 收集所有客户 ID
    customerIDs := make([]uuid.UUID, 0, len(orders))
    customerIDSet := make(map[uuid.UUID]bool)
    for _, order := range orders {
        if !customerIDSet[order.CustomerID()] {
            customerIDs = append(customerIDs, order.CustomerID())
            customerIDSet[order.CustomerID()] = true
        }
    }

    // 2. 批量查询客户 (1 次查询)
    customers, _ := userRepo.FindByIDs(context.Background(), customerIDs)

    // 3. 构建客户映射
    customerMap := make(map[uuid.UUID]*entity.User)
    for _, customer := range customers {
        customerMap[customer.ID()] = customer
    }

    // 4. 组装结果
    results := make([]*OrderWithCustomer, len(orders))
    for i, order := range orders {
        results[i] = &OrderWithCustomer{
            Order:    order,
            Customer: customerMap[order.CustomerID()],
        }
    }

    return results, nil
}

// UserRepository 支持批量查询
type UserRepository interface {
    FindByIDs(ctx context.Context, ids []uuid.UUID) ([]*entity.User, error)
}

// 实现批量查询
func (r *UserRepositoryImpl) FindByIDs(ctx context.Context, ids []uuid.UUID) ([]*entity.User, error) {
    if len(ids) == 0 {
        return []*entity.User{}, nil
    }

    // 构建 IN 查询
    placeholders := make([]string, len(ids))
    args := make([]interface{}, len(ids))
    for i, id := range ids {
        placeholders[i] = "?"
        args[i] = id.String()
    }

    query := fmt.Sprintf("SELECT * FROM users WHERE id IN (%s)", strings.Join(placeholders, ","))

    rows, err := r.db.QueryContext(ctx, query, args...)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var users []*entity.User
    for rows.Next() {
        user, err := r.scanUser(rows)
        if err != nil {
            return nil, err
        }
        users = append(users, user)
    }

    return users, nil
}
```

### 预加载策略

```go
package repository

// OrderRepository 支持预加载
type OrderRepository interface {
    // 基础查询
    FindByID(ctx context.Context, id uuid.UUID) (*entity.Order, error)

    // 预加载订单项
    FindByIDWithItems(ctx context.Context, id uuid.UUID) (*entity.Order, error)

    // 预加载客户信息
    FindByIDWithCustomer(ctx context.Context, id uuid.UUID) (*OrderWithCustomer, error)
}

// FindByIDWithItems 一次查询加载订单和订单项
func (r *OrderRepositoryImpl) FindByIDWithItems(ctx context.Context, id uuid.UUID) (*entity.Order, error) {
    // 使用 JOIN 一次性加载
    query := `
        SELECT
            o.id, o.customer_id, o.status, o.total_amount, o.created_at,
            oi.id, oi.product_id, oi.quantity, oi.price
        FROM orders o
        LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.id = ?
    `

    rows, err := r.db.QueryContext(ctx, query, id.String())
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    // 扫描并组装订单和订单项
    return r.scanOrderWithItems(rows)
}
```

## Repository 反模式

### 反模式 1: 过度通用

```go
// ❌ 错误: 过度通用的仓储
type GenericRepository interface {
    Get(id string) (interface{}, error)
    Save(entity interface{}) error
    Delete(id string) error
    Query(sql string, args ...interface{}) ([]interface{}, error)
}

// 问题:
// - 失去类型安全
// - 暴露 SQL 细节
// - 不符合领域语言
```

### 反模式 2: 智能查询

```go
// ❌ 错误: Repository 包含业务逻辑
type UserRepository interface {
    FindByID(id uuid.UUID) (*entity.User, error)

    // 业务逻辑不应在 Repository
    CalculateUserScore(id uuid.UUID) (int, error)
    SendWelcomeEmail(id uuid.UUID) error
}

// ✅ 正确: Repository 只负责持久化
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
    Save(ctx context.Context, user *entity.User) error
}

// 业务逻辑在 Domain Service
type UserService struct {
    userRepo UserRepository
}

func (s *UserService) CalculateUserScore(user *entity.User) int {
    // 业务逻辑
    return score
}
```

### 反模式 3: 跨聚合查询

```go
// ❌ 错误: Repository 返回跨聚合对象
type OrderRepository interface {
    // 混合了 Order 和 User 聚合
    FindOrderWithUser(orderID uuid.UUID) (*OrderUserDTO, error)
}

// ✅ 正确: 分别查询聚合，在应用层组合
type OrderApplicationService struct {
    orderRepo OrderRepository
    userRepo  UserRepository
}

func (s *OrderApplicationService) GetOrderWithCustomer(ctx context.Context, orderID uuid.UUID) (*OrderWithCustomerDTO, error) {
    // 1. 查询订单聚合
    order, err := s.orderRepo.FindByID(ctx, orderID)
    if err != nil {
        return nil, err
    }

    // 2. 查询用户聚合
    customer, err := s.userRepo.FindByID(ctx, order.CustomerID())
    if err != nil {
        return nil, err
    }

    // 3. 在应用层组合
    return &OrderWithCustomerDTO{
        Order:    order,
        Customer: customer,
    }, nil
}
```

## 总结

Repository 的关键实践:
- ✅ 只为聚合根创建 Repository
- ✅ 使用领域语言命名方法
- ✅ 不暴露技术细节 (SQL、NoSQL)
- ✅ 支持 Specification 模式构建动态查询
- ✅ 使用缓存提升性能
- ✅ 解决 N+1 查询问题
- ✅ 事务由 Application Layer 管理
- ✅ Repository 不包含业务逻辑
