package service

import (
	"context"

	"github.com/example/my-service/internal/app/domain/repository"
)

// UserService 用户领域服务
type UserService struct {
	userRepo repository.UserRepository
}

func NewUserService(repo repository.UserRepository) *UserService {
	return &UserService{userRepo: repo}
}

// CheckEmailUniqueness 检查邮箱唯一性
func (s *UserService) CheckEmailUniqueness(ctx context.Context, email string) error {
	exists, err := s.userRepo.ExistsByEmail(ctx, email)
	if err != nil {
		return err
	}
	if exists {
		return repository.ErrEmailAlreadyExists
	}
	return nil
}
