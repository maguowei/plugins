---
name: Go Tech Stack Integration
description: This skill should be used when the user asks about "Gin framework", "Ent ORM", "Viper configuration", "slog logging", "Prometheus metrics", "Sentry integration", "how to integrate Gin with Ent", "Go observability setup", or needs guidance on integrating the complete Go web technology stack.
version: 0.1.0
---

# Go 技术栈集成指南

## 概述

集成 Gin + Ent + Viper + slog + Prometheus + Sentry 构建生产就绪的 Go Web 应用。

## 技术栈组成

- **Web 框架**: Gin - 高性能 HTTP Web 框架
- **ORM**: Ent - Facebook 开源的实体框架
- **配置**: Viper - 配置管理
- **日志**: slog - Go 1.21+ 官方结构化日志
- **监控**: Prometheus - 指标采集
- **错误追踪**: Sentry - 错误监控和追踪

## 1. Gin Web 框架集成

### 基础设置

```go
// internal/app/interface/http/router.go
package http

import (
    "github.com/gin-gonic/gin"
    "myproject/internal/app/interface/http/handler"
    "myproject/internal/app/interface/http/middleware"
)

func NewRouter(userHandler *handler.UserHandler) *gin.Engine {
    router := gin.New()

    // 中间件
    router.Use(middleware.Logger())
    router.Use(middleware.Recovery())
    router.Use(middleware.CORS())

    // API 路由
    v1 := router.Group("/api/v1")
    {
        users := v1.Group("/users")
        {
            users.POST("", userHandler.CreateUser)
            users.GET("/:id", userHandler.GetUser)
            users.GET("", userHandler.ListUsers)
            users.PUT("/:id", userHandler.UpdateUser)
            users.DELETE("/:id", userHandler.DeleteUser)
        }
    }

    // 健康检查
    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    return router
}
```

### Handler 实现

```go
// internal/app/interface/http/handler/user_handler.go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
)

type UserHandler struct {
    appService *service.UserApplicationService
}

func (h *UserHandler) CreateUser(c *gin.Context) {
    var req dto.CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    resp, err := h.appService.CreateUser(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, resp)
}
```

## 2. Ent ORM 集成

### Schema 定义

```go
// pkg/ent/schema/user.go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "github.com/google/uuid"
)

type User struct {
    ent.Schema
}

func (User) Fields() []ent.Field {
    return []ent.Field{
        field.UUID("id", uuid.UUID{}).Default(uuid.New),
        field.String("email").Unique(),
        field.String("name"),
        field.Time("created_at").Immutable().Default(time.Now),
        field.Time("updated_at").Default(time.Now).UpdateDefault(time.Now),
    }
}
```

### Repository 实现

```go
// internal/app/infrastructure/repository/user_repository_impl.go
package repository

import (
    "context"
    "myproject/internal/app/domain/user/entity"
    "myproject/pkg/ent"
)

type EntUserRepository struct {
    client *ent.Client
}

func NewEntUserRepository(client *ent.Client) *EntUserRepository {
    return &EntUserRepository{client: client}
}

func (r *EntUserRepository) Save(ctx context.Context, user *entity.User) error {
    return r.client.User.
        Create().
        SetID(user.ID()).
        SetEmail(user.Email().Value()).
        SetName(user.Name()).
        OnConflict().
        UpdateNewValues().
        Exec(ctx)
}

func (r *EntUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    u, err := r.client.User.Get(ctx, id)
    if err != nil {
        return nil, err
    }
    return r.toDomain(u), nil
}
```

### 数据库连接

```go
// main.go
import (
    "myproject/pkg/ent"
    _ "github.com/go-sql-driver/mysql"
)

func initDB(cfg *config.Config) *ent.Client {
    client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
    if err != nil {
        log.Fatal(err)
    }

    // 自动迁移
    if err := client.Schema.Create(context.Background()); err != nil {
        log.Fatal(err)
    }

    return client
}
```

## 3. Viper 配置管理

### 配置结构

```go
// internal/app/infrastructure/config/config.go
package config

import (
    "github.com/spf13/viper"
)

type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Logging  LoggingConfig
    Sentry   SentryConfig
    Prometheus PrometheusConfig
}

type ServerConfig struct {
    Port string
    Mode string
}

type DatabaseConfig struct {
    Driver string
    DSN    string
}

func Load() (*Config, error) {
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    viper.AddConfigPath("./configs")
    viper.AddConfigPath(".")

    // 环境变量优先级更高
    viper.AutomaticEnv()

    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    var cfg Config
    if err := viper.Unmarshal(&cfg); err != nil {
        return nil, err
    }

    return &cfg, nil
}
```

### 配置文件

```yaml
# configs/config.yaml
server:
  port: 8080
  mode: debug

database:
  driver: mysql
  dsn: "user:password@tcp(localhost:3306)/dbname?parseTime=true"

logging:
  level: info
  format: json

sentry:
  dsn: ""
  environment: development

prometheus:
  enabled: true
  path: /metrics
```

## 4. slog 结构化日志

### Logger 初始化

