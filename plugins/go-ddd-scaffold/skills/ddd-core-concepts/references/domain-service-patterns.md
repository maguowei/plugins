# 领域服务最佳实践

## 何时需要领域服务

领域服务 (Domain Service) 用于封装不自然属于任何单一实体或值对象的业务逻辑。

**使用场景**:
- 操作跨越多个实体或聚合
- 业务逻辑不属于任何单一实体
- 需要多个仓储协作
- 复杂的计算或验证规则

**识别标准**:
- 如果业务操作涉及两个或更多聚合，考虑使用领域服务
- 如果实体方法需要注入仓储，应该使用领域服务
- 如果操作是无状态的且不修改自身，适合领域服务

## 领域服务 vs 应用服务

### 清晰的对比

| 维度 | 领域服务 | 应用服务 |
|------|---------|---------|
| 位置 | Domain Layer | Application Layer |
| 状态 | 无状态 | 可有状态 |
| 事务管理 | 不管理 | 管理事务 |
| 业务逻辑 | 包含核心业务逻辑 | 不包含，只编排 |
| 依赖 | 依赖其他领域对象和仓储接口 | 依赖领域服务和仓储实现 |
| DTO | 不使用 | 使用 DTO |
| 返回值 | 领域对象 | DTO |
| 事件发布 | 不发布 | 发布事件 |

### 代码对比

```go
// 领域服务 (Domain Service)
package service

type TransferDomainService struct {
    accountRepo repository.AccountRepository
}

// Transfer 转账业务逻辑 (领域服务)
func (s *TransferDomainService) Transfer(
    ctx context.Context,
    fromAccount *entity.Account,
    toAccount *entity.Account,
    amount valueobject.Money,
) error {
    // 业务规则验证
    if fromAccount.Balance().LessThan(amount) {
        return errors.New("insufficient balance")
    }

    if fromAccount.Status() != valueobject.AccountStatusActive {
        return errors.New("account not active")
    }

    // 执行转账
    if err := fromAccount.Debit(amount); err != nil {
        return err
    }

    if err := toAccount.Credit(amount); err != nil {
        // 回滚
        fromAccount.Credit(amount)
        return err
    }

    return nil
}

// 应用服务 (Application Service)
package service

type TransferApplicationService struct {
    transferService *domain.TransferDomainService
    accountRepo     repository.AccountRepository
    eventPublisher  event.EventPublisher
}

// ExecuteTransfer 执行转账用例 (应用服务)
func (s *TransferApplicationService) ExecuteTransfer(
    ctx context.Context,
    req dto.TransferRequest,
) (*dto.TransferResponse, error) {
    // 1. 参数验证
    if err := req.Validate(); err != nil {
        return nil, err
    }

    // 2. 获取聚合
    fromAccount, err := s.accountRepo.FindByID(ctx, req.FromAccountID)
    if err != nil {
        return nil, err
    }

    toAccount, err := s.accountRepo.FindByID(ctx, req.ToAccountID)
    if err != nil {
        return nil, err
    }

    // 3. 调用领域服务 (业务逻辑)
    amount := valueobject.NewMoney(req.Amount, req.Currency)
    if err := s.transferService.Transfer(ctx, fromAccount, toAccount, amount); err != nil {
        return nil, err
    }

    // 4. 保存聚合
    if err := s.accountRepo.Save(ctx, fromAccount); err != nil {
        return nil, err
    }
    if err := s.accountRepo.Save(ctx, toAccount); err != nil {
        return nil, err
    }

    // 5. 发布事件
    events := append(fromAccount.DomainEvents(), toAccount.DomainEvents()...)
    s.eventPublisher.PublishBatch(ctx, events)

    // 6. 返回 DTO
    return &dto.TransferResponse{
        TransactionID: uuid.New().String(),
        Status:        "completed",
    }, nil
}
```

## 领域服务的特征

### 无状态设计

