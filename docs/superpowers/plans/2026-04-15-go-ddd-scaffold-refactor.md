# go-ddd-scaffold 插件重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 go-ddd-scaffold 从半成品重构为可运行的脚手架，生成的项目能编译、测试、启动、跑通 User CRUD。

**Architecture:** 分四阶段执行——先手写可运行的黄金参考实现，再编写 Go 渲染 CLI，然后将参考实现提取为模板，最后精简插件文档和 skills。

**Tech Stack:** Go 1.26, Gin, Ent, Viper, slog, Prometheus, Sentry, CloudEvents, testify

**设计文档:** `docs/superpowers/specs/2026-04-15-go-ddd-scaffold-refactor-design.md`

**插件根目录:** `plugins/go-ddd-scaffold/`

---

## 阶段 1: 黄金参考实现

在 `plugins/go-ddd-scaffold/reference/` 目录下手写一个完整可运行的 Go DDD 项目。这是所有模板的"真理来源"。

---

### Task 1: 项目骨架 — go.mod、main、config

**Files:**
- Create: `plugins/go-ddd-scaffold/reference/go.mod`
- Create: `plugins/go-ddd-scaffold/reference/cmd/server/main.go`
- Create: `plugins/go-ddd-scaffold/reference/cmd/migrate/main.go`
- Create: `plugins/go-ddd-scaffold/reference/configs/config.yaml`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/infrastructure/config/config.go`

- [ ] **Step 1: 创建 go.mod**

```bash
mkdir -p plugins/go-ddd-scaffold/reference
cd plugins/go-ddd-scaffold/reference
go mod init github.com/example/my-service
```

- [ ] **Step 2: 创建配置文件 `configs/config.yaml`**

```yaml
server:
  port: 8080
  mode: debug

database:
  driver: mysql
  dsn: "root:password@tcp(127.0.0.1:3306)/my_service?parseTime=true"
  max_open_conns: 25
  max_idle_conns: 5

logging:
  level: info
  format: json

sentry:
  dsn: ""
  environment: development

prometheus:
  enabled: true
  path: /metrics
```

- [ ] **Step 3: 创建配置加载 `internal/app/infrastructure/config/config.go`**

```go
package config

import (
	"github.com/spf13/viper"
)

type Config struct {
	Server     ServerConfig
	Database   DatabaseConfig
	Logging    LoggingConfig
	Sentry     SentryConfig
	Prometheus PrometheusConfig
}

type ServerConfig struct {
	Port int
	Mode string
}

type DatabaseConfig struct {
	Driver       string
	DSN          string
	MaxOpenConns int `mapstructure:"max_open_conns"`
	MaxIdleConns int `mapstructure:"max_idle_conns"`
}

type LoggingConfig struct {
	Level  string
	Format string
}

type SentryConfig struct {
	DSN         string
	Environment string
}

type PrometheusConfig struct {
	Enabled bool
	Path    string
}

// Load 从配置文件和环境变量加载配置
func Load(path string) (*Config, error) {
	viper.SetConfigFile(path)
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		return nil, err
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}
```

- [ ] **Step 4: 创建最小 `cmd/server/main.go`（先只做健康检查）**

```go
package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/example/my-service/internal/app/infrastructure/config"
)

func main() {
	cfg, err := config.Load("configs/config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	if cfg.Server.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	log.Printf("服务启动于 %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("服务启动失败: %v", err)
	}
}
```

- [ ] **Step 5: 创建占位 `cmd/migrate/main.go`**

```go
package main

import (
	"fmt"
)

func main() {
	fmt.Println("数据库迁移工具 - 将在后续步骤实现")
}
```

- [ ] **Step 6: 安装依赖并验证编译**

```bash
cd plugins/go-ddd-scaffold/reference
go get github.com/gin-gonic/gin
go get github.com/spf13/viper
go mod tidy
go build ./cmd/server
go build ./cmd/migrate
```

Expected: 两个 build 命令均成功，无报错。

- [ ] **Step 7: 提交**

```bash
git add plugins/go-ddd-scaffold/reference/
git commit -m "feat(go-ddd-scaffold): 添加黄金参考实现骨架 — go.mod、main、config"
```

---

### Task 2: 领域层 — Entity、Value Object、Event、Repository 接口、Domain Service

**Files:**
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/entity/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/entity/user_test.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/valueobject/email.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/valueobject/email_test.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/event/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/repository/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/service/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/domain/service/user_test.go`

- [ ] **Step 1: 编写 Value Object 测试 `domain/valueobject/email_test.go`**

```go
package valueobject_test

import (
	"testing"

	"github.com/example/my-service/internal/app/domain/valueobject"
	"github.com/stretchr/testify/assert"
)

func TestNewEmail_Valid(t *testing.T) {
	email, err := valueobject.NewEmail("test@example.com")
	assert.NoError(t, err)
	assert.Equal(t, "test@example.com", email.Value())
}

func TestNewEmail_Empty(t *testing.T) {
	_, err := valueobject.NewEmail("")
	assert.Error(t, err)
}

func TestNewEmail_InvalidFormat(t *testing.T) {
	_, err := valueobject.NewEmail("not-an-email")
	assert.Error(t, err)
}

func TestNewEmail_Normalized(t *testing.T) {
	email, err := valueobject.NewEmail("  TEST@Example.COM  ")
	assert.NoError(t, err)
	assert.Equal(t, "test@example.com", email.Value())
}

func TestEmail_Equals(t *testing.T) {
	e1, _ := valueobject.NewEmail("test@example.com")
	e2, _ := valueobject.NewEmail("test@example.com")
	assert.True(t, e1.Equals(e2))
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd plugins/go-ddd-scaffold/reference
go test ./internal/app/domain/valueobject/... -v
```

Expected: FAIL — 包不存在。

- [ ] **Step 3: 实现 `domain/valueobject/email.go`**

```go
package valueobject

import (
	"errors"
	"strings"
)

// Email 值对象（不可变）
type Email struct {
	value string
}

// NewEmail 创建 Email，强制验证格式
func NewEmail(raw string) (Email, error) {
	email := strings.TrimSpace(strings.ToLower(raw))
	if email == "" {
		return Email{}, errors.New("邮箱不能为空")
	}
	if !strings.Contains(email, "@") || !strings.Contains(email, ".") {
		return Email{}, errors.New("邮箱格式无效")
	}
	return Email{value: email}, nil
}

func (e Email) Value() string         { return e.value }
func (e Email) String() string         { return e.value }
func (e Email) Equals(other Email) bool { return e.value == other.value }
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd plugins/go-ddd-scaffold/reference
go test ./internal/app/domain/valueobject/... -v
```

Expected: PASS — 所有 5 个测试通过。

- [ ] **Step 5: 编写 Entity 测试 `domain/entity/user_test.go`**

```go
package entity_test

import (
	"testing"

	"github.com/example/my-service/internal/app/domain/entity"
	"github.com/example/my-service/internal/app/domain/valueobject"
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
```

- [ ] **Step 6: 实现 `domain/entity/user.go`**

```go
package entity

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/example/my-service/internal/app/domain/valueobject"
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

func (u *User) ID() uuid.UUID              { return u.id }
func (u *User) Email() valueobject.Email    { return u.email }
func (u *User) Name() string               { return u.name }
func (u *User) CreatedAt() time.Time        { return u.createdAt }
func (u *User) UpdatedAt() time.Time        { return u.updatedAt }

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
```

- [ ] **Step 7: 运行 Entity 测试确认通过**

