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
	"{{.go_module}}/internal/app/application/service"
	domainservice "{{.go_module}}/internal/app/domain/service"
	"{{.go_module}}/internal/app/infrastructure/config"
	infraevent "{{.go_module}}/internal/app/infrastructure/event"
	"{{.go_module}}/internal/app/infrastructure/observability"
	infrarepo "{{.go_module}}/internal/app/infrastructure/repository"
	apphttp "{{.go_module}}/internal/app/interface/http"
	"{{.go_module}}/internal/app/interface/http/handler"
	"{{.go_module}}/internal/ent"

	{{if eq .database "mysql"}}_ "github.com/go-sql-driver/mysql"{{else}}_ "github.com/mattn/go-sqlite3"{{end}}
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
