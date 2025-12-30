# SOLID 原则详解与 Go 实现

## SOLID 五原则概述

SOLID 是面向对象设计的五个基本原则，由 Robert C. Martin 提出。这些原则帮助开发者创建更易维护、扩展和测试的代码。虽然 Go 不是传统的面向对象语言，但 SOLID 原则同样适用。

## 1. Single Responsibility Principle (SRP) - 单一职责原则

**定义**: 一个类/结构体应该只有一个引起它变化的原因。

**本质**: 一个模块应该只对一个角色负责。

### 何时违反 SRP

当一个结构体承担多个职责时，就违反了 SRP：

```go
// ❌ 错误示例: User 结构体承担了过多职责
type User struct {
    ID    uuid.UUID
    Email string
    Name  string
}

// 职责1: 业务逻辑
func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    u.Name = newName
    return nil
}

// 职责2: 数据库操作
func (u *User) Save(db *sql.DB) error {
    _, err := db.Exec("UPDATE users SET name = ? WHERE id = ?", u.Name, u.ID)
    return err
}

// 职责3: 序列化
func (u *User) ToJSON() ([]byte, error) {
    return json.Marshal(u)
}

// 职责4: 邮件发送
func (u *User) SendWelcomeEmail() error {
    // 发送邮件逻辑
    return nil
}

// 问题:
// - 变更原因过多 (业务规则、数据库、序列化格式、邮件服务)
// - 难以测试
// - 违反了单一职责原则
```

### 正确做法: 职责分离

```go
// ✅ 正确示例: 职责分离

// 职责1: User 实体只负责业务逻辑
type User struct {
    id    uuid.UUID
    email string
    name  string
}

func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    u.name = newName
    return nil
}

// 职责2: UserRepository 负责数据库操作
type UserRepository struct {
    db *sql.DB
}

func (r *UserRepository) Save(ctx context.Context, user *User) error {
    _, err := r.db.ExecContext(ctx,
        "UPDATE users SET name = ? WHERE id = ?",
        user.name, user.id)
    return err
}

// 职责3: UserSerializer 负责序列化
type UserSerializer struct{}

func (s *UserSerializer) ToJSON(user *User) ([]byte, error) {
    return json.Marshal(map[string]interface{}{
        "id":    user.id,
        "email": user.email,
        "name":  user.name,
    })
}

// 职责4: EmailService 负责邮件发送
type EmailService struct {
    smtpConfig SMTPConfig
}

func (s *EmailService) SendWelcomeEmail(user *User) error {
    // 发送邮件逻辑
    return nil
}

// 优势:
// - 每个结构体只有一个变更原因
// - 易于测试
// - 易于维护
```

### Go 特定的 SRP 实现

```go
// 文件读取器只负责读取
type FileReader struct {
    filePath string
}

func (r *FileReader) Read() ([]byte, error) {
    return os.ReadFile(r.filePath)
}

// 文件解析器只负责解析
type ConfigParser struct{}

func (p *ConfigParser) Parse(data []byte) (*Config, error) {
    var config Config
    if err := json.Unmarshal(data, &config); err != nil {
        return nil, err
    }
    return &config, nil
}

// 配置验证器只负责验证
type ConfigValidator struct{}

func (v *ConfigValidator) Validate(config *Config) error {
    if config.Port <= 0 {
        return errors.New("invalid port")
    }
    return nil
}

// 使用组合
type ConfigLoader struct {
    reader    *FileReader
    parser    *ConfigParser
    validator *ConfigValidator
}

func (l *ConfigLoader) Load() (*Config, error) {
    // 读取
    data, err := l.reader.Read()
    if err != nil {
        return nil, err
    }

    // 解析
    config, err := l.parser.Parse(data)
    if err != nil {
        return nil, err
    }

    // 验证
    if err := l.validator.Validate(config); err != nil {
        return nil, err
    }

    return config, nil
}
```

## 2. Open-Closed Principle (OCP) - 开闭原则

**定义**: 软件实体应该对扩展开放，对修改关闭。

**本质**: 新增功能时，应该通过添加新代码而非修改现有代码。

### 使用接口实现扩展

