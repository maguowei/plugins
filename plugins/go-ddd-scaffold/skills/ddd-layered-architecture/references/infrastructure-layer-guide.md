# Infrastructure Layer 完整指南

## Infrastructure Layer 的角色

Infrastructure Layer (基础设施层) 提供技术实现，支撑上层业务逻辑的运行。它实现了 Domain Layer 定义的接口，并提供与外部系统交互的能力。

**核心职责**:
- 实现 Domain 定义的仓储接口
- 数据库访问和 ORM 集成
- 外部服务集成 (邮件、短信、支付等)
- 消息队列集成
- 缓存实现
- 可观测性 (日志、监控、追踪)
- 配置管理

**不应包含**:
- 业务规则 (属于 Domain Layer)
- 用例编排 (属于 Application Layer)
- HTTP 请求处理 (属于 Interface Layer)

## 组织结构

### 推荐的目录结构

```
internal/app/infrastructure/
├── repository/                     # 仓储实现
│   ├── user_repository_impl.go
│   ├── user_repository_impl_test.go
│   └── order_repository_impl.go
├── external/                       # 外部服务集成
│   ├── email/
│   │   ├── smtp_email_service.go
│   │   └── smtp_email_service_test.go
│   ├── payment/
│   │   └── stripe_payment_service.go
│   └── sms/
│       └── twilio_sms_service.go
├── cache/                          # 缓存实现
│   ├── redis_cache.go
│   └── memory_cache.go
├── messagequeue/                   # 消息队列
│   ├── kafka_publisher.go
│   └── kafka_consumer.go
├── observability/                  # 可观测性
│   ├── logger.go
│   ├── metrics.go
│   └── tracer.go
└── config/                         # 配置管理
    └── config.go
```

## Repository 实现

### 实现 Domain 定义的接口

