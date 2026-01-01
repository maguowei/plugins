package middleware

import (
	"github.com/gin-gonic/gin"
)

// CORS 跨域资源共享中间件
// 允许前端应用从不同域访问 API
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 设置 CORS 响应头
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		// 处理 OPTIONS 预检请求
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		// 继续处理请求
		c.Next()
	}
}

// CORSWithConfig 带配置的 CORS 中间件
// 允许自定义允许的域、方法和头部
type CORSConfig struct {
	AllowOrigins     []string // 允许的源，例如 ["https://example.com"]
	AllowMethods     []string // 允许的方法，例如 ["GET", "POST"]
	AllowHeaders     []string // 允许的头部
	ExposeHeaders    []string // 暴露的头部
	AllowCredentials bool     // 是否允许携带凭证
	MaxAge           int      // 预检请求的缓存时间（秒）
}

// CORSWithConfig 创建带配置的 CORS 中间件
func CORSWithConfigFunc(config CORSConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// 检查是否允许该源
		allowed := false
		if len(config.AllowOrigins) == 0 || contains(config.AllowOrigins, "*") {
			allowed = true
			c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		} else if contains(config.AllowOrigins, origin) {
			allowed = true
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		}

		if !allowed {
			c.AbortWithStatus(403)
			return
		}

		// 设置其他 CORS 头部
		if config.AllowCredentials {
			c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		}

		if len(config.AllowMethods) > 0 {
			methods := ""
			for i, method := range config.AllowMethods {
				if i > 0 {
					methods += ", "
				}
				methods += method
			}
			c.Writer.Header().Set("Access-Control-Allow-Methods", methods)
		}

		if len(config.AllowHeaders) > 0 {
			headers := ""
			for i, header := range config.AllowHeaders {
				if i > 0 {
					headers += ", "
				}
				headers += header
			}
			c.Writer.Header().Set("Access-Control-Allow-Headers", headers)
		}

		if len(config.ExposeHeaders) > 0 {
			headers := ""
			for i, header := range config.ExposeHeaders {
				if i > 0 {
					headers += ", "
				}
				headers += header
			}
			c.Writer.Header().Set("Access-Control-Expose-Headers", headers)
		}

		if config.MaxAge > 0 {
			c.Writer.Header().Set("Access-Control-Max-Age", string(rune(config.MaxAge)))
		}

		// 处理 OPTIONS 预检请求
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		// 继续处理请求
		c.Next()
	}
}

// contains 检查字符串切片是否包含指定字符串
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
