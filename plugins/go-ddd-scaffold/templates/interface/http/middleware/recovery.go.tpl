package middleware

import (
	"log/slog"
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/observability"
)

// Recovery Panic 恢复中间件
// 捕获 panic 并返回 500 错误，同时将错误发送到 Sentry
func Recovery(logger *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// 获取堆栈信息
				stack := debug.Stack()

				// 记录 panic 信息到日志
				logger.Error("Panic recovered",
					slog.String("request_id", GetRequestID(c)),
					slog.String("method", c.Request.Method),
					slog.String("path", c.Request.URL.Path),
					slog.Any("panic", err),
					slog.String("stack", string(stack)),
				)

				// 发送错误到 Sentry
				// 注意：CapturePanic 会重新 panic，这里我们不希望这样
				// 所以使用 RecoverWithSentry 代替
				observability.RecoverWithSentry()

				// 返回 500 错误响应
				c.JSON(http.StatusInternalServerError, gin.H{
					"error":   "internal_server_error",
					"message": "服务器内部错误，请稍后重试",
				})

				// 中止请求处理
				c.Abort()
			}
		}()

		// 继续处理请求
		c.Next()
	}
}

// RecoveryWithSentry Panic 恢复中间件（带 Sentry 集成）
// 功能与 Recovery 相同，但专门用于 Sentry 集成的场景
// 如果不需要 Sentry，可以使用 Gin 默认的 Recovery 中间件
func RecoveryWithSentry(logger *slog.Logger) gin.HandlerFunc {
	return Recovery(logger)
}
