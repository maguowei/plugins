package observability

import (
	"log/slog"
	"os"

	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/config"
)

// InitLogger 初始化日志器
// 使用 Go 1.21+ 标准库的 slog
func InitLogger(cfg *config.LoggingConfig) *slog.Logger {
	// 解析日志级别
	level := parseLogLevel(cfg.Level)

	// 创建 Handler
	var handler slog.Handler
	opts := &slog.HandlerOptions{
		Level: level,
		// 添加源码位置信息（文件名和行号）
		AddSource: true,
	}

	switch cfg.Format {
	case "json":
		handler = slog.NewJSONHandler(os.Stdout, opts)
	default:
		handler = slog.NewTextHandler(os.Stdout, opts)
	}

	// 创建 Logger
	logger := slog.New(handler)

	// 设置为默认 logger
	slog.SetDefault(logger)

	return logger
}

// parseLogLevel 解析日志级别
func parseLogLevel(level string) slog.Level {
	switch level {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

// LoggerMiddleware 日志中间件辅助函数
// 用于在日志中添加结构化上下文信息
func WithRequestID(logger *slog.Logger, requestID string) *slog.Logger {
	return logger.With(slog.String("request_id", requestID))
}

// WithUserID 添加用户 ID 到日志上下文
func WithUserID(logger *slog.Logger, userID string) *slog.Logger {
	return logger.With(slog.String("user_id", userID))
}

// WithError 添加错误信息到日志
func WithError(logger *slog.Logger, err error) *slog.Logger {
	return logger.With(slog.Any("error", err))
}
