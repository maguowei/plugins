# Clean Architecture 完整指南

## Clean Architecture 概述

Clean Architecture (整洁架构) 是 Robert C. Martin (Uncle Bob) 提出的软件架构模式,强调关注点分离和依赖倒置。

**核心理念**:
- **独立于框架**: 业务逻辑不依赖特定框架
- **可测试性**: 业务逻辑可独立测试
- **独立于 UI**: UI 可以轻易更换
- **独立于数据库**: 业务逻辑不依赖数据库实现
- **独立于外部系统**: 业务逻辑与外部系统解耦

**架构特征**:
```
外层 → 内层: 依赖方向单向
内层: 业务规则 (稳定)
外层: 实现细节 (易变)
```

## 四层架构

### 层次结构

```
┌─────────────────────────────────────┐
│     Interface Layer (接口层)         │  ← 外部交互
├─────────────────────────────────────┤
│  Infrastructure Layer (基础设施层)   │  ← 技术实现
├─────────────────────────────────────┤
│   Application Layer (应用层)         │  ← 用例编排
├─────────────────────────────────────┤
│     Domain Layer (领域层)            │  ← 业务核心
└─────────────────────────────────────┘
```

### Domain Layer (领域层)

**职责**:
- 核心业务逻辑
- 领域模型 (实体、值对象、聚合)
- 领域服务
- 领域事件
- 仓储接口 (不实现)

**特点**:
- 不依赖任何外层
- 不依赖框架和库
- 纯粹的业务逻辑

**目录结构**:
```
internal/app/domain/
├── user/
│   ├── entity/
│   │   └── user.go
│   ├── valueobject/
│   │   ├── email.go
│   │   └── user_status.go
│   ├── event/
│   │   └── user_events.go
│   ├── repository/
│   │   └── user_repository.go      # 接口
│   └── service/
│       └── user_domain_service.go
└── order/
    └── ...
```

**示例代码**:
```go
// internal/app/domain/user/entity/user.go
package entity

import (
    "errors"
    "time"
    "github.com/google/uuid"
)

// User 用户聚合根
type User struct {
    id           uuid.UUID
    email        valueobject.Email
    name         string
    passwordHash string
    status       valueobject.UserStatus
    createdAt    time.Time
    updatedAt    time.Time

    // 领域事件
    domainEvents []event.DomainEvent
}

// NewUser 创建用户
func NewUser(email, name, password string) (*User, error) {
    // 验证
    emailVO, err := valueobject.NewEmail(email)
    if err != nil {
        return nil, err
    }

    if name == "" {
        return nil, errors.New("name cannot be empty")
    }

    // 创建用户
    user := &User{
        id:           uuid.New(),
        email:        emailVO,
        name:         name,
        passwordHash: hashPassword(password),
        status:       valueobject.UserStatusActive,
        createdAt:    time.Now(),
        updatedAt:    time.Now(),
    }

    // 记录领域事件
    user.domainEvents = append(user.domainEvents, event.UserCreated{
        UserID: user.id,
        Email:  email,
    })

    return user, nil
}

// ChangeName 修改名称 (业务方法)
func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }

    oldName := u.name
    u.name = newName
    u.updatedAt = time.Now()

    // 记录领域事件
    u.domainEvents = append(u.domainEvents, event.UserNameChanged{
        UserID:  u.id,
        OldName: oldName,
        NewName: newName,
    })

    return nil
}

// Getter 方法
func (u *User) ID() uuid.UUID              { return u.id }
func (u *User) Email() valueobject.Email   { return u.email }
func (u *User) Name() string               { return u.name }
func (u *User) Status() valueobject.UserStatus { return u.status }
```

### Application Layer (应用层)

**职责**:
- 用例编排
- 事务管理
- 领域事件发布
- 定义应用层 DTO

**特点**:
- 依赖领域层接口
- 不包含业务逻辑
- 协调多个聚合

**目录结构**:
```
internal/app/application/
├── service/
│   ├── user_application_service.go
│   └── order_application_service.go
└── dto/
    ├── user_dto.go      # 应用层 DTO
    └── order_dto.go
```

