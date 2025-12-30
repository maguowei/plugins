# Application Layer 完整指南

## Application Layer 的角色

Application Layer (应用层) 位于 Domain Layer 和 Interface Layer 之间，负责协调应用程序的用例执行。它是业务逻辑的编排者，而非实现者。

**核心职责**:
- 用例编排 (协调领域对象完成业务流程)
- 事务管理 (控制事务边界)
- DTO 转换 (领域对象 ↔ 数据传输对象)
- 事件发布 (在适当时机发布领域事件)
- 权限检查 (调用权限服务)

**不应包含**:
- 业务规则 (属于 Domain Layer)
- HTTP 请求处理 (属于 Interface Layer)
- 数据库访问 (属于 Infrastructure Layer)
- 外部服务调用细节 (通过 Domain 接口抽象)

**所有权**: Application Layer 属于开发团队，实现具体的应用用例。

## 组织结构

### 推荐的目录结构

```
internal/app/application/
├── service/                        # 应用服务
│   ├── user_application_service.go
│   ├── user_application_service_test.go
│   ├── order_application_service.go
│   └── order_application_service_test.go
├── dto/                            # 数据传输对象
│   ├── user_dto.go
│   ├── order_dto.go
│   └── mapper/
│       ├── user_mapper.go
│       └── order_mapper.go
└── command/                        # 命令对象 (可选, CQRS模式)
    ├── create_user_command.go
    └── update_user_command.go
```

## Application Service 设计

### 一个用例一个方法

```go
package service

import (
    "context"
    "github.com/google/uuid"

    "myproject/internal/app/application/dto"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/repository"
    "myproject/internal/app/domain/user/valueobject"
)

// UserApplicationService 用户应用服务
type UserApplicationService struct {
    userRepo      repository.UserRepository
    eventPublisher event.EventPublisher
}

func NewUserApplicationService(
    userRepo repository.UserRepository,
    eventPublisher event.EventPublisher,
) *UserApplicationService {
    return &UserApplicationService{
        userRepo:      userRepo,
        eventPublisher: eventPublisher,
    }
}

// CreateUser 创建用户用例
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    // 1. 参数验证
    if err := req.Validate(); err != nil {
        return nil, err
    }

    // 2. 转换为值对象
    email, err := valueobject.NewEmail(req.Email)
    if err != nil {
        return nil, err
    }

    // 3. 创建领域对象
    user, err := entity.NewUser(email, req.Name, req.Password)
    if err != nil {
        return nil, err
    }

    // 4. 持久化
    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 5. 发布事件
    if err := s.eventPublisher.PublishBatch(ctx, user.DomainEvents()); err != nil {
        // 记录日志但不影响主流程
        log.Printf("failed to publish events: %v", err)
    }
    user.ClearDomainEvents()

    // 6. 转换为 DTO 返回
    return dto.NewUserResponse(user), nil
}

// UpdateUser 更新用户用例
func (s *UserApplicationService) UpdateUser(ctx context.Context, id uuid.UUID, req dto.UpdateUserRequest) (*dto.UserResponse, error) {
    // 1. 参数验证
    if err := req.Validate(); err != nil {
        return nil, err
    }

    // 2. 获取聚合
    user, err := s.userRepo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // 3. 调用业务方法
    if req.Name != "" {
        if err := user.ChangeName(req.Name); err != nil {
            return nil, err
        }
    }

    // 4. 保存聚合
    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 5. 发布事件
    if err := s.eventPublisher.PublishBatch(ctx, user.DomainEvents()); err != nil {
        log.Printf("failed to publish events: %v", err)
    }
    user.ClearDomainEvents()

    // 6. 返回 DTO
    return dto.NewUserResponse(user), nil
}

// GetUser 获取用户用例
func (s *UserApplicationService) GetUser(ctx context.Context, id uuid.UUID) (*dto.UserResponse, error) {
    user, err := s.userRepo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    return dto.NewUserResponse(user), nil
}

// DeleteUser 删除用户用例
func (s *UserApplicationService) DeleteUser(ctx context.Context, id uuid.UUID) error {
    // 1. 检查用户是否存在
    user, err := s.userRepo.FindByID(ctx, id)
    if err != nil {
        return err
    }

    // 2. 删除用户
    if err := s.userRepo.Delete(ctx, user.ID()); err != nil {
        return err
    }

    return nil
}
```

