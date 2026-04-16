package observability

import (
	"log/slog"
	"time"

	"github.com/getsentry/sentry-go"
	sentrygin "github.com/getsentry/sentry-go/gin"
	"github.com/gin-gonic/gin"
)

// SetupSentry 初始化 Sentry
func SetupSentry(dsn, environment string) error {
	if dsn == "" {
		slog.Info("Sentry DSN 为空，跳过初始化")
		return nil
	}
	return sentry.Init(sentry.ClientOptions{
		Dsn:         dsn,
		Environment: environment,
	})
}

// SentryMiddleware 返回 Sentry Gin 中间件
func SentryMiddleware() gin.HandlerFunc {
	return sentrygin.New(sentrygin.Options{Repanic: true})
}

// FlushSentry 刷新 Sentry 缓冲
func FlushSentry() {
	sentry.Flush(2 * time.Second)
}
