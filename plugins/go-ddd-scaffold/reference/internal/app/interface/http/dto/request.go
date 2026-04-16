package dto

// CreateUserHTTPRequest HTTP 创建用户请求
type CreateUserHTTPRequest struct {
	Email string `json:"email" binding:"required,email"`
	Name  string `json:"name" binding:"required,min=1,max=100"`
}

// UpdateUserHTTPRequest HTTP 更新用户请求
type UpdateUserHTTPRequest struct {
	Email string `json:"email,omitempty" binding:"omitempty,email"`
	Name  string `json:"name,omitempty" binding:"omitempty,min=1,max=100"`
}

// ListUsersHTTPRequest HTTP 列表查询参数
type ListUsersHTTPRequest struct {
	Offset int `form:"offset" binding:"min=0"`
	Limit  int `form:"limit" binding:"min=1,max=100"`
}