```bash
cd plugins/go-ddd-scaffold/reference
go get github.com/google/uuid
go get github.com/stretchr/testify
go test ./internal/app/domain/entity/... -v
```

Expected: PASS — 所有 5 个测试通过。

- [ ] **Step 8: 创建 Domain Event `domain/event/user.go`**

```go
package event

import (
	"time"

	cloudevents "github.com/cloudevents/sdk-go/v2"
	"github.com/google/uuid"
)

// UserCreated 用户创建事件
type UserCreated struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

func NewUserCreated(userID uuid.UUID, email, name string) UserCreated {
	return UserCreated{
		UserID:    userID,
		Email:     email,
		Name:      name,
		CreatedAt: time.Now(),
	}
}

func (e UserCreated) ToCloudEvent() cloudevents.Event {
	ce := cloudevents.NewEvent()
	ce.SetID(uuid.New().String())
	ce.SetSource("my-service")
	ce.SetType("com.example.user.created")
	ce.SetTime(e.CreatedAt)
	_ = ce.SetData(cloudevents.ApplicationJSON, e)
	return ce
}

// UserUpdated 用户更新事件
type UserUpdated struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	UpdatedAt time.Time `json:"updated_at"`
}

func NewUserUpdated(userID uuid.UUID, email, name string) UserUpdated {
	return UserUpdated{
		UserID:    userID,
		Email:     email,
		Name:      name,
		UpdatedAt: time.Now(),
	}
}

func (e UserUpdated) ToCloudEvent() cloudevents.Event {
	ce := cloudevents.NewEvent()
	ce.SetID(uuid.New().String())
	ce.SetSource("my-service")
	ce.SetType("com.example.user.updated")
	ce.SetTime(e.UpdatedAt)
	_ = ce.SetData(cloudevents.ApplicationJSON, e)
	return ce
}
```

- [ ] **Step 9: 创建 Repository 接口 `domain/repository/user.go`**

```go
package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/example/my-service/internal/app/domain/entity"
)

var (
	ErrUserNotFound      = errors.New("用户不存在")
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
```

- [ ] **Step 10: 编写 Domain Service 测试 `domain/service/user_test.go`**

```go
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

func (m *mockUserRepo) Save(_ context.Context, _ *entity.User) error             { return nil }
func (m *mockUserRepo) Update(_ context.Context, _ *entity.User) error           { return nil }
func (m *mockUserRepo) FindByID(_ context.Context, _ uuid.UUID) (*entity.User, error) { return nil, repository.ErrUserNotFound }
func (m *mockUserRepo) FindByEmail(_ context.Context, _ string) (*entity.User, error) { return nil, repository.ErrUserNotFound }
func (m *mockUserRepo) List(_ context.Context, _, _ int) ([]*entity.User, int, error) { return nil, 0, nil }
func (m *mockUserRepo) Delete(_ context.Context, _ uuid.UUID) error              { return nil }
func (m *mockUserRepo) ExistsByEmail(_ context.Context, _ string) (bool, error)  { return m.existsByEmail, nil }

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
```

- [ ] **Step 11: 实现 `domain/service/user.go`**

```go
package service

import (
	"context"

	"github.com/example/my-service/internal/app/domain/repository"
)

// UserService 用户领域服务
type UserService struct {
	userRepo repository.UserRepository
}

func NewUserService(repo repository.UserRepository) *UserService {
	return &UserService{userRepo: repo}
}

// CheckEmailUniqueness 检查邮箱唯一性
func (s *UserService) CheckEmailUniqueness(ctx context.Context, email string) error {
	exists, err := s.userRepo.ExistsByEmail(ctx, email)
	if err != nil {
		return err
	}
	if exists {
		return repository.ErrEmailAlreadyExists
	}
	return nil
}
```

- [ ] **Step 12: 运行全部领域层测试**

```bash
cd plugins/go-ddd-scaffold/reference
go get github.com/cloudevents/sdk-go/v2
go mod tidy
go test ./internal/app/domain/... -v
```

Expected: PASS — 所有测试通过。

- [ ] **Step 13: 提交**

```bash
git add plugins/go-ddd-scaffold/reference/internal/app/domain/
git commit -m "feat(go-ddd-scaffold): 参考实现 — 领域层完整实现和测试"
```

---

### Task 3: 基础设施层 — Ent Schema、Repository 实现、可观测性、事件总线

**Files:**
- Create: `plugins/go-ddd-scaffold/reference/internal/ent/schema/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/infrastructure/repository/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/infrastructure/observability/logger.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/infrastructure/observability/metrics.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/infrastructure/observability/sentry.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/infrastructure/event/eventbus.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/ent/generate.go`

- [ ] **Step 1: 创建 Ent Schema `internal/ent/schema/user.go`**

```go
package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// User Ent Schema
type User struct {
	ent.Schema
}

func (User) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).Default(uuid.New),
		field.String("email").Unique().NotEmpty(),
		field.String("name").NotEmpty(),
		field.Time("created_at").Immutable(),
		field.Time("updated_at"),
	}
}

func (User) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("email").Unique(),
	}
}

func (User) Edges() []ent.Edge {
	return nil
}
```

- [ ] **Step 2: 创建 Ent generate 文件并生成代码**

创建 `internal/ent/generate.go`:

```go
package ent

//go:generate go run -mod=mod entgo.io/ent/cmd/ent generate ./schema
```

然后执行:

```bash
cd plugins/go-ddd-scaffold/reference
go get entgo.io/ent/cmd/ent
go generate ./internal/ent/...
```

Expected: `internal/ent/` 下生成 Ent 客户端代码（client.go, user.go 等）。

- [ ] **Step 3: 实现 Repository `infrastructure/repository/user.go`**

```go
package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/example/my-service/internal/app/domain/entity"
	domainrepo "github.com/example/my-service/internal/app/domain/repository"
	"github.com/example/my-service/internal/app/domain/valueobject"
	"github.com/example/my-service/internal/ent"
	entuser "github.com/example/my-service/internal/ent/user"
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
```

- [ ] **Step 4: 创建日志初始化 `infrastructure/observability/logger.go`**

```go
package observability

import (
	"log/slog"
	"os"
)

// SetupLogger 初始化 slog 日志
func SetupLogger(level, format string) *slog.Logger {
	var lvl slog.Level
	switch level {
	case "debug":
		lvl = slog.LevelDebug
	case "warn":
		lvl = slog.LevelWarn
	case "error":
		lvl = slog.LevelError
	default:
		lvl = slog.LevelInfo
	}

	opts := &slog.HandlerOptions{Level: lvl}

	var handler slog.Handler
	if format == "json" {
		handler = slog.NewJSONHandler(os.Stdout, opts)
	} else {
		handler = slog.NewTextHandler(os.Stdout, opts)
	}

	logger := slog.New(handler)
	slog.SetDefault(logger)
	return logger
}
```

- [ ] **Step 5: 创建 Prometheus 指标 `infrastructure/observability/metrics.go`**

```go
package observability

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "HTTP 请求总数",
		},
		[]string{"method", "path", "status"},
	)
	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP 请求耗时",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "path"},
	)
)

// MetricsMiddleware Prometheus 指标中间件
func MetricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		duration := time.Since(start).Seconds()
		status := strconv.Itoa(c.Writer.Status())
		httpRequestsTotal.WithLabelValues(c.Request.Method, c.FullPath(), status).Inc()
		httpRequestDuration.WithLabelValues(c.Request.Method, c.FullPath()).Observe(duration)
	}
}

// MetricsHandler 返回 Prometheus 指标 handler
func MetricsHandler() gin.HandlerFunc {
	h := promhttp.Handler()
	return func(c *gin.Context) {
		h.ServeHTTP(c.Writer, c.Request)
	}
}
```

