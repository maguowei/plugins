package http

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"{{ .GoModule }}/{{ .Paths.Application }}/{{ .Aggregate.Name }}/service"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/config"
	"{{ .GoModule }}/{{ .Paths.Interface }}/http/handler"
	"{{ .GoModule }}/{{ .Paths.Interface }}/http/middleware"
)

// Router HTTP 路由器
type Router struct {
	engine *gin.Engine
	config *config.Config
	logger *slog.Logger
}

// NewRouter 创建 HTTP 路由器
func NewRouter(
	cfg *config.Config,
	logger *slog.Logger,
	{{- if .IncludeExamples }}
	{{ .Aggregate.Name }}Service *service.{{ .Entity.Name }}ApplicationService,
	{{- end }}
) *Router {
	// 设置 Gin 模式
	gin.SetMode(cfg.Server.Mode)

	// 创建 Gin 引擎
	engine := gin.New()

	// 注册全局中间件
	engine.Use(middleware.Recovery(logger))       // Panic 恢复
	engine.Use(middleware.Logger(logger))         // 日志记录
	engine.Use(middleware.CORS())                 // 跨域支持
	engine.Use(middleware.Metrics())              // Prometheus 指标

	router := &Router{
		engine: engine,
		config: cfg,
		logger: logger,
	}

	// 注册路由
	router.registerRoutes(
		{{- if .IncludeExamples }}
		{{ .Aggregate.Name }}Service,
		{{- end }}
	)

	return router
}

// registerRoutes 注册所有路由
func (r *Router) registerRoutes(
	{{- if .IncludeExamples }}
	{{ .Aggregate.Name }}Service *service.{{ .Entity.Name }}ApplicationService,
	{{- end }}
) {
	// 健康检查端点
	r.engine.GET("/health", r.healthCheck)
	r.engine.GET("/ping", r.ping)

	// Prometheus metrics 端点
	if r.config.Prometheus.Enabled {
		r.engine.GET(r.config.Prometheus.Path, gin.WrapH(promhttp.Handler()))
	}

	{{- if .IncludeExamples }}
	// API 路由组
	api := r.engine.Group("/api")
	{
		// v1 版本路由
		v1 := api.Group("/v1")
		{
			// {{ .Entity.NameCN }}路由
			{{ .Aggregate.Name }}Handler := handler.New{{ .Entity.Name }}Handler({{ .Aggregate.Name }}Service)
			{{ .Aggregate.Name }}Group := v1.Group("/{{ .Aggregate.NamePlural }}")
			{
				{{ .Aggregate.Name }}Group.POST("/", {{ .Aggregate.Name }}Handler.Create{{ .Entity.Name }})
				{{ .Aggregate.Name }}Group.GET("/:id", {{ .Aggregate.Name }}Handler.Get{{ .Entity.Name }})
				{{ .Aggregate.Name }}Group.PUT("/:id", {{ .Aggregate.Name }}Handler.Update{{ .Entity.Name }})
				{{ .Aggregate.Name }}Group.DELETE("/:id", {{ .Aggregate.Name }}Handler.Delete{{ .Entity.Name }})
				{{ .Aggregate.Name }}Group.GET("/", {{ .Aggregate.Name }}Handler.List{{ .Entity.NamePlural }})
			}
		}
	}
	{{- end }}

	// 404 处理
	r.engine.NoRoute(r.notFound)
}

// healthCheck 健康检查
func (r *Router) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"service": "{{ .Project.Name }}",
	})
}

// ping Ping 端点
func (r *Router) ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "pong",
	})
}

// notFound 404 处理
func (r *Router) notFound(c *gin.Context) {
	c.JSON(http.StatusNotFound, gin.H{
		"error": "not_found",
		"message": "请求的资源不存在",
	})
}

// Engine 获取 Gin 引擎
func (r *Router) Engine() *gin.Engine {
	return r.engine
}

// Run 启动 HTTP 服务器
func (r *Router) Run() error {
	addr := ":" + r.config.Server.Port
	r.logger.Info("Starting HTTP server", slog.String("address", addr))
	return r.engine.Run(addr)
}
