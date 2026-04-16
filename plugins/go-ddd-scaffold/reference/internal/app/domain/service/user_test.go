package service_test

import (
	"context"
	"testing"

	"github.com/example/my-service/internal/app/domain/entity"
	"github.com/example/my-service/internal/app/domain/repository"
	"github.com/example/my-service/internal/app/domain/service"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

// mockUserRepo 测试用 Mock
type mockUserRepo struct {
	existsByEmail bool
}

func (m *mockUserRepo) Save(_ context.Context, _ *entity.User) error   { return nil }
func (m *mockUserRepo) Update(_ context.Context, _ *entity.User) error { return nil }
func (m *mockUserRepo) FindByID(_ context.Context, _ uuid.UUID) (*entity.User, error) {
	return nil, repository.ErrUserNotFound
}
func (m *mockUserRepo) FindByEmail(_ context.Context, _ string) (*entity.User, error) {
	return nil, repository.ErrUserNotFound
}
func (m *mockUserRepo) List(_ context.Context, _, _ int) ([]*entity.User, int, error) {
	return nil, 0, nil
}
func (m *mockUserRepo) Delete(_ context.Context, _ uuid.UUID) error             { return nil }
func (m *mockUserRepo) ExistsByEmail(_ context.Context, _ string) (bool, error) { return m.existsByEmail, nil }

func TestCheckEmailUniqueness_Available(t *testing.T) {
	svc := service.NewUserService(&mockUserRepo{existsByEmail: false})
	err := svc.CheckEmailUniqueness(context.Background(), "new@example.com")
	assert.NoError(t, err)
}

func TestCheckEmailUniqueness_AlreadyExists(t *testing.T) {
	svc := service.NewUserService(&mockUserRepo{existsByEmail: true})
	err := svc.CheckEmailUniqueness(context.Background(), "exists@example.com")
	assert.ErrorIs(t, err, repository.ErrEmailAlreadyExists)
}
