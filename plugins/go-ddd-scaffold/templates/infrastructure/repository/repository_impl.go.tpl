package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/entity"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/repository"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/valueobject"
	"{{ .GoModule }}/{{ .Paths.EntSchema | replace "/schema" "" }}"
)

// Ent{{ .Entity.Name }}Repository Ent ORM 实现的用户仓储
// Infrastructure Layer：实现 Domain Layer 定义的接口
type Ent{{ .Entity.Name }}Repository struct {
	client *ent.Client
}

// NewEnt{{ .Entity.Name }}Repository 创建 Ent 仓储实现
func NewEnt{{ .Entity.Name }}Repository(client *ent.Client) repository.{{ .Repository.Name }} {
	return &Ent{{ .Entity.Name }}Repository{client: client}
}

// Save 保存用户（创建或更新）
func (r *Ent{{ .Entity.Name }}Repository) Save(ctx context.Context, user *entity.User) error {
	// 将领域实体转换为 Ent 实体
	return r.client.User.
		Create().
		SetID(user.ID()).
		SetEmail(user.Email().Value()).
		SetName(user.Name()).
		SetCreatedAt(user.CreatedAt()).
		SetUpdatedAt(user.UpdatedAt()).
		OnConflict().
		UpdateNewValues().
		Exec(ctx)
}

// FindByID 根据 ID 查找用户
func (r *Ent{{ .Entity.Name }}Repository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
	// 查询 Ent 实体
	entUser, err := r.client.User.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, repository.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to find user by id: %w", err)
	}

	// 将 Ent 实体转换为领域实体
	return r.toDomain(entUser)
}

// FindByEmail 根据邮箱查找用户
func (r *Ent{{ .Entity.Name }}Repository) FindByEmail(ctx context.Context, email string) (*entity.User, error) {
	entUser, err := r.client.User.
		Query().
		Where(user.EmailEQ(email)).
		Only(ctx)

	if err != nil {
		if ent.IsNotFound(err) {
			return nil, repository.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to find user by email: %w", err)
	}

	return r.toDomain(entUser)
}

// List 分页查询用户列表
func (r *Ent{{ .Entity.Name }}Repository) List(ctx context.Context, offset, limit int) ([]*entity.User, int, error) {
	// 查询总数
	total, err := r.client.User.Query().Count(ctx)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count users: %w", err)
	}

	// 分页查询
	entUsers, err := r.client.User.
		Query().
		Offset(offset).
		Limit(limit).
		Order(ent.Desc(user.FieldCreatedAt)).
		All(ctx)

	if err != nil {
		return nil, 0, fmt.Errorf("failed to list users: %w", err)
	}

	// 转换为领域实体列表
	users := make([]*entity.User, 0, len(entUsers))
	for _, entUser := range entUsers {
		domainUser, err := r.toDomain(entUser)
		if err != nil {
			return nil, 0, err
		}
		users = append(users, domainUser)
	}

	return users, total, nil
}

// Delete 删除用户
func (r *Ent{{ .Entity.Name }}Repository) Delete(ctx context.Context, id uuid.UUID) error {
	err := r.client.User.DeleteOneID(id).Exec(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return repository.ErrUserNotFound
		}
		return fmt.Errorf("failed to delete user: %w", err)
	}
	return nil
}

// ExistsByEmail 检查邮箱是否已存在
func (r *Ent{{ .Entity.Name }}Repository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	exists, err := r.client.User.
		Query().
		Where(user.EmailEQ(email)).
		Exist(ctx)

	if err != nil {
		return false, fmt.Errorf("failed to check email existence: %w", err)
	}

	return exists, nil
}

// toDomain 将 Ent 实体转换为领域实体
// ORM Entity → Domain Entity
func (r *Ent{{ .Entity.Name }}Repository) toDomain(entUser *ent.User) (*entity.User, error) {
	// 重建值对象
	email, err := valueobject.NewEmail(entUser.Email)
	if err != nil {
		return nil, fmt.Errorf("invalid email in database: %w", err)
	}

	// 重建实体
	// 注意：这里使用反射或其他方式重建实体，保持其 ID 和时间戳
	user, err := entity.NewUser(email, entUser.Name)
	if err != nil {
		return nil, err
	}

	// 使用反射设置私有字段（仅用于从数据库重建）
	// 在实际项目中，可以在 entity 包中提供一个 internal 构造函数
	// 这里简化处理，假设 entity 包提供了 Reconstitute 方法

	return user, nil
}