```go
// ✅ 正确示例: 使用接口实现 OCP

// NotificationSender 通知发送接口
type NotificationSender interface {
    Send(message string) error
}

// EmailNotification 邮件通知实现
type EmailNotification struct {
    smtpServer string
}

func (e *EmailNotification) Send(message string) error {
    // 发送邮件
    fmt.Printf("Email sent: %s\n", message)
    return nil
}

// SMSNotification 短信通知实现
type SMSNotification struct {
    apiKey string
}

func (s *SMSNotification) Send(message string) error {
    // 发送短信
    fmt.Printf("SMS sent: %s\n", message)
    return nil
}

// PushNotification 推送通知实现 (新增功能，无需修改现有代码)
type PushNotification struct {
    deviceToken string
}

func (p *PushNotification) Send(message string) error {
    // 推送通知
    fmt.Printf("Push notification sent: %s\n", message)
    return nil
}

// NotificationService 通知服务 (对扩展开放，对修改关闭)
type NotificationService struct {
    senders []NotificationSender
}

func (s *NotificationService) AddSender(sender NotificationSender) {
    s.senders = append(s.senders, sender)
}

func (s *NotificationService) Notify(message string) error {
    for _, sender := range s.senders {
        if err := sender.Send(message); err != nil {
            return err
        }
    }
    return nil
}

// 使用示例
func main() {
    service := &NotificationService{}

    // 添加不同的发送器 (扩展)
    service.AddSender(&EmailNotification{smtpServer: "smtp.example.com"})
    service.AddSender(&SMSNotification{apiKey: "xxx"})
    service.AddSender(&PushNotification{deviceToken: "yyy"})

    // 无需修改 NotificationService 代码
    service.Notify("Hello World")
}
```

### 策略模式实现 OCP

```go
// 价格计算策略接口
type PricingStrategy interface {
    Calculate(basePrice float64) float64
}

// 标准定价
type StandardPricing struct{}

func (s *StandardPricing) Calculate(basePrice float64) float64 {
    return basePrice
}

// VIP 折扣定价
type VIPPricing struct {
    discountRate float64
}

func (v *VIPPricing) Calculate(basePrice float64) float64 {
    return basePrice * (1 - v.discountRate)
}

// 黑色星期五促销定价 (新增策略，不修改现有代码)
type BlackFridayPricing struct{}

func (b *BlackFridayPricing) Calculate(basePrice float64) float64 {
    return basePrice * 0.5 // 五折
}

// 订单处理器 (对扩展开放，对修改关闭)
type OrderProcessor struct {
    pricingStrategy PricingStrategy
}

func (o *OrderProcessor) SetPricingStrategy(strategy PricingStrategy) {
    o.pricingStrategy = strategy
}

func (o *OrderProcessor) CalculateTotal(items []OrderItem) float64 {
    var total float64
    for _, item := range items {
        total += o.pricingStrategy.Calculate(item.Price)
    }
    return total
}
```

### 装饰器模式实现 OCP

```go
// Logger 接口
type Logger interface {
    Log(message string)
}

// ConsoleLogger 基础实现
type ConsoleLogger struct{}

func (l *ConsoleLogger) Log(message string) {
    fmt.Println(message)
}

// TimestampLogger 装饰器 (添加时间戳)
type TimestampLogger struct {
    logger Logger
}

func (l *TimestampLogger) Log(message string) {
    timestamped := fmt.Sprintf("[%s] %s", time.Now().Format(time.RFC3339), message)
    l.logger.Log(timestamped)
}

// LevelLogger 装饰器 (添加日志级别)
type LevelLogger struct {
    logger Logger
    level  string
}

func (l *LevelLogger) Log(message string) {
    leveled := fmt.Sprintf("[%s] %s", l.level, message)
    l.logger.Log(leveled)
}

// 使用示例: 通过组合扩展功能，不修改原有代码
func main() {
    logger := &ConsoleLogger{}
    logger = &TimestampLogger{logger: logger}
    logger = &LevelLogger{logger: logger, level: "INFO"}

    logger.Log("Application started") // [INFO] [2024-01-15T10:30:00Z] Application started
}
```

## 3. Liskov Substitution Principle (LSP) - 里氏替换原则

**定义**: 子类型必须能够替换其父类型。

**本质**: 使用接口的代码应该可以无感知地使用任何实现。

### 违反 LSP 的陷阱

```go
// ❌ 错误示例: 违反 LSP

type Rectangle struct {
    width  float64
    height float64
}

func (r *Rectangle) SetWidth(w float64) {
    r.width = w
}

func (r *Rectangle) SetHeight(h float64) {
    r.height = h
}

func (r *Rectangle) Area() float64 {
    return r.width * r.height
}

// Square "继承" Rectangle (错误的抽象)
type Square struct {
    Rectangle
}

func (s *Square) SetWidth(w float64) {
    s.width = w
    s.height = w // 正方形宽高相同
}

func (s *Square) SetHeight(h float64) {
    s.width = h
    s.height = h
}

// 问题: Square 不能替换 Rectangle
func TestArea(r *Rectangle) {
    r.SetWidth(5)
    r.SetHeight(10)
    expected := 50.0
    actual := r.Area()
    // 如果传入 Square，actual 会是 100 而非 50，违反了 LSP
}
```