```go
package service

// ✅ 正确: 无状态领域服务
type PricingDomainService struct {
    // 只依赖仓储接口，不保存状态
    productRepo repository.ProductRepository
}

func NewPricingDomainService(productRepo repository.ProductRepository) *PricingDomainService {
    return &PricingDomainService{
        productRepo: productRepo,
    }
}

// CalculateOrderPrice 计算订单价格 (无状态)
func (s *PricingDomainService) CalculateOrderPrice(
    ctx context.Context,
    order *entity.Order,
) (valueobject.Money, error) {
    var total valueobject.Money

    for _, item := range order.Items() {
        // 获取产品信息
        product, err := s.productRepo.FindByID(ctx, item.ProductID())
        if err != nil {
            return valueobject.Money{}, err
        }

        // 计算单项价格
        itemPrice := product.Price().Multiply(item.Quantity())
        total = total.Add(itemPrice)
    }

    // 应用折扣规则 (业务逻辑)
    if order.ItemCount() > 10 {
        discount := total.Multiply(0.1) // 10% 折扣
        total = total.Subtract(discount)
    }

    return total, nil
}

// ❌ 错误: 有状态的服务 (这应该是应用服务)
type BadPricingService struct {
    lastCalculatedPrice valueobject.Money // 保存状态
    calculationCount    int               // 保存状态
}
```

### 操作领域对象

```go
package service

// UserAuthDomainService 用户认证领域服务
type UserAuthDomainService struct {
    userRepo repository.UserRepository
}

// AuthenticateUser 认证用户 (操作领域对象)
func (s *UserAuthDomainService) AuthenticateUser(
    ctx context.Context,
    email valueobject.Email,
    password string,
) (*entity.User, error) {
    // 1. 查找用户
    user, err := s.userRepo.FindByEmail(ctx, email)
    if err != nil {
        return nil, errors.New("invalid credentials")
    }

    // 2. 验证密码 (调用实体方法)
    if !user.VerifyPassword(password) {
        return nil, errors.New("invalid credentials")
    }

    // 3. 检查账户状态 (业务规则)
    if user.Status() == valueobject.UserStatusSuspended {
        return nil, errors.New("account suspended")
    }

    if user.Status() == valueobject.UserStatusLocked {
        return nil, errors.New("account locked")
    }

    // 4. 更新最后登录时间 (调用实体方法)
    user.UpdateLastLoginTime(time.Now())

    return user, nil
}
```

### 协调多个仓储

```go
package service

// InventoryDomainService 库存领域服务
type InventoryDomainService struct {
    productRepo   repository.ProductRepository
    inventoryRepo repository.InventoryRepository
    warehouseRepo repository.WarehouseRepository
}

// ReserveInventory 预留库存 (协调多个仓储)
func (s *InventoryDomainService) ReserveInventory(
    ctx context.Context,
    productID uuid.UUID,
    quantity int,
) (*entity.InventoryReservation, error) {
    // 1. 获取产品
    product, err := s.productRepo.FindByID(ctx, productID)
    if err != nil {
        return nil, err
    }

    // 2. 查询库存
    inventories, err := s.inventoryRepo.FindByProductID(ctx, productID)
    if err != nil {
        return nil, err
    }

    // 3. 计算总可用库存
    totalAvailable := 0
    for _, inv := range inventories {
        totalAvailable += inv.AvailableQuantity()
    }

    if totalAvailable < quantity {
        return nil, errors.New("insufficient inventory")
    }

    // 4. 从多个仓库预留
    remaining := quantity
    reservations := make([]*entity.InventoryReservation, 0)

    for _, inv := range inventories {
        if remaining <= 0 {
            break
        }

        reserveQty := min(inv.AvailableQuantity(), remaining)
        if err := inv.Reserve(reserveQty); err != nil {
            return nil, err
        }

        reservation := entity.NewInventoryReservation(
            inv.ID(),
            productID,
            reserveQty,
        )
        reservations = append(reservations, reservation)

        remaining -= reserveQty
    }

    // 返回预留记录
    return entity.CombineReservations(reservations), nil
}
```

## 典型领域服务案例

### 案例 1: 转账服务 (跨账户)