### 有限的内聚职责

```go
// ✅ 正确: 用户相关的用例内聚在一个服务中
type UserApplicationService struct {
    userRepo repository.UserRepository
}

func (s *UserApplicationService) CreateUser(...)
func (s *UserApplicationService) UpdateUser(...)
func (s *UserApplicationService) DeleteUser(...)
func (s *UserApplicationService) GetUser(...)
func (s *UserApplicationService) ListUsers(...)

// ❌ 错误: 职责过多，包含了订单管理
type UserApplicationService struct {
    userRepo  repository.UserRepository
    orderRepo repository.OrderRepository
}

func (s *UserApplicationService) CreateUser(...)
func (s *UserApplicationService) CreateOrder(...)  // 应该在 OrderApplicationService
func (s *UserApplicationService) ProcessPayment(...) // 应该在 PaymentApplicationService
```

## DTO 设计

### 应用层 DTO

```go
package dto

import (
    "errors"
    "github.com/google/uuid"
    "myproject/internal/app/domain/user/entity"
)

// CreateUserRequest 创建用户请求 DTO
type CreateUserRequest struct {
    Email    string `json:"email"`
    Name     string `json:"name"`
    Password string `json:"password"`
}

// Validate 验证请求
func (r *CreateUserRequest) Validate() error {
    if r.Email == "" {
        return errors.New("email is required")
    }
    if r.Name == "" {
        return errors.New("name is required")
    }
    if r.Password == "" {
        return errors.New("password is required")
    }
    return nil
}

// UpdateUserRequest 更新用户请求 DTO
type UpdateUserRequest struct {
    Name string `json:"name"`
}

// Validate 验证请求
func (r *UpdateUserRequest) Validate() error {
    if r.Name == "" {
        return errors.New("name is required")
    }
    return nil
}

// UserResponse 用户响应 DTO
type UserResponse struct {
    ID        string `json:"id"`
    Email     string `json:"email"`
    Name      string `json:"name"`
    Status    string `json:"status"`
    CreatedAt string `json:"created_at"`
}

// NewUserResponse 从实体创建响应 DTO
func NewUserResponse(user *entity.User) *UserResponse {
    return &UserResponse{
        ID:        user.ID().String(),
        Email:     user.Email().Value(),
        Name:      user.Name(),
        Status:    user.Status().String(),
        CreatedAt: user.CreatedAt().Format(time.RFC3339),
    }
}

// UserListResponse 用户列表响应 DTO
type UserListResponse struct {
    Users      []*UserResponse `json:"users"`
    Total      int             `json:"total"`
    Page       int             `json:"page"`
    PageSize   int             `json:"page_size"`
}
```

### 嵌套 DTO 设计

```go
package dto

// OrderResponse 订单响应 DTO (包含嵌套)
type OrderResponse struct {
    ID          string              `json:"id"`
    Customer    *CustomerInfo       `json:"customer"`    // 嵌套客户信息
    Items       []*OrderItemInfo    `json:"items"`       // 嵌套订单项
    TotalAmount float64             `json:"total_amount"`
    Status      string              `json:"status"`
    CreatedAt   string              `json:"created_at"`
}

// CustomerInfo 客户信息 (嵌套DTO)
type CustomerInfo struct {
    ID    string `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

// OrderItemInfo 订单项信息 (嵌套DTO)
type OrderItemInfo struct {
    ProductID   string  `json:"product_id"`
    ProductName string  `json:"product_name"`
    Quantity    int     `json:"quantity"`
    Price       float64 `json:"price"`
    Subtotal    float64 `json:"subtotal"`
}

// NewOrderResponse 从实体创建响应
func NewOrderResponse(order *entity.Order, user *entity.User) *OrderResponse {
    return &OrderResponse{
        ID: order.ID().String(),
        Customer: &CustomerInfo{
            ID:    user.ID().String(),
            Name:  user.Name(),
            Email: user.Email().Value(),
        },
        Items:       mapOrderItems(order.Items()),
        TotalAmount: order.TotalAmount(),
        Status:      order.Status().String(),
        CreatedAt:   order.CreatedAt().Format(time.RFC3339),
    }
}

