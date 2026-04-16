# DDD 核心构建块 — Entity, Value Object, Aggregate

## Entity (实体)

**定义**: 具有唯一标识和生命周期的领域对象，通过 ID 区分。

### 关键模式

- **私有字段 + 公开 Getter**: 保护封装性
- **构造函数验证**: `NewUser(...)` 确保初始有效状态
- **业务方法变更状态**: `user.ChangeName(newName)` 而非直接赋值
- **基于 ID 的相等性**: `u.Equals(other)` 比较 ID

### 富领域模型 vs 贫血模型

```go
// 贫血模型 (Anti-pattern): 业务逻辑在服务层
type User struct { ID uuid.UUID; Name string }

// 富领域模型 (正确): 业务逻辑封装在实体
type User struct {
    id   uuid.UUID
    name string
}

func (u *User) ChangeName(newName string) error {
    if newName == "" { return errors.New("name cannot be empty") }
    u.name = newName
    u.updatedAt = time.Now()
    return nil
}
```

### 高级模式

| 模式 | 说明 |
|------|------|
| 不变式 (Invariants) | 构造函数和方法保护业务规则始终为真 |
| 生命周期/状态机 | `Draft → Submitted → Completed/Cancelled` |
| ID 生成策略 | UUID (推荐客户端生成) 或数据库自增 |
| 事件收集 | `domainEvents []DomainEvent` + `PopDomainEvents()` |

## Value Object (值对象)

**定义**: 无唯一标识，完全由属性值定义的不可变对象。

### 关键模式

- **不可变**: 所有字段私有，只通过构造函数创建
- **构造函数验证**: `NewEmail(raw)` 强制格式校验
- **操作返回新对象**: `money.Add(other)` 返回新 Money
- **基于值的相等性**: `e.Equals(other)` 比较属性值

### 常见值对象

| 值对象 | 验证规则 | 典型操作 |
|--------|----------|----------|
| Email | 格式校验、标准化 | `Value()`, `Domain()` |
| Money | 币种非空、精度控制 | `Add()`, `Subtract()`, `Multiply()` |
| Address | 必填字段校验 | `FullAddress()` |
| DateRange | end >= start | `Duration()`, `Contains()`, `Overlaps()` |

### 高级模式

- **Builder 模式**: 复杂值对象使用 `NewAddressBuilder().Street(...).City(...).Build()`
- **值对象组合**: `ContactInfo { email Email; phone PhoneNumber }`
- **值对象集合**: `Tags` 封装 `[]string`，操作返回新集合

## Aggregate (聚合)

**定义**: 一组相关对象的集合，通过聚合根作为唯一入口，保证一致性边界。

### 核心原则

| 原则 | 说明 |
|------|------|
| 聚合根是唯一入口 | 外部只通过聚合根访问内部对象 |
| 一个事务一个聚合 | 不跨聚合做事务 |
| 聚合间 ID 引用 | 不直接持有其他聚合的引用 |
| 基于不变式设计边界 | 需要同时满足的规则放同一聚合 |

### 聚合大小

```go
// 过大: 包含 Customer, Payment, Shipment 等独立聚合
// 过小: OrderItem 单独做聚合 (应该是 Order 聚合的一部分)
// 合适:
type Order struct {
    id          uuid.UUID
    customerID  uuid.UUID       // 通过 ID 引用其他聚合
    items       []*OrderItem    // 聚合内实体
    totalAmount Money
    status      OrderStatus
}
```

### 聚合间通信

1. **ID 引用**: `order.customerID` 而非 `order.customer *Customer`
2. **领域事件**: `order.Submit()` 记录 `OrderSubmitted` 事件
3. **领域服务**: `OrderPlacementService` 协调 Order + Inventory 聚合

### 测试聚合

```go
func TestOrder_AddItem_ToSubmittedOrder(t *testing.T) {
    order := entity.NewOrder(uuid.New(), address)
    order.AddItem(uuid.New(), "Product A", 1, price)
    order.Submit()
    err := order.AddItem(uuid.New(), "Product B", 1, price)
    assert.Error(t, err) // 不变式: 已提交订单不能添加
}
```