```go
package service

// TransferDomainService 转账领域服务
type TransferDomainService struct {
    accountRepo repository.AccountRepository
}

// Transfer 转账 (涉及两个聚合)
func (s *TransferDomainService) Transfer(
    ctx context.Context,
    fromAccountID uuid.UUID,
    toAccountID uuid.UUID,
    amount valueobject.Money,
) error {
    // 1. 获取两个账户
    fromAccount, err := s.accountRepo.FindByID(ctx, fromAccountID)
    if err != nil {
        return err
    }

    toAccount, err := s.accountRepo.FindByID(ctx, toAccountID)
    if err != nil {
        return err
    }

    // 2. 业务规则: 不能给自己转账
    if fromAccountID == toAccountID {
        return errors.New("cannot transfer to same account")
    }

    // 3. 业务规则: 检查余额
    if fromAccount.Balance().LessThan(amount) {
        return errors.New("insufficient balance")
    }

    // 4. 业务规则: 检查账户状态
    if fromAccount.IsFrozen() || toAccount.IsFrozen() {
        return errors.New("account frozen")
    }

    // 5. 执行转账 (调用实体方法)
    if err := fromAccount.Debit(amount); err != nil {
        return err
    }

    if err := toAccount.Credit(amount); err != nil {
        // 补偿: 回滚扣款
        fromAccount.Credit(amount)
        return err
    }

    // 6. 保存由应用服务完成

    return nil
}
```

### 案例 2: 库存预留服务 (跨产品)

```go
package service

// InventoryReservationService 库存预留服务
type InventoryReservationService struct {
    inventoryRepo repository.InventoryRepository
}

// ReserveForOrder 为订单预留库存
func (s *InventoryReservationService) ReserveForOrder(
    ctx context.Context,
    orderItems []*entity.OrderItem,
) ([]*entity.InventoryReservation, error) {
    reservations := make([]*entity.InventoryReservation, 0, len(orderItems))

    // 遍历订单项
    for _, item := range orderItems {
        // 查询库存
        inventory, err := s.inventoryRepo.FindByProductID(ctx, item.ProductID())
        if err != nil {
            // 失败时释放已预留的库存
            s.releaseReservations(ctx, reservations)
            return nil, err
        }

        // 业务规则: 检查库存是否充足
        if inventory.AvailableQuantity() < item.Quantity() {
            s.releaseReservations(ctx, reservations)
            return nil, fmt.Errorf("insufficient inventory for product %s", item.ProductID())
        }

        // 预留库存
        reservation, err := inventory.Reserve(item.Quantity())
        if err != nil {
            s.releaseReservations(ctx, reservations)
            return nil, err
        }

        reservations = append(reservations, reservation)
    }

    return reservations, nil
}

// releaseReservations 释放预留 (补偿操作)
func (s *InventoryReservationService) releaseReservations(
    ctx context.Context,
    reservations []*entity.InventoryReservation,
) {
    for _, reservation := range reservations {
        inventory, _ := s.inventoryRepo.FindByProductID(ctx, reservation.ProductID())
        if inventory != nil {
            inventory.Release(reservation.Quantity())
        }
    }
}
```

### 案例 3: 价格计算服务 (复杂规则)

