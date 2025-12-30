# Interface Layer 完整指南

## Interface Layer 的角色

Interface Layer (表现层/接口层) 是系统的最外层，负责处理外部请求和响应。它将外部协议转换为应用层能理解的调用，并将结果转换回外部协议格式。

**核心职责**:
- 处理 HTTP/gRPC/WebSocket 等协议请求
- 请求参数验证
- 调用 Application Service
- 响应格式化
- 错误处理和响应
- 认证和授权

**不应包含**:
- 业务逻辑 (属于 Domain Layer)
- 用例编排 (属于 Application Layer)
- 数据库访问 (属于 Infrastructure Layer)

## 组织结构

### 推荐的目录结构

```
internal/app/interface/
├── http/                           # HTTP 接口
│   ├── handler/                    # 处理器
│   │   ├── user_handler.go
│   │   ├── user_handler_test.go
│   │   └── order_handler.go
│   ├── dto/                        # 请求/响应 DTO
│   │   ├── user_request.go
│   │   └── user_response.go
│   ├── middleware/                 # 中间件
│   │   ├── auth_middleware.go
│   │   ├── logger_middleware.go
│   │   └── error_middleware.go
│   └── router.go                   # 路由配置
├── grpc/                           # gRPC 接口 (可选)
│   ├── user_service.go
│   └── pb/
│       └── user.proto
└── websocket/                      # WebSocket 接口 (可选)
    └── chat_handler.go
```

## HTTP Handler 设计

### 标准 Handler 结构

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"

    "myproject/internal/app/application/service"
    "myproject/internal/app/interface/http/dto"
)

// UserHandler 用户处理器
type UserHandler struct {
    userService *service.UserApplicationService
}

func NewUserHandler(userService *service.UserApplicationService) *UserHandler {
    return &UserHandler{
        userService: userService,
    }
}

// CreateUser 创建用户
// @Summary 创建新用户
// @Tags users
// @Accept json
// @Produce json
// @Param request body dto.CreateUserHTTPRequest true "创建用户请求"
// @Success 201 {object} dto.UserHTTPResponse
// @Failure 400 {object} dto.ErrorResponse
// @Router /users [post]
func (h *UserHandler) CreateUser(c *gin.Context) {
    // 1. 解析请求
    var req dto.CreateUserHTTPRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Code:    "INVALID_REQUEST",
            Message: "Invalid request format",
            Details: err.Error(),
        })
        return
    }

    // 2. 转换为应用层 DTO
    appReq := dto.ToApplicationDTO(req)

    // 3. 调用应用服务
    user, err := h.userService.CreateUser(c.Request.Context(), appReq)
    if err != nil {
        h.handleError(c, err)
        return
    }

    // 4. 转换为 HTTP 响应
    response := dto.ToHTTPResponse(user)

    // 5. 返回响应
    c.JSON(http.StatusCreated, response)
}

// GetUser 获取用户
// @Summary 获取用户详情
// @Tags users
// @Produce json
// @Param id path string true "用户ID"
// @Success 200 {object} dto.UserHTTPResponse
// @Failure 404 {object} dto.ErrorResponse
// @Router /users/{id} [get]
func (h *UserHandler) GetUser(c *gin.Context) {
    // 1. 解析路径参数
    idStr := c.Param("id")
    id, err := uuid.Parse(idStr)
    if err != nil {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Code:    "INVALID_ID",
            Message: "Invalid user ID format",
        })
        return
    }

    // 2. 调用应用服务
    user, err := h.userService.GetUser(c.Request.Context(), id)
    if err != nil {
        h.handleError(c, err)
        return
    }

    // 3. 返回响应
    c.JSON(http.StatusOK, dto.ToHTTPResponse(user))
}

// UpdateUser 更新用户
// @Summary 更新用户信息
// @Tags users
// @Accept json
// @Produce json
// @Param id path string true "用户ID"
// @Param request body dto.UpdateUserHTTPRequest true "更新用户请求"
// @Success 200 {object} dto.UserHTTPResponse
// @Failure 400 {object} dto.ErrorResponse
// @Router /users/{id} [put]
func (h *UserHandler) UpdateUser(c *gin.Context) {
    // 1. 解析路径参数
    id, err := uuid.Parse(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Code:    "INVALID_ID",
            Message: "Invalid user ID format",
        })
        return
    }

    // 2. 解析请求体
    var req dto.UpdateUserHTTPRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Code:    "INVALID_REQUEST",
            Message: "Invalid request format",
        })
        return
    }

    // 3. 调用应用服务
    user, err := h.userService.UpdateUser(c.Request.Context(), id, dto.ToApplicationUpdateDTO(req))
    if err != nil {
        h.handleError(c, err)
        return
    }

    // 4. 返回响应
    c.JSON(http.StatusOK, dto.ToHTTPResponse(user))
}

