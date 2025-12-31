# Gin 框架最佳实践

## Gin 基础

Gin 是一个高性能的 Go Web 框架，具有类似 Martini 的 API，但性能更优。

**核心特性**:
- 高性能路由（基于 httprouter）
- 中间件支持
- 错误管理
- JSON 验证
- 路由分组
- 可扩展性强

## 路由组织

### 基础路由注册

```go
package main

import "github.com/gin-gonic/gin"

func main() {
    router := gin.Default() // 包含 Logger 和 Recovery 中间件

    // GET 请求
    router.GET("/ping", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "message": "pong",
        })
    })

    // POST 请求
    router.POST("/users", createUser)

    // PUT 请求
    router.PUT("/users/:id", updateUser)

    // DELETE 请求
    router.DELETE("/users/:id", deleteUser)

    router.Run(":8080")
}
```

### 路由分组

```go
package main

import "github.com/gin-gonic/gin"

func SetupRouter() *gin.Engine {
    router := gin.New()

    // 全局中间件
    router.Use(gin.Logger())
    router.Use(gin.Recovery())

    // API v1 分组
    v1 := router.Group("/api/v1")
    {
        // 用户路由
        users := v1.Group("/users")
        {
            users.GET("", listUsers)
            users.GET("/:id", getUser)
            users.POST("", createUser)
            users.PUT("/:id", updateUser)
            users.DELETE("/:id", deleteUser)
        }

        // 订单路由
        orders := v1.Group("/orders")
        {
            orders.GET("", listOrders)
            orders.GET("/:id", getOrder)
            orders.POST("", createOrder)
            orders.POST("/:id/submit", submitOrder)
        }
    }

    // API v2 分组
    v2 := router.Group("/api/v2")
    {
        v2.GET("/users", listUsersV2)
    }

    return router
}
```

### 路由参数

```go
package main

// 路径参数
router.GET("/users/:id", func(c *gin.Context) {
    id := c.Param("id")  // 获取路径参数
    c.JSON(200, gin.H{"id": id})
})

// 查询参数
router.GET("/search", func(c *gin.Context) {
    query := c.Query("q")                    // 获取查询参数
    page := c.DefaultQuery("page", "1")      // 带默认值
    c.JSON(200, gin.H{"query": query, "page": page})
})

// POST 表单参数
router.POST("/form", func(c *gin.Context) {
    name := c.PostForm("name")
    email := c.PostForm("email")
    c.JSON(200, gin.H{"name": name, "email": email})
})
```

## 中间件最佳实践

### 1. 日志中间件

```go
package middleware

import (
    "log/slog"
    "time"
    "github.com/gin-gonic/gin"
)

// LoggerMiddleware 结构化日志中间件
func LoggerMiddleware(logger *slog.Logger) gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        path := c.Request.URL.Path
        query := c.Request.URL.RawQuery

        // 处理请求
        c.Next()

        // 记录日志
        duration := time.Since(start)
        status := c.Writer.Status()

        logger.Info("HTTP request",
            "method", c.Request.Method,
            "path", path,
            "query", query,
            "status", status,
            "duration_ms", duration.Milliseconds(),
            "client_ip", c.ClientIP(),
            "user_agent", c.Request.UserAgent(),
        )
    }
}
```

### 2. 错误处理中间件

```go
package middleware

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

// ErrorMiddleware 统一错误处理中间件
func ErrorMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        defer func() {
            if err := recover(); err != nil {
                // 记录 panic
                slog.Error("panic recovered",
                    "error", err,
                    "path", c.Request.URL.Path,
                )

                // 返回 500 错误
                c.JSON(http.StatusInternalServerError, gin.H{
                    "code":    "INTERNAL_ERROR",
                    "message": "An internal error occurred",
                })

                c.Abort()
            }
        }()

        c.Next()

        // 检查是否有错误
        if len(c.Errors) > 0 {
            err := c.Errors.Last()

            // 根据错误类型返回不同响应
            c.JSON(http.StatusBadRequest, gin.H{
                "code":    "REQUEST_ERROR",
                "message": err.Error(),
            })
        }
    }
}
```

### 3. 认证中间件