```go
package repository

import (
    "context"
    "database/sql"
    "errors"
    "github.com/google/uuid"

    domainrepo "myproject/internal/app/domain/user/repository"
    "myproject/internal/app/domain/user/entity"
    "myproject/internal/app/domain/user/valueobject"
)

// UserRepositoryImpl 用户仓储实现 (实现 Domain 接口)
type UserRepositoryImpl struct {
    db *sql.DB
}

// 编译时检查是否实现了接口
var _ domainrepo.UserRepository = (*UserRepositoryImpl)(nil)

// NewUserRepositoryImpl 创建仓储实现
func NewUserRepositoryImpl(db *sql.DB) *UserRepositoryImpl {
    return &UserRepositoryImpl{db: db}
}

// FindByID 根据 ID 查找用户
func (r *UserRepositoryImpl) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    // 1. 数据库查询
    query := `SELECT id, email, name, password_hash, status, created_at, updated_at
              FROM users WHERE id = ?`

    var dbUser struct {
        ID           string
        Email        string
        Name         string
        PasswordHash string
        Status       string
        CreatedAt    time.Time
        UpdatedAt    time.Time
    }

    err := r.db.QueryRowContext(ctx, query, id.String()).Scan(
        &dbUser.ID,
        &dbUser.Email,
        &dbUser.Name,
        &dbUser.PasswordHash,
        &dbUser.Status,
        &dbUser.CreatedAt,
        &dbUser.UpdatedAt,
    )

    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, domainrepo.ErrUserNotFound
        }
        return nil, err
    }

    // 2. 转换为领域对象
    return r.toDomainModel(&dbUser)
}

// Save 保存用户
func (r *UserRepositoryImpl) Save(ctx context.Context, user *entity.User) error {
    // 检查是否已存在
    exists, err := r.Exists(ctx, user.ID())
    if err != nil {
        return err
    }

    if exists {
        return r.update(ctx, user)
    }
    return r.insert(ctx, user)
}

// insert 插入新用户
func (r *UserRepositoryImpl) insert(ctx context.Context, user *entity.User) error {
    query := `INSERT INTO users (id, email, name, password_hash, status, created_at, updated_at)
              VALUES (?, ?, ?, ?, ?, ?, ?)`

    _, err := r.db.ExecContext(ctx, query,
        user.ID().String(),
        user.Email().Value(),
        user.Name(),
        user.PasswordHash(),
        user.Status().String(),
        user.CreatedAt(),
        user.UpdatedAt(),
    )

    if err != nil {
        // 转换数据库错误为领域错误
        if isUniqueViolation(err) {
            return domainrepo.ErrDuplicateEmail
        }
        return err
    }

    return nil
}

// update 更新用户
func (r *UserRepositoryImpl) update(ctx context.Context, user *entity.User) error {
    query := `UPDATE users
              SET email = ?, name = ?, password_hash = ?, status = ?, updated_at = ?
              WHERE id = ?`

    _, err := r.db.ExecContext(ctx, query,
        user.Email().Value(),
        user.Name(),
        user.PasswordHash(),
        user.Status().String(),
        user.UpdatedAt(),
        user.ID().String(),
    )

    return err
}

// Exists 检查用户是否存在
func (r *UserRepositoryImpl) Exists(ctx context.Context, id uuid.UUID) (bool, error) {
    query := `SELECT COUNT(*) FROM users WHERE id = ?`

    var count int
    err := r.db.QueryRowContext(ctx, query, id.String()).Scan(&count)
    if err != nil {
        return false, err
    }

    return count > 0, nil
}

// FindByEmail 根据邮箱查找用户
func (r *UserRepositoryImpl) FindByEmail(ctx context.Context, email valueobject.Email) (*entity.User, error) {
    query := `SELECT id, email, name, password_hash, status, created_at, updated_at
              FROM users WHERE email = ?`

    var dbUser struct {
        ID           string
        Email        string
        Name         string
        PasswordHash string
        Status       string
        CreatedAt    time.Time
        UpdatedAt    time.Time
    }

    err := r.db.QueryRowContext(ctx, query, email.Value()).Scan(
        &dbUser.ID,
        &dbUser.Email,
        &dbUser.Name,
        &dbUser.PasswordHash,
        &dbUser.Status,
        &dbUser.CreatedAt,
        &dbUser.UpdatedAt,
    )

    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, domainrepo.ErrUserNotFound
        }
        return nil, err
    }

    return r.toDomainModel(&dbUser)
}

// toDomainModel 数据库模型 -> 领域模型
func (r *UserRepositoryImpl) toDomainModel(dbUser *struct {
    ID           string
    Email        string
    Name         string
    PasswordHash string
    Status       string
    CreatedAt    time.Time
    UpdatedAt    time.Time
}) (*entity.User, error) {
    id, err := uuid.Parse(dbUser.ID)
    if err != nil {
        return nil, err
    }

    email, err := valueobject.NewEmail(dbUser.Email)
    if err != nil {
        return nil, err
    }

    status, err := valueobject.ParseUserStatus(dbUser.Status)
    if err != nil {
        return nil, err
    }

    return entity.ReconstructUser(
        id,
        email,
        dbUser.Name,
        dbUser.PasswordHash,
        status,
        dbUser.CreatedAt,
        dbUser.UpdatedAt,
    ), nil
}
```

## ORM 选择与集成

### Ent 框架集成

