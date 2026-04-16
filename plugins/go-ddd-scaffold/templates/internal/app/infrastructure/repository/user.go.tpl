package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"{{.go_module}}/internal/app/domain/entity"
	domainrepo "{{.go_module}}/internal/app/domain/repository"
	"{{.go_module}}/internal/app/domain/valueobject"
	"{{.go_module}}/internal/ent"
	entuser "{{.go_module}}/internal/ent/user"
)

// EntUserRepository Ent 实现的用户仓储
type EntUserRepository struct {
	client *ent.Client
}

// 编译时接口检查
var _ domainrepo.UserRepository = (*EntUserRepository)(nil)

func NewEntUserRepository(client *ent.Client) *EntUserRepository {
	return &EntUserRepository{client: client}
}

func (r *EntUserRepository) Save(ctx context.Context, user *entity.User) error {
	_, err := r.client.User.Create().
		SetID(user.ID()).
		SetEmail(user.Email().Value()).
		SetName(user.Name()).
		SetCreatedAt(user.CreatedAt()).
		SetUpdatedAt(user.UpdatedAt()).
		Save(ctx)
	return err
}

func (r *EntUserRepository) Update(ctx context.Context, user *entity.User) error {
	_, err := r.client.User.UpdateOneID(user.ID()).
		SetEmail(user.Email().Value()).
		SetName(user.Name()).
		SetUpdatedAt(time.Now()).
		Save(ctx)
	return err
}

func (r *EntUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
	u, err := r.client.User.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, domainrepo.ErrUserNotFound
		}
		return nil, err
	}
	return toDomain(u), nil
}

func (r *EntUserRepository) FindByEmail(ctx context.Context, email string) (*entity.User, error) {
	u, err := r.client.User.Query().Where(entuser.Email(email)).Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, domainrepo.ErrUserNotFound
		}
		return nil, err
	}
	return toDomain(u), nil
}

func (r *EntUserRepository) List(ctx context.Context, offset, limit int) ([]*entity.User, int, error) {
	total, err := r.client.User.Query().Count(ctx)
	if err != nil {
		return nil, 0, err
	}
	users, err := r.client.User.Query().
		Offset(offset).
		Limit(limit).
		Order(ent.Desc(entuser.FieldCreatedAt)).
		All(ctx)
	if err != nil {
		return nil, 0, err
	}
	result := make([]*entity.User, len(users))
	for i, u := range users {
		result[i] = toDomain(u)
	}
	return result, total, nil
}

func (r *EntUserRepository) Delete(ctx context.Context, id uuid.UUID) error {
	err := r.client.User.DeleteOneID(id).Exec(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return domainrepo.ErrUserNotFound
		}
		return err
	}
	return nil
}

func (r *EntUserRepository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	return r.client.User.Query().Where(entuser.Email(email)).Exist(ctx)
}

// toDomain 将 Ent 对象转换为领域实体
func toDomain(u *ent.User) *entity.User {
	email, _ := valueobject.NewEmail(u.Email)
	return entity.Reconstruct(u.ID, email, u.Name, u.CreatedAt, u.UpdatedAt)
}