- [ ] **Step 6: 创建 Sentry 初始化 `infrastructure/observability/sentry.go`**

```go
package observability

import (
	"log/slog"
	"time"

	"github.com/getsentry/sentry-go"
	sentrygin "github.com/getsentry/sentry-go/gin"
	"github.com/gin-gonic/gin"
)

// SetupSentry 初始化 Sentry
func SetupSentry(dsn, environment string) error {
	if dsn == "" {
		slog.Info("Sentry DSN 为空，跳过初始化")
		return nil
	}
	return sentry.Init(sentry.ClientOptions{
		Dsn:         dsn,
		Environment: environment,
	})
}

// SentryMiddleware 返回 Sentry Gin 中间件
func SentryMiddleware() gin.HandlerFunc {
	return sentrygin.New(sentrygin.Options{Repanic: true})
}

// FlushSentry 刷新 Sentry 缓冲
func FlushSentry() {
	sentry.Flush(2 * time.Second)
}
```

- [ ] **Step 7: 创建内存事件总线 `infrastructure/event/eventbus.go`**

```go
package event

import (
	"log/slog"

	cloudevents "github.com/cloudevents/sdk-go/v2"
)

// Bus 内存事件总线
type Bus struct {
	handlers []func(cloudevents.Event)
}

func NewBus() *Bus {
	return &Bus{}
}

// Subscribe 订阅事件
func (b *Bus) Subscribe(handler func(cloudevents.Event)) {
	b.handlers = append(b.handlers, handler)
}

// Publish 发布事件
func (b *Bus) Publish(event cloudevents.Event) {
	slog.Info("发布领域事件", "type", event.Type(), "id", event.ID())
	for _, h := range b.handlers {
		go h(event)
	}
}
```

- [ ] **Step 8: 验证编译**

```bash
cd plugins/go-ddd-scaffold/reference
go get github.com/prometheus/client_golang/prometheus
go get github.com/prometheus/client_golang/prometheus/promhttp
go get github.com/getsentry/sentry-go
go get github.com/getsentry/sentry-go/gin
go get github.com/cloudevents/sdk-go/v2
go mod tidy
go build ./...
```

Expected: 编译成功。

- [ ] **Step 9: 提交**

```bash
git add plugins/go-ddd-scaffold/reference/internal/
git commit -m "feat(go-ddd-scaffold): 参考实现 — 基础设施层（Ent、Repository、可观测性、事件总线）"
```

---

### Task 4: 应用层 — Application Service、DTO

**Files:**
- Create: `plugins/go-ddd-scaffold/reference/internal/app/application/service/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/application/service/user_test.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/application/dto/user.go`

- [ ] **Step 1: 创建 DTO `application/dto/user.go`**

```go
package dto

import (
	"time"

	"github.com/google/uuid"
	"github.com/example/my-service/internal/app/domain/entity"
)

// CreateUserRequest 创建用户请求
type CreateUserRequest struct {
	Email string `json:"email" binding:"required"`
	Name  string `json:"name" binding:"required"`
}

// UpdateUserRequest 更新用户请求
type UpdateUserRequest struct {
	Email string `json:"email,omitempty"`
	Name  string `json:"name,omitempty"`
}

// UserResponse 用户响应
type UserResponse struct {
	ID        uuid.UUID `json:"id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UserListResponse 用户列表响应
type UserListResponse struct {
	Users []UserResponse `json:"users"`
	Total int            `json:"total"`
}

// ToUserResponse 将领域实体转换为响应 DTO
func ToUserResponse(user *entity.User) UserResponse {
	return UserResponse{
		ID:        user.ID(),
		Email:     user.Email().Value(),
		Name:      user.Name(),
		CreatedAt: user.CreatedAt(),
		UpdatedAt: user.UpdatedAt(),
	}
}

// ToUserListResponse 将领域实体列表转换为响应 DTO
func ToUserListResponse(users []*entity.User, total int) UserListResponse {
	responses := make([]UserResponse, len(users))
	for i, u := range users {
		responses[i] = ToUserResponse(u)
	}
	return UserListResponse{Users: responses, Total: total}
}
```

- [ ] **Step 2: 编写 Application Service 测试 `application/service/user_test.go`**

```go
package service_test

import (
	"context"
	"testing"

	"github.com/example/my-service/internal/app/application/dto"
	"github.com/example/my-service/internal/app/application/service"
	"github.com/example/my-service/internal/app/domain/entity"
	domainrepo "github.com/example/my-service/internal/app/domain/repository"
	"github.com/example/my-service/internal/app/domain/valueobject"
	domainservice "github.com/example/my-service/internal/app/domain/service"
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
```

- [ ] **Step 3: 实现 `application/service/user.go`**

```go
package service

import (
	"context"
	"log/slog"

	cloudevents "github.com/cloudevents/sdk-go/v2"
	"github.com/google/uuid"
	"github.com/example/my-service/internal/app/application/dto"
	"github.com/example/my-service/internal/app/domain/entity"
	"github.com/example/my-service/internal/app/domain/event"
	"github.com/example/my-service/internal/app/domain/repository"
	domainservice "github.com/example/my-service/internal/app/domain/service"
	"github.com/example/my-service/internal/app/domain/valueobject"
)

// EventPublisher 事件发布接口
type EventPublisher interface {
	Publish(event cloudevents.Event)
}

// UserApplicationService 用户应用服务
type UserApplicationService struct {
	userRepo   repository.UserRepository
	domainSvc  *domainservice.UserService
	eventBus   EventPublisher
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
```

- [ ] **Step 4: 运行应用层测试**

```bash
cd plugins/go-ddd-scaffold/reference
go mod tidy
go test ./internal/app/application/... -v
```

Expected: PASS — 所有测试通过。

- [ ] **Step 5: 提交**

```bash
git add plugins/go-ddd-scaffold/reference/internal/app/application/
git commit -m "feat(go-ddd-scaffold): 参考实现 — 应用层（Service、DTO）和测试"
```

---

### Task 5: 接口层 — HTTP Handler、Middleware、Router

**Files:**
- Create: `plugins/go-ddd-scaffold/reference/internal/app/interface/http/handler/user.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/interface/http/dto/request.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/interface/http/dto/response.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/interface/http/middleware/cors.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/interface/http/middleware/logger.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/interface/http/middleware/recovery.go`
- Create: `plugins/go-ddd-scaffold/reference/internal/app/interface/http/router.go`

- [ ] **Step 1: 创建 HTTP DTO `interface/http/dto/request.go`**

```go
package dto

// CreateUserHTTPRequest HTTP 创建用户请求
type CreateUserHTTPRequest struct {
	Email string `json:"email" binding:"required,email"`
	Name  string `json:"name" binding:"required,min=1,max=100"`
}

// UpdateUserHTTPRequest HTTP 更新用户请求
type UpdateUserHTTPRequest struct {
	Email string `json:"email,omitempty" binding:"omitempty,email"`
	Name  string `json:"name,omitempty" binding:"omitempty,min=1,max=100"`
}

// ListUsersHTTPRequest HTTP 列表查询参数
type ListUsersHTTPRequest struct {
	Offset int `form:"offset" binding:"min=0"`
	Limit  int `form:"limit" binding:"min=1,max=100"`
}
```

- [ ] **Step 2: 创建 HTTP 响应 `interface/http/dto/response.go`**

```go
package dto

import "github.com/gin-gonic/gin"

// ErrorResponse 统一错误响应
type ErrorResponse struct {
	Error string `json:"error"`
}

// NewErrorResponse 创建错误响应
func NewErrorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
```

- [ ] **Step 3: 创建 Handler `interface/http/handler/user.go`**

```go
package handler

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	appdto "github.com/example/my-service/internal/app/application/dto"
	appservice "github.com/example/my-service/internal/app/application/service"
	domainrepo "github.com/example/my-service/internal/app/domain/repository"
	httpdto "github.com/example/my-service/internal/app/interface/http/dto"
)

// UserHandler 用户 HTTP 处理器
type UserHandler struct {
	appService *appservice.UserApplicationService
}

func NewUserHandler(appService *appservice.UserApplicationService) *UserHandler {
	return &UserHandler{appService: appService}
}

// Create 创建用户
func (h *UserHandler) Create(c *gin.Context) {
	var req httpdto.CreateUserHTTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.NewErrorResponse(err))
		return
	}

	resp, err := h.appService.CreateUser(c.Request.Context(), appdto.CreateUserRequest{
		Email: req.Email,
		Name:  req.Name,
	})
	if err != nil {
		if errors.Is(err, domainrepo.ErrEmailAlreadyExists) {
			c.JSON(http.StatusConflict, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// Get 查询用户
func (h *UserHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户 ID"})
		return
	}

	resp, err := h.appService.GetUser(c.Request.Context(), id)
	if err != nil {
		if errors.Is(err, domainrepo.ErrUserNotFound) {
			c.JSON(http.StatusNotFound, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusOK, resp)
}

// Update 更新用户
func (h *UserHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户 ID"})
		return
	}

	var req httpdto.UpdateUserHTTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.NewErrorResponse(err))
		return
	}

	resp, err := h.appService.UpdateUser(c.Request.Context(), id, appdto.UpdateUserRequest{
		Email: req.Email,
		Name:  req.Name,
	})
	if err != nil {
		if errors.Is(err, domainrepo.ErrUserNotFound) {
			c.JSON(http.StatusNotFound, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusOK, resp)
}

// List 用户列表
func (h *UserHandler) List(c *gin.Context) {
	var req httpdto.ListUsersHTTPRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, httpdto.NewErrorResponse(err))
		return
	}
	if req.Limit == 0 {
		req.Limit = 20
	}

	resp, err := h.appService.ListUsers(c.Request.Context(), req.Offset, req.Limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusOK, resp)
}

// Delete 删除用户
func (h *UserHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户 ID"})
		return
	}

	if err := h.appService.DeleteUser(c.Request.Context(), id); err != nil {
		if errors.Is(err, domainrepo.ErrUserNotFound) {
			c.JSON(http.StatusNotFound, httpdto.NewErrorResponse(err))
			return
		}
		c.JSON(http.StatusInternalServerError, httpdto.NewErrorResponse(err))
		return
	}

	c.JSON(http.StatusNoContent, nil)
}
```

- [ ] **Step 4: 创建 Middleware — CORS `middleware/cors.go`**

```go
package middleware