**示例代码**:
```go
// internal/app/application/dto/user_dto.go
package dto

// CreateUserRequest 创建用户请求 (应用层 DTO)
type CreateUserRequest struct {
    Email    string
    Name     string
    Password string
}

// UserResponse 用户响应 (应用层 DTO)
type UserResponse struct {
    ID     string
    Email  string
    Name   string
    Status string
}

// internal/app/application/service/user_application_service.go
package service

import (
    "context"
    "myproject/internal/app/application/dto"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/repository"
)

// UserApplicationService 用户应用服务
type UserApplicationService struct {
    userRepo       repository.UserRepository
    eventPublisher event.EventPublisher
}

func NewUserApplicationService(
    userRepo repository.UserRepository,
    eventPublisher event.EventPublisher,
) *UserApplicationService {
    return &UserApplicationService{
        userRepo:       userRepo,
        eventPublisher: eventPublisher,
    }
}

// CreateUser 创建用户用例
func (s *UserApplicationService) CreateUser(
    ctx context.Context,
    req dto.CreateUserRequest,
) (*dto.UserResponse, error) {
    // 1. 调用领域层创建用户
    user, err := entity.NewUser(req.Email, req.Name, req.Password)
    if err != nil {
        return nil, err
    }

    // 2. 保存聚合
    if err := s.userRepo.Save(ctx, user); err != nil {
        return nil, err
    }

    // 3. 发布领域事件
    events := user.DomainEvents()
    if err := s.eventPublisher.PublishBatch(ctx, events); err != nil {
        return nil, err
    }

    // 4. 返回应用层 DTO
    return s.toDTO(user), nil
}

// toDTO 转换为应用层 DTO (私有方法)
func (s *UserApplicationService) toDTO(user *entity.User) *dto.UserResponse {
    return &dto.UserResponse{
        ID:     user.ID().String(),
        Email:  user.Email().Value(),
        Name:   user.Name(),
        Status: string(user.Status()),
    }
}
```

### Infrastructure Layer (基础设施层)

**职责**:
- 仓储实现
- 外部服务集成
- 缓存实现
- 消息队列

**特点**:
- 依赖领域层接口
- 实现技术细节
- 可替换的实现

**目录结构**:
```
internal/app/infrastructure/
├── repository/
│   ├── user_repository_impl.go
│   └── order_repository_impl.go
├── cache/
│   └── redis_client.go
└── messaging/
    └── kafka_producer.go
```

**示例代码**:
```go
// internal/app/infrastructure/repository/user_repository_impl.go
package repository

import (
    "context"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/repository"
    "myproject/internal/ent"
)

// UserRepositoryImpl 用户仓储实现
type UserRepositoryImpl struct {
    client *ent.Client
}

func NewUserRepositoryImpl(client *ent.Client) repository.UserRepository {
    return &UserRepositoryImpl{client: client}
}

// FindByID 查询用户
func (r *UserRepositoryImpl) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    entUser, err := r.client.User.Get(ctx, id)
    if err != nil {
        if ent.IsNotFound(err) {
            return nil, repository.ErrUserNotFound
        }
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
        OnConflict().
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

### Interface Layer (接口层)

**职责**:
- HTTP/gRPC 处理
- 请求验证 (接口层 DTO)
- DTO 转换 (接口层 DTO → 应用层 DTO)
- 响应格式化
- 中间件

**特点**:
- 依赖应用层
- 处理协议细节
- 不包含业务逻辑

**目录结构**:
```
internal/app/interface/
├── http/
│   ├── handler/
│   │   ├── user_handler.go
│   │   └── order_handler.go
│   ├── dto/
│   │   ├── user_dto.go        # 接口层 DTO (带校验)
│   │   └── order_dto.go
│   ├── middleware/
│   │   ├── auth.go
│   │   └── logger.go
│   └── router.go
└── grpc/
    └── server/
```

**示例代码**:
```go
// internal/app/interface/http/dto/user_dto.go
package dto

import "github.com/go-playground/validator/v10"

// CreateUserRequest 创建用户请求 (接口层 DTO - 带校验)
type CreateUserRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Name     string `json:"name" binding:"required,min=1,max=100"`
    Password string `json:"password" binding:"required,min=8"`
}

// Validate 验证请求
func (r *CreateUserRequest) Validate() error {
    validate := validator.New()
    return validate.Struct(r)
}

// ToApplicationDTO 转换为应用层 DTO
func (r *CreateUserRequest) ToApplicationDTO() appdto.CreateUserRequest {
    return appdto.CreateUserRequest{
        Email:    r.Email,
        Name:     r.Name,
        Password: r.Password,
    }
}

// internal/app/interface/http/handler/user_handler.go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "myproject/internal/app/application/service"
    httpdto "myproject/internal/app/interface/http/dto"
)

// UserHandler 用户 Handler
type UserHandler struct {
    userService *service.UserApplicationService
}

func NewUserHandler(userService *service.UserApplicationService) *UserHandler {
    return &UserHandler{userService: userService}
}

// CreateUser 创建用户 HTTP 处理
func (h *UserHandler) CreateUser(c *gin.Context) {
    // 1. 绑定接口层 DTO
    var req httpdto.CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "INVALID_REQUEST",
            "message": err.Error(),
        })
        return
    }

    // 2. 验证接口层 DTO
    if err := req.Validate(); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "VALIDATION_ERROR",
            "message": err.Error(),
        })
        return
    }

    // 3. 转换为应用层 DTO
    appReq := req.ToApplicationDTO()

    // 4. 调用应用服务 (传入应用层 DTO)
    user, err := h.userService.CreateUser(c.Request.Context(), appReq)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code":    "INTERNAL_ERROR",
            "message": err.Error(),
        })
        return
    }

    // 5. 返回响应 (应用层 DTO)
    c.JSON(http.StatusCreated, user)
}

