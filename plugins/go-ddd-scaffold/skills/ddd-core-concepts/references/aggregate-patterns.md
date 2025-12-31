# 聚合设计与实现

## 聚合概念

聚合 (Aggregate) 是 DDD 中的关键模式，它是一组相关对象的集合，作为数据修改的单元。

**核心概念**:
- **聚合根 (Aggregate Root)**: 聚合的入口，对外唯一可访问的实体
- **聚合边界**: 定义了哪些对象属于同一个聚合
- **一致性边界**: 聚合内部保持强一致性
- **事务边界**: 一个事务只能修改一个聚合

**关键原则**:
- 聚合根是唯一的入口点
- 外部只能通过聚合根引用聚合内部对象
- 聚合间通过 ID 引用，不直接持有引用
- 一个事务只修改一个聚合实例

## 设计聚合边界

### 基于不变式分组

不变式 (Invariant) 是必须始终为真的业务规则。将需要同时满足的不变式放在同一个聚合中。

```go
// 订单聚合的不变式:
// 1. 订单总额 = 所有订单项金额之和
// 2. 订单项数量 > 0
// 3. 已提交的订单不能添加订单项

// Order 聚合根
type Order struct {
    id          uuid.UUID
    customerID  uuid.UUID
    items       []*OrderItem     // 聚合内实体
    totalAmount valueobject.Money
    status      OrderStatus
}

// AddItem 添加订单项 (保护不变式)
func (o *Order) AddItem(productID uuid.UUID, quantity int, price valueobject.Money) error {
    // 不变式检查: 只有草稿状态可以添加
    if o.status != OrderStatusDraft {
        return errors.New("cannot add item to non-draft order")
    }

    // 不变式检查: 数量必须 > 0
    if quantity <= 0 {
        return errors.New("quantity must be positive")
    }

    // 添加订单项
    item := &OrderItem{
        id:        uuid.New(),
        productID: productID,
        quantity:  quantity,
        price:     price,
    }
    o.items = append(o.items, item)

    // 重新计算总额 (维护不变式)
    o.recalculateTotal()

    return nil
}

// recalculateTotal 重新计算总额 (私有方法，保护不变式)
func (o *Order) recalculateTotal() {
    var total int64
    for _, item := range o.items {
        total += item.price.Amount() * int64(item.quantity)
    }
    o.totalAmount = valueobject.NewMoney(total, "USD")
}
```

### 基于业务规则分组

```go
// 用户聚合: 包含用户基本信息和地址
// 业务规则: 用户必须有至少一个地址

type User struct {
    id        uuid.UUID
    email     valueobject.Email
    name      string
    addresses []*Address  // 聚合内值对象集合
}

// AddAddress 添加地址 (业务规则)
func (u *User) AddAddress(address *Address) error {
    // 业务规则: 最多5个地址
    if len(u.addresses) >= 5 {
        return errors.New("maximum 5 addresses allowed")
    }

    u.addresses = append(u.addresses, address)
    return nil
}

// RemoveAddress 移除地址 (业务规则)
func (u *User) RemoveAddress(addressID uuid.UUID) error {
    // 业务规则: 至少保留一个地址
    if len(u.addresses) <= 1 {
        return errors.New("must have at least one address")
    }

    // 查找并移除
    for i, addr := range u.addresses {
        if addr.ID() == addressID {
            u.addresses = append(u.addresses[:i], u.addresses[i+1:]...)
            return nil
        }
    }

    return errors.New("address not found")
}
```

### 避免过大聚合

```go
// ❌ 错误: 聚合过大
type Order struct {
    id          uuid.UUID
    customer    *Customer         // 不应该包含整个客户聚合
    items       []*OrderItem
    payments    []*Payment        // 支付应该是独立聚合
    shipments   []*Shipment       // 发货应该是独立聚合
    invoices    []*Invoice        // 发票应该是独立聚合
    reviews     []*Review         // 评价应该是独立聚合
}

// ✅ 正确: 合理的聚合大小
type Order struct {
    id          uuid.UUID
    customerID  uuid.UUID         // 通过 ID 引用
    items       []*OrderItem      // 聚合内实体
    totalAmount valueobject.Money
    status      OrderStatus
}

// 其他概念作为独立聚合:
// - Payment 聚合 (包含订单ID引用)
// - Shipment 聚合 (包含订单ID引用)
// - Invoice 聚合 (包含订单ID引用)
```

