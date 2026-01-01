package service

import (
	"context"
	"log/slog"

	"{{ .GoModule }}/{{ .Paths.Application }}/dto"
	"{{ .GoModule }}/{{ .Paths.Domain }}/event"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/entity"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/repository"
	domainservice "{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/service"
	domainevent "{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/event"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/valueobject"
)

// {{ .ApplicationService.Name }} {{ .ApplicationService.NameCN }}
// Application Service：编排领域对象完成业务用例
//
// 职责：
// 1. 用例编排：调用 Domain Services 和 Repositories
// 2. 事务管理：控制事务边界
// 3. DTO 转换：Domain Entity ↔ Application DTO
// 4. 事件发布：发布领域事件
//
// 特征：
// - 无业务逻辑（业务逻辑在 Domain Layer）
// - 无状态（Stateless）
// - 可并发调用
type {{ .ApplicationService.Name }} struct {
	userRepo    repository.UserRepository
	domainSvc   *domainservice.UserDomainService
	eventBus    event.EventBus
	logger      *slog.Logger
}

// New{{ .ApplicationService.Name }} 创建{{ .ApplicationService.NameCN }}
func New{{ .ApplicationService.Name }}(
	userRepo repository.UserRepository,
	domainSvc *domainservice.UserDomainService,
	eventBus event.EventBus,
	logger *slog.Logger,
) *{{ .ApplicationService.Name }} {
	return &{{ .ApplicationService.Name }}{
		userRepo:  userRepo,
		domainSvc: domainSvc,
		eventBus:  eventBus,
		logger:    logger,
	}
}

// CreateUser 创建用户用例
func (s *{{ .ApplicationService.Name }}) CreateUser(ctx context.Context, req dto.CreateUserRequest) (*dto.UserResponse, error) {
	s.logger.InfoContext(ctx, "creating user", slog.String("email", req.Email))

	// 1. 检查邮箱唯一性（调用领域服务）
	if err := s.domainSvc.CheckEmailUniqueness(ctx, req.Email); err != nil {
		s.logger.ErrorContext(ctx, "email already exists", slog.String("email", req.Email))
		return nil, err
	}

	// 2. 创建值对象
	email, err := valueobject.NewEmail(req.Email)
	if err != nil {
		return nil, err
	}

	// 3. 创建实体
	user, err := entity.NewUser(email, req.Name)
	if err != nil {
		return nil, err
	}

	// 4. 持久化（调用仓储）
	if err := s.userRepo.Save(ctx, user); err != nil {
		s.logger.ErrorContext(ctx, "failed to save user", slog.Any("error", err))
		return nil, err
	}

	// 5. 发布领域事件
	evt := domainevent.NewUserCreated(user.ID(), user.Email().Value(), user.Name())
	if err := s.eventBus.Publish(evt.ToCloudEvent()); err != nil {
		// 事件发布失败不应阻止主流程
		s.logger.ErrorContext(ctx, "failed to publish event", slog.Any("error", err))
	}

	s.logger.InfoContext(ctx, "user created successfully", slog.String("user_id", user.ID().String()))

	// 6. DTO 转换
	return dto.ToUserResponse(user), nil
}

// GetUser 获取用户详情用例
func (s *{{ .ApplicationService.Name }}) GetUser(ctx context.Context, userID string) (*dto.UserResponse, error) {
	s.logger.InfoContext(ctx, "getting user", slog.String("user_id", userID))

	// 解析 UUID
	id, err := parseUUID(userID)
	if err != nil {
		return nil, err
	}

	// 查询用户
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		s.logger.ErrorContext(ctx, "user not found", slog.String("user_id", userID))
		return nil, err
	}

	return dto.ToUserResponse(user), nil
}

// UpdateUser 更新用户用例
func (s *{{ .ApplicationService.Name }}) UpdateUser(ctx context.Context, userID string, req dto.UpdateUserRequest) (*dto.UserResponse, error) {
	s.logger.InfoContext(ctx, "updating user", slog.String("user_id", userID))

	// 解析 UUID
	id, err := parseUUID(userID)
	if err != nil {
		return nil, err
	}

	// 查询用户
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	// 更新邮箱
	if req.Email != "" && req.Email != user.Email().Value() {
		// 检查新邮箱唯一性
		if err := s.domainSvc.CheckEmailUniqueness(ctx, req.Email); err != nil {
			return nil, err
		}

		newEmail, err := valueobject.NewEmail(req.Email)
		if err != nil {
			return nil, err
		}

		if err := user.ChangeEmail(newEmail); err != nil {
			return nil, err
		}
	}

	// 更新名称
	if req.Name != "" && req.Name != user.Name() {
		if err := user.ChangeName(req.Name); err != nil {
			return nil, err
		}
	}

	// 持久化
	if err := s.userRepo.Save(ctx, user); err != nil {
		s.logger.ErrorContext(ctx, "failed to update user", slog.Any("error", err))
		return nil, err
	}

	// 发布更新事件
	evt := domainevent.NewUserUpdated(user.ID(), user.Email().Value(), user.Name(), user.UpdatedAt())
	if err := s.eventBus.Publish(evt.ToCloudEvent()); err != nil {
		s.logger.ErrorContext(ctx, "failed to publish event", slog.Any("error", err))
	}

	s.logger.InfoContext(ctx, "user updated successfully", slog.String("user_id", userID))

	return dto.ToUserResponse(user), nil
}

// DeleteUser 删除用户用例
func (s *{{ .ApplicationService.Name }}) DeleteUser(ctx context.Context, userID string) error {
	s.logger.InfoContext(ctx, "deleting user", slog.String("user_id", userID))

	// 解析 UUID
	id, err := parseUUID(userID)
	if err != nil {
		return err
	}

	// 删除用户
	if err := s.userRepo.Delete(ctx, id); err != nil {
		s.logger.ErrorContext(ctx, "failed to delete user", slog.Any("error", err))
		return err
	}

	s.logger.InfoContext(ctx, "user deleted successfully", slog.String("user_id", userID))

	return nil
}

// ListUsers 用户列表用例
func (s *{{ .ApplicationService.Name }}) ListUsers(ctx context.Context, offset, limit int) (*dto.UserListResponse, error) {
	s.logger.InfoContext(ctx, "listing users", slog.Int("offset", offset), slog.Int("limit", limit))

	// 查询用户列表
	users, total, err := s.userRepo.List(ctx, offset, limit)
	if err != nil {
		s.logger.ErrorContext(ctx, "failed to list users", slog.Any("error", err))
		return nil, err
	}

	return dto.ToUserListResponse(users, total), nil
}

// 辅助函数
func parseUUID(id string) (uuid.UUID, error) {
	return uuid.Parse(id)
}
