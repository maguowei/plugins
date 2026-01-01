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
	"time"

	_ "github.com/go-sql-driver/mysql" // MySQL driver
	_ "github.com/mattn/go-sqlite3"    // SQLite driver

	"{{ .GoModule }}/{{ .Paths.Application }}/{{ .Aggregate.Name }}/service"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/config"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/event"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/observability"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/repository"
	httpserver "{{ .GoModule }}/{{ .Paths.Interface }}/http"
	"{{ .GoModule }}/internal/ent"
)

func main() {
	// 1. 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 2. 初始化日志
	logger := observability.InitLogger(&cfg.Logging)
	logger.Info("Starting {{ .Project.Name }} server")

	// 3. 初始化 Sentry（错误追踪）
	if err := observability.InitSentry(&cfg.Sentry); err != nil {
		logger.Warn("Failed to initialize Sentry", slog.Any("error", err))
	}
	defer observability.FlushSentry(2 * time.Second)

	// 4. 初始化 Prometheus 指标
	observability.InitMetrics()

	// 5. 初始化数据库连接
	client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
	if err != nil {
		logger.Error("Failed to connect to database", slog.Any("error", err))
		observability.CaptureError(err)
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer client.Close()

	// 运行数据库迁移
	if err := client.Schema.Create(context.Background()); err != nil {
		logger.Error("Failed to run database migrations", slog.Any("error", err))
		observability.CaptureError(err)
		log.Fatalf("Failed to run database migrations: %v", err)
	}
	logger.Info("Database migrations completed successfully")

	{{- if .IncludeExamples }}
	// 6. 初始化事件总线
	eventBus := event.NewMemoryEventBus()

	// 7. 依赖注入：组装所有组件
	// Repository 层
	{{ .Aggregate.Name }}Repo := repository.New{{ .Entity.Name }}Repository(client)

	// Application Service 层
	{{ .Aggregate.Name }}Service := service.New{{ .Entity.Name }}ApplicationService(
		{{ .Aggregate.Name }}Repo,
		eventBus,
		logger,
	)
	{{- end }}

	// 8. 创建 HTTP 路由器
	router := httpserver.NewRouter(
		cfg,
		logger,
		{{- if .IncludeExamples }}
		{{ .Aggregate.Name }}Service,
		{{- end }}
	)

	// 9. 创建 HTTP 服务器
	srv := &http.Server{
		Addr:    ":" + cfg.Server.Port,
		Handler: router.Engine(),
	}

	// 10. 启动服务器（非阻塞）
	go func() {
		logger.Info(
			"HTTP server started",
			slog.String("address", srv.Addr),
			slog.String("mode", cfg.Server.Mode),
		)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("Failed to start HTTP server", slog.Any("error", err))
			observability.CaptureError(err)
			log.Fatalf("Failed to start HTTP server: %v", err)
		}
	}()

	// 11. 优雅关闭
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// 设置关闭超时时间
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// 关闭 HTTP 服务器
	if err := srv.Shutdown(ctx); err != nil {
		logger.Error("Server forced to shutdown", slog.Any("error", err))
		observability.CaptureError(err)
	}

	logger.Info("Server exited successfully")
}

func init() {
	// 设置时区
	loc, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		loc = time.UTC
	}
	time.Local = loc

	// 设置日志前缀
	log.SetPrefix("[{{ .Project.Name }}] ")
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}