import (
	"github.com/gin-gonic/gin"
)

// CORS 跨域中间件
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}
```

- [ ] **Step 5: 创建 Middleware — Logger `middleware/logger.go`**

```go
package middleware

import (
	"log/slog"
	"time"

	"github.com/gin-gonic/gin"
)

// Logger slog 请求日志中间件
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		slog.Info("HTTP 请求",
			"method", c.Request.Method,
			"path", c.Request.URL.Path,
			"status", c.Writer.Status(),
			"latency", time.Since(start).String(),
			"client_ip", c.ClientIP(),
		)
	}
}
```

- [ ] **Step 6: 创建 Middleware — Recovery `middleware/recovery.go`**

```go
package middleware

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Recovery panic 恢复中间件
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				slog.Error("Panic recovered", "error", err)
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error": "内部服务器错误",
				})
			}
		}()
		c.Next()
	}
}
```

- [ ] **Step 7: 创建路由 `interface/http/router.go`**

```go
package http

import (
	"github.com/gin-gonic/gin"
	"github.com/example/my-service/internal/app/interface/http/handler"
	"github.com/example/my-service/internal/app/interface/http/middleware"
	"github.com/example/my-service/internal/app/infrastructure/observability"
)

// NewRouter 创建路由
func NewRouter(userHandler *handler.UserHandler, metricsPath string) *gin.Engine {
	r := gin.New()

	// 全局中间件
	r.Use(middleware.Recovery())
	r.Use(middleware.Logger())
	r.Use(middleware.CORS())
	r.Use(observability.MetricsMiddleware())

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Prometheus 指标
	r.GET(metricsPath, observability.MetricsHandler())

	// API v1
	v1 := r.Group("/api/v1")
	{
		users := v1.Group("/users")
		{
			users.POST("", userHandler.Create)
			users.GET("", userHandler.List)
			users.GET("/:id", userHandler.Get)
			users.PUT("/:id", userHandler.Update)
			users.DELETE("/:id", userHandler.Delete)
		}
	}

	return r
}
```

- [ ] **Step 8: 验证编译**

```bash
cd plugins/go-ddd-scaffold/reference
go mod tidy
go build ./...
```

Expected: 编译成功。

- [ ] **Step 9: 提交**

```bash
git add plugins/go-ddd-scaffold/reference/internal/app/interface/
git commit -m "feat(go-ddd-scaffold): 参考实现 — 接口层（Handler、Middleware、Router）"
```

---

### Task 6: 组装 main.go 和 migrate，端到端验证

**Files:**
- Modify: `plugins/go-ddd-scaffold/reference/cmd/server/main.go`
- Modify: `plugins/go-ddd-scaffold/reference/cmd/migrate/main.go`
- Create: `plugins/go-ddd-scaffold/reference/.gitignore`
- Create: `plugins/go-ddd-scaffold/reference/Makefile`
- Create: `plugins/go-ddd-scaffold/reference/docker/Dockerfile`
- Create: `plugins/go-ddd-scaffold/reference/docker/docker-compose.yaml`
- Create: `plugins/go-ddd-scaffold/reference/README.md`

- [ ] **Step 1: 重写 `cmd/server/main.go`（完整组装）**

```go
package main

