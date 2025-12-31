# 可观测性配置指南

## 可观测性三大支柱

可观测性 (Observability) 由三大支柱组成:

**日志 (Logging)**:
- 记录应用运行时的事件
- 结构化日志便于检索和分析
- Go 标准库: `log/slog`

**指标 (Metrics)**:
- 量化系统性能指标
- 时间序列数据便于监控和告警
- 标准工具: Prometheus

**追踪 (Tracing)**:
- 追踪请求在分布式系统中的流转
- 分析性能瓶颈和依赖关系
- 标准协议: OpenTelemetry

## 结构化日志 (slog)

### 基础配置

```go
package logger

import (
    "log/slog"
    "os"
)

// InitLogger 初始化日志器
func InitLogger(env string) *slog.Logger {
    var handler slog.Handler

    switch env {
    case "production":
        // 生产环境: JSON 格式
        handler = slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
            Level: slog.LevelInfo,
            AddSource: true, // 添加源码位置
        })
    case "development":
        // 开发环境: 文本格式
        handler = slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
            Level: slog.LevelDebug,
            AddSource: true,
        })
    default:
        handler = slog.NewJSONHandler(os.Stdout, nil)
    }

    logger := slog.New(handler)
    slog.SetDefault(logger) // 设置为全局默认

    return logger
}
```

### 结构化日志记录

```go
package service

import (
    "context"
    "log/slog"
)

// UserApplicationService 应用服务
type UserApplicationService struct {
    logger *slog.Logger
}

// CreateUser 创建用户
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    // 记录请求开始
    s.logger.Info("creating user",
        "email", req.Email,
        "name", req.Name,
    )

    // 业务逻辑
    user, err := entity.NewUser(req.Email, req.Name, req.Password)
    if err != nil {
        // 记录错误
        s.logger.Error("failed to create user entity",
            "email", req.Email,
            "error", err,
        )
        return nil, err
    }

    // 保存用户
    if err := s.userRepo.Save(ctx, user); err != nil {
        s.logger.Error("failed to save user",
            "user_id", user.ID(),
            "error", err,
        )
        return nil, err
    }

    // 记录成功
    s.logger.Info("user created successfully",
        "user_id", user.ID(),
        "email", user.Email().Value(),
    )

    return s.toDTO(user), nil
}
```

### 上下文日志

```go
package middleware

import (
    "context"
    "log/slog"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
)

// RequestIDMiddleware 请求 ID 中间件
func RequestIDMiddleware(logger *slog.Logger) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 生成请求 ID
        requestID := uuid.New().String()

        // 创建带请求 ID 的日志器
        requestLogger := logger.With(
            "request_id", requestID,
            "method", c.Request.Method,
            "path", c.Request.URL.Path,
        )

        // 注入到上下文
        ctx := context.WithValue(c.Request.Context(), "logger", requestLogger)
        c.Request = c.Request.WithContext(ctx)

        c.Next()
    }
}

// LoggerFromContext 从上下文获取日志器
func LoggerFromContext(ctx context.Context) *slog.Logger {
    if logger, ok := ctx.Value("logger").(*slog.Logger); ok {
        return logger
    }
    return slog.Default()
}
```

### 分级日志

```go
package service

// 不同级别的日志示例
func (s *UserApplicationService) ProcessUser(ctx context.Context, userID uuid.UUID) error {
    logger := LoggerFromContext(ctx)

    // Debug: 调试信息
    logger.Debug("processing user", "user_id", userID)

    // Info: 常规信息
    logger.Info("user processing started", "user_id", userID)

    // Warn: 警告信息
    if user.Status() == "suspended" {
        logger.Warn("processing suspended user", "user_id", userID)
    }

    // Error: 错误信息
    if err != nil {
        logger.Error("failed to process user",
            "user_id", userID,
            "error", err,
        )
        return err
    }

    return nil
}
```

## Prometheus 指标

### 基础配置

```go
package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    // 计数器: 请求总数
    HttpRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    // 直方图: 请求耗时
    HttpRequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )

    // 仪表盘: 当前活跃用户
    ActiveUsers = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "active_users",
            Help: "Number of active users",
        },
    )

    // 摘要: 订单金额
    OrderAmount = promauto.NewSummaryVec(
        prometheus.SummaryOpts{
            Name:       "order_amount",
            Help:       "Order amount distribution",
            Objectives: map[float64]float64{0.5: 0.05, 0.9: 0.01, 0.99: 0.001},
        },
        []string{"status"},
    )
)
```