// GetUser 获取用户
func (h *UserHandler) GetUser(c *gin.Context) {
    userID := c.Param("id")

    user, err := h.userService.GetUser(c.Request.Context(), userID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "code":    "USER_NOT_FOUND",
            "message": "User not found",
        })
        return
    }

    c.JSON(http.StatusOK, user)
}
```

## 依赖规则

### 依赖方向

```
Interface → Application → Domain
Infrastructure → Domain

❌ 不允许: Domain → Infrastructure
❌ 不允许: Domain → Application
❌ 不允许: Application → Interface
```

### 依赖倒置原则 (DIP)

```go
// ✅ 正确: 依赖接口 (定义在领域层)

// Domain Layer: 定义接口
package repository

type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
    Save(ctx context.Context, user *entity.User) error
}

// Infrastructure Layer: 实现接口
package repository

type UserRepositoryImpl struct {
    db *sql.DB
}

func (r *UserRepositoryImpl) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    // 实现细节
}

// Application Layer: 依赖接口
package service

type UserApplicationService struct {
    userRepo repository.UserRepository  // 依赖接口,不依赖实现
}
```

## 跨层通信模式

### 1. DTO 分层模式

```
HTTP Request
    ↓
Interface DTO (带校验)
    ↓ ToApplicationDTO()
Application DTO
    ↓
Application Service
    ↓
Domain Entity
```

**示例**:
```go
// Interface Layer DTO
type CreateUserRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Name     string `json:"name" binding:"required"`
    Password string `json:"password" binding:"required,min=8"`
}

func (r *CreateUserRequest) ToApplicationDTO() appdto.CreateUserRequest {
    return appdto.CreateUserRequest{
        Email:    r.Email,
        Name:     r.Name,
        Password: r.Password,
    }
}

// Application Layer DTO
type CreateUserRequest struct {
    Email    string
    Name     string
    Password string
}

// Handler 中的使用
func (h *UserHandler) CreateUser(c *gin.Context) {
    var interfaceReq httpdto.CreateUserRequest
    c.ShouldBindJSON(&interfaceReq)

    // 转换为应用层 DTO
    appReq := interfaceReq.ToApplicationDTO()

    // 调用应用服务
    user, _ := h.userService.CreateUser(c.Request.Context(), appReq)
    c.JSON(201, user)
}
```

### 2. 事件驱动

```go
// Domain Layer: 定义事件
package event

type UserCreated struct {
    UserID uuid.UUID
    Email  string
    Time   time.Time
}

// Application Layer: 发布事件
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    user, _ := entity.NewUser(req.Email, req.Name, req.Password)
    s.userRepo.Save(ctx, user)

    // 发布领域事件
    events := user.DomainEvents()
    s.eventPublisher.PublishBatch(ctx, events)

    return s.toDTO(user), nil
}

// Infrastructure Layer: 订阅事件
type UserEventHandler struct {
    emailService *EmailService
}

func (h *UserEventHandler) Handle(ctx context.Context, evt event.DomainEvent) error {
    switch e := evt.(type) {
    case *event.UserCreated:
        // 发送欢迎邮件
        return h.emailService.SendWelcomeEmail(e.Email)
    }
    return nil
}
```

### 3. 仓储模式

```go
// Domain Layer: 定义接口
package repository

type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
    Save(ctx context.Context, user *entity.User) error
}

// Infrastructure Layer: 实现接口
package repository

type UserRepositoryImpl struct {
    client *ent.Client
}

// Application Layer: 使用接口
type UserApplicationService struct {
    userRepo repository.UserRepository  // 依赖接口
}
```

## 完整实现示例

### 用例: 创建订单

#### 1. Domain Layer

```go
// Order 聚合根
type Order struct {
    id          uuid.UUID
    customerID  uuid.UUID
    items       []*OrderItem
    totalAmount valueobject.Money
    status      valueobject.OrderStatus
}

func NewOrder(customerID uuid.UUID) *Order {
    return &Order{
        id:         uuid.New(),
        customerID: customerID,
        items:      make([]*OrderItem, 0),
        status:     valueobject.OrderStatusDraft,
    }
}

func (o *Order) AddItem(productID uuid.UUID, quantity int, price valueobject.Money) error {
    // 不变式: 只有草稿状态可以添加
    if o.status != valueobject.OrderStatusDraft {
        return errors.New("can only add to draft order")
    }

    item := &OrderItem{
        id:        uuid.New(),
        productID: productID,
        quantity:  quantity,
        price:     price,
    }

    o.items = append(o.items, item)
    o.recalculateTotal()

    return nil
}