```go
package repository

import (
    "context"
    "myproject/internal/ent"
    "myproject/internal/ent/user"
)

// EntUserRepository Ent ORM 实现
type EntUserRepository struct {
    client *ent.Client
}

func NewEntUserRepository(client *ent.Client) *EntUserRepository {
    return &EntUserRepository{client: client}
}

// FindByID 使用 Ent 查询
func (r *EntUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    // Ent 查询
    u, err := r.client.User.
        Query().
        Where(user.ID(id)).
        Only(ctx)

    if err != nil {
        if ent.IsNotFound(err) {
            return nil, domainrepo.ErrUserNotFound
        }
        return nil, err
    }

    // 转换为领域对象
    return r.toDomain(u), nil
}

// Save 使用 Ent 保存
func (r *EntUserRepository) Save(ctx context.Context, usr *entity.User) error {
    // Upsert (插入或更新)
    return r.client.User.
        Create().
        SetID(usr.ID()).
        SetEmail(usr.Email().Value()).
        SetName(usr.Name()).
        SetPasswordHash(usr.PasswordHash()).
        SetStatus(usr.Status().String()).
        SetCreatedAt(usr.CreatedAt()).
        SetUpdatedAt(usr.UpdatedAt()).
        OnConflict().
        UpdateNewValues().
        Exec(ctx)
}

// FindWithRelations 查询包含关联对象
func (r *EntUserRepository) FindWithRelations(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    u, err := r.client.User.
        Query().
        Where(user.ID(id)).
        WithOrders().    // 预加载订单
        WithProfile().   // 预加载个人资料
        Only(ctx)

    if err != nil {
        if ent.IsNotFound(err) {
            return nil, domainrepo.ErrUserNotFound
        }
        return nil, err
    }

    return r.toDomain(u), nil
}

// toDomain Ent 模型 -> 领域模型
func (r *EntUserRepository) toDomain(u *ent.User) *entity.User {
    email, _ := valueobject.NewEmail(u.Email)
    status, _ := valueobject.ParseUserStatus(u.Status)

    return entity.ReconstructUser(
        u.ID,
        email,
        u.Name,
        u.PasswordHash,
        status,
        u.CreatedAt,
        u.UpdatedAt,
    )
}
```

### GORM 框架集成

```go
package repository

import (
    "context"
    "errors"
    "gorm.io/gorm"
)

// GormUserRepository GORM 实现
type GormUserRepository struct {
    db *gorm.DB
}

// UserModel GORM 数据库模型
type UserModel struct {
    ID           string    `gorm:"primaryKey"`
    Email        string    `gorm:"uniqueIndex"`
    Name         string
    PasswordHash string
    Status       string
    CreatedAt    time.Time
    UpdatedAt    time.Time
}

func (UserModel) TableName() string {
    return "users"
}

func NewGormUserRepository(db *gorm.DB) *GormUserRepository {
    return &GormUserRepository{db: db}
}

// FindByID 使用 GORM 查询
func (r *GormUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    var model UserModel

    err := r.db.WithContext(ctx).
        Where("id = ?", id.String()).
        First(&model).Error

    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, domainrepo.ErrUserNotFound
        }
        return nil, err
    }

    return r.toDomain(&model), nil
}

// Save 使用 GORM 保存
func (r *GormUserRepository) Save(ctx context.Context, usr *entity.User) error {
    model := r.toModel(usr)

    // GORM Upsert
    return r.db.WithContext(ctx).
        Clauses(clause.OnConflict{
            UpdateAll: true,
        }).
        Create(model).Error
}

// toDomain GORM 模型 -> 领域模型
func (r *GormUserRepository) toDomain(model *UserModel) *entity.User {
    id, _ := uuid.Parse(model.ID)
    email, _ := valueobject.NewEmail(model.Email)
    status, _ := valueobject.ParseUserStatus(model.Status)

    return entity.ReconstructUser(
        id,
        email,
        model.Name,
        model.PasswordHash,
        status,
        model.CreatedAt,
        model.UpdatedAt,
    )
}

// toModel 领域模型 -> GORM 模型
func (r *GormUserRepository) toModel(usr *entity.User) *UserModel {
    return &UserModel{
        ID:           usr.ID().String(),
        Email:        usr.Email().Value(),
        Name:         usr.Name(),
        PasswordHash: usr.PasswordHash(),
        Status:       usr.Status().String(),
        CreatedAt:    usr.CreatedAt(),
        UpdatedAt:    usr.UpdatedAt(),
    }
}
```

## 数据库错误处理

### 将技术异常转为领域异常