### Gin 集成

```go
package middleware

import (
    "strconv"
    "time"
    "github.com/gin-gonic/gin"
)

// PrometheusMiddleware 指标中间件
func PrometheusMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()

        // 处理请求
        c.Next()

        // 记录耗时
        duration := time.Since(start).Seconds()
        metrics.HttpRequestDuration.WithLabelValues(
            c.Request.Method,
            c.FullPath(),
        ).Observe(duration)

        // 记录请求计数
        metrics.HttpRequestsTotal.WithLabelValues(
            c.Request.Method,
            c.FullPath(),
            strconv.Itoa(c.Writer.Status()),
        ).Inc()
    }
}
```

### 业务指标

```go
package service

import "github.com/prometheus/client_golang/prometheus"

var (
    // 用户注册计数
    UserRegistrations = promauto.NewCounter(
        prometheus.CounterOpts{
            Name: "user_registrations_total",
            Help: "Total number of user registrations",
        },
    )

    // 订单创建计数
    OrdersCreated = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "orders_created_total",
            Help: "Total number of orders created",
        },
        []string{"status"},
    )

    // 数据库查询耗时
    DatabaseQueryDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "database_query_duration_seconds",
            Help:    "Database query duration in seconds",
            Buckets: []float64{0.001, 0.01, 0.1, 0.5, 1, 5},
        },
        []string{"operation", "table"},
    )
)

// CreateUser 记录业务指标
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    // 业务逻辑...

    // 增加注册计数
    UserRegistrations.Inc()

    return user, nil
}

// CreateOrder 记录订单指标
func (s *OrderApplicationService) CreateOrder(ctx context.Context, req dto.CreateOrderRequest) (*dto.OrderResponse, error) {
    // 业务逻辑...

    // 记录订单创建
    OrdersCreated.WithLabelValues(string(order.Status())).Inc()

    // 记录订单金额
    metrics.OrderAmount.WithLabelValues(string(order.Status())).Observe(float64(order.TotalAmount().Amount()))

    return order, nil
}
```

### 暴露指标端点

```go
package main

import (
    "github.com/gin-gonic/gin"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

func SetupRouter() *gin.Engine {
    router := gin.Default()

    // 添加 Prometheus 中间件
    router.Use(middleware.PrometheusMiddleware())

    // 暴露指标端点
    router.GET("/metrics", gin.WrapH(promhttp.Handler()))

    // 业务路由
    router.POST("/users", handler.CreateUser)

    return router
}
```

## OpenTelemetry 追踪

### 基础配置

```go
package tracing

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/jaeger"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

// InitTracer 初始化追踪器
func InitTracer(serviceName, jaegerEndpoint string) (*sdktrace.TracerProvider, error) {
    // 创建 Jaeger 导出器
    exporter, err := jaeger.New(
        jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(jaegerEndpoint)),
    )
    if err != nil {
        return nil, err
    }

    // 创建资源
    res, err := resource.New(
        context.Background(),
        resource.WithAttributes(
            semconv.ServiceNameKey.String(serviceName),
        ),
    )
    if err != nil {
        return nil, err
    }

    // 创建 TracerProvider
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(res),
        sdktrace.WithSampler(sdktrace.AlwaysSample()),
    )

    // 设置为全局
    otel.SetTracerProvider(tp)

    return tp, nil
}
```

### Gin 集成

```go
package middleware

import (
    "github.com/gin-gonic/gin"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/trace"
)

// TracingMiddleware 追踪中间件
func TracingMiddleware(serviceName string) gin.HandlerFunc {
    tracer := otel.Tracer(serviceName)

    return func(c *gin.Context) {
        // 创建 Span
        ctx, span := tracer.Start(
            c.Request.Context(),
            c.Request.Method+" "+c.FullPath(),
            trace.WithAttributes(
                attribute.String("http.method", c.Request.Method),
                attribute.String("http.url", c.Request.URL.String()),
                attribute.String("http.client_ip", c.ClientIP()),
            ),
        )
        defer span.End()

        // 注入到上下文
        c.Request = c.Request.WithContext(ctx)

        // 处理请求
        c.Next()

        // 记录响应状态
        span.SetAttributes(
            attribute.Int("http.status_code", c.Writer.Status()),
        )
    }
}
```

### 服务追踪