```go
// internal/app/infrastructure/observability/logger.go
package observability

import (
    "log/slog"
    "os"
)

func InitLogger(cfg *config.LoggingConfig) *slog.Logger {
    var handler slog.Handler

    if cfg.Format == "json" {
        handler = slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
            Level: parseLevel(cfg.Level),
        })
    } else {
        handler = slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
            Level: parseLevel(cfg.Level),
        })
    }

    return slog.New(handler)
}

func parseLevel(level string) slog.Level {
    switch level {
    case "debug":
        return slog.LevelDebug
    case "info":
        return slog.LevelInfo
    case "warn":
        return slog.LevelWarn
    case "error":
        return slog.LevelError
    default:
        return slog.LevelInfo
    }
}
```

### 使用示例

```go
func (s *UserApplicationService) CreateUser(ctx context.Context, req CreateUserRequest) (*UserResponse, error) {
    s.logger.Info("creating user",
        slog.String("email", req.Email),
        slog.String("name", req.Name),
    )

    // 业务逻辑

    s.logger.Info("user created successfully",
        slog.String("user_id", user.ID().String()),
    )

    return resp, nil
}
```

## 5. Prometheus 监控

### Metrics 初始化

```go
// internal/app/infrastructure/observability/metrics.go
package observability

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    HTTPRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    HTTPRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request latencies in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )
)

func InitMetrics() {
    prometheus.MustRegister(HTTPRequestsTotal)
    prometheus.MustRegister(HTTPRequestDuration)
}

func MetricsHandler() gin.HandlerFunc {
    return gin.WrapH(promhttp.Handler())
}
```

### Middleware

```go
// internal/app/interface/http/middleware/metrics.go
package middleware

func Metrics() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()

        c.Next()

        duration := time.Since(start).Seconds()
        status := strconv.Itoa(c.Writer.Status())

        observability.HTTPRequestsTotal.WithLabelValues(
            c.Request.Method,
            c.FullPath(),
            status,
        ).Inc()

        observability.HTTPRequestDuration.WithLabelValues(
            c.Request.Method,
            c.FullPath(),
        ).Observe(duration)
    }
}
```

## 6. Sentry 错误追踪

### Sentry 初始化

```go
// internal/app/infrastructure/observability/sentry.go
package observability

import (
    "github.com/getsentry/sentry-go"
    "time"
)

func InitSentry(cfg *config.SentryConfig) error {
    return sentry.Init(sentry.ClientOptions{
        Dsn:         cfg.DSN,
        Environment: cfg.Environment,
        TracesSampleRate: 1.0,
    })
}

func CapturePanic() {
    if r := recover(); r != nil {
        sentry.CurrentHub().Recover(r)
        sentry.Flush(2 * time.Second)
        panic(r)
    }
}
```

### Middleware

```go
// internal/app/interface/http/middleware/sentry.go
package middleware

func SentryMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        defer func() {
            if r := recover(); r != nil {
                sentry.CurrentHub().Recover(r)
                c.AbortWithStatus(500)
            }
        }()

        hub := sentry.CurrentHub().Clone()
        hub.Scope().SetRequest(c.Request)
        c.Set("sentry_hub", hub)

        c.Next()

        if len(c.Errors) > 0 {
            for _, err := range c.Errors {
                hub.CaptureException(err)
            }
        }
    }
}
```

## 完整集成示例

### main.go

```go
package main

import (
    "context"
    "log"
    "myproject/internal/app/infrastructure/config"
    "myproject/internal/app/infrastructure/observability"
    "myproject/internal/app/interface/http"
)

func main() {
    // 1. 加载配置
    cfg, err := config.Load()
    if err != nil {
        log.Fatal(err)
    }

    // 2. 初始化日志
    logger := observability.InitLogger(&cfg.Logging)

    // 3. 初始化 Sentry
    if err := observability.InitSentry(&cfg.Sentry); err != nil {
        logger.Error("failed to init sentry", "error", err)
    }

    // 4. 初始化 Prometheus
    observability.InitMetrics()

    // 5. 初始化数据库
    dbClient := initDB(cfg)
    defer dbClient.Close()

    // 6. 初始化依赖注入
    userHandler := initializeUserHandler(dbClient, logger)

    // 7. 创建路由
    router := http.NewRouter(userHandler)

    // 8. 启动服务器
    logger.Info("starting server", "port", cfg.Server.Port)
    if err := router.Run(":" + cfg.Server.Port); err != nil {
        logger.Error("server failed", "error", err)
    }
}
```

## 最佳实践

1. **配置分离**: 敏感配置通过环境变量
2. **结构化日志**: 使用 slog 记录结构化日志
3. **监控覆盖**: HTTP 请求、数据库查询、业务指标
4. **错误追踪**: 所有 panic 和 error 上报 Sentry
5. **健康检查**: 提供 /health 端点
6. **优雅关机**: 处理 SIGTERM 信号

## 额外资源

详细集成指南:
- **`references/gin-best-practices.md`** - Gin 最佳实践
- **`references/ent-advanced.md`** - Ent 高级用法
- **`references/observability-setup.md`** - 完整可观测性配置
