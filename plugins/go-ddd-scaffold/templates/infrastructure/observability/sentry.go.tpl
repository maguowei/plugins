package observability

import (
	"fmt"
	"time"

	"github.com/getsentry/sentry-go"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/config"
)

// InitSentry 初始化 Sentry
// Sentry 用于错误追踪和性能监控
func InitSentry(cfg *config.SentryConfig) error {
	// 如果未配置 DSN，跳过初始化
	if cfg.DSN == "" {
		return nil
	}

	err := sentry.Init(sentry.ClientOptions{
		Dsn:         cfg.DSN,
		Environment: cfg.Environment,

		// 性能监控采样率 (0.0 - 1.0)
		TracesSampleRate: cfg.TracesSampleRate,

		// 启用性能监控
		EnableTracing: true,

		// 设置发布版本（从环境变量读取）
		// Release: os.Getenv("APP_VERSION"),

		// 在生产环境建议设置采样率，避免发送过多数据
		// SampleRate: 0.5,

		// 附加标签
		BeforeSend: func(event *sentry.Event, hint *sentry.EventHint) *sentry.Event {
			// 可以在这里过滤或修改事件
			// 例如：移除敏感信息
			return event
		},
	})

	if err != nil {
		return fmt.Errorf("failed to initialize sentry: %w", err)
	}

	return nil
}

// FlushSentry 刷新 Sentry 缓冲区
// 在应用关闭前调用，确保所有事件都被发送
func FlushSentry(timeout time.Duration) {
	sentry.Flush(timeout)
}

// CaptureError 捕获错误并发送到 Sentry
func CaptureError(err error) {
	if err != nil {
		sentry.CaptureException(err)
	}
}

// CaptureErrorWithContext 捕获错误并附加上下文信息
func CaptureErrorWithContext(err error, tags map[string]string, extra map[string]interface{}) {
	if err != nil {
		sentry.WithScope(func(scope *sentry.Scope) {
			// 添加标签
			for key, value := range tags {
				scope.SetTag(key, value)
			}

			// 添加额外信息
			for key, value := range extra {
				scope.SetExtra(key, value)
			}

			sentry.CaptureException(err)
		})
	}
}

// CaptureMessage 发送消息到 Sentry
func CaptureMessage(message string, level sentry.Level) {
	sentry.CaptureMessage(message)
}

// CapturePanic 捕获 panic 并发送到 Sentry
// 使用 defer 调用此函数
func CapturePanic() {
	if r := recover(); r != nil {
		sentry.CurrentHub().Recover(r)
		sentry.Flush(2 * time.Second)
		panic(r) // 重新 panic，让应用正常崩溃
	}
}

// RecoverWithSentry 捕获 panic 但不重新 panic
// 用于 goroutine 中的错误处理
func RecoverWithSentry() {
	if r := recover(); r != nil {
		sentry.CurrentHub().Recover(r)
		sentry.Flush(2 * time.Second)
	}
}