```go
package service

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
)

// UserApplicationService 应用服务
type UserApplicationService struct {
    tracer trace.Tracer
}

func NewUserApplicationService() *UserApplicationService {
    return &UserApplicationService{
        tracer: otel.Tracer("user-service"),
    }
}

// CreateUser 创建用户 (带追踪)
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
    // 创建 Span
    ctx, span := s.tracer.Start(ctx, "CreateUser")
    defer span.End()

    // 添加属性
    span.SetAttributes(
        attribute.String("user.email", req.Email),
        attribute.String("user.name", req.Name),
    )

    // 业务逻辑...
    user, err := entity.NewUser(req.Email, req.Name, req.Password)
    if err != nil {
        span.RecordError(err)
        return nil, err
    }

    // 调用仓储 (会创建子 Span)
    if err := s.userRepo.Save(ctx, user); err != nil {
        span.RecordError(err)
        return nil, err
    }

    span.SetAttributes(attribute.String("user.id", user.ID().String()))

    return s.toDTO(user), nil
}
```

### 仓储追踪

```go
package repository

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
)

// UserRepositoryImpl 仓储实现
type UserRepositoryImpl struct {
    tracer trace.Tracer
}

func NewUserRepositoryImpl(db *sql.DB) *UserRepositoryImpl {
    return &UserRepositoryImpl{
        tracer: otel.Tracer("user-repository"),
    }
}

// Save 保存用户 (带追踪)
func (r *UserRepositoryImpl) Save(ctx context.Context, user *entity.User) error {
    // 创建子 Span
    ctx, span := r.tracer.Start(ctx, "UserRepository.Save")
    defer span.End()

    span.SetAttributes(
        attribute.String("user.id", user.ID().String()),
        attribute.String("db.operation", "INSERT"),
    )

    // 数据库操作...
    _, err := r.db.ExecContext(ctx, query, args...)
    if err != nil {
        span.RecordError(err)
        return err
    }

    return nil
}
```

## 整合实践

### 完整的中间件栈

```go
package main

import (
    "github.com/gin-gonic/gin"
    "log/slog"
)

func SetupRouter(logger *slog.Logger) *gin.Engine {
    router := gin.New()

    // 1. 追踪中间件 (最外层)
    router.Use(middleware.TracingMiddleware("my-service"))

    // 2. 日志中间件
    router.Use(middleware.LoggerMiddleware(logger))

    // 3. 指标中间件
    router.Use(middleware.PrometheusMiddleware())

    // 4. Recovery 中间件
    router.Use(gin.Recovery())

    // 业务路由
    router.POST("/users", handler.CreateUser)

    // 健康检查
    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    // 指标端点
    router.GET("/metrics", gin.WrapH(promhttp.Handler()))

    return router
}
```

### 完整的 main.go

```go
package main

import (
    "context"
    "log"
    "log/slog"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    // 1. 初始化日志
    logger := logger.InitLogger(os.Getenv("ENV"))

    // 2. 初始化追踪
    tp, err := tracing.InitTracer("my-service", "http://localhost:14268/api/traces")
    if err != nil {
        log.Fatal(err)
    }
    defer func() {
        if err := tp.Shutdown(context.Background()); err != nil {
            logger.Error("failed to shutdown tracer", "error", err)
        }
    }()

    // 3. 初始化数据库
    db, err := initDatabase()
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    // 4. 初始化服务
    userRepo := repository.NewUserRepositoryImpl(db)
    userService := service.NewUserApplicationService(userRepo, logger)
    userHandler := handler.NewUserHandler(userService)

    // 5. 设置路由
    router := SetupRouter(logger)

    // 6. 启动服务器
    server := &http.Server{
        Addr:    ":8080",
        Handler: router,
    }

    go func() {
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            logger.Error("server error", "error", err)
        }
    }()

    logger.Info("server started", "port", 8080)

    // 7. 优雅关闭
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    logger.Info("shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := server.Shutdown(ctx); err != nil {
        logger.Error("server forced to shutdown", "error", err)
    }

    logger.Info("server exited")
}
```

## 总结

可观测性的关键实践:
- ✅ 使用结构化日志 (slog)
- ✅ 记录业务和技术指标 (Prometheus)
- ✅ 分布式追踪 (OpenTelemetry)
- ✅ 中间件栈组合使用
- ✅ 上下文传递 (logger, tracer)
- ✅ 健康检查和指标端点
- ✅ 优雅关闭和资源清理
- ✅ 开发/生产环境配置分离