func mapOrderItems(items []*entity.OrderItem) []*OrderItemInfo {
    result := make([]*OrderItemInfo, len(items))
    for i, item := range items {
        result[i] = &OrderItemInfo{
            ProductID:   item.ProductID().String(),
            ProductName: item.ProductName(),
            Quantity:    item.Quantity(),
            Price:       item.Price(),
            Subtotal:    item.Subtotal(),
        }
    }
    return result
}
```

## Mapper 实现

### 双向映射

```go
package mapper

import (
    "myproject/internal/app/application/dto"
    "myproject/internal/app/domain/user/entity"
)

// UserMapper 用户映射器
type UserMapper struct{}

// ToDTO 实体 -> DTO
func (m *UserMapper) ToDTO(user *entity.User) *dto.UserResponse {
    return &dto.UserResponse{
        ID:        user.ID().String(),
        Email:     user.Email().Value(),
        Name:      user.Name(),
        Status:    user.Status().String(),
        CreatedAt: user.CreatedAt().Format(time.RFC3339),
    }
}

// ToDTOList 实体列表 -> DTO列表
func (m *UserMapper) ToDTOList(users []*entity.User) []*dto.UserResponse {
    result := make([]*dto.UserResponse, len(users))
    for i, user := range users {
        result[i] = m.ToDTO(user)
    }
    return result
}

// ToEntity DTO -> 实体 (用于创建)
func (m *UserMapper) ToEntity(req dto.CreateUserRequest) (*entity.User, error) {
    email, err := valueobject.NewEmail(req.Email)
    if err != nil {
        return nil, err
    }

    return entity.NewUser(email, req.Name, req.Password)
}
```

### 条件映射

```go
package mapper

// OrderMapper 订单映射器
type OrderMapper struct {
    includeCustomer bool
    includeItems    bool
}

// NewOrderMapper 创建映射器
func NewOrderMapper(includeCustomer, includeItems bool) *OrderMapper {
    return &OrderMapper{
        includeCustomer: includeCustomer,
        includeItems:    includeItems,
    }
}

// ToDTO 条件映射
func (m *OrderMapper) ToDTO(order *entity.Order, user *entity.User) *dto.OrderResponse {
    response := &dto.OrderResponse{
        ID:          order.ID().String(),
        TotalAmount: order.TotalAmount(),
        Status:      order.Status().String(),
        CreatedAt:   order.CreatedAt().Format(time.RFC3339),
    }

    // 条件包含客户信息
    if m.includeCustomer && user != nil {
        response.Customer = &dto.CustomerInfo{
            ID:    user.ID().String(),
            Name:  user.Name(),
            Email: user.Email().Value(),
        }
    }

    // 条件包含订单项
    if m.includeItems {
        response.Items = m.mapOrderItems(order.Items())
    }

    return response
}
```

## 事务管理

### Unit of Work 模式

```go
package service

import (
    "context"
    "database/sql"
)

// UnitOfWork 工作单元接口
type UnitOfWork interface {
    Begin(ctx context.Context) (*sql.Tx, error)
    Commit(tx *sql.Tx) error
    Rollback(tx *sql.Tx) error
}

// TransactionalUserApplicationService 支持事务的应用服务
type TransactionalUserApplicationService struct {
    userRepo repository.UserRepository
    uow      UnitOfWork
}

// CreateUserTransactional 在事务中创建用户
func (s *TransactionalUserApplicationService) CreateUserTransactional(
    ctx context.Context,
    req dto.CreateUserRequest,
) (*dto.UserResponse, error) {
    // 1. 开启事务
    tx, err := s.uow.Begin(ctx)
    if err != nil {
        return nil, err
    }
    defer s.uow.Rollback(tx) // 确保异常时回滚

    // 2. 创建实体
    email, err := valueobject.NewEmail(req.Email)
    if err != nil {
        return nil, err
    }

    user, err := entity.NewUser(email, req.Name, req.Password)
    if err != nil {
        return nil, err
    }

    // 3. 在事务中保存
    if err := s.userRepo.SaveWithTx(ctx, tx, user); err != nil {
        return nil, err
    }

    // 4. 提交事务
    if err := s.uow.Commit(tx); err != nil {
        return nil, err
    }

    // 5. 返回结果
    return dto.NewUserResponse(user), nil
}
```

### 事务装饰器模式

```go
package service