```go
package repository

import (
    "errors"
    "strings"
)

// isUniqueViolation 检查是否是唯一性冲突
func isUniqueViolation(err error) bool {
    if err == nil {
        return false
    }

    // MySQL
    if strings.Contains(err.Error(), "Duplicate entry") {
        return true
    }

    // PostgreSQL
    if strings.Contains(err.Error(), "duplicate key value") {
        return true
    }

    // SQLite
    if strings.Contains(err.Error(), "UNIQUE constraint failed") {
        return true
    }

    return false
}

// isForeignKeyViolation 检查是否是外键约束冲突
func isForeignKeyViolation(err error) bool {
    if err == nil {
        return false
    }

    return strings.Contains(err.Error(), "foreign key constraint")
}

// Save 错误转换示例
func (r *UserRepositoryImpl) Save(ctx context.Context, user *entity.User) error {
    err := r.insert(ctx, user)
    if err != nil {
        // 转换为领域错误
        if isUniqueViolation(err) {
            return domainrepo.ErrDuplicateEmail
        }
        if isForeignKeyViolation(err) {
            return domainrepo.ErrInvalidReference
        }
        return err
    }
    return nil
}
```

## 缓存实现

### Redis 缓存

```go
package cache

import (
    "context"
    "encoding/json"
    "time"

    "github.com/redis/go-redis/v9"
)

// RedisCache Redis 缓存实现
type RedisCache struct {
    client *redis.Client
}

func NewRedisCache(client *redis.Client) *RedisCache {
    return &RedisCache{client: client}
}

// Get 获取缓存
func (c *RedisCache) Get(ctx context.Context, key string, dest interface{}) error {
    data, err := c.client.Get(ctx, key).Bytes()
    if err != nil {
        if err == redis.Nil {
            return ErrCacheMiss
        }
        return err
    }

    return json.Unmarshal(data, dest)
}

// Set 设置缓存
func (c *RedisCache) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
    data, err := json.Marshal(value)
    if err != nil {
        return err
    }

    return c.client.Set(ctx, key, data, ttl).Err()
}

// Delete 删除缓存
func (c *RedisCache) Delete(ctx context.Context, key string) error {
    return c.client.Del(ctx, key).Err()
}

// 使用缓存的仓储装饰器
type CachedUserRepository struct {
    repo  repository.UserRepository
    cache *RedisCache
}

func NewCachedUserRepository(repo repository.UserRepository, cache *RedisCache) *CachedUserRepository {
    return &CachedUserRepository{
        repo:  repo,
        cache: cache,
    }
}

// FindByID 先查缓存，再查数据库
func (r *CachedUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    cacheKey := fmt.Sprintf("user:%s", id.String())

    // 1. 尝试从缓存获取
    var user *entity.User
    err := r.cache.Get(ctx, cacheKey, &user)
    if err == nil {
        return user, nil // 缓存命中
    }

    // 2. 缓存未命中，从数据库查询
    user, err = r.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // 3. 写入缓存
    _ = r.cache.Set(ctx, cacheKey, user, 10*time.Minute)

    return user, nil
}

// Save 保存后清除缓存
func (r *CachedUserRepository) Save(ctx context.Context, user *entity.User) error {
    // 1. 保存到数据库
    if err := r.repo.Save(ctx, user); err != nil {
        return err
    }

    // 2. 清除缓存
    cacheKey := fmt.Sprintf("user:%s", user.ID().String())
    _ = r.cache.Delete(ctx, cacheKey)

    return nil
}
```

## 外部服务集成

### Email 服务

```go
package email

import (
    "context"
    "fmt"
    "net/smtp"
)

// SMTPEmailService SMTP 邮件服务
type SMTPEmailService struct {
    host     string
    port     int
    username string
    password string
    from     string
}

func NewSMTPEmailService(host string, port int, username, password, from string) *SMTPEmailService {
    return &SMTPEmailService{
        host:     host,
        port:     port,
        username: username,
        password: password,
        from:     from,
    }
}

// SendWelcomeEmail 发送欢迎邮件
func (s *SMTPEmailService) SendWelcomeEmail(ctx context.Context, to, name string) error {
    subject := "Welcome to Our Service"
    body := fmt.Sprintf("Hello %s,\n\nWelcome to our service!", name)

    return s.send(to, subject, body)
}

// send 发送邮件
func (s *SMTPEmailService) send(to, subject, body string) error {
    // SMTP 认证
    auth := smtp.PlainAuth("", s.username, s.password, s.host)

    // 邮件内容
    msg := []byte(fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
        s.from, to, subject, body))

    // 发送
    addr := fmt.Sprintf("%s:%d", s.host, s.port)
    return smtp.SendMail(addr, auth, s.from, []string{to}, msg)
}
```