### 正确的抽象

```go
// ✅ 正确示例: 遵循 LSP

// Shape 接口
type Shape interface {
    Area() float64
}

// Rectangle 实现
type Rectangle struct {
    width  float64
    height float64
}

func (r *Rectangle) Area() float64 {
    return r.width * r.height
}

// Square 实现 (独立的类型)
type Square struct {
    side float64
}

func (s *Square) Area() float64 {
    return s.side * s.side
}

// 使用示例: 任何 Shape 都可以互相替换
func PrintArea(shape Shape) {
    fmt.Printf("Area: %.2f\n", shape.Area())
}

func main() {
    rect := &Rectangle{width: 5, height: 10}
    square := &Square{side: 7}

    PrintArea(rect)   // 正常工作
    PrintArea(square) // 正常工作
}
```

### Repository 接口的多实现

```go
// UserRepository 接口
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*User, error)
    Save(ctx context.Context, user *User) error
}

// MySQLUserRepository 实现
type MySQLUserRepository struct {
    db *sql.DB
}

func (r *MySQLUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
    // MySQL 查询
    row := r.db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = ?", id)
    // 扫描结果
    var user User
    if err := row.Scan(&user); err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *MySQLUserRepository) Save(ctx context.Context, user *User) error {
    // MySQL 保存
    _, err := r.db.ExecContext(ctx, "INSERT INTO users ...")
    return err
}

// MongoUserRepository 实现 (不同的数据库，但接口相同)
type MongoUserRepository struct {
    collection *mongo.Collection
}

func (r *MongoUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
    // MongoDB 查询
    var user User
    err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&user)
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *MongoUserRepository) Save(ctx context.Context, user *User) error {
    // MongoDB 保存
    _, err := r.collection.InsertOne(ctx, user)
    return err
}

// InMemoryUserRepository 实现 (用于测试)
type InMemoryUserRepository struct {
    users map[uuid.UUID]*User
}

func (r *InMemoryUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
    user, exists := r.users[id]
    if !exists {
        return nil, errors.New("user not found")
    }
    return user, nil
}

func (r *InMemoryUserRepository) Save(ctx context.Context, user *User) error {
    r.users[user.ID()] = user
    return nil
}

// UserService 可以使用任何 UserRepository 实现
type UserService struct {
    repo UserRepository // 可以是 MySQL、Mongo 或 InMemory
}

func (s *UserService) GetUser(ctx context.Context, id uuid.UUID) (*User, error) {
    return s.repo.FindByID(ctx, id) // LSP: 任何实现都能正确工作
}
```

## 4. Interface Segregation Principle (ISP) - 接口隔离原则

**定义**: 客户端不应该依赖它不需要的接口。

**本质**: 使用多个专门的接口，而不是单一的通用接口。

### 臃肿接口的危害

```go
// ❌ 错误示例: 臃肿的接口

// Worker 接口包含了太多方法
type Worker interface {
    Work()
    Eat()
    Sleep()
    GetSalary() float64
    TakeLunch()
    UseOffice()
}

// Robot 实现 Worker (但机器人不吃饭、不睡觉)
type Robot struct{}

func (r *Robot) Work() {
    fmt.Println("Robot working")
}

func (r *Robot) Eat() {
    // 机器人不吃饭，但被迫实现
    panic("Robot cannot eat")
}

func (r *Robot) Sleep() {
    // 机器人不睡觉，但被迫实现
    panic("Robot cannot sleep")
}

func (r *Robot) GetSalary() float64 {
    return 0 // 机器人没有工资
}

func (r *Robot) TakeLunch() {
    panic("Robot cannot take lunch")
}

func (r *Robot) UseOffice() {
    fmt.Println("Robot using office")
}

// 问题: Robot 被迫实现不需要的方法
```

### 接口拆分的最佳实践

