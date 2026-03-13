---
name: Go Tech Stack Integration
description: 用户问"Gin 怎么配置路由"、"Ent 怎么连数据库"、"Viper 怎么读配置"、"slog 怎么初始化"、"Prometheus 指标怎么加"、"Sentry 怎么集成"、"Go Web 技术栈怎么搭建"时触发。涵盖 Gin+Ent+Viper+slog+Prometheus+Sentry 的集成方式。
version: 0.2.0
---

# Go 技术栈集成指南

## 概述

集成 Gin + Ent + Viper + slog + Prometheus + Sentry 构建生产就绪的 Go Web 应用。

## 技术栈组成

| 组件 | 用途 | 包 |
|-----|------|-----|
| Gin | HTTP Web 框架 | `github.com/gin-gonic/gin` |
| Ent | 实体框架 (ORM) | `entgo.io/ent` |
| Viper | 配置管理 | `github.com/spf13/viper` |
| slog | 结构化日志 (Go 1.21+) | `log/slog` |
| Prometheus | 指标采集 | `github.com/prometheus/client_golang` |
| Sentry | 错误监控和追踪 | `github.com/getsentry/sentry-go` |

## 1. Gin Web 框架

### 路由配置

```go
// internal/app/interface/http/router.go
func NewRouter(userHandler *handler.UserHandler) *gin.Engine {
    router := gin.New()

    router.Use(middleware.Logger())
    router.Use(middleware.Recovery())
    router.Use(middleware.CORS())

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

    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    return router
}
```

### Handler 模式

```go
// internal/app/interface/http/handler/user_handler.go
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

## 2. Ent ORM

### Schema 定义

```go
// internal/ent/schema/user.go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
    "github.com/google/uuid"
)

type User struct { ent.Schema }

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

### 数据库连接

```go
func initDB(cfg *config.Config) *ent.Client {
    client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
    if err != nil {
        log.Fatal(err)
    }
    if err := client.Schema.Create(context.Background()); err != nil {
        log.Fatal(err)
    }
    return client
}
```

Repository 实现模式详见 ddd-layered-architecture skill 的 Infrastructure Layer 部分。

## 3. Viper 配置管理

```go
// internal/app/infrastructure/config/config.go
type Config struct {
    Server     ServerConfig
    Database   DatabaseConfig
    Logging    LoggingConfig
    Sentry     SentryConfig
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

```go
// internal/app/infrastructure/observability/logger.go
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
    case "debug": return slog.LevelDebug
    case "warn":  return slog.LevelWarn
    case "error": return slog.LevelError
    default:      return slog.LevelInfo
    }
}
```

**使用示例**:

```go
logger.Info("creating user", slog.String("email", req.Email))
logger.Error("failed to save", "error", err)
```

## 5. Prometheus 监控

### Metrics 定义

```go
// internal/app/infrastructure/observability/metrics.go
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
```

### Metrics 中间件

```go
// internal/app/interface/http/middleware/metrics.go
func Metrics() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        c.Next()
        duration := time.Since(start).Seconds()
        status := strconv.Itoa(c.Writer.Status())

        observability.HTTPRequestsTotal.WithLabelValues(
            c.Request.Method, c.FullPath(), status,
        ).Inc()
        observability.HTTPRequestDuration.WithLabelValues(
            c.Request.Method, c.FullPath(),
        ).Observe(duration)
    }
}
```

## 6. Sentry 错误追踪

### 初始化

```go
// internal/app/infrastructure/observability/sentry.go
func InitSentry(cfg *config.SentryConfig) error {
    return sentry.Init(sentry.ClientOptions{
        Dsn:              cfg.DSN,
        Environment:      cfg.Environment,
        TracesSampleRate: 1.0,
    })
}
```

### Sentry 中间件

```go
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
    }
}
```

## 完整集成 (main.go)

```go
func main() {
    cfg, _ := config.Load()
    logger := observability.InitLogger(&cfg.Logging)
    observability.InitSentry(&cfg.Sentry)
    observability.InitMetrics()

    dbClient := initDB(cfg)
    defer dbClient.Close()

    userHandler := initializeUserHandler(dbClient, logger)
    router := http.NewRouter(userHandler)

    logger.Info("starting server", "port", cfg.Server.Port)
    router.Run(":" + cfg.Server.Port)
}
```

## 最佳实践

1. **配置分离**: 敏感配置通过环境变量
2. **结构化日志**: 使用 slog 记录上下文信息
3. **监控覆盖**: HTTP 请求、数据库查询、业务指标
4. **错误追踪**: panic 和 error 上报 Sentry
5. **健康检查**: 提供 `/health` 端点
6. **优雅关机**: 处理 SIGTERM 信号