```go
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware JWT 认证中间件
type AuthMiddleware struct {
    jwtSecret []byte
}

func NewAuthMiddleware(secret string) *AuthMiddleware {
    return &AuthMiddleware{
        jwtSecret: []byte(secret),
    }
}

// RequireAuth 要求认证
func (m *AuthMiddleware) RequireAuth() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 获取 Authorization header
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "code":    "UNAUTHORIZED",
                "message": "Missing authorization header",
            })
            c.Abort()
            return
        }

        // 解析 Bearer token
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

        // 验证 JWT
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

        // 提取用户信息
        if claims, ok := token.Claims.(jwt.MapClaims); ok {
            c.Set("user_id", claims["user_id"])
            c.Set("email", claims["email"])
        }

        c.Next()
    }
}

// GetUserID 从上下文获取用户ID
func GetUserID(c *gin.Context) (string, bool) {
    userID, exists := c.Get("user_id")
    if !exists {
        return "", false
    }
    return userID.(string), true
}
```

### 4. CORS 中间件

```go
package middleware

import "github.com/gin-gonic/gin"

// CORSMiddleware 跨域中间件
func CORSMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
        c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
        c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Authorization, X-Requested-With")
        c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    }
}

// CORSConfig 可配置的 CORS 中间件
type CORSConfig struct {
    AllowOrigins []string
    AllowMethods []string
    AllowHeaders []string
}

func CORSMiddlewareWithConfig(config CORSConfig) gin.HandlerFunc {
    return func(c *gin.Context) {
        origin := c.Request.Header.Get("Origin")

        // 检查是否允许该来源
        allowed := false
        for _, allowedOrigin := range config.AllowOrigins {
            if allowedOrigin == "*" || allowedOrigin == origin {
                allowed = true
                break
            }
        }

        if allowed {
            c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
        }

        c.Writer.Header().Set("Access-Control-Allow-Methods", strings.Join(config.AllowMethods, ", "))
        c.Writer.Header().Set("Access-Control-Allow-Headers", strings.Join(config.AllowHeaders, ", "))

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    }
}
```

### 5. 限流中间件

```go
package middleware

import (
    "net/http"
    "sync"
    "time"
    "github.com/gin-gonic/gin"
)

// RateLimiter 基于令牌桶的限流器
type RateLimiter struct {
    rate     int           // 每秒令牌数
    capacity int           // 桶容量
    buckets  map[string]*TokenBucket
    mu       sync.Mutex
}

type TokenBucket struct {
    tokens    int
    lastRefill time.Time
}

func NewRateLimiter(rate, capacity int) *RateLimiter {
    return &RateLimiter{
        rate:     rate,
        capacity: capacity,
        buckets:  make(map[string]*TokenBucket),
    }
}

// RateLimit 限流中间件
func (rl *RateLimiter) RateLimit() gin.HandlerFunc {
    return func(c *gin.Context) {
        clientIP := c.ClientIP()

        if !rl.allow(clientIP) {
            c.JSON(http.StatusTooManyRequests, gin.H{
                "code":    "RATE_LIMIT_EXCEEDED",
                "message": "Too many requests, please try again later",
            })
            c.Abort()
            return
        }

        c.Next()
    }
}

// allow 检查是否允许请求
func (rl *RateLimiter) allow(key string) bool {
    rl.mu.Lock()
    defer rl.mu.Unlock()

    bucket, exists := rl.buckets[key]
    if !exists {
        bucket = &TokenBucket{
            tokens:     rl.capacity,
            lastRefill: time.Now(),
        }
        rl.buckets[key] = bucket
    }

    // 补充令牌
    now := time.Now()
    elapsed := now.Sub(bucket.lastRefill).Seconds()
    tokensToAdd := int(elapsed * float64(rl.rate))

    if tokensToAdd > 0 {
        bucket.tokens = min(bucket.tokens+tokensToAdd, rl.capacity)
        bucket.lastRefill = now
    }

    // 尝试消耗令牌
    if bucket.tokens > 0 {
        bucket.tokens--
        return true
    }

    return false
}
```

## 参数验证

### 结构体绑定和验证

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

// CreateUserRequest 创建用户请求
type CreateUserRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Name     string `json:"name" binding:"required,min=1,max=100"`
    Password string `json:"password" binding:"required,min=8"`
    Age      int    `json:"age" binding:"required,gte=0,lte=150"`
}

