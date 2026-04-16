# Repository 模式

## 核心概念

Repository 提供集合式接口访问聚合根，隔离领域层与数据访问细节。

| 维度 | Repository | DAO |
|------|-----------|-----|
| 层次 | Domain Layer 定义接口 | 数据访问层 |
| 命名 | 领域语言 (FindActiveUsers) | 技术术语 (SelectByStatus) |
| 返回类型 | 领域对象 | 数据库记录 |

## 接口设计原则

- **只为聚合根创建**: `OrderRepository` 存在，`OrderItemRepository` 不应存在
- **使用领域语言**: `FindActiveUsers` 而非 `SelectByStatus`
- **不暴露技术细节**: 返回领域对象，不返回 ORM 对象

```go
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
    FindByEmail(ctx context.Context, email string) (*entity.User, error)
    Save(ctx context.Context, user *entity.User) error
    Delete(ctx context.Context, id uuid.UUID) error
    ExistsByEmail(ctx context.Context, email string) (bool, error)
}
```

## 实现策略

| 策略 | 说明 |
|------|------|
| 单一存储 | MySQL/Postgres 直接实现 |
| 读写分离 | readDB (从库) + writeDB (主库) |
| 缓存分层 | `CachedUserRepository` 装饰器先查缓存再查 DB |
| Query Object | `NewUserQuery().WithEmail(e).WithStatus(s).WithPagination(...)` |
| Specification | `And(&ActiveUserSpec{}, NewEmailSpec(email))` 组合查询条件 |

## 事务管理

Unit of Work 模式: Application Service 控制事务边界。

```go
func CreateUserWithOrder(uow *UnitOfWork, userRepo, orderRepo) error {
    uow.Begin(ctx)
    defer uow.Rollback()
    userRepo.SaveWithTx(ctx, uow.GetTx(), user)
    orderRepo.SaveWithTx(ctx, uow.GetTx(), order)
    return uow.Commit()
}
```

## 性能优化

### N+1 问题

```go
// 错误: 每个订单查一次用户
// 正确: 收集所有 customerID → 批量 FindByIDs → 构建 map
```

### 预加载

```go
type OrderRepository interface {
    FindByIDWithItems(ctx context.Context, id uuid.UUID) (*entity.Order, error)
}
```

## 反模式

| 反模式 | 问题 |
|--------|------|
| 过度通用 `GenericRepository` | 失去类型安全，不符合领域语言 |
| Repository 包含业务逻辑 | `CalculateUserScore()` 应在 Domain Service |
| 跨聚合查询 | `FindOrderWithUser()` 应在应用层组合 |