```go
package service

// PricingDomainService 定价领域服务
type PricingDomainService struct {
    productRepo  repository.ProductRepository
    customerRepo repository.CustomerRepository
}

// CalculatePrice 计算价格 (复杂业务规则)
func (s *PricingDomainService) CalculatePrice(
    ctx context.Context,
    customerID uuid.UUID,
    items []*entity.OrderItem,
) (valueobject.Money, error) {
    // 1. 获取客户
    customer, err := s.customerRepo.FindByID(ctx, customerID)
    if err != nil {
        return valueobject.Money{}, err
    }

    // 2. 计算基础价格
    var basePrice valueobject.Money
    for _, item := range items {
        product, err := s.productRepo.FindByID(ctx, item.ProductID())
        if err != nil {
            return valueobject.Money{}, err
        }

        itemPrice := product.Price().Multiply(item.Quantity())
        basePrice = basePrice.Add(itemPrice)
    }

    // 3. 应用客户等级折扣
    discount := s.calculateCustomerDiscount(customer, basePrice)
    finalPrice := basePrice.Subtract(discount)

    // 4. 应用数量折扣
    quantityDiscount := s.calculateQuantityDiscount(items, finalPrice)
    finalPrice = finalPrice.Subtract(quantityDiscount)

    // 5. 应用促销折扣
    promotionDiscount := s.calculatePromotionDiscount(items, finalPrice)
    finalPrice = finalPrice.Subtract(promotionDiscount)

    // 6. 确保价格不为负
    if finalPrice.Amount() < 0 {
        finalPrice = valueobject.NewMoney(0, finalPrice.Currency())
    }

    return finalPrice, nil
}

// calculateCustomerDiscount 客户等级折扣
func (s *PricingDomainService) calculateCustomerDiscount(
    customer *entity.Customer,
    basePrice valueobject.Money,
) valueobject.Money {
    switch customer.Level() {
    case valueobject.CustomerLevelVIP:
        return basePrice.Multiply(0.15) // 15% 折扣
    case valueobject.CustomerLevelGold:
        return basePrice.Multiply(0.10) // 10% 折扣
    case valueobject.CustomerLevelSilver:
        return basePrice.Multiply(0.05) // 5% 折扣
    default:
        return valueobject.NewMoney(0, basePrice.Currency())
    }
}

// calculateQuantityDiscount 数量折扣
func (s *PricingDomainService) calculateQuantityDiscount(
    items []*entity.OrderItem,
    price valueobject.Money,
) valueobject.Money {
    totalQuantity := 0
    for _, item := range items {
        totalQuantity += item.Quantity()
    }

    if totalQuantity >= 100 {
        return price.Multiply(0.20) // 20% 折扣
    } else if totalQuantity >= 50 {
        return price.Multiply(0.10) // 10% 折扣
    }

    return valueobject.NewMoney(0, price.Currency())
}

// calculatePromotionDiscount 促销折扣
func (s *PricingDomainService) calculatePromotionDiscount(
    items []*entity.OrderItem,
    price valueobject.Money,
) valueobject.Money {
    // 简化示例: 检查是否有促销商品
    for _, item := range items {
        if item.IsPromotional() {
            return price.Multiply(0.05) // 5% 额外折扣
        }
    }

    return valueobject.NewMoney(0, price.Currency())
}
```

### 案例 4: 权限检查服务 (跨用户)

```go
package service

// PermissionDomainService 权限领域服务
type PermissionDomainService struct {
    userRepo repository.UserRepository
    roleRepo repository.RoleRepository
}

// CanAccessResource 检查用户是否有权访问资源
func (s *PermissionDomainService) CanAccessResource(
    ctx context.Context,
    userID uuid.UUID,
    resourceID uuid.UUID,
    operation string,
) (bool, error) {
    // 1. 获取用户
    user, err := s.userRepo.FindByID(ctx, userID)
    if err != nil {
        return false, err
    }

    // 2. 检查用户状态
    if user.Status() != valueobject.UserStatusActive {
        return false, nil
    }

    // 3. 获取用户角色
    roles, err := s.roleRepo.FindByUserID(ctx, userID)
    if err != nil {
        return false, err
    }

    // 4. 检查角色权限
    for _, role := range roles {
        if role.HasPermission(resourceID, operation) {
            return true, nil
        }
    }

    // 5. 检查用户是否是资源所有者
    if user.OwnsResource(resourceID) {
        return true, nil
    }

    return false, nil
}
```

## 避免的陷阱

### 陷阱 1: 将应用逻辑放入领域服务

```go
// ❌ 错误: 领域服务包含应用逻辑
type UserDomainService struct {
    userRepo       repository.UserRepository
    eventPublisher event.EventPublisher  // 不应该在领域服务
}

func (s *UserDomainService) CreateUser(email, name string) (*entity.User, error) {
    user := entity.NewUser(email, name)

    // 错误: 发布事件是应用层的职责
    s.eventPublisher.Publish(UserCreatedEvent{...})

    return user, nil
}

// ✅ 正确: 领域服务只包含业务逻辑
type UserDomainService struct {
    userRepo repository.UserRepository
}

func (s *UserDomainService) ValidateUniqueEmail(ctx context.Context, email string) error {
    exists, err := s.userRepo.ExistsByEmail(ctx, email)
    if err != nil {
        return err
    }

    if exists {
        return errors.New("email already exists")
    }

    return nil
}
```

