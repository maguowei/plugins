# 依赖注入最佳实践

## 为什么需要依赖注入

依赖注入 (Dependency Injection, DI) 是实现控制反转 (Inversion of Control, IoC) 的一种方式，它有以下优势：

**核心优势**:
- **解耦**: 组件不直接创建依赖，降低耦合度
- **易于测试**: 可以注入 Mock 对象进行单元测试
- **灵活性**: 轻松替换实现（如从 MySQL 切换到 PostgreSQL）
- **可维护性**: 依赖关系清晰，易于理解和修改

## 推荐方式：手动依赖注入

**本项目推荐完全手动依赖注入**，不使用 Wire、Fx 等依赖注入框架。

**为什么选择手动注入？**

| 优势 | 说明 |
|------|------|
| **直观易懂** | 代码即文档，依赖关系一目了然 |
| **无魔法** | 没有代码生成、没有运行时反射，纯粹的 Go 代码 |
| **易于调试** | 可以直接在 IDE 中跳转、断点调试 |
| **零学习成本** | 不需要学习额外的框架和 DSL |
| **AI 友好** | Claude Code 等 AI 工具可以轻松理解和生成依赖注入代码 |
| **编译时检查** | 所有依赖错误在编译时就能发现 |

**AI 辅助编写依赖注入代码**:

借助 Claude Code 等 AI 编程工具，手动依赖注入的"繁琐"问题已不复存在：
- AI 可以自动分析项目结构，识别所有需要注入的依赖
- AI 生成的代码与手写代码完全一致，直观且易于理解
- 相比 Wire 生成的 `wire_gen.go`，手动注入代码更容易阅读和维护
- 当添加新的依赖时，AI 可以自动更新初始化代码

## Go 中的 DI 方式

### 1. 构造函数注入 (推荐)

```go
package service

// UserApplicationService 用户应用服务
type UserApplicationService struct {
    userRepo       repository.UserRepository  // 依赖接口
    eventPublisher event.EventPublisher       // 依赖接口
}

// NewUserApplicationService 构造函数注入
func NewUserApplicationService(
    userRepo repository.UserRepository,
    eventPublisher event.EventPublisher,
) *UserApplicationService {
    return &UserApplicationService{
        userRepo:       userRepo,
        eventPublisher: eventPublisher,
    }
}

// 优势:
// - 依赖显式声明
// - 编译时类型检查
// - 无法创建不完整的对象
// - Go 社区推荐的做法
```

### 2. 字段注入 (不推荐)

```go
// ❌ 不推荐: 字段注入

type UserService struct {
    repo repository.UserRepository
}

func main() {
    service := &UserService{}
    service.repo = repository.NewUserRepository() // 外部设置

    // 问题:
    // - 依赖不明确
    // - 可能创建不完整的对象
    // - 没有编译时检查
}
```

### 3. Method Injection (特定场景)

```go
// 方法注入 (用于可选依赖)
type UserService struct {
    repo repository.UserRepository
}

// SetLogger 可选的日志器
func (s *UserService) SetLogger(logger *slog.Logger) {
    s.logger = logger
}

// 适用场景: 可选依赖、运行时动态依赖
```

## 依赖组织

### 完整的 main.go 示例

```go
package main

import (
    "context"
    "database/sql"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    _ "github.com/go-sql-driver/mysql"

    "myproject/internal/app/application/service"
    "myproject/internal/app/infrastructure/repository"
    "myproject/internal/app/interface/http/handler"
    httpInterface "myproject/internal/app/interface/http"
    "myproject/pkg/config"
)

func main() {
    // 1. 加载配置
    cfg, err := config.LoadConfig("config.yaml")
    if err != nil {
        log.Fatalf("failed to load config: %v", err)
    }

    // 2. 初始化数据库
    db, err := initDatabase(cfg)
    if err != nil {
        log.Fatalf("failed to init database: %v", err)
    }
    defer db.Close()

    // 3. 初始化仓储
    userRepo := repository.NewUserRepositoryImpl(db)
    orderRepo := repository.NewOrderRepositoryImpl(db)

    // 4. 初始化事件发布器
    eventPublisher := event.NewInMemoryEventBus()

    // 5. 初始化应用服务
    userService := service.NewUserApplicationService(userRepo, eventPublisher)
    orderService := service.NewOrderApplicationService(orderRepo, userRepo, eventPublisher)

    // 6. 初始化 Handler
    userHandler := handler.NewUserHandler(userService)
    orderHandler := handler.NewOrderHandler(orderService)

    // 7. 设置路由
    router := httpInterface.SetupRouter(userHandler, orderHandler, nil)

    // 8. 启动 HTTP 服务器
    server := &http.Server{
        Addr:    fmt.Sprintf(":%d", cfg.Server.Port),
        Handler: router,
    }

    // 9. 优雅关闭
    go func() {
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("server error: %v", err)
        }
    }()

    log.Printf("Server started on :%d", cfg.Server.Port)

    // 10. 等待中断信号
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := server.Shutdown(ctx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }

    log.Println("Server exited")
}

func initDatabase(cfg *config.Config) (*sql.DB, error) {
    dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=true",
        cfg.Database.User,
        cfg.Database.Password,
        cfg.Database.Host,
        cfg.Database.Port,
        cfg.Database.Database,
    )

    db, err := sql.Open("mysql", dsn)
    if err != nil {
        return nil, err
    }

    // 连接池配置
    db.SetMaxOpenConns(cfg.Database.MaxOpenConns)
    db.SetMaxIdleConns(cfg.Database.MaxIdleConns)
    db.SetConnMaxLifetime(time.Hour)

    // 测试连接
    if err := db.Ping(); err != nil {
        return nil, err
    }

    return db, nil
}
```

