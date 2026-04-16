package dto

import (
	"time"

	"github.com/google/uuid"
	"github.com/example/my-service/internal/app/domain/entity"
)

// CreateUserRequest 创建用户请求
type CreateUserRequest struct {
	Email string `json:"email" binding:"required"`
	Name  string `json:"name" binding:"required"`
}

// UpdateUserRequest 更新用户请求
type UpdateUserRequest struct {
	Email string `json:"email,omitempty"`
	Name  string `json:"name,omitempty"`
}

// UserResponse 用户响应
type UserResponse struct {
	ID        uuid.UUID `json:"id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UserListResponse 用户列表响应
type UserListResponse struct {
	Users []UserResponse `json:"users"`
	Total int            `json:"total"`
}

// ToUserResponse 将领域实体转换为响应 DTO
func ToUserResponse(user *entity.User) UserResponse {
	return UserResponse{
		ID:        user.ID(),
		Email:     user.Email().Value(),
		Name:      user.Name(),
		CreatedAt: user.CreatedAt(),
		UpdatedAt: user.UpdatedAt(),
	}
}

// ToUserListResponse 将领域实体列表转换为响应 DTO
func ToUserListResponse(users []*entity.User, total int) UserListResponse {
	responses := make([]UserResponse, len(users))
	for i, u := range users {
		responses[i] = ToUserResponse(u)
	}
	return UserListResponse{Users: responses, Total: total}
}