import (
    "context"
    "database/sql"
)

// WithTransaction 事务装饰器
func (s *UserApplicationService) WithTransaction(
    ctx context.Context,
    fn func(ctx context.Context, tx *sql.Tx) error,
) error {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    if err := fn(ctx, tx); err != nil {
        return err
    }

    return tx.Commit()
}

// CreateUser 使用事务装饰器
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    var user *entity.User

    err := s.WithTransaction(ctx, func(ctx context.Context, tx *sql.Tx) error {
        // 创建实体
        email, err := valueobject.NewEmail(req.Email)
        if err != nil {
            return err
        }

        user, err = entity.NewUser(email, req.Name, req.Password)
        if err != nil {
            return err
        }

        // 保存
        return s.userRepo.SaveWithTx(ctx, tx, user)
    })

    if err != nil {
        return nil, err
    }

    return dto.NewUserResponse(user), nil
}
```

## 事件发布

### 在事务内发布

```go
package service

// CreateUserWithEventInTransaction 在事务内收集事件，事务外发布
func (s *UserApplicationService) CreateUserWithEventInTransaction(
    ctx context.Context,
    req dto.CreateUserRequest,
) (*dto.UserResponse, error) {
    var user *entity.User
    var events []event.DomainEvent

    // 事务块
    err := s.WithTransaction(ctx, func(ctx context.Context, tx *sql.Tx) error {
        email, err := valueobject.NewEmail(req.Email)
        if err != nil {
            return err
        }

        user, err = entity.NewUser(email, req.Name, req.Password)
        if err != nil {
            return err
        }

        // 保存到数据库
        if err := s.userRepo.SaveWithTx(ctx, tx, user); err != nil {
            return err
        }

        // 收集事件 (但不发布)
        events = user.DomainEvents()
        user.ClearDomainEvents()

        return nil
    })

    if err != nil {
        return nil, err
    }

    // 事务提交成功后发布事件
    if err := s.eventPublisher.PublishBatch(ctx, events); err != nil {
        // 记录日志，但不影响主流程
        log.Printf("failed to publish events: %v", err)
    }

    return dto.NewUserResponse(user), nil
}
```

### 异步发布模式

```go
package service

// CreateUserWithAsyncEvents 异步发布事件
func (s *UserApplicationService) CreateUserWithAsyncEvents(
    ctx context.Context,
    req dto.CreateUserRequest,
) (*dto.UserResponse, error) {
    email, err := valueobject.NewEmail(req.Email)
    if err != nil {
        return nil, err
    }

    user, err := entity.NewUser(email, req.Name, req.Password)
    if err != nil {
        return nil, err
    }

    // 保存
    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 异步发布事件 (不阻塞主流程)
    events := user.DomainEvents()
    user.ClearDomainEvents()

    go func() {
        if err := s.eventPublisher.PublishBatch(context.Background(), events); err != nil {
            log.Printf("async event publishing failed: %v", err)
        }
    }()

    return dto.NewUserResponse(user), nil
}
```

## Application Service 的典型流程

### 完整的 CRUD 示例

```go
package service

import (
    "context"
    "errors"
    "github.com/google/uuid"
)

// OrderApplicationService 订单应用服务
type OrderApplicationService struct {
    orderRepo      repository.OrderRepository
    userRepo       repository.UserRepository
    eventPublisher event.EventPublisher
}