## 单例 vs 工厂

### 单例模式 (无状态服务)

```go
// 单例: 服务是无状态的，可以重用

var (
    userServiceInstance *service.UserApplicationService
    once                sync.Once
)

// GetUserService 单例模式
func GetUserService() *service.UserApplicationService {
    once.Do(func() {
        userRepo := repository.NewUserRepositoryImpl(db)
        eventPublisher := event.NewInMemoryEventBus()
        userServiceInstance = service.NewUserApplicationService(userRepo, eventPublisher)
    })
    return userServiceInstance
}

// 适用: 无状态服务、数据库连接池、配置对象
```

### 工厂模式 (有状态对象)

```go
// 工厂: 每次都创建新实例

// UserFactory 用户工厂
type UserFactory struct {
    emailService *EmailService
}

func NewUserFactory(emailService *EmailService) *UserFactory {
    return &UserFactory{
        emailService: emailService,
    }
}

// CreateUser 每次创建新用户实例
func (f *UserFactory) CreateUser(email, name string) (*entity.User, error) {
    user, err := entity.NewUser(email, name, "")
    if err != nil {
        return nil, err
    }

    // 发送欢迎邮件
    f.emailService.SendWelcome(user.Email())

    return user, nil
}

// 适用: 有状态对象、需要每次创建新实例的场景
```

## 配置注入

### 从环境变量读取

```go
package config

import (
    "os"
    "strconv"
)

// Config 配置结构
type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
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

// LoadFromEnv 从环境变量加载配置
func LoadFromEnv() *Config {
    return &Config{
        Server: ServerConfig{
            Port: getEnvInt("SERVER_PORT", 8080),
            Host: getEnv("SERVER_HOST", "0.0.0.0"),
        },
        Database: DatabaseConfig{
            Host:     getEnv("DB_HOST", "localhost"),
            Port:     getEnvInt("DB_PORT", 3306),
            User:     getEnv("DB_USER", "root"),
            Password: getEnv("DB_PASSWORD", ""),
            Database: getEnv("DB_NAME", "mydb"),
        },
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        if intValue, err := strconv.Atoi(value); err == nil {
            return intValue
        }
    }
    return defaultValue
}
```

## 测试中的依赖注入

### Mock 对象注入

```go
package service_test

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"

    "myproject/internal/app/application/service"
)

// MockUserRepository Mock 仓储
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*entity.User), args.Error(1)
}

func (m *MockUserRepository) Save(ctx context.Context, user *entity.User) error {
    args := m.Called(ctx, user)
    return args.Error(0)
}

// TestUserApplicationService 使用 Mock
func TestUserApplicationService_CreateUser(t *testing.T) {
    // 创建 Mock
    mockRepo := new(MockUserRepository)
    mockPublisher := new(MockEventPublisher)

    // 注入 Mock (依赖注入)
    svc := service.NewUserApplicationService(mockRepo, mockPublisher)

    // 设置期望
    mockRepo.On("Save", mock.Anything, mock.Anything).Return(nil)
    mockPublisher.On("PublishBatch", mock.Anything, mock.Anything).Return(nil)

    // 执行测试
    req := dto.CreateUserRequest{
        Email:    "test@example.com",
        Name:     "Test",
        Password: "password",
    }

    user, err := svc.CreateUser(context.Background(), req)

    // 断言
    assert.NoError(t, err)
    assert.NotNil(t, user)

    mockRepo.AssertExpectations(t)
    mockPublisher.AssertExpectations(t)
}
```

## 为什么不推荐 Wire/Fx

虽然 Wire (Google) 和 Fx (Uber) 是流行的依赖注入框架，但本项目**不推荐使用**：

| 框架 | 问题 |
|------|------|
| **Wire** | 需要学习特定 DSL、生成的代码不直观、增加构建复杂度、调试困难 |
| **Fx** | 运行时反射开销、魔法般的依赖解析、错误信息不友好、学习曲线陡峭 |

**手动注入 + AI 工具是更好的选择**：

```go
// ✅ 推荐: 手动依赖注入 (所有项目规模)
// 借助 Claude Code 等 AI 工具，即使是大型项目也能轻松管理
func main() {
    // 基础设施层
    db := initDB()
    redis := initRedis()

    // 仓储层
    userRepo := repository.NewUserRepository(db)
    orderRepo := repository.NewOrderRepository(db)
    cacheRepo := repository.NewCacheRepository(redis)

    // 应用服务层
    eventBus := event.NewInMemoryEventBus()
    userService := service.NewUserService(userRepo, eventBus)
    orderService := service.NewOrderService(orderRepo, userRepo, eventBus)

    // 接口层
    userHandler := handler.NewUserHandler(userService)
    orderHandler := handler.NewOrderHandler(orderService)

    // 路由和服务器
    router := setupRouter(userHandler, orderHandler)
    startServer(router)
}

// 优势:
// - 代码即文档，依赖关系清晰可见
// - IDE 支持完美 (跳转、重构、查找引用)
// - 编译时检查，运行时零开销
// - AI 工具可以轻松理解和维护
```

## 总结

依赖注入的关键实践:
- ✅ **优先使用构造函数注入**
- ✅ **依赖接口而非实现** (DIP)
- ✅ **所有项目规模都推荐手动注入** (配合 AI 工具)
- ✅ 无状态服务使用单例，有状态对象使用工厂
- ✅ 测试时注入 Mock 对象
- ✅ 配置通过依赖注入传递
- ✅ 完整的生命周期管理 (启动、运行、优雅关闭)

**核心理念**: 借助 Claude Code 等 AI 编程工具，手动依赖注入的代码编写不再繁琐，而其带来的直观性、可调试性和零学习成本的优势远超任何 DI 框架。