// CreateUser 创建用户
func CreateUser(c *gin.Context) {
    var req CreateUserRequest

    // 绑定并验证
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "VALIDATION_ERROR",
            "message": err.Error(),
        })
        return
    }

    // 处理请求
    c.JSON(http.StatusCreated, gin.H{
        "message": "User created successfully",
    })
}
```

### 自定义验证器

```go
package validator

import (
    "github.com/go-playground/validator/v10"
    "regexp"
)

// 注册自定义验证器
func RegisterCustomValidators(v *validator.Validate) {
    // 注册手机号验证
    v.RegisterValidation("phone", validatePhone)

    // 注册强密码验证
    v.RegisterValidation("strong_password", validateStrongPassword)
}

// validatePhone 验证手机号
func validatePhone(fl validator.FieldLevel) bool {
    phone := fl.Field().String()
    matched, _ := regexp.MatchString(`^1[3-9]\d{9}$`, phone)
    return matched
}

// validateStrongPassword 验证强密码
func validateStrongPassword(fl validator.FieldLevel) bool {
    password := fl.Field().String()

    // 至少8位，包含大小写字母和数字
    hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
    hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
    hasNumber := regexp.MustCompile(`[0-9]`).MatchString(password)

    return len(password) >= 8 && hasUpper && hasLower && hasNumber
}

// 使用自定义验证器
type RegisterRequest struct {
    Phone    string `json:"phone" binding:"required,phone"`
    Password string `json:"password" binding:"required,strong_password"`
}
```

## 文件上传

### 单文件上传

```go
package handler

import (
    "net/http"
    "path/filepath"
    "github.com/gin-gonic/gin"
)

// UploadFile 上传文件
func UploadFile(c *gin.Context) {
    // 获取文件
    file, err := c.FormFile("file")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "INVALID_FILE",
            "message": "No file uploaded",
        })
        return
    }

    // 检查文件大小 (限制10MB)
    if file.Size > 10*1024*1024 {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "FILE_TOO_LARGE",
            "message": "File size exceeds 10MB",
        })
        return
    }

    // 检查文件类型
    ext := filepath.Ext(file.Filename)
    allowedExts := map[string]bool{
        ".jpg":  true,
        ".jpeg": true,
        ".png":  true,
        ".gif":  true,
    }

    if !allowedExts[ext] {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "INVALID_FILE_TYPE",
            "message": "Only image files are allowed",
        })
        return
    }

    // 保存文件
    filename := fmt.Sprintf("uploads/%d%s", time.Now().Unix(), ext)
    if err := c.SaveUploadedFile(file, filename); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code":    "UPLOAD_FAILED",
            "message": "Failed to save file",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "message":  "File uploaded successfully",
        "filename": filename,
    })
}
```

### 多文件上传

```go
package handler

// UploadMultipleFiles 多文件上传
func UploadMultipleFiles(c *gin.Context) {
    form, err := c.MultipartForm()
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "INVALID_FORM",
            "message": "Invalid multipart form",
        })
        return
    }

    files := form.File["files"]
    uploadedFiles := make([]string, 0, len(files))

    for _, file := range files {
        // 验证每个文件
        if file.Size > 10*1024*1024 {
            continue // 跳过过大的文件
        }

        // 保存文件
        filename := fmt.Sprintf("uploads/%d_%s", time.Now().UnixNano(), file.Filename)
        if err := c.SaveUploadedFile(file, filename); err != nil {
            continue // 跳过保存失败的文件
        }

        uploadedFiles = append(uploadedFiles, filename)
    }

    c.JSON(http.StatusOK, gin.H{
        "message": "Files uploaded",
        "files":   uploadedFiles,
        "count":   len(uploadedFiles),
    })
}
```

## 性能优化

### 连接复用

```go
package main

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
)

func main() {
    router := gin.Default()

    // 配置 HTTP Server
    server := &http.Server{
        Addr:           ":8080",
        Handler:        router,
        ReadTimeout:    10 * time.Second,
        WriteTimeout:   10 * time.Second,
        MaxHeaderBytes: 1 << 20, // 1MB
    }

    server.ListenAndServe()
}
```

### 异步处理

```go
package handler

import (
    "log"
    "time"
    "github.com/gin-gonic/gin"
)