```go
// ✅ 正确示例: 拆分接口

// 基础工作接口
type Workable interface {
    Work()
}

// 用餐接口
type Eatable interface {
    Eat()
    TakeLunch()
}

// 休息接口
type Sleepable interface {
    Sleep()
}

// 薪资接口
type Payable interface {
    GetSalary() float64
}

// 办公设施使用接口
type OfficeUser interface {
    UseOffice()
}

// Human 实现多个接口
type Human struct {
    salary float64
}

func (h *Human) Work() {
    fmt.Println("Human working")
}

func (h *Human) Eat() {
    fmt.Println("Human eating")
}

func (h *Human) TakeLunch() {
    fmt.Println("Human taking lunch")
}

func (h *Human) Sleep() {
    fmt.Println("Human sleeping")
}

func (h *Human) GetSalary() float64 {
    return h.salary
}

func (h *Human) UseOffice() {
    fmt.Println("Human using office")
}

// Robot 只实现需要的接口
type Robot struct{}

func (r *Robot) Work() {
    fmt.Println("Robot working")
}

func (r *Robot) UseOffice() {
    fmt.Println("Robot using office")
}

// 使用示例
func ManageWork(workers []Workable) {
    for _, worker := range workers {
        worker.Work()
    }
}

func ManagePayroll(employees []Payable) {
    for _, employee := range employees {
        fmt.Printf("Salary: %.2f\n", employee.GetSalary())
    }
}

func main() {
    human := &Human{salary: 5000}
    robot := &Robot{}

    // 工作管理 (Human 和 Robot 都可以)
    ManageWork([]Workable{human, robot})

    // 薪资管理 (只有 Human)
    ManagePayroll([]Payable{human})
}
```

### Go 标准库的 ISP 示例

```go
// Go 标准库完美展示了 ISP

// io.Reader 只负责读取
type Reader interface {
    Read(p []byte) (n int, err error)
}

// io.Writer 只负责写入
type Writer interface {
    Write(p []byte) (n int, err error)
}

// io.Closer 只负责关闭
type Closer interface {
    Close() error
}

// io.ReadWriter 组合多个小接口
type ReadWriter interface {
    Reader
    Writer
}

// io.ReadWriteCloser 组合更多接口
type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}

// 示例: File 实现多个小接口
type File struct {
    // ...
}

func (f *File) Read(p []byte) (n int, err error) {
    // 实现读取
    return 0, nil
}

func (f *File) Write(p []byte) (n int, err error) {
    // 实现写入
    return 0, nil
}

func (f *File) Close() error {
    // 实现关闭
    return nil
}

// 函数只依赖需要的接口
func CopyData(src Reader, dst Writer) error {
    data := make([]byte, 1024)
    n, err := src.Read(data)
    if err != nil {
        return err
    }
    _, err = dst.Write(data[:n])
    return err
}
```

## 5. Dependency Inversion Principle (DIP) - 依赖倒置原则

**定义**:
- 高层模块不应该依赖低层模块，两者都应该依赖抽象
- 抽象不应该依赖细节，细节应该依赖抽象

**本质**: 依赖接口而非实现。

### Domain 层定义接口

```go
// domain/user/repository/user_repository.go
package repository

import (
    "context"
    "github.com/google/uuid"
)

// UserRepository 由 Domain 层定义接口
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
    Save(ctx context.Context, user *entity.User) error
}
```

### Infrastructure 层实现接口

```go
// infrastructure/repository/user_repository_impl.go
package repository

import (
    "context"
    "database/sql"
    "github.com/google/uuid"

    domainrepo "myproject/domain/user/repository" // 导入 Domain 接口
    "myproject/domain/user/entity"
)

// UserRepositoryImpl 在 Infrastructure 层实现 Domain 接口
type UserRepositoryImpl struct {
    db *sql.DB
}

// 确保实现了接口
var _ domainrepo.UserRepository = (*UserRepositoryImpl)(nil)

func NewUserRepositoryImpl(db *sql.DB) *UserRepositoryImpl {
    return &UserRepositoryImpl{db: db}
}

func (r *UserRepositoryImpl) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    // 数据库实现
    row := r.db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = ?", id)
    // 扫描并返回
    var user entity.User
    if err := row.Scan(&user); err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *UserRepositoryImpl) Save(ctx context.Context, user *entity.User) error {
    // 数据库保存
    _, err := r.db.ExecContext(ctx, "INSERT INTO users ...")
    return err
}
```

### 依赖注入

```go
// application/service/user_service.go
package service

import (
    "context"
    domainrepo "myproject/domain/user/repository"
)

// UserApplicationService 依赖接口，而非具体实现
type UserApplicationService struct {
    userRepo domainrepo.UserRepository // 依赖抽象
}

// 构造函数注入
func NewUserApplicationService(userRepo domainrepo.UserRepository) *UserApplicationService {
    return &UserApplicationService{
        userRepo: userRepo,
    }
}

func (s *UserApplicationService) GetUser(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    return s.userRepo.FindByID(ctx, id)
}
```

