package middleware

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Recovery panic 恢复中间件
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				slog.Error("Panic recovered", "error", err)
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error": "内部服务器错误",
				})
			}
		}()
		c.Next()
	}
}