### 支付服务

```go
package payment

import (
    "context"
    "errors"
)

// StripePaymentService Stripe 支付服务
type StripePaymentService struct {
    apiKey string
}

func NewStripePaymentService(apiKey string) *StripePaymentService {
    return &StripePaymentService{apiKey: apiKey}
}

// ChargeCard 扣款
func (s *StripePaymentService) ChargeCard(
    ctx context.Context,
    amount int64,
    currency string,
    cardToken string,
) (string, error) {
    // 调用 Stripe API
    // 简化示例
    if amount <= 0 {
        return "", errors.New("invalid amount")
    }

    // 返回支付ID
    return "ch_1234567890", nil
}

// RefundCharge 退款
func (s *StripePaymentService) RefundCharge(ctx context.Context, chargeID string) error {
    // 调用 Stripe API 退款
    return nil
}
```

## 消息队列集成

### Kafka 发布器

```go
package messagequeue

import (
    "context"
    "encoding/json"

    "github.com/segmentio/kafka-go"
)

// KafkaPublisher Kafka 事件发布器
type KafkaPublisher struct {
    writer *kafka.Writer
}

func NewKafkaPublisher(brokers []string, topic string) *KafkaPublisher {
    return &KafkaPublisher{
        writer: &kafka.Writer{
            Addr:     kafka.TCP(brokers...),
            Topic:    topic,
            Balancer: &kafka.LeastBytes{},
        },
    }
}

// Publish 发布事件
func (p *KafkaPublisher) Publish(ctx context.Context, event event.DomainEvent) error {
    // 序列化事件
    data, err := json.Marshal(event)
    if err != nil {
        return err
    }

    // 发送到 Kafka
    return p.writer.WriteMessages(ctx, kafka.Message{
        Key:   []byte(event.AggregateID()),
        Value: data,
    })
}

// PublishBatch 批量发布
func (p *KafkaPublisher) PublishBatch(ctx context.Context, events []event.DomainEvent) error {
    messages := make([]kafka.Message, len(events))

    for i, evt := range events {
        data, err := json.Marshal(evt)
        if err != nil {
            return err
        }

        messages[i] = kafka.Message{
            Key:   []byte(evt.AggregateID()),
            Value: data,
        }
    }

    return p.writer.WriteMessages(ctx, messages...)
}

// Close 关闭发布器
func (p *KafkaPublisher) Close() error {
    return p.writer.Close()
}
```

## 可观测性实现

### 结构化日志 (slog)

```go
package observability

import (
    "log/slog"
    "os"
)

// NewLogger 创建结构化日志器
func NewLogger() *slog.Logger {
    return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
        Level: slog.LevelInfo,
    }))
}

// 使用示例
func ExampleLogging(logger *slog.Logger) {
    logger.Info("user created",
        "user_id", "123",
        "email", "test@example.com",
    )

    logger.Error("failed to save user",
        "user_id", "123",
        "error", "database connection lost",
    )
}
```

### Prometheus 指标

```go
package observability

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    // HTTP 请求总数
    HTTPRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    // HTTP 请求延迟
    HTTPRequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request latencies in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )

    // 数据库连接数
    DBConnections = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "db_connections",
            Help: "Number of database connections",
        },
    )
)

// 使用示例
func RecordHTTPRequest(method, endpoint string, statusCode int, duration float64) {
    HTTPRequestsTotal.WithLabelValues(method, endpoint, fmt.Sprintf("%d", statusCode)).Inc()
    HTTPRequestDuration.WithLabelValues(method, endpoint).Observe(duration)
}
```

