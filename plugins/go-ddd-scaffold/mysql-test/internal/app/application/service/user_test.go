package service_test

import (
	"context"
	"testing"

	"github.com/test/mysql-test/internal/app/application/dto"
	"github.com/test/mysql-test/internal/app/application/service"
	"github.com/test/mysql-test/internal/app/domain/entity"
	domainrepo "github.com/test/mysql-test/internal/app/domain/repository"
	domainservice "github.com/test/mysql-test/internal/app/domain/service"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"

	cloudevents "github.com/cloudevents/sdk-go/v2"
)

// mockRepo 测试用仓储 Mock
type mockRepo struct {
	users         map[uuid.UUID]*entity.User
	emailToExists map[string]bool
}

func newMockRepo() *mockRepo {
	return &mockRepo{
		users:         make(map[uuid.UUID]*entity.User),
		emailToExists: make(map[string]bool),
	}
}

func (m *mockRepo) Save(_ context.Context, user *entity.User) error {
	m.users[user.ID()] = user
	m.emailToExists[user.Email().Value()] = true
	return nil
}
func (m *mockRepo) Update(_ context.Context, user *entity.User) error {
	m.users[user.ID()] = user
	return nil
}
func (m *mockRepo) FindByID(_ context.Context, id uuid.UUID) (*entity.User, error) {
	u, ok := m.users[id]
	if !ok {
		return nil, domainrepo.ErrUserNotFound
	}
	return u, nil
}
func (m *mockRepo) FindByEmail(_ context.Context, email string) (*entity.User, error) {
	for _, u := range m.users {
		if u.Email().Value() == email {
			return u, nil
		}
	}
	return nil, domainrepo.ErrUserNotFound
}
func (m *mockRepo) List(_ context.Context, offset, limit int) ([]*entity.User, int, error) {
	all := make([]*entity.User, 0, len(m.users))
	for _, u := range m.users {
		all = append(all, u)
	}
	total := len(all)
	if offset >= total {
		return nil, total, nil
	}
	end := offset + limit
	if end > total {
		end = total
	}
	return all[offset:end], total, nil
}
func (m *mockRepo) Delete(_ context.Context, id uuid.UUID) error {
	if _, ok := m.users[id]; !ok {
		return domainrepo.ErrUserNotFound
	}
	delete(m.users, id)
	return nil
}
func (m *mockRepo) ExistsByEmail(_ context.Context, email string) (bool, error) {
	return m.emailToExists[email], nil
}

// mockEventBus 测试用事件总线
type mockEventBus struct {
	events []cloudevents.Event
}

func (m *mockEventBus) Publish(e cloudevents.Event) { m.events = append(m.events, e) }

func TestCreateUser(t *testing.T) {
	repo := newMockRepo()
	bus := &mockEventBus{}
	domainSvc := domainservice.NewUserService(repo)
	appSvc := service.NewUserApplicationService(repo, domainSvc, bus)

	resp, err := appSvc.CreateUser(context.Background(), dto.CreateUserRequest{
		Email: "test@example.com",
		Name:  "张三",
	})
	assert.NoError(t, err)
	assert.Equal(t, "张三", resp.Name)
	assert.Equal(t, "test@example.com", resp.Email)
	assert.Len(t, bus.events, 1)
}

func TestCreateUser_DuplicateEmail(t *testing.T) {
	repo := newMockRepo()
	bus := &mockEventBus{}
	domainSvc := domainservice.NewUserService(repo)
	appSvc := service.NewUserApplicationService(repo, domainSvc, bus)

	// 先创建一个用户
	_, _ = appSvc.CreateUser(context.Background(), dto.CreateUserRequest{
		Email: "dup@example.com", Name: "用户1",
	})

	// 再用同邮箱创建
	_, err := appSvc.CreateUser(context.Background(), dto.CreateUserRequest{
		Email: "dup@example.com", Name: "用户2",
	})
	assert.ErrorIs(t, err, domainrepo.ErrEmailAlreadyExists)
}