import (
	"context"
	"fmt"
	"log"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"github.com/example/my-service/internal/app/application/service"
	domainservice "github.com/example/my-service/internal/app/domain/service"
	"github.com/example/my-service/internal/app/infrastructure/config"
	infraevent "github.com/example/my-service/internal/app/infrastructure/event"
	"github.com/example/my-service/internal/app/infrastructure/observability"
	infrarepo "github.com/example/my-service/internal/app/infrastructure/repository"
	"github.com/example/my-service/internal/app/interface/http"
	"github.com/example/my-service/internal/app/interface/http/handler"
	"github.com/example/my-service/internal/ent"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	// 加载配置
	cfg, err := config.Load("configs/config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 初始化日志
	observability.SetupLogger(cfg.Logging.Level, cfg.Logging.Format)

	// 初始化 Sentry
	if err := observability.SetupSentry(cfg.Sentry.DSN, cfg.Sentry.Environment); err != nil {
		slog.Warn("Sentry 初始化失败", "error", err)
	}
	defer observability.FlushSentry()

	// 初始化数据库
	client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
	if err != nil {
		log.Fatalf("数据库连接失败: %v", err)
	}
	defer client.Close()

	// 设置 Gin 模式
	if cfg.Server.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 依赖注入
	userRepo := infrarepo.NewEntUserRepository(client)
	eventBus := infraevent.NewBus()
	domainSvc := domainservice.NewUserService(userRepo)
	appSvc := service.NewUserApplicationService(userRepo, domainSvc, eventBus)
	userHandler := handler.NewUserHandler(appSvc)

	// 创建路由
	router := http.NewRouter(userHandler, cfg.Prometheus.Path)

	// 启动服务
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	slog.Info("服务启动", "addr", addr)

	// 优雅退出
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	go func() {
		if err := router.Run(addr); err != nil {
			log.Fatalf("服务启动失败: %v", err)
		}
	}()

	<-ctx.Done()
	slog.Info("收到退出信号，正在关闭...")
}
```

- [ ] **Step 2: 重写 `cmd/migrate/main.go`**

```go
package main

import (
	"context"
	"log"

	"github.com/example/my-service/internal/app/infrastructure/config"
	"github.com/example/my-service/internal/ent"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	cfg, err := config.Load("configs/config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
	if err != nil {
		log.Fatalf("数据库连接失败: %v", err)
	}
	defer client.Close()

	log.Println("开始数据库迁移...")
	if err := client.Schema.Create(context.Background()); err != nil {
		log.Fatalf("迁移失败: %v", err)
	}
	log.Println("数据库迁移完成")
}
```

- [ ] **Step 3: 创建 `.gitignore`**

```
# 二进制
/server
/migrate
*.exe

# 依赖
/vendor/

# IDE
.idea/
.vscode/
*.swp

# 环境配置
.env
```

- [ ] **Step 4: 创建 `Makefile`**

```makefile
.PHONY: build run test migrate lint clean

build:
	go build -o bin/server ./cmd/server
	go build -o bin/migrate ./cmd/migrate

run:
	go run ./cmd/server

test:
	go test ./... -v

migrate:
	go run ./cmd/migrate

lint:
	golangci-lint run ./...

generate:
	go generate ./...

clean:
	rm -rf bin/

docker-up:
	docker-compose -f docker/docker-compose.yaml up -d

docker-down:
	docker-compose -f docker/docker-compose.yaml down
```

- [ ] **Step 5: 创建 `docker/docker-compose.yaml`**

```yaml
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: my_service
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 3s
      retries: 10

  app:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    ports:
      - "8080:8080"
    depends_on:
      db:
        condition: service_healthy
    environment:
      - DATABASE_DSN=root:password@tcp(db:3306)/my_service?parseTime=true

volumes:
  mysql_data:
```

- [ ] **Step 6: 创建 `docker/Dockerfile`**

```dockerfile
FROM golang:1.26-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/server ./cmd/server
RUN CGO_ENABLED=0 go build -o /bin/migrate ./cmd/migrate

FROM alpine:3.21
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /bin/server /bin/migrate ./
COPY configs/ ./configs/
EXPOSE 8080
CMD ["./server"]
```

- [ ] **Step 7: 创建简要 `README.md`**

```markdown
# my-service

基于 DDD 架构的 Go Web 服务。

## 快速开始

1. 启动数据库: `make docker-up`
2. 运行迁移: `make migrate`
3. 启动服务: `make run`
4. 测试: `curl http://localhost:8080/health`

## API

- `POST /api/v1/users` — 创建用户
- `GET /api/v1/users` — 用户列表
- `GET /api/v1/users/:id` — 查询用户
- `PUT /api/v1/users/:id` — 更新用户
- `DELETE /api/v1/users/:id` — 删除用户
```

- [ ] **Step 8: 验证全部编译通过**

```bash
cd plugins/go-ddd-scaffold/reference
go get github.com/go-sql-driver/mysql
go mod tidy
go build ./cmd/server
go build ./cmd/migrate
go test ./... -v
```

Expected: 编译成功，所有测试通过。

- [ ] **Step 9: 提交**

```bash
git add plugins/go-ddd-scaffold/reference/
git commit -m "feat(go-ddd-scaffold): 参考实现 — 完整组装、Docker、端到端验证通过"
```

---

## 阶段 2: 渲染工具链

---

### Task 7: 编写 scaffold CLI (`tools/scaffold/main.go`)

**Files:**
- Create: `plugins/go-ddd-scaffold/tools/scaffold/main.go`
- Create: `plugins/go-ddd-scaffold/tools/scaffold/go.mod`
- Create: `plugins/go-ddd-scaffold/tools/scaffold/main_test.go`

- [ ] **Step 1: 编写 scaffold CLI 测试**

```go
// tools/scaffold/main_test.go
package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRenderTemplate(t *testing.T) {
	// 创建临时模板目录
	tmpDir := t.TempDir()
	tplDir := filepath.Join(tmpDir, "templates")
	outDir := filepath.Join(tmpDir, "output")
	os.MkdirAll(filepath.Join(tplDir, "sub"), 0o755)

	// 写入测试模板
	os.WriteFile(filepath.Join(tplDir, "hello.txt.tpl"), []byte("Hello {{.project_name}}!"), 0o644)
	os.WriteFile(filepath.Join(tplDir, "sub", "nested.go.tpl"), []byte("package {{.project_name}}"), 0o644)

	// 写入变量文件
	varsFile := filepath.Join(tmpDir, "vars.yaml")
	os.WriteFile(varsFile, []byte("project_name: myapp\ngo_module: github.com/me/myapp\n"), 0o644)

	// 执行渲染
	err := render(varsFile, tplDir, outDir)
	require.NoError(t, err)

	// 验证输出
	content, err := os.ReadFile(filepath.Join(outDir, "hello.txt"))
	require.NoError(t, err)
	assert.Equal(t, "Hello myapp!", string(content))

	content, err = os.ReadFile(filepath.Join(outDir, "sub", "nested.go"))
	require.NoError(t, err)
	assert.Equal(t, "package myapp", string(content))
}

func TestSkipUserFilesWhenNoExamples(t *testing.T) {
	tmpDir := t.TempDir()
	tplDir := filepath.Join(tmpDir, "templates")
	outDir := filepath.Join(tmpDir, "output")
	os.MkdirAll(filepath.Join(tplDir, "handler"), 0o755)

	os.WriteFile(filepath.Join(tplDir, "handler", "user.go.tpl"), []byte("package handler"), 0o644)
	os.WriteFile(filepath.Join(tplDir, "config.go.tpl"), []byte("package config"), 0o644)

	varsFile := filepath.Join(tmpDir, "vars.yaml")
	os.WriteFile(varsFile, []byte("project_name: test\ninclude_examples: false\n"), 0o644)

	err := render(varsFile, tplDir, outDir)
	require.NoError(t, err)

	// user.go 应该被跳过
	_, err = os.Stat(filepath.Join(outDir, "handler", "user.go"))
	assert.True(t, os.IsNotExist(err))

	// config.go 应该存在
	_, err = os.Stat(filepath.Join(outDir, "config.go"))
	assert.NoError(t, err)
}

func TestCopyNonTplFiles(t *testing.T) {
	tmpDir := t.TempDir()
	tplDir := filepath.Join(tmpDir, "templates")
	outDir := filepath.Join(tmpDir, "output")
	os.MkdirAll(tplDir, 0o755)

	os.WriteFile(filepath.Join(tplDir, "static.txt"), []byte("raw content"), 0o644)

	varsFile := filepath.Join(tmpDir, "vars.yaml")
	os.WriteFile(varsFile, []byte("project_name: test\n"), 0o644)

	err := render(varsFile, tplDir, outDir)
	require.NoError(t, err)

	content, err := os.ReadFile(filepath.Join(outDir, "static.txt"))
	require.NoError(t, err)
	assert.Equal(t, "raw content", string(content))
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd plugins/go-ddd-scaffold/tools/scaffold
go test -v
```

Expected: FAIL — render 函数不存在。

- [ ] **Step 3: 创建 `tools/scaffold/go.mod`**

```bash
cd plugins/go-ddd-scaffold/tools/scaffold
go mod init scaffold
go get gopkg.in/yaml.v3
go get github.com/stretchr/testify
```

- [ ] **Step 4: 实现 `tools/scaffold/main.go`**

```go
package main

import (
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"gopkg.in/yaml.v3"
)

func main() {
	varsFile := flag.String("vars", "", "变量文件路径 (YAML)")
	tplDir := flag.String("templates", "", "模板目录路径")
	outDir := flag.String("output", "", "输出目录路径")
	flag.Parse()

	if *varsFile == "" || *tplDir == "" || *outDir == "" {
		flag.Usage()
		os.Exit(1)
	}

	if err := render(*varsFile, *tplDir, *outDir); err != nil {
		log.Fatalf("渲染失败: %v", err)
	}
}

// render 读取变量并将模板目录渲染到输出目录
func render(varsFile, tplDir, outDir string) error {
	// 读取变量
	vars, err := loadVars(varsFile)
	if err != nil {
		return fmt.Errorf("加载变量失败: %w", err)
	}

	includeExamples, _ := vars["include_examples"].(bool)

	// 遍历模板目录
	return filepath.WalkDir(tplDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// 计算相对路径
		relPath, err := filepath.Rel(tplDir, path)
		if err != nil {
			return err
		}

		// 跳过根目录和 vars.yaml
		if relPath == "." || relPath == "vars.yaml" {
			return nil
		}

		// 创建目录
		if d.IsDir() {
			return os.MkdirAll(filepath.Join(outDir, relPath), 0o755)
		}

		// 检查是否为 user 相关文件（include_examples 控制）
		baseName := filepath.Base(relPath)
		if !includeExamples && isUserFile(baseName) {
			return nil
		}

		// 处理 .tpl 文件
		if strings.HasSuffix(relPath, ".tpl") {
			outputPath := filepath.Join(outDir, strings.TrimSuffix(relPath, ".tpl"))
			return renderTemplate(path, outputPath, vars)
		}

		// 非 .tpl 文件直接复制
		outputPath := filepath.Join(outDir, relPath)
		return copyFile(path, outputPath)
	})
}

// loadVars 加载 YAML 变量文件
func loadVars(path string) (map[string]any, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var vars map[string]any
	if err := yaml.Unmarshal(data, &vars); err != nil {
		return nil, err
	}
	return vars, nil
}

// isUserFile 判断文件名是否包含 "user"
func isUserFile(name string) bool {
	lower := strings.ToLower(name)
	return strings.Contains(lower, "user")
}

// renderTemplate 渲染单个模板文件
func renderTemplate(tplPath, outputPath string, vars map[string]any) error {
	content, err := os.ReadFile(tplPath)
	if err != nil {
		return err
	}

	tmpl, err := template.New(filepath.Base(tplPath)).Parse(string(content))
	if err != nil {
		return fmt.Errorf("解析模板 %s 失败: %w", tplPath, err)
	}

	if err := os.MkdirAll(filepath.Dir(outputPath), 0o755); err != nil {
		return err
	}

	f, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer f.Close()

	return tmpl.Execute(f, vars)
}

// copyFile 复制文件
func copyFile(src, dst string) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return err
}
```

- [ ] **Step 5: 运行测试确认通过**

```bash
cd plugins/go-ddd-scaffold/tools/scaffold
go mod tidy
go test -v
```

Expected: PASS — 所有 3 个测试通过。

- [ ] **Step 6: 提交**

```bash
git add plugins/go-ddd-scaffold/tools/
git commit -m "feat(go-ddd-scaffold): 实现 scaffold CLI — Go text/template 渲染器"
```

---

## 阶段 3: 提取模板

---

### Task 8: 从参考实现提取所有模板

**Files:**
- Create: `plugins/go-ddd-scaffold/templates/vars.yaml`
- Create: `plugins/go-ddd-scaffold/templates/base/` — 4 个 .tpl 文件
- Create: `plugins/go-ddd-scaffold/templates/cmd/` — 2 个 .tpl 文件
- Create: `plugins/go-ddd-scaffold/templates/internal/` — 所有 DDD 层 .tpl 文件
- Create: `plugins/go-ddd-scaffold/templates/configs/config.yaml.tpl`
- Create: `plugins/go-ddd-scaffold/templates/docker/` — 2 个 .tpl 文件

此任务将参考实现中的所有具体值替换为 `{{.variable}}` 模板变量。下面仅展示关键的替换规则和几个代表性文件的完整代码。**每个文件都必须从 `reference/` 对应文件出发做替换**。

- [ ] **Step 1: 删除旧模板目录内容**

```bash
rm -rf plugins/go-ddd-scaffold/templates/
mkdir -p plugins/go-ddd-scaffold/templates
```

- [ ] **Step 2: 创建 `templates/vars.yaml`**

```yaml
# 项目级变量（generate.sh 从用户输入生成）
project_name: "my-service"
go_module: "github.com/example/my-service"
database: "mysql"
include_examples: true
go_version: "1.26"

# 示例聚合级变量（固定值）
entity_name: "User"
entity_name_lower: "user"
entity_id_type: "uuid.UUID"
```

- [ ] **Step 3: 创建基础模板 — `base/go.mod.tpl`**

```
module {{.go_module}}

go {{.go_version}}
```

- [ ] **Step 4: 创建基础模板 — `base/.gitignore.tpl`、`base/README.md.tpl`、`base/Makefile.tpl`**

直接从 `reference/` 对应文件复制，将 `my-service` 替换为 `{{.project_name}}`，将 `github.com/example/my-service` 替换为 `{{.go_module}}`。

- [ ] **Step 5: 创建 cmd 模板 — `cmd/server/main.go.tpl`**

从 `reference/cmd/server/main.go` 出发做以下替换：
- `github.com/example/my-service` → `{{.go_module}}`
- `_ "github.com/go-sql-driver/mysql"` → `{{if eq .database "mysql"}}_ "github.com/go-sql-driver/mysql"{{else}}_ "github.com/mattn/go-sqlite3"{{end}}`

- [ ] **Step 6: 创建 cmd 模板 — `cmd/migrate/main.go.tpl`**

同理替换 module 路径和数据库驱动导入。

- [ ] **Step 7: 创建领域层模板**

从 `reference/internal/app/domain/` 的每个文件出发：
- `github.com/example/my-service` → `{{.go_module}}`
- 文件名保持 `user.go.tpl` 格式

创建以下模板文件：
- `templates/internal/app/domain/entity/user.go.tpl`
- `templates/internal/app/domain/entity/user_test.go.tpl`
- `templates/internal/app/domain/valueobject/email.go.tpl`
- `templates/internal/app/domain/valueobject/email_test.go.tpl`
- `templates/internal/app/domain/event/user.go.tpl`
- `templates/internal/app/domain/repository/user.go.tpl`
- `templates/internal/app/domain/service/user.go.tpl`
- `templates/internal/app/domain/service/user_test.go.tpl`

- [ ] **Step 8: 创建基础设施层模板**

从 `reference/internal/app/infrastructure/` 的每个文件出发替换 module 路径。

创建以下模板文件：
- `templates/internal/app/infrastructure/repository/user.go.tpl`
- `templates/internal/app/infrastructure/config/config.go.tpl`
- `templates/internal/app/infrastructure/observability/logger.go.tpl`
- `templates/internal/app/infrastructure/observability/metrics.go.tpl`
- `templates/internal/app/infrastructure/observability/sentry.go.tpl`
- `templates/internal/app/infrastructure/event/eventbus.go.tpl`

- [ ] **Step 9: 创建 Ent Schema 模板**

- `templates/internal/ent/schema/user.go.tpl`
- `templates/internal/ent/generate.go.tpl`

- [ ] **Step 10: 创建应用层模板**

- `templates/internal/app/application/service/user.go.tpl`
- `templates/internal/app/application/service/user_test.go.tpl`
- `templates/internal/app/application/dto/user.go.tpl`

- [ ] **Step 11: 创建接口层模板**

- `templates/internal/app/interface/http/handler/user.go.tpl`
- `templates/internal/app/interface/http/dto/request.go.tpl`
- `templates/internal/app/interface/http/dto/response.go.tpl`
- `templates/internal/app/interface/http/middleware/cors.go.tpl`
- `templates/internal/app/interface/http/middleware/logger.go.tpl`
- `templates/internal/app/interface/http/middleware/recovery.go.tpl`
- `templates/internal/app/interface/http/router.go.tpl`

- [ ] **Step 12: 创建配置和 Docker 模板**

- `templates/configs/config.yaml.tpl` — 替换数据库 DSN 为 `{{if eq .database "mysql"}}...{{else}}...{{end}}`
- `templates/docker/Dockerfile.tpl` — 替换 Go 版本为 `{{.go_version}}`
- `templates/docker/docker-compose.yaml.tpl` — MySQL/SQLite 条件

- [ ] **Step 13: 用 scaffold CLI 验证生成结果 === 参考实现**

```bash
cd plugins/go-ddd-scaffold
go build -o /tmp/scaffold ./tools/scaffold
/tmp/scaffold \
  -vars templates/vars.yaml \
  -templates templates \
  -output /tmp/test-generated

cd /tmp/test-generated
go mod tidy
go build ./...
go test ./... -v
```

Expected: 生成的项目编译通过，测试通过。

- [ ] **Step 14: 提交**

```bash
git add plugins/go-ddd-scaffold/templates/
git commit -m "feat(go-ddd-scaffold): 从参考实现提取所有模板"
```

---

### Task 9: 编写 generate.sh 和更新 init-go-web 命令

**Files:**
- Rewrite: `plugins/go-ddd-scaffold/scripts/generate.sh`
- Rewrite: `plugins/go-ddd-scaffold/commands/init-go-web.md`

- [ ] **Step 1: 重写 `scripts/generate.sh`（~100 行）**

```bash
#!/bin/bash
# Go DDD Scaffold 项目生成脚本
#
# 用法: bash generate.sh <project_name> <go_module> <database> <include_examples> <plugin_root>

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$#" -ne 5 ]; then
    echo -e "${RED}错误: 参数数量不正确${NC}"
    echo "用法: $0 <project_name> <go_module> <database> <include_examples> <plugin_root>"
    exit 1
fi

PROJECT_NAME=$1
GO_MODULE=$2
DATABASE=$3
INCLUDE_EXAMPLES=$4
PLUGIN_ROOT=$5

TEMPLATE_DIR="$PLUGIN_ROOT/templates"
TOOL_DIR="$PLUGIN_ROOT/tools/scaffold"

echo -e "${GREEN}=== Go DDD Scaffold ===${NC}"
echo "项目: $PROJECT_NAME | 模块: $GO_MODULE | 数据库: $DATABASE | 示例: $INCLUDE_EXAMPLES"
echo ""

# 验证 Go
echo -e "${BLUE}[1/6] 验证环境...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}Go 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓ $(go version)${NC}"

# 检查目录
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}目录已存在: $PROJECT_NAME${NC}"
    exit 1
