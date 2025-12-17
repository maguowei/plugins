# Code Reviewer - 专业代码审查工具

自动化代码审查工具，提供多维度的代码质量、安全性和性能分析。

## 概述

Code Reviewer 是一个基于 AI 的专业代码审查工具，它可以：

- 🔍 **自动触发**：代码修改后自动执行审查
- 📊 **多维度分析**：代码质量、安全性、性能、最佳实践、测试、文档
- 🎯 **技术栈特定**：支持 Go、TypeScript、React 等技术栈
- 🔐 **安全检查**：基于 OWASP Top 10 的安全审查
- 📝 **详细报告**：结构化的审查报告，包含具体的改进建议
- ⭐ **评分系统**：为每个维度提供 1-5 星评分
- 🚨 **严重性分级**：Critical / Major / Medium / Minor

## 安装

```bash
/plugin install code-reviewer
```

## 技术方案

**架构：** Agent + Skill

```
代码修改完成
    ↓
Code Reviewer Agent 自动触发
    ↓
调用 Review Checklist Skill
    ↓
根据文件类型加载 checklist
    ↓
逐项检查代码
    ↓
生成详细的审查报告
```

## 审查维度

### 1. 代码质量 (Code Quality)

- **命名规范**：变量、函数、类的命名是否清晰
- **代码结构**：模块划分、函数长度、复杂度
- **可读性**：代码是否易于理解
- **重复代码**：是否有可以提取的重复逻辑
- **代码异味**：是否有明显的代码坏味道

**示例问题：**
```go
// ❌ 差：函数名不清晰，功能过多
func process(d []byte) error {
    // 100 行代码...
}

// ✅ 好：清晰的命名，单一职责
func validateAndSaveUser(userData []byte) error {
    user, err := parseUserData(userData)
    if err != nil {
        return err
    }
    return saveUser(user)
}
```

### 2. 安全性 (Security)

基于 **OWASP Top 10** 的安全检查：

- **SQL 注入**
- **XSS（跨站脚本攻击）**
- **CSRF（跨站请求伪造）**
- **敏感信息泄露**
- **不安全的加密**
- **认证和会话管理**
- **访问控制**
- **安全配置**
- **依赖安全**
- **日志和监控**

**示例问题：**
```go
// ❌ 危险：SQL 注入风险
query := "SELECT * FROM users WHERE id = " + userID

// ✅ 安全：使用参数化查询
query := "SELECT * FROM users WHERE id = ?"
db.QueryRow(query, userID)
```

```typescript
// ❌ 危险：XSS 风险
element.innerHTML = userInput;

// ✅ 安全：转义用户输入
element.textContent = userInput;
// 或使用 DOMPurify
element.innerHTML = DOMPurify.sanitize(userInput);
```

### 3. 性能 (Performance)

- **算法复杂度**：O(n²) → O(n)
- **数据库查询**：N+1 问题、缺少索引
- **缓存使用**：是否合理使用缓存
- **内存管理**：内存泄漏、不必要的分配
- **并发处理**：Goroutine 泄漏、race condition

**示例问题：**
```go
// ❌ 差：N+1 查询问题
users := db.GetAllUsers()
for _, user := range users {
    orders := db.GetOrdersByUserID(user.ID) // 每个用户一次查询
}

// ✅ 好：使用 JOIN 或预加载
users := db.GetUsersWithOrders() // 一次查询
```

```typescript
// ❌ 差：每次渲染都创建新函数
function Component() {
    return <button onClick={() => handleClick()}>Click</button>
}

// ✅ 好：使用 useCallback
function Component() {
    const handleClick = useCallback(() => {
        // handle click
    }, []);
    return <button onClick={handleClick}>Click</button>
}
```

### 4. 最佳实践 (Best Practices)

- **DDD 原则**：领域驱动设计
- **SOLID 原则**：单一职责、开闭原则等
- **设计模式**：合理使用设计模式
- **错误处理**：统一的错误处理策略
- **依赖注入**：避免硬编码依赖

