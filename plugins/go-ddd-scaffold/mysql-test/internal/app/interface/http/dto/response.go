package dto

import "github.com/gin-gonic/gin"

// ErrorResponse 统一错误响应
type ErrorResponse struct {
	Error string `json:"error"`
}

// NewErrorResponse 创建错误响应
func NewErrorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