// CreateOrder 创建订单 (典型流程)
func (s *OrderApplicationService) CreateOrder(
    ctx context.Context,
    req dto.CreateOrderRequest,
) (*dto.OrderResponse, error) {
    // 步骤1: 参数验证
    if err := req.Validate(); err != nil {
        return nil, err
    }

    // 步骤2: 获取关联聚合
    customer, err := s.userRepo.FindByID(ctx, req.CustomerID)
    if err != nil {
        return nil, errors.New("customer not found")
    }

    // 步骤3: 创建聚合根
    order := entity.NewOrder(customer.ID())

    // 步骤4: 调用业务方法
    for _, item := range req.Items {
        if err := order.AddItem(item.ProductID, item.Quantity, item.Price); err != nil {
            return nil, err
        }
    }

    // 步骤5: 保存聚合
    if err := s.orderRepo.Save(ctx, order); err != nil {
        return nil, err
    }

    // 步骤6: 发布事件
    if err := s.eventPublisher.PublishBatch(ctx, order.DomainEvents()); err != nil {
        log.Printf("failed to publish events: %v", err)
    }
    order.ClearDomainEvents()

    // 步骤7: 返回 DTO
    return dto.NewOrderResponse(order, customer), nil
}

// SubmitOrder 提交订单 (状态转换流程)
func (s *OrderApplicationService) SubmitOrder(
    ctx context.Context,
    orderID uuid.UUID,
) (*dto.OrderResponse, error) {
    // 1. 获取聚合
    order, err := s.orderRepo.FindByID(ctx, orderID)
    if err != nil {
        return nil, err
    }

    // 2. 调用业务方法 (状态转换)
    if err := order.Submit(); err != nil {
        return nil, err
    }

    // 3. 保存聚合
    if err := s.orderRepo.Save(ctx, order); err != nil {
        return nil, err
    }

    // 4. 发布事件
    if err := s.eventPublisher.PublishBatch(ctx, order.DomainEvents()); err != nil {
        log.Printf("failed to publish events: %v", err)
    }
    order.ClearDomainEvents()

    // 5. 获取客户信息
    customer, err := s.userRepo.FindByID(ctx, order.CustomerID())
    if err != nil {
        customer = nil // 忽略错误
    }

    // 6. 返回 DTO
    return dto.NewOrderResponse(order, customer), nil
}
```

## 错误处理策略

### 业务异常处理

```go
package service

import (
    "errors"
    "fmt"
)

// 应用层错误定义
var (
    ErrValidationFailed   = errors.New("validation failed")
    ErrUserNotFound       = errors.New("user not found")
    ErrOrderNotFound      = errors.New("order not found")
    ErrUnauthorized       = errors.New("unauthorized")
    ErrConcurrencyConflict = errors.New("concurrency conflict")
)

// CreateUser 错误处理
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    // 参数验证错误
    if err := req.Validate(); err != nil {
        return nil, fmt.Errorf("%w: %v", ErrValidationFailed, err)
    }

    // 领域逻辑错误
    email, err := valueobject.NewEmail(req.Email)
    if err != nil {
        return nil, fmt.Errorf("%w: %v", ErrValidationFailed, err)
    }

    user, err := entity.NewUser(email, req.Name, req.Password)
    if err != nil {
        return nil, fmt.Errorf("%w: %v", ErrValidationFailed, err)
    }

    // 持久化错误
    if err := s.userRepo.Save(ctx, user); err != nil {
        // 检查是否是唯一性冲突
        if isUniqueViolation(err) {
            return nil, errors.New("email already exists")
        }
        return nil, fmt.Errorf("failed to save user: %w", err)
    }

    return dto.NewUserResponse(user), nil
}
```

### 错误转换

```go
package service

// 将基础设施错误转换为应用层错误
func (s *UserApplicationService) GetUser(ctx context.Context, id uuid.UUID) (*dto.UserResponse, error) {
    user, err := s.userRepo.FindByID(ctx, id)
    if err != nil {
        // 将仓储错误转换为应用层错误
        if errors.Is(err, repository.ErrNotFound) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("failed to get user: %w", err)
    }

    return dto.NewUserResponse(user), nil
}
```

## 性能优化

### 批量操作

```go
package service

