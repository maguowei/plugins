package service

import (
	"context"
	"log/slog"

	cloudevents "github.com/cloudevents/sdk-go/v2"
	"github.com/google/uuid"
	"{{.go_module}}/internal/app/application/dto"
	"{{.go_module}}/internal/app/domain/entity"
	"{{.go_module}}/internal/app/domain/event"
	"{{.go_module}}/internal/app/domain/repository"
	domainservice "{{.go_module}}/internal/app/domain/service"
	"{{.go_module}}/internal/app/domain/valueobject"
)

// EventPublisher 事件发布接口
type EventPublisher interface {
	Publish(event cloudevents.Event)
}

// UserApplicationService 用户应用服务
type UserApplicationService struct {
	userRepo  repository.UserRepository
	domainSvc *domainservice.UserService
	eventBus  EventPublisher
}

func NewUserApplicationService(
	repo repository.UserRepository,
	domainSvc *domainservice.UserService,
	eventBus EventPublisher,
) *UserApplicationService {
	return &UserApplicationService{
		userRepo:  repo,
		domainSvc: domainSvc,
		eventBus:  eventBus,
	}
}

// CreateUser 创建用户
func (s *UserApplicationService) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
	if err := s.domainSvc.CheckEmailUniqueness(ctx, req.Email); err != nil {
		return nil, err
	}

	email, err := valueobject.NewEmail(req.Email)
	if err != nil {
		return nil, err
	}

	user, err := entity.NewUser(email, req.Name)
	if err != nil {
		return nil, err
	}

	if err := s.userRepo.Save(ctx, user); err != nil {
		return nil, err
	}

	ce := event.NewUserCreated(user.ID(), user.Email().Value(), user.Name()).ToCloudEvent()
	s.eventBus.Publish(ce)
	slog.Info("用户创建成功", "user_id", user.ID())

	resp := dto.ToUserResponse(user)
	return &resp, nil
}

// GetUser 查询用户
func (s *UserApplicationService) GetUser(ctx context.Context, id uuid.UUID) (*dto.UserResponse, error) {
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	resp := dto.ToUserResponse(user)
	return &resp, nil
}

// UpdateUser 更新用户
func (s *UserApplicationService) UpdateUser(ctx context.Context, id uuid.UUID, req dto.UpdateUserRequest) (*dto.UserResponse, error) {
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if req.Name != "" {
		if err := user.ChangeName(req.Name); err != nil {
			return nil, err
		}
	}
	if req.Email != "" {
		email, err := valueobject.NewEmail(req.Email)
		if err != nil {
			return nil, err
		}
		user.ChangeEmail(email)
	}

	if err := s.userRepo.Update(ctx, user); err != nil {
		return nil, err
	}

	ce := event.NewUserUpdated(user.ID(), user.Email().Value(), user.Name()).ToCloudEvent()
	s.eventBus.Publish(ce)
	slog.Info("用户更新成功", "user_id", user.ID())

	resp := dto.ToUserResponse(user)
	return &resp, nil
}

// ListUsers 列表查询
func (s *UserApplicationService) ListUsers(ctx context.Context, offset, limit int) (*dto.UserListResponse, error) {
	users, total, err := s.userRepo.List(ctx, offset, limit)
	if err != nil {
		return nil, err
	}
	resp := dto.ToUserListResponse(users, total)
	return &resp, nil
}

// DeleteUser 删除用户
func (s *UserApplicationService) DeleteUser(ctx context.Context, id uuid.UUID) error {
	return s.userRepo.Delete(ctx, id)
}