fi

# 构建 scaffold CLI
echo -e "${BLUE}[2/6] 构建渲染工具...${NC}"
SCAFFOLD_BIN=$(mktemp)
(cd "$TOOL_DIR" && go build -o "$SCAFFOLD_BIN" .)
echo -e "${GREEN}✓ scaffold CLI 构建完成${NC}"

# 生成变量文件
echo -e "${BLUE}[3/6] 生成项目文件...${NC}"
VARS_FILE=$(mktemp)
INCLUDE_BOOL="true"
if [ "$INCLUDE_EXAMPLES" = "no" ]; then
    INCLUDE_BOOL="false"
fi

cat > "$VARS_FILE" << EOF
project_name: "$PROJECT_NAME"
go_module: "$GO_MODULE"
database: "$DATABASE"
include_examples: $INCLUDE_BOOL
go_version: "1.26"
entity_name: "User"
entity_name_lower: "user"
entity_id_type: "uuid.UUID"
EOF

# 渲染模板
"$SCAFFOLD_BIN" -vars "$VARS_FILE" -templates "$TEMPLATE_DIR" -output "$PROJECT_NAME"
echo -e "${GREEN}✓ 文件生成完成${NC}"

# 初始化 Go 模块
echo -e "${BLUE}[4/6] 初始化 Go 模块...${NC}"
cd "$PROJECT_NAME"
go mod init "$GO_MODULE"
go mod tidy
echo -e "${GREEN}✓ 模块初始化完成${NC}"