### 陷阱 2: 领域服务职责过重

```go
// ❌ 错误: 职责过重
type OrderDomainService struct {
    // 包含太多职责
    orderRepo     repository.OrderRepository
    productRepo   repository.ProductRepository
    inventoryRepo repository.InventoryRepository
    paymentRepo   repository.PaymentRepository
    shippingRepo  repository.ShippingRepository
}

// 应该拆分为多个领域服务
// - OrderValidationService
// - OrderPricingService
// - OrderFulfillmentService
```

### 陷阱 3: 忽视不变式检查

```go
// ❌ 错误: 没有检查不变式
func (s *TransferDomainService) Transfer(from, to *entity.Account, amount valueobject.Money) error {
    from.Debit(amount)  // 没有检查余额
    to.Credit(amount)
    return nil
}

// ✅ 正确: 检查不变式
func (s *TransferDomainService) Transfer(from, to *entity.Account, amount valueobject.Money) error {
    // 检查不变式
    if from.Balance().LessThan(amount) {
        return errors.New("insufficient balance")
    }

    if from.IsFrozen() {
        return errors.New("account frozen")
    }

    // 执行操作
    if err := from.Debit(amount); err != nil {
        return err
    }

    if err := to.Credit(amount); err != nil {
        from.Credit(amount) // 回滚
        return err
    }

    return nil
}
```

## 单元测试策略

### 纯业务逻辑测试

```go
package service_test

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

// MockAccountRepository Mock 仓储
type MockAccountRepository struct {
    mock.Mock
}

func (m *MockAccountRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.Account, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*entity.Account), args.Error(1)
}

// TestTransferDomainService_Transfer 测试转账服务
func TestTransferDomainService_Transfer(t *testing.T) {
    // Arrange
    mockRepo := new(MockAccountRepository)
    service := service.NewTransferDomainService(mockRepo)

    fromAccount := entity.NewAccount(uuid.New(), valueobject.NewMoney(1000, "USD"))
    toAccount := entity.NewAccount(uuid.New(), valueobject.NewMoney(500, "USD"))
    amount := valueobject.NewMoney(100, "USD")

    // Act
    err := service.Transfer(context.Background(), fromAccount, toAccount, amount)

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, int64(900), fromAccount.Balance().Amount()) // 1000 - 100
    assert.Equal(t, int64(600), toAccount.Balance().Amount())   // 500 + 100
}

// TestTransferDomainService_Transfer_InsufficientBalance 测试余额不足
func TestTransferDomainService_Transfer_InsufficientBalance(t *testing.T) {
    // Arrange
    mockRepo := new(MockAccountRepository)
    service := service.NewTransferDomainService(mockRepo)

    fromAccount := entity.NewAccount(uuid.New(), valueobject.NewMoney(50, "USD"))
    toAccount := entity.NewAccount(uuid.New(), valueobject.NewMoney(500, "USD"))
    amount := valueobject.NewMoney(100, "USD")

    // Act
    err := service.Transfer(context.Background(), fromAccount, toAccount, amount)

    // Assert
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "insufficient balance")
    assert.Equal(t, int64(50), fromAccount.Balance().Amount())  // 余额未变
    assert.Equal(t, int64(500), toAccount.Balance().Amount())   // 余额未变
}
```

## 总结

领域服务的关键实践:
- ✅ 只在真正需要时使用领域服务
- ✅ 领域服务必须无状态
- ✅ 操作领域对象，不操作 DTO
- ✅ 协调多个聚合或仓储
- ✅ 实现复杂的业务规则
- ✅ 不包含应用逻辑（事务、事件发布等）
- ✅ 使用 Mock 仓储进行单元测试
- ✅ 职责单一，避免过度膨胀
