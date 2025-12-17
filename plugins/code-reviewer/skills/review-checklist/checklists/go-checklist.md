# Go 代码审查检查清单

## 1. 错误处理

### ✅ 检查项

- [ ] **所有错误都被检查**
  - 不忽略任何返回的 error
  - 使用 `if err != nil` 检查错误

  ```go
  // ❌ 错误示例
  result, _ := doSomething()

  // ✅ 正确示例
  result, err := doSomething()
  if err != nil {
      return fmt.Errorf("do something failed: %w", err)
  }
  ```

- [ ] **错误信息有意义**
  - 使用 `fmt.Errorf` 包装错误，添加上下文
  - 使用 `%w` 保持错误链

  ```go
  // ❌ 错误示例
  if err != nil {
      return err
  }

  // ✅ 正确示例
  if err != nil {
      return fmt.Errorf("failed to get user %s: %w", userID, err)
  }
  ```

- [ ] **错误类型使用恰当**
  - 使用自定义错误类型表达特定错误
  - 使用 `errors.Is` 和 `errors.As` 判断错误类型

  ```go
  // 定义自定义错误
  var ErrUserNotFound = errors.New("user not found")

  // 使用
  if errors.Is(err, ErrUserNotFound) {
      // 处理用户不存在的情况
  }
  ```

- [ ] **避免 panic**
  - 仅在程序无法继续运行时使用 panic
  - 库代码不应该 panic，应返回 error

## 2. Context 使用

### ✅ 检查项

- [ ] **正确传递 Context**
  - Context 作为第一个参数
  - 不在结构体中存储 Context

  ```go
  // ✅ 正确示例
  func GetUser(ctx context.Context, userID string) (*User, error) {
      // ...
  }
  ```

- [ ] **检查 Context 取消**
  - 在长时间运行的操作中检查 `ctx.Done()`

  ```go
  select {
  case <-ctx.Done():
      return ctx.Err()
  case result := <-ch:
      return result, nil
  }
  ```

- [ ] **不传递 nil Context**
  - 使用 `context.Background()` 或 `context.TODO()`

## 3. Goroutine 和并发

### ✅ 检查项

- [ ] **避免 Goroutine 泄漏**
  - 确保 goroutine 能够退出
  - 使用 Context 或 channel 控制 goroutine 生命周期

  ```go
  // ❌ 可能泄漏
  go func() {
      for {
          // 无退出条件
      }
  }()

  // ✅ 正确示例
  go func() {
      for {
          select {
          case <-ctx.Done():
              return
          case item := <-ch:
              process(item)
          }
      }
  }()
  ```

- [ ] **使用 sync.WaitGroup 等待 goroutine**

  ```go
  var wg sync.WaitGroup
  wg.Add(1)
  go func() {
      defer wg.Done()
      // work
  }()
  wg.Wait()
  ```

- [ ] **正确使用 channel**
  - 只有发送者关闭 channel
  - 避免向已关闭的 channel 发送数据
  - 使用带缓冲的 channel 避免阻塞

- [ ] **并发安全**
  - 使用 mutex 保护共享数据
  - 使用 `sync.Map` 处理并发 map 访问
  - 避免 data race（使用 `-race` 检测）

  ```go
  type SafeCounter struct {
      mu sync.Mutex
      count int
  }

  func (c *SafeCounter) Inc() {
      c.mu.Lock()
      defer c.mu.Unlock()
      c.count++
  }
  ```

## 4. 内存和性能

### ✅ 检查项

- [ ] **避免不必要的内存分配**
  - 复用对象（使用 `sync.Pool`）
  - 预分配 slice 容量

  ```go
  // ❌ 频繁扩容
  var results []Result
  for _, item := range items {
      results = append(results, process(item))
  }

  // ✅ 预分配
  results := make([]Result, 0, len(items))
  for _, item := range items {
      results = append(results, process(item))
  }
  ```

- [ ] **正确使用 defer**
  - defer 有性能开销，避免在循环中使用
  - defer 用于资源清理（文件、锁、连接等）

  ```go
  // ✅ 正确使用 defer
  func ReadFile(path string) ([]byte, error) {
      f, err := os.Open(path)
      if err != nil {
          return nil, err
      }
      defer f.Close()
      return io.ReadAll(f)
  }
  ```

- [ ] **避免内存泄漏**
  - 及时释放不再使用的大对象
  - 避免 goroutine 泄漏
  - 正确使用数据库连接池

## 5. 代码组织

### ✅ 检查项

- [ ] **包命名规范**
  - 使用小写单词，不使用下划线或驼峰
  - 包名简短且有意义
  - 避免通用名称（util, common, base）