### 避免过小聚合

```go
// ❌ 错误: 聚合过小 (OrderItem 不应该是独立聚合)
type OrderItem struct {
    id        uuid.UUID
    orderID   uuid.UUID  // 引用 Order
    productID uuid.UUID
    quantity  int
    price     valueobject.Money
}

// OrderItemRepository 不应该存在
type OrderItemRepository interface {
    FindByID(id uuid.UUID) (*OrderItem, error)
    Save(item *OrderItem) error
}

// ✅ 正确: OrderItem 是 Order 聚合的一部分
type Order struct {
    id    uuid.UUID
    items []*OrderItem  // 聚合内实体，不单独持久化
}

// 通过聚合根访问
func (o *Order) AddItem(...) error { }
func (o *Order) RemoveItem(itemID uuid.UUID) error { }
func (o *Order) Items() []*OrderItem { return o.items }
```

## 聚合内部结构

### 标准结构

```
聚合根 (Aggregate Root)
├── 子实体 (Entities)
├── 值对象 (Value Objects)
└── 领域事件 (Domain Events)
```

### 完整示例: Order 聚合

```go
package entity

import (
    "errors"
    "time"
    "github.com/google/uuid"
)

// Order 订单聚合根
type Order struct {
    // 基本属性
    id          uuid.UUID
    customerID  uuid.UUID

    // 聚合内实体
    items       []*OrderItem

    // 值对象
    totalAmount valueobject.Money
    status      valueobject.OrderStatus
    shippingAddress valueobject.Address

    // 审计字段
    createdAt time.Time
    updatedAt time.Time

    // 领域事件
    domainEvents []event.DomainEvent
}

// OrderItem 聚合内实体 (不是聚合根)
type OrderItem struct {
    id          uuid.UUID
    productID   uuid.UUID
    productName string
    quantity    int
    price       valueobject.Money
}

// NewOrder 创建订单聚合
func NewOrder(customerID uuid.UUID, shippingAddress valueobject.Address) *Order {
    order := &Order{
        id:              uuid.New(),
        customerID:      customerID,
        items:           make([]*OrderItem, 0),
        totalAmount:     valueobject.NewMoney(0, "USD"),
        status:          valueobject.OrderStatusDraft,
        shippingAddress: shippingAddress,
        createdAt:       time.Now(),
        updatedAt:       time.Now(),
    }

    // 记录领域事件
    order.domainEvents = append(order.domainEvents, event.NewOrderCreated(
        order.id,
        customerID,
    ))

    return order
}

// Getter 方法
func (o *Order) ID() uuid.UUID                      { return o.id }
func (o *Order) CustomerID() uuid.UUID              { return o.customerID }
func (o *Order) Items() []*OrderItem                { return o.items }
func (o *Order) TotalAmount() valueobject.Money     { return o.totalAmount }
func (o *Order) Status() valueobject.OrderStatus    { return o.status }
func (o *Order) ShippingAddress() valueobject.Address { return o.shippingAddress }

// AddItem 添加订单项 (聚合根控制)
func (o *Order) AddItem(productID uuid.UUID, productName string, quantity int, price valueobject.Money) error {
    // 不变式: 只有草稿状态可以添加
    if o.status != valueobject.OrderStatusDraft {
        return errors.New("can only add items to draft orders")
    }

    // 不变式: 数量必须 > 0
    if quantity <= 0 {
        return errors.New("quantity must be positive")
    }

    // 创建订单项
    item := &OrderItem{
        id:          uuid.New(),
        productID:   productID,
        productName: productName,
        quantity:    quantity,
        price:       price,
    }

    o.items = append(o.items, item)

    // 重新计算总额 (维护不变式)
    o.recalculateTotal()
    o.updatedAt = time.Now()

    // 记录事件
    o.domainEvents = append(o.domainEvents, event.NewOrderItemAdded(
        o.id,
        item.id,
        productID,
        quantity,
    ))

    return nil
}

// RemoveItem 移除订单项
func (o *Order) RemoveItem(itemID uuid.UUID) error {
    // 不变式: 只有草稿状态可以移除
    if o.status != valueobject.OrderStatusDraft {
        return errors.New("can only remove items from draft orders")
    }

    // 查找并移除
    for i, item := range o.items {
        if item.id == itemID {
            o.items = append(o.items[:i], o.items[i+1:]...)
            o.recalculateTotal()
            o.updatedAt = time.Now()
            return nil
        }
    }

    return errors.New("item not found")
}

// Submit 提交订单 (状态转换)
func (o *Order) Submit() error {
    // 不变式: 只有草稿状态可以提交
    if o.status != valueobject.OrderStatusDraft {
        return errors.New("can only submit draft orders")
    }

    // 不变式: 必须有订单项
    if len(o.items) == 0 {
        return errors.New("cannot submit empty order")
    }

    // 状态转换
    o.status = valueobject.OrderStatusSubmitted
    o.updatedAt = time.Now()

    // 记录事件
    o.domainEvents = append(o.domainEvents, event.NewOrderSubmitted(
        o.id,
        o.totalAmount,
    ))

    return nil
}

// Cancel 取消订单
func (o *Order) Cancel() error {
    // 不变式: 已完成的订单不能取消
    if o.status == valueobject.OrderStatusCompleted {
        return errors.New("cannot cancel completed order")
    }

    o.status = valueobject.OrderStatusCancelled
    o.updatedAt = time.Now()

    // 记录事件
    o.domainEvents = append(o.domainEvents, event.NewOrderCancelled(o.id))

    return nil
}

// recalculateTotal 重新计算总额 (私有方法)
func (o *Order) recalculateTotal() {
    var total int64
    for _, item := range o.items {
        total += item.price.Amount() * int64(item.quantity)
    }
    o.totalAmount = valueobject.NewMoney(total, "USD")
}

// ItemCount 订单项数量
func (o *Order) ItemCount() int {
    return len(o.items)
}

// DomainEvents 获取领域事件
func (o *Order) DomainEvents() []event.DomainEvent {
    return o.domainEvents
}

// ClearDomainEvents 清空领域事件
func (o *Order) ClearDomainEvents() {
    o.domainEvents = nil
}
```