// DeleteUser 删除用户
// @Summary 删除用户
// @Tags users
// @Param id path string true "用户ID"
// @Success 204
// @Failure 404 {object} dto.ErrorResponse
// @Router /users/{id} [delete]
func (h *UserHandler) DeleteUser(c *gin.Context) {
    id, err := uuid.Parse(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Code:    "INVALID_ID",
            Message: "Invalid user ID format",
        })
        return
    }

    if err := h.userService.DeleteUser(c.Request.Context(), id); err != nil {
        h.handleError(c, err)
        return
    }

    c.Status(http.StatusNoContent)
}

// ListUsers 列出用户
// @Summary 获取用户列表
// @Tags users
// @Produce json
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(10)
// @Success 200 {object} dto.UserListHTTPResponse
// @Router /users [get]
func (h *UserHandler) ListUsers(c *gin.Context) {
    // 1. 解析查询参数
    page := c.DefaultQuery("page", "1")
    pageSize := c.DefaultQuery("page_size", "10")

    pageInt, _ := strconv.Atoi(page)
    pageSizeInt, _ := strconv.Atoi(pageSize)

    // 2. 调用应用服务
    users, err := h.userService.ListUsers(c.Request.Context(), pageInt, pageSizeInt)
    if err != nil {
        h.handleError(c, err)
        return
    }

    // 3. 返回响应
    c.JSON(http.StatusOK, users)
}

// handleError 统一错误处理
func (h *UserHandler) handleError(c *gin.Context, err error) {
    switch {
    case errors.Is(err, service.ErrUserNotFound):
        c.JSON(http.StatusNotFound, dto.ErrorResponse{
            Code:    "USER_NOT_FOUND",
            Message: "User not found",
        })
    case errors.Is(err, service.ErrValidationFailed):
        c.JSON(http.StatusBadRequest, dto.ErrorResponse{
            Code:    "VALIDATION_FAILED",
            Message: err.Error(),
        })
    case errors.Is(err, service.ErrUnauthorized):
        c.JSON(http.StatusUnauthorized, dto.ErrorResponse{
            Code:    "UNAUTHORIZED",
            Message: "Unauthorized access",
        })
    default:
        c.JSON(http.StatusInternalServerError, dto.ErrorResponse{
            Code:    "INTERNAL_ERROR",
            Message: "An internal error occurred",
        })
    }
}
```

## 请求 DTO

### 参数验证

```go
package dto

// CreateUserHTTPRequest 创建用户HTTP请求
type CreateUserHTTPRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Name     string `json:"name" binding:"required,min=1,max=100"`
    Password string `json:"password" binding:"required,min=8"`
}

// UpdateUserHTTPRequest 更新用户HTTP请求
type UpdateUserHTTPRequest struct {
    Name string `json:"name" binding:"omitempty,min=1,max=100"`
}

// 自定义验证器
type LoginRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

// Validate 自定义验证
func (r *LoginRequest) Validate() error {
    if r.Email == "" {
        return errors.New("email is required")
    }
    if r.Password == "" {
        return errors.New("password is required")
    }
    return nil
}
```

## 响应 DTO

### 标准化响应格式

```go
package dto

import (
    "time"
    appdto "myproject/internal/app/application/dto"
)

// UserHTTPResponse 用户HTTP响应
type UserHTTPResponse struct {
    ID        string `json:"id"`
    Email     string `json:"email"`
    Name      string `json:"name"`
    Status    string `json:"status"`
    CreatedAt string `json:"created_at"`
}

// ToHTTPResponse 应用层DTO -> HTTP响应
func ToHTTPResponse(user *appdto.UserResponse) *UserHTTPResponse {
    return &UserHTTPResponse{
        ID:        user.ID,
        Email:     user.Email,
        Name:      user.Name,
        Status:    user.Status,
        CreatedAt: user.CreatedAt,
    }
}

// ErrorResponse 错误响应
type ErrorResponse struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details string `json:"details,omitempty"`
}

// UserListHTTPResponse 用户列表响应
type UserListHTTPResponse struct {
    Users    []*UserHTTPResponse `json:"users"`
    Total    int                 `json:"total"`
    Page     int                 `json:"page"`
    PageSize int                 `json:"page_size"`
}

// SuccessResponse 成功响应 (通用)
type SuccessResponse struct {
    Message string      `json:"message"`
    Data    interface{} `json:"data,omitempty"`
}
```

## Gin 框架最佳实践

### 路由组织

```go
package http

import (
    "github.com/gin-gonic/gin"
    "myproject/internal/app/interface/http/handler"
    "myproject/internal/app/interface/http/middleware"
)