- [ ] **接口设计**
  - 接口小而专注（单一职责）
  - 在使用处定义接口，而非实现处

  ```go
  // ✅ 小接口
  type Reader interface {
      Read(p []byte) (n int, err error)
  }

  type Writer interface {
      Write(p []byte) (n int, err error)
  }
  ```

- [ ] **结构体初始化**
  - 使用构造函数初始化复杂结构体
  - 避免导出未初始化的字段

  ```go
  func NewUser(name string) *User {
      return &User{
          Name: name,
          CreatedAt: time.Now(),
      }
  }
  ```

## 6. DDD 架构（如适用）

### ✅ 检查项

- [ ] **Domain 层纯净**
  - 实体和值对象不依赖外部（数据库、HTTP等）
  - 只包含业务逻辑

  ```go
  // ✅ 纯净的实体
  type User struct {
      ID    string
      Email string
      Name  string
  }

  func (u *User) Validate() error {
      if u.Email == "" {
          return errors.New("email is required")
      }
      return nil
  }
  ```

- [ ] **Repository 接口在 Domain 层**
  - 在 domain 层定义接口
  - 在 infrastructure 层实现

  ```go
  // domain/repository/user.go
  type UserRepository interface {
      Get(ctx context.Context, id string) (*User, error)
      Save(ctx context.Context, user *User) error
  }

  // infrastructure/persistence/user_repo.go
  type userRepository struct {
      db *sql.DB
  }

  func (r *userRepository) Get(ctx context.Context, id string) (*User, error) {
      // 实现
  }
  ```

- [ ] **依赖方向正确**
  - Interfaces → Application → Domain
  - Infrastructure → Application/Domain
  - Domain 不依赖任何外层

## 7. 测试

### ✅ 检查项

- [ ] **单元测试覆盖**
  - 测试文件命名：`*_test.go`
  - 测试函数命名：`TestXxx`
  - 使用表驱动测试

  ```go
  func TestAdd(t *testing.T) {
      tests := []struct {
          name string
          a, b int
          want int
      }{
          {"positive", 1, 2, 3},
          {"negative", -1, -2, -3},
          {"zero", 0, 0, 0},
      }

      for _, tt := range tests {
          t.Run(tt.name, func(t *testing.T) {
              got := Add(tt.a, tt.b)
              if got != tt.want {
                  t.Errorf("Add(%d, %d) = %d, want %d",
                      tt.a, tt.b, got, tt.want)
              }
          })
      }
  }
  ```

- [ ] **Mock 和依赖注入**
  - 使用接口便于测试
  - 使用依赖注入而非全局变量

## 8. 命名规范

### ✅ 检查项

- [ ] **变量命名**
  - 驼峰命名法
  - 缩写词全大写（HTTP, URL, ID）
  - 简短但有意义

  ```go
  // ✅ 正确
  userID := "123"
  httpClient := &http.Client{}

  // ❌ 错误
  userId := "123"
  httpClient := &http.Client{}
  ```

- [ ] **函数命名**
  - 动词开头
  - 导出函数首字母大写
  - Get/Set 用于访问器

## 9. 数据库操作

### ✅ 检查项

- [ ] **使用参数化查询**
  - 防止 SQL 注入

  ```go
  // ❌ SQL 注入风险
  query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", id)

  // ✅ 参数化查询
  query := "SELECT * FROM users WHERE id = ?"
  row := db.QueryRow(query, id)
  ```

- [ ] **正确处理事务**
  - 使用 defer 回滚
  - 显式提交

  ```go
  tx, err := db.Begin()
  if err != nil {
      return err
  }
  defer tx.Rollback()

  // 执行操作

  return tx.Commit()
  ```

- [ ] **关闭数据库资源**
  - 使用 defer 关闭 rows

  ```go
  rows, err := db.Query(query)
  if err != nil {
      return err
  }
  defer rows.Close()
  ```

## 10. HTTP 处理

### ✅ 检查项

- [ ] **正确处理 HTTP 错误**
  - 返回适当的状态码
  - 提供有意义的错误信息

- [ ] **验证输入**
  - 验证请求参数
  - 验证请求体

- [ ] **设置超时**
  - HTTP client 设置超时
  - Context 传递超时

## 严重性评估

| 问题 | 严重性 |
|------|--------|
| SQL 注入 | 高 |
| Goroutine 泄漏 | 高 |
| Data race | 高 |
| 忽略错误 | 中 |
| 缺少 Context | 中 |
| 命名不规范 | 低 |
| 缺少注释 | 低 |
