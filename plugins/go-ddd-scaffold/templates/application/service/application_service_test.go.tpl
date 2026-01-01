package service

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	"{{ .GoModule }}/{{ .Paths.Application }}/dto"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/entity"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/valueobject"
)

// Mock Repository
type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Save(ctx context.Context, user *entity.User) error {
	args := m.Called(ctx, user)
	return args.Error(0)
}

func (m *MockUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.User), args.Error(1)
}

func (m *MockUserRepository) FindByEmail(ctx context.Context, email string) (*entity.User, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entity.User), args.Error(1)
}

func (m *MockUserRepository) List(ctx context.Context, offset, limit int) ([]*entity.User, int, error) {
	args := m.Called(ctx, offset, limit)
	return args.Get(0).([]*entity.User), args.Int(1), args.Error(2)
}

func (m *MockUserRepository) Delete(ctx context.Context, id uuid.UUID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockUserRepository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	args := m.Called(ctx, email)
	return args.Bool(0), args.Error(1)
}

// Mock Event Bus
type MockEventBus struct {
	mock.Mock
}

func (m *MockEventBus) Publish(event interface{}) error {
	args := m.Called(event)
	return args.Error(0)
}

func (m *MockEventBus) Subscribe(eventType string, handler interface{}) error {
	args := m.Called(eventType, handler)
	return args.Error(0)
}

// Test Helper
func setupService() (*{{ .ApplicationService.Name }}, *MockUserRepository, *MockEventBus) {
	mockRepo := new(MockUserRepository)
	mockEventBus := new(MockEventBus)
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	service := New{{ .ApplicationService.Name }}(mockRepo, nil, mockEventBus, logger)

	return service, mockRepo, mockEventBus
}

func TestCreateUser(t *testing.T) {
	service, mockRepo, mockEventBus := setupService()

	// 测试数据
	req := dto.CreateUserRequest{
		Email: "test@example.com",
		Name:  "Test User",
	}

	// Mock 行为
	mockRepo.On("ExistsByEmail", mock.Anything, req.Email).Return(false, nil)
	mockRepo.On("Save", mock.Anything, mock.Anything).Return(nil)
	mockEventBus.On("Publish", mock.Anything).Return(nil)

	// 执行
	resp, err := service.CreateUser(context.Background(), req)

	// 断言
	require.NoError(t, err)
	require.NotNil(t, resp)
	assert.Equal(t, req.Email, resp.Email)
	assert.Equal(t, req.Name, resp.Name)
	assert.NotEmpty(t, resp.ID)

	// 验证 Mock 调用
	mockRepo.AssertExpectations(t)
	mockEventBus.AssertExpectations(t)
}

func TestCreateUser_EmailExists(t *testing.T) {
	service, mockRepo, _ := setupService()

	req := dto.CreateUserRequest{
		Email: "existing@example.com",
		Name:  "Test User",
	}

	// Mock: 邮箱已存在
	mockRepo.On("ExistsByEmail", mock.Anything, req.Email).Return(true, nil)

	// 执行
	resp, err := service.CreateUser(context.Background(), req)

	// 断言：应该返回错误
	assert.Error(t, err)
	assert.Nil(t, resp)

	mockRepo.AssertExpectations(t)
}

func TestGetUser(t *testing.T) {
	service, mockRepo, _ := setupService()

	// 准备测试数据
	userID := uuid.New()
	email, _ := valueobject.NewEmail("test@example.com")
	user, _ := entity.NewUser(email, "Test User")

	// Mock 行为
	mockRepo.On("FindByID", mock.Anything, userID).Return(user, nil)

	// 执行
	resp, err := service.GetUser(context.Background(), userID.String())

	// 断言
	require.NoError(t, err)
	require.NotNil(t, resp)
	assert.Equal(t, user.Email().Value(), resp.Email)
	assert.Equal(t, user.Name(), resp.Name)

	mockRepo.AssertExpectations(t)
}

func TestUpdateUser(t *testing.T) {
	service, mockRepo, mockEventBus := setupService()

	// 准备测试数据
	userID := uuid.New()
	email, _ := valueobject.NewEmail("old@example.com")
	user, _ := entity.NewUser(email, "Old Name")

	req := dto.UpdateUserRequest{
		Name: "New Name",
	}

	// Mock 行为
	mockRepo.On("FindByID", mock.Anything, userID).Return(user, nil)
	mockRepo.On("Save", mock.Anything, mock.Anything).Return(nil)
	mockEventBus.On("Publish", mock.Anything).Return(nil)

	// 执行
	resp, err := service.UpdateUser(context.Background(), userID.String(), req)

	// 断言
	require.NoError(t, err)
	require.NotNil(t, resp)
	assert.Equal(t, req.Name, resp.Name)

	mockRepo.AssertExpectations(t)
	mockEventBus.AssertExpectations(t)
}

func TestListUsers(t *testing.T) {
	service, mockRepo, _ := setupService()

	// 准备测试数据
	email1, _ := valueobject.NewEmail("user1@example.com")
	email2, _ := valueobject.NewEmail("user2@example.com")
	user1, _ := entity.NewUser(email1, "User 1")
	user2, _ := entity.NewUser(email2, "User 2")

	users := []*entity.User{user1, user2}

	// Mock 行为
	mockRepo.On("List", mock.Anything, 0, 10).Return(users, 2, nil)

	// 执行
	resp, err := service.ListUsers(context.Background(), 0, 10)

	// 断言
	require.NoError(t, err)
	require.NotNil(t, resp)
	assert.Equal(t, 2, resp.Total)
	assert.Len(t, resp.Users, 2)

	mockRepo.AssertExpectations(t)
}