# Ent 代码生成
echo -e "${BLUE}[5/6] 生成 Ent 代码...${NC}"
if [ "$INCLUDE_EXAMPLES" = "yes" ]; then
    go generate ./internal/ent/...
    go mod tidy
    echo -e "${GREEN}✓ Ent 代码生成完成${NC}"
else
    echo "跳过（无示例）"
fi

# 验证
echo -e "${BLUE}[6/6] 验证构建...${NC}"
go build ./...
echo -e "${GREEN}✓ 构建验证通过${NC}"
cd ..

# 清理临时文件
rm -f "$SCAFFOLD_BIN" "$VARS_FILE"

echo ""
echo -e "${GREEN}=== 项目生成完成 ===${NC}"
echo ""
echo "后续步骤:"
echo "  cd $PROJECT_NAME"
if [ "$DATABASE" = "mysql" ]; then
    echo "  docker-compose -f docker/docker-compose.yaml up -d"
fi
echo "  make migrate"
echo "  make run"
echo "  curl http://localhost:8080/health"
```

- [ ] **Step 2: 重写 `commands/init-go-web.md`（~80 行）**

```markdown
---
name: init-go-web
description: 初始化 Go DDD Web 项目（Gin + Ent + Viper + slog + Prometheus + Sentry）
argument-hint: "[项目名称]"
allowed-tools:
  - Bash
  - AskUserQuestion
---

# 初始化 Go DDD Web 项目

## 执行流程

### 第 1 步: 收集项目信息

使用 AskUserQuestion 逐步收集:

1. **项目名称**（必需）: 小写字母、数字、连字符
2. **Go module 路径**（必需）: 如 `github.com/myorg/my-service`
3. **数据库类型**: mysql（默认）或 sqlite
4. **是否包含示例代码**: yes（默认）或 no

### 第 2 步: 调用生成脚本

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate.sh \
  "<project_name>" \
  "<go_module>" \
  "<database>" \
  "<include_examples>" \
  "${CLAUDE_PLUGIN_ROOT}"
```

### 第 3 步: 显示后续步骤

```
cd <project-name>
docker-compose -f docker/docker-compose.yaml up -d  # MySQL
make migrate
make run
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/users
```

## 前置依赖

- Go 1.26+

## 错误处理

- 目录已存在: 提示选择其他名称
- Go 未安装: 提示安装 Go 1.26+
- 构建失败: 显示错误信息
```

