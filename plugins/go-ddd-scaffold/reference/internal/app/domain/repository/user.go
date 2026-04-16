package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/example/my-service/internal/app/domain/entity"
)

var (
	ErrUserNotFound       = errors.New("用户不存在")
	ErrEmailAlreadyExists = errors.New("邮箱已被注册")
)

// UserRepository 用户仓储接口（在领域层定义，基础设施层实现）
type UserRepository interface {
	Save(ctx context.Context, user *entity.User) error
	Update(ctx context.Context, user *entity.User) error
	FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
	FindByEmail(ctx context.Context, email string) (*entity.User, error)
	List(ctx context.Context, offset, limit int) ([]*entity.User, int, error)
	Delete(ctx context.Context, id uuid.UUID) error
	ExistsByEmail(ctx context.Context, email string) (bool, error)
}