// SetupRouter 配置路由
func SetupRouter(
    userHandler *handler.UserHandler,
    orderHandler *handler.OrderHandler,
    authMiddleware *middleware.AuthMiddleware,
) *gin.Engine {
    router := gin.New()

    // 全局中间件
    router.Use(gin.Recovery())
    router.Use(middleware.LoggerMiddleware())
    router.Use(middleware.CORSMiddleware())

    // 健康检查
    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    // API v1
    v1 := router.Group("/api/v1")
    {
        // 公开路由
        public := v1.Group("")
        {
            public.POST("/login", userHandler.Login)
            public.POST("/register", userHandler.Register)
        }

        // 需要认证的路由
        authenticated := v1.Group("")
        authenticated.Use(authMiddleware.RequireAuth())
        {
            // 用户路由
            users := authenticated.Group("/users")
            {
                users.GET("", userHandler.ListUsers)
                users.GET("/:id", userHandler.GetUser)
                users.PUT("/:id", userHandler.UpdateUser)
                users.DELETE("/:id", userHandler.DeleteUser)
            }

            // 订单路由
            orders := authenticated.Group("/orders")
            {
                orders.POST("", orderHandler.CreateOrder)
                orders.GET("/:id", orderHandler.GetOrder)
                orders.POST("/:id/submit", orderHandler.SubmitOrder)
            }
        }
    }

    return router
}
```

### 中间件设计

#### 日志中间件

```go
package middleware

import (
    "log/slog"
    "time"
    "github.com/gin-gonic/gin"
)

// LoggerMiddleware 请求日志中间件
func LoggerMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()

        // 处理请求
        c.Next()

        // 记录日志
        duration := time.Since(start)
        slog.Info("http request",
            "method", c.Request.Method,
            "path", c.Request.URL.Path,
            "status", c.Writer.Status(),
            "duration_ms", duration.Milliseconds(),
            "client_ip", c.ClientIP(),
        )
    }
}
```

#### 错误处理中间件

```go
package middleware

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

// ErrorMiddleware 错误处理中间件
func ErrorMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        defer func() {
            if err := recover(); err != nil {
                slog.Error("panic recovered",
                    "error", err,
                    "path", c.Request.URL.Path,
                )

                c.JSON(http.StatusInternalServerError, gin.H{
                    "code":    "INTERNAL_ERROR",
                    "message": "An internal error occurred",
                })
            }
        }()

        c.Next()
    }
}
```

#### 认证中间件

```go
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware 认证中间件
type AuthMiddleware struct {
    jwtSecret []byte
}

func NewAuthMiddleware(jwtSecret string) *AuthMiddleware {
    return &AuthMiddleware{
        jwtSecret: []byte(jwtSecret),
    }
}

// RequireAuth 要求认证
func (m *AuthMiddleware) RequireAuth() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 1. 获取 Authorization header
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "code":    "UNAUTHORIZED",
                "message": "Missing authorization header",
            })
            c.Abort()
            return
        }

        // 2. 解析 Bearer token
        parts := strings.SplitN(authHeader, " ", 2)
        if len(parts) != 2 || parts[0] != "Bearer" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "code":    "UNAUTHORIZED",
                "message": "Invalid authorization header format",
            })
            c.Abort()
            return
        }

        tokenString := parts[1]

        // 3. 验证 JWT
        token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
            return m.jwtSecret, nil
        })

        if err != nil || !token.Valid {
            c.JSON(http.StatusUnauthorized, gin.H{
                "code":    "UNAUTHORIZED",
                "message": "Invalid token",
            })
            c.Abort()
            return
        }

        // 4. 提取用户信息
        if claims, ok := token.Claims.(jwt.MapClaims); ok {
            c.Set("user_id", claims["user_id"])
            c.Set("email", claims["email"])
        }

        c.Next()
    }
}
```

#### CORS 中间件

```go
package middleware

import (
    "github.com/gin-gonic/gin"
)

// CORSMiddleware CORS 中间件
func CORSMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
        c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
        c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
        c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    }
}
```

#### 限流中间件

```go
package middleware

import (
    "net/http"
    "sync"
    "time"
    "github.com/gin-gonic/gin"
)

// RateLimiter 限流器
type RateLimiter struct {
    requests map[string][]time.Time
    mu       sync.Mutex
    limit    int
    window   time.Duration
}

func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
    return &RateLimiter{
        requests: make(map[string][]time.Time),
        limit:    limit,
        window:   window,
    }
}