// BatchCreateUsers 批量创建用户
func (s *UserApplicationService) BatchCreateUsers(
    ctx context.Context,
    requests []dto.CreateUserRequest,
) ([]*dto.UserResponse, error) {
    users := make([]*entity.User, 0, len(requests))

    // 1. 创建所有实体
    for _, req := range requests {
        email, err := valueobject.NewEmail(req.Email)
        if err != nil {
            return nil, err
        }

        user, err := entity.NewUser(email, req.Name, req.Password)
        if err != nil {
            return nil, err
        }

        users = append(users, user)
    }

    // 2. 批量保存 (一次数据库操作)
    if err := s.userRepo.SaveBatch(ctx, users); err != nil {
        return nil, err
    }

    // 3. 批量发布事件
    var events []event.DomainEvent
    for _, user := range users {
        events = append(events, user.DomainEvents()...)
        user.ClearDomainEvents()
    }
    if err := s.eventPublisher.PublishBatch(ctx, events); err != nil {
        log.Printf("failed to publish events: %v", err)
    }

    // 4. 转换为 DTO
    mapper := &mapper.UserMapper{}
    return mapper.ToDTOList(users), nil
}
```

### 查询优化

```go
package service

// ListOrdersWithCustomers 优化的列表查询
func (s *OrderApplicationService) ListOrdersWithCustomers(
    ctx context.Context,
    page, pageSize int,
) (*dto.OrderListResponse, error) {
    // 1. 查询订单列表
    orders, total, err := s.orderRepo.FindWithPagination(ctx, page, pageSize)
    if err != nil {
        return nil, err
    }

    // 2. 收集所有客户ID (避免 N+1 查询)
    customerIDs := make([]uuid.UUID, 0, len(orders))
    customerIDSet := make(map[uuid.UUID]bool)
    for _, order := range orders {
        if !customerIDSet[order.CustomerID()] {
            customerIDs = append(customerIDs, order.CustomerID())
            customerIDSet[order.CustomerID()] = true
        }
    }

    // 3. 批量查询客户 (1次查询)
    customers, err := s.userRepo.FindByIDs(ctx, customerIDs)
    if err != nil {
        return nil, err
    }

    // 4. 构建客户映射
    customerMap := make(map[uuid.UUID]*entity.User)
    for _, customer := range customers {
        customerMap[customer.ID()] = customer
    }

    // 5. 组装响应
    orderResponses := make([]*dto.OrderResponse, len(orders))
    for i, order := range orders {
        customer := customerMap[order.CustomerID()]
        orderResponses[i] = dto.NewOrderResponse(order, customer)
    }

    return &dto.OrderListResponse{
        Orders:   orderResponses,
        Total:    total,
        Page:     page,
        PageSize: pageSize,
    }, nil
}
```

## Application Layer 测试

### Mock Repository

```go
package service_test

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

// MockUserRepository Mock 仓储
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*entity.User), args.Error(1)
}

func (m *MockUserRepository) Save(ctx context.Context, user *entity.User) error {
    args := m.Called(ctx, user)
    return args.Error(0)
}

// 测试创建用户
func TestUserApplicationService_CreateUser(t *testing.T) {
    // Arrange
    mockRepo := new(MockUserRepository)
    mockPublisher := new(MockEventPublisher)
    service := NewUserApplicationService(mockRepo, mockPublisher)

    req := dto.CreateUserRequest{
        Email:    "test@example.com",
        Name:     "Test User",
        Password: "password123",
    }

    // 设置 Mock 期望
    mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entity.User")).Return(nil)
    mockPublisher.On("PublishBatch", mock.Anything, mock.Anything).Return(nil)

    // Act
    response, err := service.CreateUser(context.Background(), req)

    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, response)
    assert.Equal(t, "test@example.com", response.Email)
    assert.Equal(t, "Test User", response.Name)

    mockRepo.AssertExpectations(t)
    mockPublisher.AssertExpectations(t)
}
```

## 总结

Application Layer 的关键实践:
- ✅ 一个用例一个方法
- ✅ 协调领域对象而非实现业务逻辑
- ✅ 管理事务边界
- ✅ DTO 转换保护领域模型
- ✅ 事务提交后发布事件
- ✅ 使用 Mock 测试，不依赖数据库
