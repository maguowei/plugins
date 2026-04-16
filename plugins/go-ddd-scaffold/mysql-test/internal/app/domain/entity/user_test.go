package entity_test

import (
	"testing"

	"github.com/test/mysql-test/internal/app/domain/entity"
	"github.com/test/mysql-test/internal/app/domain/valueobject"
	"github.com/stretchr/testify/assert"
)

func TestNewUser_Valid(t *testing.T) {
	email, _ := valueobject.NewEmail("test@example.com")
	user, err := entity.NewUser(email, "张三")
	assert.NoError(t, err)
	assert.Equal(t, "张三", user.Name())
	assert.Equal(t, "test@example.com", user.Email().Value())
	assert.NotEmpty(t, user.ID())
}

func TestNewUser_EmptyName(t *testing.T) {
	email, _ := valueobject.NewEmail("test@example.com")
	_, err := entity.NewUser(email, "")
	assert.Error(t, err)
}

func TestUser_ChangeName(t *testing.T) {
	email, _ := valueobject.NewEmail("test@example.com")
	user, _ := entity.NewUser(email, "旧名字")
	err := user.ChangeName("新名字")
	assert.NoError(t, err)
	assert.Equal(t, "新名字", user.Name())
}

func TestUser_ChangeEmail(t *testing.T) {
	email, _ := valueobject.NewEmail("old@example.com")
	user, _ := entity.NewUser(email, "张三")
	newEmail, _ := valueobject.NewEmail("new@example.com")
	user.ChangeEmail(newEmail)
	assert.Equal(t, "new@example.com", user.Email().Value())
}

func TestUser_Equals(t *testing.T) {
	email, _ := valueobject.NewEmail("test@example.com")
	user1, _ := entity.NewUser(email, "张三")
	user2, _ := entity.NewUser(email, "张三")
	assert.False(t, user1.Equals(user2)) // 不同 ID
	assert.True(t, user1.Equals(user1))  // 相同 ID
}
