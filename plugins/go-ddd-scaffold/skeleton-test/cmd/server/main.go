package main

import (
	"context"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"github.com/test/skeleton-test/internal/app/infrastructure/config"
	"github.com/test/skeleton-test/internal/app/infrastructure/observability"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	// 加载配置
	cfg, err := config.Load("configs/config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 初始化日志
	observability.SetupLogger(cfg.Logging.Level, cfg.Logging.Format)

	// 初始化 Sentry
	if err := observability.SetupSentry(cfg.Sentry.DSN, cfg.Sentry.Environment); err != nil {
		slog.Warn("Sentry 初始化失败", "error", err)
	}
	defer observability.FlushSentry()

	// 设置 Gin 模式
	if cfg.Server.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建路由（添加你的 handler 后替换此处）
	router := gin.New()
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
	router.GET(cfg.Prometheus.Path, observability.MetricsHandler())

	// 启动服务
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	slog.Info("服务启动", "addr", addr)

	// 优雅退出
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	go func() {
		if err := router.Run(addr); err != nil {
			log.Fatalf("服务启动失败: %v", err)
		}
	}()

	<-ctx.Done()
	slog.Info("收到退出信号，正在关闭...")
}