**示例问题：**
```go
// ❌ 差：违反单一职责原则
type UserService struct {
    db *sql.DB
}

func (s *UserService) CreateUser(user *User) error {
    // 验证用户
    // 保存到数据库
    // 发送欢迎邮件
    // 记录日志
}

// ✅ 好：职责分离
type CreateUserUseCase struct {
    repo     UserRepository
    emailSvc EmailService
    logger   Logger
}

func (uc *CreateUserUseCase) Execute(user *User) error {
    if err := user.Validate(); err != nil {
        return err
    }
    if err := uc.repo.Save(user); err != nil {
        return err
    }
    uc.emailSvc.SendWelcome(user.Email)
    uc.logger.Info("User created", "id", user.ID)
    return nil
}
```

### 5. 测试覆盖 (Testing)

- **单元测试**：关键逻辑是否有测试
- **集成测试**：API 端点是否有测试
- **测试质量**：测试是否有意义
- **测试覆盖率**：是否达到合理的覆盖率
- **边界情况**：是否测试了边界情况

**建议：**
```go
// 建议添加测试
func TestCreateUser(t *testing.T) {
    tests := []struct {
        name    string
        user    *User
        wantErr bool
    }{
        {
            name: "valid user",
            user: &User{Email: "test@example.com", Name: "Test"},
            wantErr: false,
        },
        {
            name: "invalid email",
            user: &User{Email: "invalid", Name: "Test"},
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := CreateUser(tt.user)
            if (err != nil) != tt.wantErr {
                t.Errorf("CreateUser() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 6. 文档完整性 (Documentation)

- **代码注释**：复杂逻辑是否有注释
- **函数文档**：公共 API 是否有文档
- **README**：是否有使用说明
- **API 文档**：是否有 OpenAPI 规范
- **架构文档**：是否有架构说明

## 技术栈特定检查

### Go Checklist

文件：`skills/review-checklist/checklists/go-checklist.md`

**检查项：**
1. **错误处理**
   ```go
   // ❌ 忽略错误
   result, _ := someFunction()

   // ✅ 正确处理
   result, err := someFunction()
   if err != nil {
       return fmt.Errorf("some function failed: %w", err)
   }
   ```

2. **Context 传递**
   ```go
   // ❌ 不传递 context
   func GetUser(id string) (*User, error)

   // ✅ 传递 context
   func GetUser(ctx context.Context, id string) (*User, error)
   ```

3. **Goroutine 泄漏**
   ```go
   // ❌ 可能泄漏
   go func() {
       for {
           // 没有退出机制
       }
   }()

   // ✅ 使用 context 控制
   go func(ctx context.Context) {
       for {
           select {
           case <-ctx.Done():
               return
           default:
               // do work
           }
       }
   }(ctx)
   ```

4. **并发安全**
   ```go
   // ❌ 不安全
   type Counter struct {
       count int
   }

   // ✅ 使用 mutex
   type Counter struct {
       mu    sync.Mutex
       count int
   }

   func (c *Counter) Inc() {
       c.mu.Lock()
       defer c.mu.Unlock()
       c.count++
   }
   ```

5. **DDD 分层**
   - Domain 层不依赖外部框架
   - 接口在 Domain 层定义，在 Infrastructure 层实现
   - 依赖方向正确（外层依赖内层）

### TypeScript Checklist

文件：`skills/review-checklist/checklists/typescript-checklist.md`

**检查项：**
1. **类型定义**
   ```typescript
   // ❌ 使用 any
   function process(data: any) {
       return data.value;
   }

   // ✅ 明确类型
   interface Data {
       value: string;
   }

   function process(data: Data): string {
       return data.value;
   }
   ```

2. **空值检查**
   ```typescript
   // ❌ 可能 undefined
   function getName(user: User) {
       return user.name.toUpperCase();
   }

   // ✅ 安全检查
   function getName(user: User): string | undefined {
       return user.name?.toUpperCase();
   }
   ```

3. **异步错误处理**
   ```typescript
   // ❌ 未处理 rejection
   async function fetchData() {
       const response = await fetch('/api/data');
       return response.json();
   }

   // ✅ 处理错误
   async function fetchData(): Promise<Data> {
       try {
           const response = await fetch('/api/data');
           if (!response.ok) {
               throw new Error(`HTTP ${response.status}`);
           }
           return await response.json();
       } catch (error) {
           console.error('Fetch failed:', error);
           throw error;
       }
   }
   ```

### React Checklist

文件：`skills/review-checklist/checklists/react-checklist.md`

**检查项：**
1. **Hooks 依赖数组**
   ```typescript
   // ❌ 依赖缺失
   useEffect(() => {
       fetchData(userId);
   }, []); // userId 未包含在依赖中

   // ✅ 完整依赖
   useEffect(() => {
       fetchData(userId);
   }, [userId]);
   ```

2. **useEffect 清理**
   ```typescript
   // ❌ 未清理
   useEffect(() => {
       const timer = setInterval(() => {}, 1000);
   }, []);

   // ✅ 正确清理
   useEffect(() => {
       const timer = setInterval(() => {}, 1000);
       return () => clearInterval(timer);
   }, []);
   ```

3. **组件职责**
   ```typescript
   // ❌ 职责过多
   function UserProfile() {
       // 数据获取
       // 表单验证
       // API 调用
       // UI 渲染
       return <div>...</div>;
   }

   // ✅ 职责分离
   function UserProfile() {
       const user = useUser(); // 自定义 hook
       return <UserProfileView user={user} />;
   }
   ```

4. **性能优化**
   ```typescript
   // ❌ 不必要的重新渲染
   function List({ items }) {
       return items.map(item => <Item data={item} />);
   }

   // ✅ 使用 memo
   const Item = memo(({ data }) => {
       return <div>{data.name}</div>;
   });
   ```

### Security Checklist

文件：`skills/review-checklist/checklists/security-checklist.md`

**基于 OWASP Top 10 的检查项：**

1. **A01: Broken Access Control**
   - 检查权限验证
   - 避免直接对象引用

2. **A02: Cryptographic Failures**
   - 使用安全的加密算法
   - 正确处理密钥

3. **A03: Injection**
   - SQL 注入防护
   - 命令注入防护
   - XSS 防护

4. **A04: Insecure Design**
   - 安全的架构设计
   - 威胁建模

5. **A05: Security Misconfiguration**
   - 安全的默认配置
   - 错误消息不泄露信息

6. **A06: Vulnerable Components**
   - 依赖版本检查
   - 已知漏洞扫描

7. **A07: Authentication Failures**
   - 强密码策略
   - 会话管理

8. **A08: Software and Data Integrity**
   - 代码签名
   - 完整性校验

9. **A09: Security Logging Failures**
   - 安全事件记录
   - 日志保护

10. **A10: Server-Side Request Forgery**
    - SSRF 防护
    - URL 验证

## 审查报告格式

### 报告结构

```markdown
# 代码审查报告