## 聚合内通信

### 直接持有引用

```go
// ✅ 聚合内: 直接持有引用
type Order struct {
    items []*OrderItem  // 直接持有聚合内实体
}

// 通过聚合根方法访问
func (o *Order) GetItem(itemID uuid.UUID) *OrderItem {
    for _, item := range o.items {
        if item.id == itemID {
            return item
        }
    }
    return nil
}

// 聚合根方法修改聚合内实体
func (o *Order) UpdateItemQuantity(itemID uuid.UUID, newQuantity int) error {
    item := o.GetItem(itemID)
    if item == nil {
        return errors.New("item not found")
    }

    // 直接修改
    item.quantity = newQuantity

    // 重新计算总额
    o.recalculateTotal()

    return nil
}
```

## 聚合间通信

### 通过聚合根 ID 引用

```go
// ✅ 正确: 聚合间通过 ID 引用
type Order struct {
    id         uuid.UUID
    customerID uuid.UUID  // 引用 User 聚合根的 ID
    items      []*OrderItem
}

type Payment struct {
    id      uuid.UUID
    orderID uuid.UUID  // 引用 Order 聚合根的 ID
    amount  valueobject.Money
}

// 获取关联对象时通过仓储
func GetOrderWithCustomer(
    orderRepo repository.OrderRepository,
    userRepo repository.UserRepository,
    orderID uuid.UUID,
) (*Order, *User, error) {
    // 1. 查询订单聚合
    order, err := orderRepo.FindByID(context.Background(), orderID)
    if err != nil {
        return nil, nil, err
    }

    // 2. 查询用户聚合
    customer, err := userRepo.FindByID(context.Background(), order.CustomerID())
    if err != nil {
        return nil, nil, err
    }

    return order, customer, nil
}
```

