package middleware

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/observability"
)

// Metrics Prometheus 指标中间件
// 记录每个 HTTP 请求的指标（请求次数、延迟、大小等）
func Metrics() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 记录请求开始时间
		startTime := time.Now()

		// 记录请求大小
		requestSize := computeRequestSize(c.Request)

		// 处理请求
		c.Next()

		// 计算请求耗时
		duration := time.Since(startTime).Seconds()

		// 获取响应大小
		responseSize := c.Writer.Size()

		// 获取请求信息
		method := c.Request.Method
		path := c.FullPath() // 使用路由模板而不是实际路径，避免高基数问题
		if path == "" {
			path = c.Request.URL.Path
		}
		status := strconv.Itoa(c.Writer.Status())

		// 记录 HTTP 请求总数和延迟
		observability.HTTPRequestsTotal.WithLabelValues(method, path, status).Inc()
		observability.HTTPRequestDuration.WithLabelValues(method, path).Observe(duration)

		// 记录请求和响应大小
		observability.HTTPRequestSize.WithLabelValues(method, path).Observe(float64(requestSize))
		if responseSize > 0 {
			observability.HTTPResponseSize.WithLabelValues(method, path).Observe(float64(responseSize))
		}
	}
}

// computeRequestSize 计算请求大小
func computeRequestSize(r interface{}) int64 {
	// 这是一个简化的实现
	// 更精确的实现需要考虑请求头、URL 等
	// 这里只计算 Content-Length

	// 类型断言
	type requestWithContentLength interface {
		ContentLength() int64
	}

	if req, ok := r.(requestWithContentLength); ok {
		return req.ContentLength()
	}

	// 如果无法获取 Content-Length，返回 0
	return 0
}

// MetricsWithConfig 带配置的 Metrics 中间件
type MetricsConfig struct {
	// SkipPaths 跳过这些路径的指标记录
	// 例如：健康检查端点不需要记录指标
	SkipPaths []string

	// Subsystem Prometheus 指标的子系统名称
	// 默认为空，可以设置为应用名称
	Subsystem string
}

// MetricsWithConfigFunc 创建带配置的 Metrics 中间件
func MetricsWithConfigFunc(config MetricsConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 检查是否跳过该路径
		path := c.Request.URL.Path
		for _, skipPath := range config.SkipPaths {
			if path == skipPath {
				c.Next()
				return
			}
		}

		// 使用默认的 Metrics 中间件
		Metrics()(c)
	}
}
