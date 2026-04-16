package entity

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/test/mysql-test/internal/app/domain/valueobject"
)

// User 用户实体
type User struct {
	id        uuid.UUID
	email     valueobject.Email
	name      string
	createdAt time.Time
	updatedAt time.Time
}

// NewUser 创建用户实体
func NewUser(email valueobject.Email, name string) (*User, error) {
	if name == "" {
		return nil, errors.New("用户名不能为空")
	}
	now := time.Now()
	return &User{
		id:        uuid.New(),
		email:     email,
		name:      name,
		createdAt: now,
		updatedAt: now,
	}, nil
}

// Reconstruct 从持久化数据重建实体（不做验证）
func Reconstruct(id uuid.UUID, email valueobject.Email, name string, createdAt, updatedAt time.Time) *User {
	return &User{
		id:        id,
		email:     email,
		name:      name,
		createdAt: createdAt,
		updatedAt: updatedAt,
	}
}

func (u *User) ID() uuid.UUID           { return u.id }
func (u *User) Email() valueobject.Email { return u.email }
func (u *User) Name() string            { return u.name }
func (u *User) CreatedAt() time.Time     { return u.createdAt }
func (u *User) UpdatedAt() time.Time     { return u.updatedAt }

// ChangeName 修改用户名
func (u *User) ChangeName(name string) error {
	if name == "" {
		return errors.New("用户名不能为空")
	}
	u.name = name
	u.updatedAt = time.Now()
	return nil
}

// ChangeEmail 修改邮箱
func (u *User) ChangeEmail(email valueobject.Email) {
	u.email = email
	u.updatedAt = time.Now()
}

// Equals 基于 ID 的相等性判断
func (u *User) Equals(other *User) bool {
	if other == nil {
		return false
	}
	return u.id == other.id
}