// RateLimit 限流中间件
func (rl *RateLimiter) RateLimit() gin.HandlerFunc {
    return func(c *gin.Context) {
        clientIP := c.ClientIP()

        rl.mu.Lock()
        defer rl.mu.Unlock()

        now := time.Now()
        windowStart := now.Add(-rl.window)

        // 清理过期的请求记录
        if times, exists := rl.requests[clientIP]; exists {
            validTimes := []time.Time{}
            for _, t := range times {
                if t.After(windowStart) {
                    validTimes = append(validTimes, t)
                }
            }
            rl.requests[clientIP] = validTimes
        }

        // 检查是否超过限制
        if len(rl.requests[clientIP]) >= rl.limit {
            c.JSON(http.StatusTooManyRequests, gin.H{
                "code":    "RATE_LIMIT_EXCEEDED",
                "message": "Too many requests",
            })
            c.Abort()
            return
        }

        // 记录当前请求
        rl.requests[clientIP] = append(rl.requests[clientIP], now)

        c.Next()
    }
}
```

## gRPC 服务实现

### Proto 定义

```protobuf
// user.proto
syntax = "proto3";

package user;

option go_package = "myproject/internal/app/interface/grpc/pb";

service UserService {
    rpc CreateUser(CreateUserRequest) returns (UserResponse);
    rpc GetUser(GetUserRequest) returns (UserResponse);
    rpc UpdateUser(UpdateUserRequest) returns (UserResponse);
    rpc DeleteUser(DeleteUserRequest) returns (Empty);
}

message CreateUserRequest {
    string email = 1;
    string name = 2;
    string password = 3;
}

message GetUserRequest {
    string id = 1;
}

message UpdateUserRequest {
    string id = 1;
    string name = 2;
}

message DeleteUserRequest {
    string id = 1;
}

message UserResponse {
    string id = 1;
    string email = 2;
    string name = 3;
    string status = 4;
    string created_at = 5;
}

message Empty {}
```

### gRPC 服务实现

```go
package grpc

import (
    "context"
    "github.com/google/uuid"

    "myproject/internal/app/application/service"
    "myproject/internal/app/interface/grpc/pb"
)

// UserGRPCService gRPC 用户服务
type UserGRPCService struct {
    pb.UnimplementedUserServiceServer
    userService *service.UserApplicationService
}

func NewUserGRPCService(userService *service.UserApplicationService) *UserGRPCService {
    return &UserGRPCService{
        userService: userService,
    }
}

// CreateUser 创建用户
func (s *UserGRPCService) CreateUser(ctx context.Context, req *pb.CreateUserRequest) (*pb.UserResponse, error) {
    // 转换为应用层 DTO
    appReq := dto.CreateUserRequest{
        Email:    req.Email,
        Name:     req.Name,
        Password: req.Password,
    }

    // 调用应用服务
    user, err := s.userService.CreateUser(ctx, appReq)
    if err != nil {
        return nil, err
    }

    // 转换为 gRPC 响应
    return &pb.UserResponse{
        Id:        user.ID,
        Email:     user.Email,
        Name:      user.Name,
        Status:    user.Status,
        CreatedAt: user.CreatedAt,
    }, nil
}

// GetUser 获取用户
func (s *UserGRPCService) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.UserResponse, error) {
    id, err := uuid.Parse(req.Id)
    if err != nil {
        return nil, err
    }

    user, err := s.userService.GetUser(ctx, id)
    if err != nil {
        return nil, err
    }

    return &pb.UserResponse{
        Id:        user.ID,
        Email:     user.Email,
        Name:      user.Name,
        Status:    user.Status,
        CreatedAt: user.CreatedAt,
    }, nil
}
```

## 测试 Interface Layer

### HTTP Handler 测试

```go
package handler_test

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

func TestUserHandler_CreateUser(t *testing.T) {
    // 设置 Gin 为测试模式
    gin.SetMode(gin.TestMode)

    // Mock 应用服务
    mockService := new(MockUserApplicationService)
    handler := handler.NewUserHandler(mockService)

    // 准备请求
    reqBody := dto.CreateUserHTTPRequest{
        Email:    "test@example.com",
        Name:     "Test User",
        Password: "password123",
    }
    body, _ := json.Marshal(reqBody)

    // 创建测试请求
    req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()

    // 设置 Mock 期望
    mockService.On("CreateUser", mock.Anything, mock.Anything).
        Return(&dto.UserResponse{
            ID:    "123",
            Email: "test@example.com",
            Name:  "Test User",
        }, nil)

    // 执行请求
    c, _ := gin.CreateTestContext(w)
    c.Request = req
    handler.CreateUser(c)

    // 断言
    assert.Equal(t, http.StatusCreated, w.Code)

    var response dto.UserHTTPResponse
    json.Unmarshal(w.Body.Bytes(), &response)
    assert.Equal(t, "test@example.com", response.Email)
}
```

## 总结

Interface Layer 的关键实践:
- ✅ Handler 只负责协议转换，不包含业务逻辑
- ✅ 使用中间件处理横切关注点
- ✅ 统一的错误处理和响应格式
- ✅ 请求参数验证在接口层完成
- ✅ 支持多种协议 (HTTP, gRPC, WebSocket)
- ✅ 使用 httptest 进行单元测试
