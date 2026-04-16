package http

import (
	"github.com/gin-gonic/gin"
	"github.com/example/my-service/internal/app/infrastructure/observability"
	"github.com/example/my-service/internal/app/interface/http/handler"
	"github.com/example/my-service/internal/app/interface/http/middleware"
)

// NewRouter 创建路由
func NewRouter(userHandler *handler.UserHandler, metricsPath string) *gin.Engine {
	r := gin.New()

	// 全局中间件
	r.Use(middleware.Recovery())
	r.Use(middleware.Logger())
	r.Use(middleware.CORS())
	r.Use(observability.MetricsMiddleware())

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Prometheus 指标
	r.GET(metricsPath, observability.MetricsHandler())

	// API v1
	v1 := r.Group("/api/v1")
	{
		users := v1.Group("/users")
		{
			users.POST("", userHandler.Create)
			users.GET("", userHandler.List)
			users.GET("/:id", userHandler.Get)
			users.PUT("/:id", userHandler.Update)
			users.DELETE("/:id", userHandler.Delete)
		}
	}

	return r
}