### 通过领域事件通信

```go
// Order 聚合发布事件
func (o *Order) Submit() error {
    o.status = OrderStatusSubmitted

    // 发布事件
    o.domainEvents = append(o.domainEvents, event.NewOrderSubmitted(
        o.id,
        o.customerID,
        o.totalAmount,
    ))

    return nil
}

// Inventory 聚合订阅事件并响应
type InventoryEventHandler struct {
    inventoryService *InventoryService
}

func (h *InventoryEventHandler) Handle(ctx context.Context, evt event.DomainEvent) error {
    switch e := evt.(type) {
    case *event.OrderSubmitted:
        // 响应订单提交事件，预留库存
        return h.inventoryService.ReserveForOrder(ctx, e.OrderID)
    }
    return nil
}
```

### 通过领域服务协调

```go
// 领域服务协调多个聚合
type OrderPlacementService struct {
    orderRepo     repository.OrderRepository
    inventoryRepo repository.InventoryRepository
}

func (s *OrderPlacementService) PlaceOrder(
    ctx context.Context,
    order *entity.Order,
) error {
    // 1. 检查库存 (Inventory 聚合)
    for _, item := range order.Items() {
        inventory, err := s.inventoryRepo.FindByProductID(ctx, item.ProductID())
        if err != nil {
            return err
        }

        if inventory.AvailableQuantity() < item.Quantity() {
            return errors.New("insufficient inventory")
        }
    }

    // 2. 提交订单 (Order 聚合)
    if err := order.Submit(); err != nil {
        return err
    }

    // 3. 预留库存 (Inventory 聚合)
    for _, item := range order.Items() {
        inventory, _ := s.inventoryRepo.FindByProductID(ctx, item.ProductID())
        if err := inventory.Reserve(item.Quantity()); err != nil {
            // 回滚订单
            order.Cancel()
            return err
        }
    }

    return nil
}
```

## 不变式管理

### 聚合根负责保护不变式

```go
// Order 聚合保护不变式
type Order struct {
    items       []*OrderItem
    totalAmount valueobject.Money
}

// AddItem 保护不变式
func (o *Order) AddItem(productID uuid.UUID, quantity int, price valueobject.Money) error {
    // 不变式1: 订单项数量必须 > 0
    if quantity <= 0 {
        return errors.New("quantity must be positive")
    }

    // 不变式2: 只有草稿状态可以添加
    if o.status != OrderStatusDraft {
        return errors.New("can only add to draft order")
    }

    // 添加订单项
    item := &OrderItem{...}
    o.items = append(o.items, item)

    // 不变式3: 总额 = 订单项金额之和
    o.recalculateTotal()

    return nil
}

// recalculateTotal 维护不变式
func (o *Order) recalculateTotal() {
    var total int64
    for _, item := range o.items {
        total += item.price.Amount() * int64(item.quantity)
    }
    o.totalAmount = valueobject.NewMoney(total, "USD")
}
```

## 聚合的生命周期

### 创建阶段

```go
// NewOrder 创建订单聚合
func NewOrder(customerID uuid.UUID) *Order {
    return &Order{
        id:         uuid.New(),
        customerID: customerID,
        items:      make([]*OrderItem, 0),
        status:     OrderStatusDraft,
        createdAt:  time.Now(),
    }
}

// 工厂方法创建复杂聚合
type OrderFactory struct {
    productRepo repository.ProductRepository
}

func (f *OrderFactory) CreateOrderWithItems(
    customerID uuid.UUID,
    itemRequests []OrderItemRequest,
) (*Order, error) {
    order := NewOrder(customerID)

    for _, req := range itemRequests {
        // 验证产品
        product, err := f.productRepo.FindByID(context.Background(), req.ProductID)
        if err != nil {
            return nil, err
        }

        // 添加订单项
        if err := order.AddItem(req.ProductID, product.Name(), req.Quantity, product.Price()); err != nil {
            return nil, err
        }
    }

    return order, nil
}
```