func (o *Order) Submit() error {
    if len(o.items) == 0 {
        return errors.New("cannot submit empty order")
    }

    o.status = valueobject.OrderStatusSubmitted
    return nil
}
```

#### 2. Application Layer

```go
// Application DTO
type CreateOrderRequest struct {
    CustomerID uuid.UUID
    Items      []OrderItemRequest
}

type OrderItemRequest struct {
    ProductID uuid.UUID
    Quantity  int
}

// Application Service
type OrderApplicationService struct {
    orderRepo      repository.OrderRepository
    productRepo    repository.ProductRepository
    eventPublisher event.EventPublisher
}

func (s *OrderApplicationService) CreateOrder(
    ctx context.Context,
    req dto.CreateOrderRequest,
) (*dto.OrderResponse, error) {
    // 1. 创建订单
    order := entity.NewOrder(req.CustomerID)

    // 2. 添加订单项
    for _, item := range req.Items {
        product, err := s.productRepo.FindByID(ctx, item.ProductID)
        if err != nil {
            return nil, err
        }

        if err := order.AddItem(item.ProductID, item.Quantity, product.Price()); err != nil {
            return nil, err
        }
    }

    // 3. 提交订单
    if err := order.Submit(); err != nil {
        return nil, err
    }

    // 4. 保存订单
    if err := s.orderRepo.Save(ctx, order); err != nil {
        return nil, err
    }

    // 5. 发布事件
    s.eventPublisher.PublishBatch(ctx, order.DomainEvents())

    return s.toDTO(order), nil
}
```

#### 3. Infrastructure Layer

```go
type OrderRepositoryImpl struct {
    client *ent.Client
}

func (r *OrderRepositoryImpl) Save(ctx context.Context, order *entity.Order) error {
    tx, _ := r.client.Tx(ctx)
    defer tx.Rollback()

    // 保存订单
    _, err := tx.Order.Create().
        SetID(order.ID()).
        SetCustomerID(order.CustomerID()).
        SetTotalAmount(order.TotalAmount().Amount()).
        SetStatus(string(order.Status())).
        Save(ctx)
    if err != nil {
        return err
    }

    // 保存订单项
    for _, item := range order.Items() {
        _, err = tx.OrderItem.Create().
            SetID(item.ID()).
            SetOrderID(order.ID()).
            SetProductID(item.ProductID()).
            SetQuantity(item.Quantity()).
            SetPrice(item.Price().Amount()).
            Save(ctx)
        if err != nil {
            return err
        }
    }

    return tx.Commit()
}
```

#### 4. Interface Layer

```go
// Interface DTO (带校验)
type CreateOrderRequest struct {
    CustomerID string           `json:"customer_id" binding:"required,uuid"`
    Items      []OrderItemInput `json:"items" binding:"required,min=1"`
}

type OrderItemInput struct {
    ProductID string `json:"product_id" binding:"required,uuid"`
    Quantity  int    `json:"quantity" binding:"required,min=1"`
}

// ToApplicationDTO 转换为应用层 DTO
func (r *CreateOrderRequest) ToApplicationDTO() appdto.CreateOrderRequest {
    customerID, _ := uuid.Parse(r.CustomerID)

    items := make([]appdto.OrderItemRequest, len(r.Items))
    for i, item := range r.Items {
        productID, _ := uuid.Parse(item.ProductID)
        items[i] = appdto.OrderItemRequest{
            ProductID: productID,
            Quantity:  item.Quantity,
        }
    }

    return appdto.CreateOrderRequest{
        CustomerID: customerID,
        Items:      items,
    }
}

// Handler
type OrderHandler struct {
    orderService *service.OrderApplicationService
}

func (h *OrderHandler) CreateOrder(c *gin.Context) {
    // 1. 绑定接口层 DTO
    var req httpdto.CreateOrderRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // 2. 转换为应用层 DTO
    appReq := req.ToApplicationDTO()

    // 3. 调用应用服务
    order, err := h.orderService.CreateOrder(c.Request.Context(), appReq)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(201, order)
}
```

## 总结

Clean Architecture 的关键实践:
- ✅ 依赖方向从外到内 (单向)
- ✅ 领域层不依赖任何框架
- ✅ 接口定义在领域层,实现在基础设施层
- ✅ 应用层编排用例,不包含业务逻辑
- ✅ Interface DTO 负责校验和转换
- ✅ Application DTO 用于应用层内部
- ✅ 事件驱动实现解耦
- ✅ 仓储模式隔离持久化细节
- ✅ 每层职责单一,边界清晰