## 概述

- **审查时间：** 2024-01-15 14:30:00
- **变更文件：** 3 个文件
- **总体评分：** ⭐⭐⭐⭐ (4/5)

## 评分详情

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | ⭐⭐⭐⭐⭐ | 优秀 |
| 安全性 | ⭐⭐⭐⭐ | 良好，有1个中等问题 |
| 性能 | ⭐⭐⭐⭐ | 良好 |
| 最佳实践 | ⭐⭐⭐⭐⭐ | 优秀 |
| 测试覆盖 | ⭐⭐⭐ | 一般，需要补充测试 |
| 文档 | ⭐⭐⭐⭐ | 良好 |

## 发现的问题

### 🔴 Critical (严重)

无

### 🟠 Major (重要)

无

### 🟡 Medium (中等)

**1. [安全性] 潜在的 SQL 注入风险**

**文件：** `backend/internal/infrastructure/persistence/user_repository.go:45`

**问题：**
```go
query := fmt.Sprintf("SELECT * FROM users WHERE name LIKE '%%%s%%'", name)
```

**建议：**
使用参数化查询：
```go
query := "SELECT * FROM users WHERE name LIKE ?"
rows, err := db.Query(query, "%"+name+"%")
```

**严重性：** Medium
**优先级：** 高

---

### 🟢 Minor (轻微)

**1. [测试] 缺少单元测试**

**文件：** `backend/internal/application/usecase/user/create_user.go`

**建议：**
为 `CreateUserUseCase` 添加单元测试，特别是错误情况。

**优先级：** 中

---

**2. [文档] 函数缺少注释**