### Wire 依赖注入容器

```go
// cmd/server/wire.go
//go:build wireinject
// +build wireinject

package main

import (
    "database/sql"
    "github.com/google/wire"

    "myproject/application/service"
    domainrepo "myproject/domain/user/repository"
    infrarepo "myproject/infrastructure/repository"
)

// ProvideDatabase 提供数据库连接
func ProvideDatabase() (*sql.DB, error) {
    return sql.Open("mysql", "user:password@tcp(localhost:3306)/db")
}

// ProvideUserRepository 提供 UserRepository 实现
func ProvideUserRepository(db *sql.DB) domainrepo.UserRepository {
    return infrarepo.NewUserRepositoryImpl(db)
}

// InitializeUserService Wire 自动生成依赖注入
func InitializeUserService() (*service.UserApplicationService, error) {
    wire.Build(
        ProvideDatabase,
        ProvideUserRepository,
        service.NewUserApplicationService,
    )
    return nil, nil
}
```

### DIP 的优势

```go
// 优势1: 易于测试 (使用 Mock)
type MockUserRepository struct {
    users map[uuid.UUID]*entity.User
}

func (m *MockUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error) {
    user, exists := m.users[id]
    if !exists {
        return nil, errors.New("not found")
    }
    return user, nil
}

func (m *MockUserRepository) Save(ctx context.Context, user *entity.User) error {
    m.users[user.ID()] = user
    return nil
}

// 测试中使用 Mock
func TestUserApplicationService(t *testing.T) {
    mockRepo := &MockUserRepository{
        users: make(map[uuid.UUID]*entity.User),
    }

    service := service.NewUserApplicationService(mockRepo)

    // 测试逻辑
}

// 优势2: 易于替换实现 (从 MySQL 切换到 Postgres)
func main() {
    // 只需要更改 Provider
    db, _ := sql.Open("postgres", "...")
    userRepo := infrarepo.NewPostgresUserRepositoryImpl(db)
    userService := service.NewUserApplicationService(userRepo)

    // 应用层代码无需修改
}
```

## 实践案例: 电商系统的 SOLID 应用

### 订单处理系统

```go
// 1. SRP: 职责分离
type Order struct {
    id    uuid.UUID
    items []OrderItem
    total float64
}

// 2. OCP: 通过接口扩展支付方式
type PaymentProcessor interface {
    Process(amount float64) error
}

type CreditCardPayment struct{}

func (p *CreditCardPayment) Process(amount float64) error {
    // 信用卡支付
    return nil
}

type AlipayPayment struct{}

func (p *AlipayPayment) Process(amount float64) error {
    // 支付宝支付
    return nil
}

// 3. LSP: 任何 PaymentProcessor 都能替换
type OrderService struct {
    paymentProcessor PaymentProcessor
}

func (s *OrderService) Checkout(order *Order) error {
    return s.paymentProcessor.Process(order.total)
}

// 4. ISP: 接口隔离
type OrderReader interface {
    GetOrder(id uuid.UUID) (*Order, error)
}

type OrderWriter interface {
    SaveOrder(order *Order) error
}

type OrderRepository interface {
    OrderReader
    OrderWriter
}

// 5. DIP: 依赖抽象
type OrderApplicationService struct {
    orderRepo OrderRepository // 依赖接口
}

func NewOrderApplicationService(orderRepo OrderRepository) *OrderApplicationService {
    return &OrderApplicationService{
        orderRepo: orderRepo,
    }
}
```

## 测试策略

### 单元测试 SOLID 设计

```go
func TestOrderService_Checkout(t *testing.T) {
    // Mock PaymentProcessor (符合 DIP)
    mockPayment := &MockPaymentProcessor{}
    service := &OrderService{paymentProcessor: mockPayment}

    order := &Order{total: 100.0}

    // 测试
    err := service.Checkout(order)
    assert.NoError(t, err)
    assert.True(t, mockPayment.ProcessCalled)
}

type MockPaymentProcessor struct {
    ProcessCalled bool
}

func (m *MockPaymentProcessor) Process(amount float64) error {
    m.ProcessCalled = true
    return nil
}
```

## 总结

SOLID 原则在 Go 中的应用：
- **SRP**: 使用小的结构体，每个只负责一件事
- **OCP**: 使用接口和组合扩展功能
- **LSP**: 确保接口的所有实现都可以互换
- **ISP**: 定义小的、专门的接口
- **DIP**: Domain 层定义接口，Infrastructure 层实现
