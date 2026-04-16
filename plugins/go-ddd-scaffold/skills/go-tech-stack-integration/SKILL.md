---
name: Go Tech Stack Integration
description: 用户问"Gin 怎么配置路由"、"Ent 怎么连数据库"、"Viper 怎么读配置"、"slog 怎么初始化"、"Prometheus 指标怎么加"、"Sentry 怎么集成"、"Go Web 技术栈怎么搭建"时触发。涵盖 Gin+Ent+Viper+slog+Prometheus+Sentry 的集成方式。
version: 0.3.0
---

# Go 技术栈集成指南

## 技术栈组成

| 组件 | 用途 | 包 |
|-----|------|-----|
| Gin | HTTP Web 框架 | `github.com/gin-gonic/gin` |
| Ent | 实体框架 (ORM) | `entgo.io/ent` |
| Viper | 配置管理 | `github.com/spf13/viper` |
| slog | 结构化日志 (Go 1.21+) | `log/slog` |
| Prometheus | 指标采集 | `github.com/prometheus/client_golang` |
| Sentry | 错误监控和追踪 | `github.com/getsentry/sentry-go` |

## Gin 要点

- 路由分组: `v1 := router.Group("/api/v1")`
- 中间件: Logger, Recovery, CORS, Auth, Metrics, RateLimit
- 参数验证: `binding:"required,email"` 结构体标签
- Handler 调用 Application Service, 不含业务逻辑

## Ent 要点

- Schema 定义字段、边 (Edges)、验证器
- `OnConflict().UpdateNewValues()` 实现 Upsert
- `WithItems()` 预加载关联 (避免 N+1)
- 事务: `client.Tx(ctx)` + `tx.Commit()`

## Viper 配置

```yaml
server: { port: 8080, mode: debug }
database: { driver: mysql, dsn: "..." }
logging: { level: info, format: json }
sentry: { dsn: "", environment: development }
prometheus: { enabled: true, path: /metrics }
```

## slog 日志

```go
logger.Info("creating user", slog.String("email", req.Email))
logger.Error("failed to save", "error", err)
```

## Prometheus 指标

```go
var HTTPRequestsTotal = prometheus.NewCounterVec(...)
var HTTPRequestDuration = prometheus.NewHistogramVec(...)
// 路由: router.GET("/metrics", gin.WrapH(promhttp.Handler()))
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

1. 配置分离 -- 敏感配置通过环境变量
2. 结构化日志 -- slog 记录上下文信息
3. 监控覆盖 -- HTTP 请求、数据库查询、业务指标
4. 错误追踪 -- panic 和 error 上报 Sentry
5. 健康检查 -- `/health` 端点
6. 优雅关机 -- 处理 SIGTERM 信号

## 参考文档

- `references/gin-best-practices.md` -- 路由组织、中间件设计、参数验证、文件上传、测试
- `references/ent-advanced.md` -- Schema 定义、Edges、查询、事务、Hooks、迁移、DDD 集成
