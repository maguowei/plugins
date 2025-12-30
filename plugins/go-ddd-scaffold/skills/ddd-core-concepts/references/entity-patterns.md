# Entity 高级模式

## 富领域模型 vs 贫血模型

### 贫血模型 (Anti-pattern)

```go
// 错误示例: 只有数据,没有行为
type User struct {
    ID    uuid.UUID
    Email string
    Name  string
}

// 业务逻辑在服务层
func (s *UserService) ChangeUserName(userID uuid.UUID, newName string) error {
    user := s.repo.FindByID(userID)
    if newName == "" {
        return errors.New("invalid name")
    }
    user.Name = newName
    return s.repo.Save(user)
}
```

### 富领域模型 (正确)

```go
// 正确示例: 封装业务逻辑
type User struct {
    id    uuid.UUID
    email valueobject.Email
    name  string
}

// 业务规则在实体内部
func (u *User) ChangeName(newName string) error {
    if newName == "" {
        return errors.New("name cannot be empty")
    }
    if len(newName) > 100 {
        return errors.New("name too long")
    }
    u.name = newName
    u.updatedAt = time.Now()
    return nil
}

// 服务层只协调
func (s *UserService) ChangeUserName(userID uuid.UUID, newName string) error {
    user := s.repo.FindByID(userID)
    if err := user.ChangeName(newName); err != nil {
        return err
    }
    return s.repo.Save(user)
}
```

## 实体不变式 (Invariants)

实体必须始终保持有效状态:

```go
type BankAccount struct {
    id      uuid.UUID
    balance Money
    status  AccountStatus
}

// 构造函数确保初始有效状态
func NewBankAccount(initialDeposit Money) (*BankAccount, error) {
    if initialDeposit.Amount() < 0 {
        return nil, errors.New("initial deposit must be positive")
    }

    return &BankAccount{
        id:      uuid.New(),
        balance: initialDeposit,
        status:  AccountStatusActive,
    }, nil
}

// 方法保护不变式
func (a *BankAccount) Withdraw(amount Money) error {
    if a.status != AccountStatusActive {
        return errors.New("account not active")
    }

    newBalance, err := a.balance.Subtract(amount)
    if err != nil {
        return err
    }

    if newBalance.Amount() < 0 {
        return errors.New("insufficient funds")
    }

    a.balance = newBalance
    return nil
}
```

## 实体生命周期管理

```go
type Order struct {
    id         uuid.UUID
    status     OrderStatus
    items      []*OrderItem
    createdAt  time.Time
    completedAt *time.Time
}

// 状态机模式
func (o *Order) Submit() error {
    if o.status != OrderStatusDraft {
        return errors.New("can only submit draft orders")
    }
    if len(o.items) == 0 {
        return errors.New("cannot submit empty order")
    }
    o.status = OrderStatusSubmitted
    return nil
}

func (o *Order) Complete() error {
    if o.status != OrderStatusSubmitted {
        return errors.New("can only complete submitted orders")
    }
    o.status = OrderStatusCompleted
    now := time.Now()
    o.completedAt = &now
    return nil
}

func (o *Order) Cancel() error {
    if o.status == OrderStatusCompleted {
        return errors.New("cannot cancel completed order")
    }
    o.status = OrderStatusCancelled
    return nil
}
```

## 实体 ID 生成策略

### UUID (推荐)

```go
import "github.com/google/uuid"

func NewUser() *User {
    return &User{
        id: uuid.New(),  // 客户端生成
    }
}
```

### 数据库自增 ID

```go
type User struct {
    id   int64  // 0 表示未持久化
    name string
}

func (u *User) IsNew() bool {
    return u.id == 0
}

// Repository 负责设置 ID
func (r *Repository) Save(user *User) error {
    if user.IsNew() {
        id := r.db.Insert(user)
        user.id = id
    } else {
        r.db.Update(user)
    }
}
```

## 实体相等性

```go
type User struct {
    id uuid.UUID
}

// 基于 ID 的相等性
func (u *User) Equals(other *User) bool {
    if other == nil {
        return false
    }
    return u.id == other.id
}

// 实现 Go 的接口
func (u *User) Equal(other interface{}) bool {
    otherUser, ok := other.(*User)
    if !ok {
        return false
    }
    return u.Equals(otherUser)
}
```

## 实体复制 (Clone)

```go
type User struct {
    id    uuid.UUID
    email valueobject.Email
    name  string
}

// 深拷贝
func (u *User) Clone() *User {
    return &User{
        id:    u.id,
        email: u.email,  // 值对象自动深拷贝
        name:  u.name,
    }
}
```

## 实体快照 (Snapshot)

用于历史记录或审计:

```go
type UserSnapshot struct {
    UserID      uuid.UUID
    Email       string
    Name        string
    SnapshotAt  time.Time
}

func (u *User) ToSnapshot() UserSnapshot {
    return UserSnapshot{
        UserID:     u.id,
        Email:      u.email.Value(),
        Name:       u.name,
        SnapshotAt: time.Now(),
    }
}
```

## 实体验证

```go
type User struct {
    id    uuid.UUID
    email valueobject.Email
    name  string
    age   int
}

// Validate 方法检查实体状态
func (u *User) Validate() error {
    var errs []error

    if u.name == "" {
        errs = append(errs, errors.New("name is required"))
    }

    if u.age < 0 || u.age > 150 {
        errs = append(errs, errors.New("invalid age"))
    }

    if len(errs) > 0 {
        return fmt.Errorf("validation errors: %v", errs)
    }

    return nil
}
```

## 实体事件发布

```go
type User struct {
    id              uuid.UUID
    email           valueobject.Email
    name            string
    domainEvents    []DomainEvent  // 收集事件
}

func (u *User) ChangeName(newName string) error {
    oldName := u.name
    u.name = newName

    // 记录事件,稍后发布
    u.domainEvents = append(u.domainEvents, UserNameChanged{
        UserID:  u.id,
        OldName: oldName,
        NewName: newName,
    })

    return nil
}

// 获取并清空事件
func (u *User) PopDomainEvents() []DomainEvent {
    events := u.domainEvents
    u.domainEvents = nil
    return events
}
```

## 实体序列化

```go
// 用于 API 响应或持久化
type User struct {
    id    uuid.UUID
    email valueobject.Email
    name  string
}

// ToJSON 转换为 JSON 表示
func (u *User) ToJSON() map[string]interface{} {
    return map[string]interface{}{
        "id":    u.id.String(),
        "email": u.email.Value(),
        "name":  u.name,
    }
}

// FromJSON 从 JSON 重建
func UserFromJSON(data map[string]interface{}) (*User, error) {
    id, _ := uuid.Parse(data["id"].(string))
    email, _ := valueobject.NewEmail(data["email"].(string))

    return &User{
        id:    id,
        email: email,
        name:  data["name"].(string),
    }, nil
}
```
