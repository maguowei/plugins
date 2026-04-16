package main

import (
	"context"
	"fmt"
	"log"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"github.com/example/my-service/internal/app/application/service"
	domainservice "github.com/example/my-service/internal/app/domain/service"
	"github.com/example/my-service/internal/app/infrastructure/config"
	infraevent "github.com/example/my-service/internal/app/infrastructure/event"
	"github.com/example/my-service/internal/app/infrastructure/observability"
	infrarepo "github.com/example/my-service/internal/app/infrastructure/repository"
	apphttp "github.com/example/my-service/internal/app/interface/http"
	"github.com/example/my-service/internal/app/interface/http/handler"
	"github.com/example/my-service/internal/ent"

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

	// 初始化数据库
	client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
	if err != nil {
		log.Fatalf("数据库连接失败: %v", err)
	}
	defer client.Close()

	// 设置 Gin 模式
	if cfg.Server.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 依赖注入
	userRepo := infrarepo.NewEntUserRepository(client)
	eventBus := infraevent.NewBus()
	domainSvc := domainservice.NewUserService(userRepo)
	appSvc := service.NewUserApplicationService(userRepo, domainSvc, eventBus)
	userHandler := handler.NewUserHandler(appSvc)

	// 创建路由
	router := apphttp.NewRouter(userHandler, cfg.Prometheus.Path)

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