### OpenTelemetry 追踪

```go
package observability

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

var tracer = otel.Tracer("myproject")

// TraceRepositoryCall 追踪仓储调用
func TraceRepositoryCall(ctx context.Context, operation string, fn func(context.Context) error) error {
    ctx, span := tracer.Start(ctx, operation,
        trace.WithAttributes(
            attribute.String("layer", "repository"),
        ),
    )
    defer span.End()

    err := fn(ctx)
    if err != nil {
        span.RecordError(err)
    }

    return err
}

// 使用示例
func (r *UserRepositoryImpl) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    var user *entity.User
    var err error

    err = TraceRepositoryCall(ctx, "UserRepository.FindByID", func(ctx context.Context) error {
        user, err = r.findByIDInternal(ctx, id)
        return err
    })

    return user, err
}
```

## 配置管理

### Viper 配置

```go
package config

import (
    "github.com/spf13/viper"
)

// Config 应用配置
type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Redis    RedisConfig
    Kafka    KafkaConfig
}

type ServerConfig struct {
    Port int
    Host string
}

type DatabaseConfig struct {
    Host     string
    Port     int
    User     string
    Password string
    Database string
}

type RedisConfig struct {
    Host     string
    Port     int
    Password string
    DB       int
}

type KafkaConfig struct {
    Brokers []string
    Topic   string
}

// LoadConfig 加载配置
func LoadConfig(path string) (*Config, error) {
    viper.SetConfigFile(path)
    viper.SetConfigType("yaml")

    // 读取环境变量
    viper.AutomaticEnv()

    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    var config Config
    if err := viper.Unmarshal(&config); err != nil {
        return nil, err
    }

    return &config, nil
}
```

## 测试基础设施层

### 使用 testcontainers 进行集成测试

```go
package repository_test

import (
    "context"
    "database/sql"
    "testing"

    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/wait"
)

func setupTestDB(t *testing.T) (*sql.DB, func()) {
    ctx := context.Background()

    // 启动 MySQL 容器
    req := testcontainers.ContainerRequest{
        Image:        "mysql:8.0",
        ExposedPorts: []string{"3306/tcp"},
        Env: map[string]string{
            "MYSQL_ROOT_PASSWORD": "password",
            "MYSQL_DATABASE":      "testdb",
        },
        WaitingFor: wait.ForLog("ready for connections"),
    }

    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req,
        Started:          true,
    })
    if err != nil {
        t.Fatal(err)
    }

    // 获取连接信息
    host, _ := container.Host(ctx)
    port, _ := container.MappedPort(ctx, "3306")

    // 连接数据库
    dsn := fmt.Sprintf("root:password@tcp(%s:%s)/testdb", host, port.Port())
    db, err := sql.Open("mysql", dsn)
    if err != nil {
        t.Fatal(err)
    }

    // 运行迁移
    runMigrations(db)

    // 清理函数
    cleanup := func() {
        db.Close()
        container.Terminate(ctx)
    }

    return db, cleanup
}

func TestUserRepository_Integration(t *testing.T) {
    db, cleanup := setupTestDB(t)
    defer cleanup()

    repo := repository.NewUserRepositoryImpl(db)

    // 测试 Save
    user, _ := entity.NewUser(...)
    err := repo.Save(context.Background(), user)
    assert.NoError(t, err)

    // 测试 FindByID
    found, err := repo.FindByID(context.Background(), user.ID())
    assert.NoError(t, err)
    assert.Equal(t, user.ID(), found.ID())
}
```

## 总结

Infrastructure Layer 的关键实践:
- ✅ 实现 Domain 定义的接口
- ✅ ORM 模型与领域模型分离
- ✅ 数据库错误转换为领域错误
- ✅ 使用缓存提升性能
- ✅ 外部服务通过接口抽象
- ✅ 集成测试使用容器化数据库
- ✅ 完善的可观测性 (日志、监控、追踪)