**文件：** `backend/internal/domain/service/user_service.go:23`

**建议：**
为公共函数添加文档注释。

**优先级：** 低

## 建议改进

1. 修复 SQL 注入风险（高优先级）
2. 补充单元测试
3. 完善代码注释

## 总结

整体代码质量良好，主要需要关注安全性问题和测试覆盖率。
```

## 使用方式

### 自动触发

Code Reviewer 会在以下情况自动触发：

1. **代码修改完成后**
   - 使用 Write 或 Edit 工具修改代码
   - Agent 会自动识别并触发审查

2. **手动请求审查**
   - 说："请审查刚才的代码"
   - 或："帮我 review 一下这段代码"

### 工作流程

1. **检测变更**
   - 识别修改的文件
   - 确定文件类型（Go/TypeScript/React）

2. **加载 Checklist**
   - 根据文件类型加载对应的 checklist
   - 加载通用的安全 checklist

3. **逐项检查**
   - 代码质量
   - 安全性
   - 性能
   - 最佳实践
   - 测试覆盖
   - 文档

4. **生成报告**
   - 评分（1-5 星）
   - 问题列表（按严重性排序）
   - 具体的改进建议和代码示例

5. **展示给用户**
   - 完整的审查报告
   - 可操作的改进建议

## 配置选项

### 审查严格程度

Agent 默认使用中等严格程度，可以通过提示调整：

```
# 更严格的审查
"请用最严格的标准审查这段代码"

# 快速审查
"快速审查一下主要问题"
```

### 关注特定维度

```
"主要关注安全性问题"
"检查一下性能方面有没有问题"
"看看有没有违反 DDD 原则"
```

## 最佳实践

### 1. 及时修复高优先级问题

Critical 和 Major 级别的问题应该立即修复。

### 2. 持续改进

将审查报告作为持续改进的依据。

### 3. 团队标准

使用审查报告建立团队的代码标准。

### 4. 自动化集成

可以将审查集成到 CI/CD 流程中。

## 与其他工具集成

### 静态分析工具

配合现有的静态分析工具使用：

**Go:**
- golangci-lint
- staticcheck
- gosec (安全扫描)

**TypeScript:**
- ESLint
- TypeScript compiler
- SonarQube

**React:**
- ESLint (with React plugins)
- React DevTools Profiler

### CI/CD 集成

虽然 Code Reviewer 是交互式工具，但可以参考其检查项建立 CI 检查。

## 技术实现细节

### Code Reviewer Agent

文件：`agents/code-reviewer.md`

**触发条件：**
描述中包含"在代码修改后自动触发"的说明，Claude 会自动识别。

**审查流程：**
1. 使用 `Read` 工具读取修改的文件
2. 调用 Review Checklist Skill
3. 逐项检查代码
4. 生成结构化报告

### Review Checklist Skill

文件：`skills/review-checklist/SKILL.md`

**组织结构：**
- 主 Skill 定义
- 4 个技术栈特定的 checklist
- 审查报告模板

## 故障排除

### 问题 1：Agent 没有自动触发

**解决方案：**
手动请求："请审查刚才的代码"

### 问题 2：审查太严格/太宽松

**解决方案：**
明确指定严格程度："请用中等严格程度审查"

### 问题 3：想要关注特定问题

**解决方案：**
明确说明："主要关注安全性和性能问题"

## 常见问题

### Q: 支持哪些编程语言？

A: 目前主要支持 Go、TypeScript 和 React。其他语言会使用通用的代码质量和安全性检查。

### Q: 审查报告可以保存吗？

A: 是的，审查报告是 Markdown 格式，可以保存到文件中。

### Q: 如何自定义检查项？

A: 可以修改 `skills/review-checklist/checklists/` 下的检查清单文件。

### Q: 审查需要多长时间？

A: 取决于代码量，通常几秒到几十秒。

### Q: 可以只审查部分代码吗？

A: 可以，明确指出要审查的文件或函数。

## 参考资源

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [TypeScript Best Practices](https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html)
- [React Best Practices](https://react.dev/learn)
- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)

## 贡献

欢迎提交 Issue 和 Pull Request，特别是：
- 新的检查项
- 更多编程语言支持
- 检查规则优化

## 许可证

MIT