// AsyncHandler 异步处理
func AsyncHandler(c *gin.Context) {
    // 复制上下文用于 goroutine
    cCopy := c.Copy()

    // 异步处理
    go func() {
        // 模拟耗时操作
        time.Sleep(5 * time.Second)

        // 使用复制的上下文
        log.Println("Done! in path " + cCopy.Request.URL.Path)
    }()

    c.JSON(200, gin.H{
        "message": "Request accepted, processing asynchronously",
    })
}
```

### 缓存响应

```go
package middleware

import (
    "crypto/sha256"
    "fmt"
    "time"
    "github.com/gin-gonic/gin"
)

// CacheMiddleware 简单的响应缓存
type CacheMiddleware struct {
    cache map[string]CacheEntry
    ttl   time.Duration
}

type CacheEntry struct {
    Data      interface{}
    ExpiresAt time.Time
}

func NewCacheMiddleware(ttl time.Duration) *CacheMiddleware {
    return &CacheMiddleware{
        cache: make(map[string]CacheEntry),
        ttl:   ttl,
    }
}

// Cache 缓存中间件
func (cm *CacheMiddleware) Cache() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 只缓存 GET 请求
        if c.Request.Method != "GET" {
            c.Next()
            return
        }

        // 生成缓存键
        key := cm.generateKey(c.Request.URL.String())

        // 检查缓存
        if entry, exists := cm.cache[key]; exists {
            if time.Now().Before(entry.ExpiresAt) {
                // 缓存命中
                c.JSON(200, entry.Data)
                c.Abort()
                return
            }
            // 缓存过期，删除
            delete(cm.cache, key)
        }

        // 继续处理请求
        c.Next()
    }
}

func (cm *CacheMiddleware) generateKey(url string) string {
    hash := sha256.Sum256([]byte(url))
    return fmt.Sprintf("%x", hash)
}
```

## 测试 Gin 应用

### Handler 测试

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
)

func TestCreateUser(t *testing.T) {
    // 设置 Gin 为测试模式
    gin.SetMode(gin.TestMode)

    // 创建路由
    router := gin.New()
    router.POST("/users", handler.CreateUser)

    // 准备请求
    reqBody := map[string]interface{}{
        "email":    "test@example.com",
        "name":     "Test User",
        "password": "password123",
        "age":      25,
    }
    body, _ := json.Marshal(reqBody)

    req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")

    // 记录响应
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    // 断言
    assert.Equal(t, http.StatusCreated, w.Code)

    var response map[string]interface{}
    json.Unmarshal(w.Body.Bytes(), &response)
    assert.Equal(t, "User created successfully", response["message"])
}

func TestCreateUser_ValidationError(t *testing.T) {
    gin.SetMode(gin.TestMode)

    router := gin.New()
    router.POST("/users", handler.CreateUser)

    // 无效的请求（缺少必填字段）
    reqBody := map[string]interface{}{
        "email": "invalid-email", // 无效邮箱
    }
    body, _ := json.Marshal(reqBody)

    req, _ := http.NewRequest("POST", "/users", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")

    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    // 应该返回 400
    assert.Equal(t, http.StatusBadRequest, w.Code)
}
```

### 中间件测试

```go
package middleware_test

import (
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
)

func TestAuthMiddleware(t *testing.T) {
    gin.SetMode(gin.TestMode)

    router := gin.New()
    authMW := middleware.NewAuthMiddleware("secret")
    router.Use(authMW.RequireAuth())
    router.GET("/protected", func(c *gin.Context) {
        c.JSON(200, gin.H{"message": "success"})
    })

    // 测试: 缺少 Authorization header
    req, _ := http.NewRequest("GET", "/protected", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusUnauthorized, w.Code)

    // 测试: 有效的 token
    req, _ = http.NewRequest("GET", "/protected", nil)
    req.Header.Set("Authorization", "Bearer valid_token")
    w = httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusOK, w.Code)
}
```

## 总结

Gin 框架的关键实践:
- ✅ 使用路由分组组织 API
- ✅ 合理使用中间件处理横切关注点
- ✅ 使用结构体绑定和验证请求参数
- ✅ 实现限流保护 API
- ✅ 异步处理耗时操作
- ✅ 使用 httptest 进行单元测试
- ✅ 配置超时和连接限制
- ✅ 统一错误处理和响应格式
