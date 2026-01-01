package middleware

import (
	"log/slog"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Logger 日志中间件
// 记录每个 HTTP 请求的详细信息
func Logger(logger *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 生成请求 ID
		requestID := uuid.New().String()
		c.Set("request_id", requestID)

		// 记录请求开始时间
		startTime := time.Now()

		// 记录请求信息
		logger.Info("HTTP request started",
			slog.String("request_id", requestID),
			slog.String("method", c.Request.Method),
			slog.String("path", c.Request.URL.Path),
			slog.String("query", c.Request.URL.RawQuery),
			slog.String("client_ip", c.ClientIP()),
			slog.String("user_agent", c.Request.UserAgent()),
		)

		// 处理请求
		c.Next()

		// 计算请求耗时
		duration := time.Since(startTime)

		// 记录响应信息
		logger.Info("HTTP request completed",
			slog.String("request_id", requestID),
			slog.String("method", c.Request.Method),
			slog.String("path", c.Request.URL.Path),
			slog.Int("status", c.Writer.Status()),
			slog.Int("size", c.Writer.Size()),
			slog.Duration("duration", duration),
		)

		// 如果有错误，记录错误信息
		if len(c.Errors) > 0 {
			for _, err := range c.Errors {
				logger.Error("HTTP request error",
					slog.String("request_id", requestID),
					slog.String("error", err.Error()),
				)
			}
		}
	}
}

// GetRequestID 从上下文中获取请求 ID
// 可以在 handler 中使用此函数获取请求 ID
func GetRequestID(c *gin.Context) string {
	if requestID, exists := c.Get("request_id"); exists {
		if id, ok := requestID.(string); ok {
			return id
		}
	}
	return ""
}
