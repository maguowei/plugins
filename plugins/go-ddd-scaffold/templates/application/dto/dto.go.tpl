package dto

import (
	"time"

	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/entity"
)

// CreateUserRequest 创建用户请求 DTO
type CreateUserRequest struct {
{{- range .ApplicationDto.Requests.0.Fields }}
	{{ .Name }} {{ .Type }} `json:"{{ .JsonTag }}" binding:"{{ .Binding }}"` // {{ .Comment }}
{{- end }}
}

// UpdateUserRequest 更新用户请求 DTO
type UpdateUserRequest struct {
{{- range .ApplicationDto.Requests.1.Fields }}
	{{ .Name }} {{ .Type }} `json:"{{ .JsonTag }}" binding:"{{ .Binding }}"` // {{ .Comment }}
{{- end }}
}

// UserResponse 用户响应 DTO
type UserResponse struct {
{{- range .ApplicationDto.Responses.0.Fields }}
	{{ .Name }} {{ .Type }} `json:"{{ .JsonTag }}"` // {{ .Comment }}
{{- end }}
}

// UserListResponse 用户列表响应 DTO
type UserListResponse struct {
	Users []UserResponse `json:"users"` // 用户列表
	Total int            `json:"total"`  // 总数
}

// ToUserResponse 将领域实体转换为响应 DTO
// Domain Entity → Application DTO
func ToUserResponse(user *entity.User) *UserResponse {
	return &UserResponse{
		ID:        user.ID().String(),
		Email:     user.Email().Value(),
		Name:      user.Name(),
		CreatedAt: user.CreatedAt(),
		UpdatedAt: user.UpdatedAt(),
	}
}

// ToUserListResponse 将领域实体列表转换为响应 DTO
func ToUserListResponse(users []*entity.User, total int) *UserListResponse {
	userResponses := make([]UserResponse, 0, len(users))
	for _, user := range users {
		userResponses = append(userResponses, *ToUserResponse(user))
	}

	return &UserListResponse{
		Users: userResponses,
		Total: total,
	}
}