### 使用阶段

```go
// 状态转换
func (o *Order) Submit() error { ... }
func (o *Order) Confirm() error { ... }
func (o *Order) Ship() error { ... }
func (o *Order) Complete() error { ... }
func (o *Order) Cancel() error { ... }

// 修改操作
func (o *Order) AddItem(...) error { ... }
func (o *Order) RemoveItem(...) error { ... }
func (o *Order) UpdateShippingAddress(...) error { ... }
```

### 删除阶段

```go
// 软删除 (推荐)
func (o *Order) MarkAsDeleted() error {
    if o.status == OrderStatusCompleted {
        return errors.New("cannot delete completed order")
    }

    o.status = OrderStatusDeleted
    o.updatedAt = time.Now()

    return nil
}

// 硬删除 (通过仓储)
func (repo *OrderRepository) Delete(ctx context.Context, id uuid.UUID) error {
    // 物理删除数据库记录
    return repo.db.ExecContext(ctx, "DELETE FROM orders WHERE id = ?", id)
}
```

## 聚合设计反模式

### 反模式 1: 过度通用化

```go
// ❌ 错误: 过度通用
type BaseAggregate struct {
    ID        uuid.UUID
    Version   int
    CreatedAt time.Time
}

type Order struct {
    BaseAggregate  // 继承导致耦合
    items []*OrderItem
}

// ✅ 正确: 组合优于继承
type Order struct {
    id        uuid.UUID
    version   int
    createdAt time.Time
    items     []*OrderItem
}
```

### 反模式 2: 忽视边界

```go
// ❌ 错误: 聚合边界模糊
type Order struct {
    customer *Customer  // 不应直接持有另一个聚合
    items    []*OrderItem
}

// ✅ 正确: 通过 ID 引用
type Order struct {
    customerID uuid.UUID  // 只持有 ID
    items      []*OrderItem
}
```

### 反模式 3: 跨聚合引用

```go
// ❌ 错误: 聚合间直接引用
type OrderItem struct {
    product *Product  // 跨聚合引用
}

// ✅ 正确: 通过 ID 和必要数据
type OrderItem struct {
    productID   uuid.UUID  // 只存 ID
    productName string     // 冗余必要数据
    price       valueobject.Money
}
```

## 测试聚合

### 聚合的独立测试

```go
package entity_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestOrder_AddItem(t *testing.T) {
    // Arrange
    order := entity.NewOrder(uuid.New(), address)

    // Act
    err := order.AddItem(uuid.New(), "Product A", 2, valueobject.NewMoney(100, "USD"))

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, 1, order.ItemCount())
    assert.Equal(t, int64(200), order.TotalAmount().Amount()) // 2 * 100
}

func TestOrder_Submit_EmptyOrder(t *testing.T) {
    // Arrange
    order := entity.NewOrder(uuid.New(), address)

    // Act
    err := order.Submit()

    // Assert
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "empty order")
}

func TestOrder_AddItem_ToSubmittedOrder(t *testing.T) {
    // Arrange
    order := entity.NewOrder(uuid.New(), address)
    order.AddItem(uuid.New(), "Product A", 1, valueobject.NewMoney(100, "USD"))
    order.Submit()

    // Act: 尝试向已提交的订单添加商品
    err := order.AddItem(uuid.New(), "Product B", 1, valueobject.NewMoney(50, "USD"))

    // Assert
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "draft")
}
```

## 总结

聚合设计的关键实践:
- ✅ 基于不变式和业务规则设计边界
- ✅ 聚合根是唯一入口点
- ✅ 聚合内直接引用，聚合间通过 ID
- ✅ 一个事务只修改一个聚合
- ✅ 不要过大也不要过小
- ✅ 聚合根保护所有不变式
- ✅ 通过事件实现聚合间通信
- ✅ 使用纯单元测试验证聚合行为