- [ ] **Step 3: 端到端测试**

```bash
cd plugins/go-ddd-scaffold
bash scripts/generate.sh test-project github.com/test/test-project mysql yes "$(pwd)"
cd test-project && go test ./... -v
cd .. && rm -rf test-project
```

Expected: 全流程成功，测试通过。

- [ ] **Step 4: 提交**

```bash
git add plugins/go-ddd-scaffold/scripts/generate.sh plugins/go-ddd-scaffold/commands/init-go-web.md
git commit -m "feat(go-ddd-scaffold): 重写 generate.sh 和 init-go-web 命令"
```

---

## 阶段 4: 插件收尾

---

### Task 10: 删除旧文件，清理遗留

**Files:**
- Delete: `plugins/go-ddd-scaffold/scripts/render.py`
- Delete: `plugins/go-ddd-scaffold/scripts/requirements.txt`
- Delete: `plugins/go-ddd-scaffold/reference/` (参考实现不发布)

- [ ] **Step 1: 删除旧 Python 渲染系统**

```bash
rm plugins/go-ddd-scaffold/scripts/render.py
rm plugins/go-ddd-scaffold/scripts/requirements.txt
```

- [ ] **Step 2: 删除参考实现（已提取为模板）**

```bash
rm -rf plugins/go-ddd-scaffold/reference/
```

- [ ] **Step 3: 更新 `.gitignore`**

确保 `plugins/go-ddd-scaffold/.gitignore` 包含：

```
# 生成的测试项目
test-project/
```

- [ ] **Step 4: 提交**

```bash
git add -A plugins/go-ddd-scaffold/
git commit -m "chore(go-ddd-scaffold): 删除 Python 渲染系统和参考实现"
```

---

### Task 11: 精简 Skills

**Files:**
- Modify: `plugins/go-ddd-scaffold/skills/ddd-core-concepts/SKILL.md`
- Delete: `plugins/go-ddd-scaffold/skills/ddd-core-concepts/references/entity-patterns.md`
- Delete: `plugins/go-ddd-scaffold/skills/ddd-core-concepts/references/value-object-patterns.md`
- Delete: `plugins/go-ddd-scaffold/skills/ddd-core-concepts/references/aggregate-patterns.md`
- Delete: `plugins/go-ddd-scaffold/skills/ddd-core-concepts/references/domain-service-patterns.md`
- Create: `plugins/go-ddd-scaffold/skills/ddd-core-concepts/references/core-building-blocks.md`（合并后）
- Modify: 其他 5 个 skill 的 SKILL.md 和 references（同理）

此任务按设计文档执行 skills 精简，每个 skill 保留 1-2 份参考文档，SKILL.md 从 ~200+ 行精简到 ~80 行。

- [ ] **Step 1: 精简 ddd-core-concepts**

合并 entity-patterns.md + value-object-patterns.md + aggregate-patterns.md → `core-building-blocks.md`
保留 repository-patterns.md → 重命名为 `repository-patterns.md`
保留 domain-events-patterns.md → 重命名为 `domain-events.md`
删除 domain-service-patterns.md（内容并入 SKILL.md 速查表）

精简 SKILL.md 到 ~80 行：保留触发短语、6 个构建块的速查表（每个 ~10 行），删除大段代码示例。

- [ ] **Step 2: 精简 ddd-layered-architecture**

合并 domain-layer-guide.md + application-layer-guide.md + infrastructure-layer-guide.md + interface-layer-guide.md → `layered-architecture-guide.md`
保留 dependency-injection.md

精简 SKILL.md 到 ~80 行。

- [ ] **Step 3: 精简 go-project-structure**

合并 directory-purposes.md + naming-conventions.md → `go-project-layout.md`

精简 SKILL.md 到 ~80 行。

- [ ] **Step 4: 精简 go-tech-stack-integration**

保留 gin-best-practices.md、ent-advanced.md
删除 observability-setup.md

精简 SKILL.md 到 ~80 行。

- [ ] **Step 5: 精简 clean-architecture-principles**

合并 clean-architecture-guide.md + solid-examples.md → `clean-architecture-and-solid.md`

精简 SKILL.md 到 ~80 行。

- [ ] **Step 6: 精简 cloudevents-pattern**

合并 cloudevents-spec.md + event-patterns.md → `cloudevents-guide.md`

精简 SKILL.md 到 ~80 行。

- [ ] **Step 7: 验证所有 skill 文件存在**

```bash
find plugins/go-ddd-scaffold/skills -name "SKILL.md" | wc -l
find plugins/go-ddd-scaffold/skills -name "*.md" -path "*/references/*" | wc -l
```

Expected: 6 个 SKILL.md，9 个参考文档。

- [ ] **Step 8: 提交**

```bash
git add plugins/go-ddd-scaffold/skills/
git commit -m "refactor(go-ddd-scaffold): 精简 skills — 20+ 参考文档合并为 9 份"
```

---

### Task 12: 精简文档，更新 plugin.json

**Files:**
- Rewrite: `plugins/go-ddd-scaffold/README.md`（~80 行）
- Rewrite: `plugins/go-ddd-scaffold/TESTING.md`（~80 行）
- Modify: `plugins/go-ddd-scaffold/.claude-plugin/plugin.json`

- [ ] **Step 1: 重写 `README.md`（~80 行）**

只保留三部分内容：这是什么、前置依赖、如何使用。

- [ ] **Step 2: 重写 `TESTING.md`（~80 行）**

只保留：如何验证生成的项目、如何运行测试、验收标准清单。

- [ ] **Step 3: 更新 `plugin.json` 版本**

将 `version` 从 `0.1.0` 更新为 `0.2.0`。

- [ ] **Step 4: 提交**

```bash
git add plugins/go-ddd-scaffold/README.md plugins/go-ddd-scaffold/TESTING.md plugins/go-ddd-scaffold/.claude-plugin/plugin.json
git commit -m "docs(go-ddd-scaffold): 精简 README 和 TESTING，更新版本为 0.2.0"
```

---

### Task 13: 最终验证 — 验收标准全部通过

**验收标准清单：**

- [ ] **Step 1: MySQL 项目生成 + 编译**

```bash
cd plugins/go-ddd-scaffold
bash scripts/generate.sh mysql-test github.com/test/mysql-test mysql yes "$(pwd)"
cd mysql-test && go build ./...
```

Expected: 编译成功。

- [ ] **Step 2: SQLite 项目生成 + 编译**

```bash
cd plugins/go-ddd-scaffold
bash scripts/generate.sh sqlite-test github.com/test/sqlite-test sqlite yes "$(pwd)"
cd sqlite-test && go build ./...
```

Expected: 编译成功。

- [ ] **Step 3: 无示例项目生成 + 编译**

```bash
cd plugins/go-ddd-scaffold
bash scripts/generate.sh skeleton-test github.com/test/skeleton-test mysql no "$(pwd)"
cd skeleton-test && go build ./...
```

Expected: 编译成功（空骨架）。

- [ ] **Step 4: 测试通过**

```bash
cd plugins/go-ddd-scaffold/mysql-test
go test ./... -v
```

Expected: 所有测试通过。

- [ ] **Step 5: 清理测试项目**

```bash
cd plugins/go-ddd-scaffold
rm -rf mysql-test sqlite-test skeleton-test
```

- [ ] **Step 6: 提交最终状态**

```bash
git add -A plugins/go-ddd-scaffold/
git commit -m "feat(go-ddd-scaffold): v0.2.0 — 完成重构，验收标准全部通过"
```
