# Code Reviewer - 专业代码审查工具

自动化代码审查，检查代码质量、安全性、性能和最佳实践。支持 Go、TypeScript、React 等技术栈。

## 功能特性

- 🤖 **自动触发** - 代码修改完成后自动运行，无需手动调用
- 🔍 **多维度审查** - 覆盖代码质量、安全性、性能、最佳实践、测试、文档
- 🛡️ **安全检查** - 基于 OWASP Top 10，检测常见安全漏洞
- 🎯 **技术栈特定** - 针对 Go、TypeScript、React 提供专业检查清单
- 📊 **详细报告** - 生成结构化的审查报告，包含具体建议和代码示例
- ⚡ **可操作建议** - 提供具体的修复方案和代码示例
- 📈 **评分系统** - 多维度评分，直观展示代码质量
- 🏗️ **DDD 架构支持** - 专门检查领域驱动设计分层架构

## 安装

```bash
/plugin install code-reviewer
```

## 使用方式

### 自动触发（推荐）

Code Reviewer 会在以下情况**自动运行**：

1. 完成新功能开发
2. 修复 bug
3. 代码重构
4. 即将提交代码前

**无需手动调用！** Claude 会自动识别合适的时机调用 code-reviewer。

### 工作流程

```
编写或修改代码
    ↓
代码完成
    ↓
Code Reviewer 自动触发
    ↓
分析变更文件
    ↓
根据文件类型加载检查清单
    ↓
逐项审查
    ↓
生成详细报告
    ↓
提供改进建议
```

## 审查维度

### 1. 代码质量

- 命名规范
- 代码结构和组织
- 函数复杂度
- 代码重复
- 可读性和可维护性

### 2. 安全性 (基于 OWASP Top 10)

- SQL 注入
- XSS (跨站脚本)
- CSRF (跨站请求伪造)
- 敏感信息泄露
- 权限控制
- 输入验证

### 3. 性能

- 算法复杂度
- 数据库查询优化
- 缓存使用
- 内存管理
- 并发处理

### 4. 最佳实践

- DDD 分层架构
- SOLID 原则
- 设计模式
- 错误处理
- 日志记录

### 5. 测试覆盖

- 单元测试建议
- 集成测试建议
- 测试用例完整性
- 边界条件测试

### 6. 文档完整性

- 函数/方法注释
- API 文档
- README 更新
- 架构文档

## 技术栈支持

### Go 代码审查

**专项检查：**
- 错误处理（是否检查所有 error）
- Context 使用（是否正确传递）
- Goroutine 管理（是否有泄漏风险）
- 并发安全性（race condition）
- 内存优化（避免不必要的分配）
- DDD 分层架构

**示例报告：**

```markdown
### 安全性问题

❌ **SQL 注入风险**
- **严重性：高**
- **位置：**backend/internal/infrastructure/db/user.go:15
- **问题：**直接拼接 SQL 查询字符串
- **风险：**攻击者可以执行任意 SQL 命令
- **修复建议：**

​```go
// 修复前
query := "SELECT * FROM users WHERE id = " + id

// 修复后
query := "SELECT * FROM users WHERE id = ?"
db.QueryRow(query, id)
​```
```

### TypeScript 代码审查

**专项检查：**
- 类型定义完整性
- `any` 使用合理性
- 可选链和空值检查
- 异步错误处理
- 类型断言安全性

**示例报告：**

```markdown
### 代码质量

⚠️ **类型定义缺失**
- **位置：**frontend/src/services/api.ts:23
- **问题：**函数参数使用 any 类型
- **建议：**

​```typescript
// 修复前
function fetchData(params: any) {
    return api.get('/data', params);
}

// 修复后
interface FetchParams {
    id: string;
    includeDetails?: boolean;
}

function fetchData(params: FetchParams) {
    return api.get('/data', params);
}
​```
```

### React 代码审查

**专项检查：**
- Hooks 依赖数组
- useEffect 清理函数
- 不必要的重新渲染
- 组件职责单一性
- Props 类型定义

**示例报告：**

```markdown
### React 最佳实践

⚠️ **依赖数组错误**
- **位置：**frontend/src/components/UserList.tsx:12
- **问题：**useEffect 依赖数组遗漏 userId
- **影响：**数据可能不会在 userId 变化时更新
- **修复建议：**

​```typescript
// 修复前
useEffect(() => {
    fetchUser(userId);
}, []);

// 修复后
useEffect(() => {
    fetchUser(userId);
}, [userId]);
​```
```

## 审查报告示例

### 完整报告结构

```markdown
# 代码审查报告

审查时间：2025-12-17 15:30
审查文件：
- backend/internal/domain/user/service.go
- frontend/src/components/UserProfile.tsx

## 概述

本次审查了用户服务和用户资料组件的实现。整体代码质量良好，发现 1 个严重安全问题和 3 个改进建议。

## 详细审查

### 1. 代码质量 ★★★★☆ (4/5)

#### ✅ 优点
- 代码结构清晰，符合 DDD 分层架构
- 命名规范，可读性好
- 函数职责单一

#### ⚠️ 改进建议
- 建议添加更多注释说明复杂业务逻辑

### 2. 安全性 ★★★☆☆ (3/5)

#### ❌ 严重问题

**SQL 注入风险**
- 严重性：高
- 位置：backend/internal/infrastructure/db/user.go:23
- [详细说明和修复方案]

### 3. 性能 ★★★★☆ (4/5)

#### 优化建议
- 建议对频繁查询的字段添加索引

### 4. 最佳实践 ★★★★☆ (4/5)

#### DDD 架构
- Domain 层：✅ 纯净，无外部依赖
- Application 层：✅ 正确协调领域服务
- Infrastructure 层：⚠️ 建议完善错误处理
- Interfaces 层：✅ 职责清晰

### 5. 测试覆盖 ★★☆☆☆ (2/5)

#### 建议添加的测试
1. 用户服务单元测试
2. 边界条件测试

### 6. 文档 ★★★☆☆ (3/5)

#### 建议
- 添加 API 文档
- 完善函数注释

## 评分

**总体评分：3.5/5**

## 优先级建议

### 🔴 立即修复（高优先级）

1. **SQL 注入风险**
   - 修复时间：24 小时内

### 🟡 尽快改进（中优先级）

1. **完善错误处理**
2. **添加单元测试**

### 🟢 后续优化（低优先级）

1. **完善文档**
2. **添加代码注释**

## 总结

代码整体质量良好，架构清晰。主要问题是存在 SQL 注入风险，需要立即修复。建议增加测试覆盖率和完善文档。
```

## 严重性等级

Code Reviewer 使用以下严重性等级：

| 等级 | 图标 | 说明 | 响应时间 |
|------|------|------|----------|
| 严重 (Critical) | ❌ | 安全漏洞、数据丢失风险 | 立即修复 |
| 高 (Major) | ⚠️ | 功能缺陷、明显性能问题 | 24-48小时 |
| 中 (Medium) | ⚡ | 代码质量、次要性能问题 | 本周内 |
| 低 (Minor) | 💡 | 代码风格、优化建议 | 下个迭代 |

## 使用场景

### 场景 1：功能开发完成

```
开发新功能（如用户登录）
    ↓
代码完成
    ↓
Code Reviewer 自动触发
    ↓
发现：密码未加密存储（严重）
    ↓
根据建议修复
    ↓
再次审查，通过
```

### 场景 2：Bug 修复

```
修复 API 错误
    ↓
Code Reviewer 自动触发
    ↓
发现：错误处理不完善（中等）
    ↓
完善错误处理
    ↓
提交代码
```

### 场景 3：代码重构

```
重构数据库访问层
    ↓
Code Reviewer 自动触发
    ↓
检查 DDD 分层是否合理
    ↓
提供架构优化建议
    ↓
根据建议调整
```

## 配置选项

可以在 `.claude/settings.json` 中配置：

```json
{
  "plugins": {
    "code-reviewer": {
      "auto-review": true,
      "min-changes-for-review": 10,
      "excluded-files": ["*.test.go", "*.spec.ts"],
      "severity-threshold": "medium",
      "languages": ["go", "typescript", "react"]
    }
  }
}
```

**选项说明：**

- `auto-review` - 是否自动触发（默认：true）
- `min-changes-for-review` - 最少变更行数触发审查（默认：10）
- `excluded-files` - 排除的文件模式
- `severity-threshold` - 严重性阈值（严重/高/中/低）
- `languages` - 启用的语言检查

## 审查清单

### Go Checklist

位于：`skills/review-checklist/checklists/go-checklist.md`

包含：
- 错误处理
- Context 使用
- Goroutine 和并发
- 内存和性能
- DDD 架构
- 测试

### TypeScript Checklist

位于：`skills/review-checklist/checklists/typescript-checklist.md`

包含：
- 类型定义
- 类型安全
- 异步处理
- 函数和方法
- 工具类型

### React Checklist

位于：`skills/review-checklist/checklists/react-checklist.md`

包含：
- Hooks 使用规范
- 组件设计
- 性能优化
- 状态管理
- 副作用管理

### Security Checklist

位于：`skills/review-checklist/checklists/security-checklist.md`

包含：
- SQL 注入
- XSS
- CSRF
- 认证和授权
- 敏感数据保护
- 输入验证

## 最佳实践

### 1. 及时修复严重问题

```
❌ 严重问题 → 立即修复（24小时内）
⚠️ 高优先级 → 尽快修复（48小时内）
⚡ 中等问题 → 本周内修复
💡 优化建议 → 下个迭代考虑
```

### 2. 保持代码审查习惯

- 每次提交前运行审查
- 重视安全问题
- 逐步提升代码质量

### 3. 学习和改进

- 阅读审查报告中的建议
- 参考提供的修复示例
- 查看相关最佳实践文档

## 技术实现

### 架构

**Agent (code-reviewer)**
- 分析代码变更
- 识别技术栈
- 加载相应检查清单
- 生成审查报告

**Skill (review-checklist)**
- 提供结构化检查清单
- Go/TypeScript/React/Security 四个维度
- 包含模板和参考资源

### 工具使用

- `Read` - 读取代码文件
- `Grep` - 搜索代码模式
- `Glob` - 查找文件
- `Bash` - 执行 git 命令
- `Skill` - 加载检查清单

### 模型

使用 Sonnet 模型，提供深度代码理解和专业建议。

## 常见问题

### Q: Code Reviewer 什么时候会自动触发？

A: 当你完成以下操作后：
- 新功能开发
- Bug 修复
- 代码重构
- 即将提交代码

Claude 会自动识别合适的时机调用 Code Reviewer。

### Q: 如何禁用自动触发？

A: 在 `.claude/settings.json` 中设置：
```json
{
  "plugins": {
    "code-reviewer": {
      "auto-review": false
    }
  }
}
```

### Q: 可以自定义检查规则吗？

A: 可以编辑 `skills/review-checklist/checklists/` 下的检查清单文件，添加或修改检查项。

### Q: 审查报告保存在哪里？

A: 审查报告会直接显示在 Claude Code 的输出中，不会自动保存。如需保存，可以复制内容到文件。

## 参考资源

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [TypeScript 最佳实践](https://www.typescriptlang.org/docs/)
- [React 文档](https://react.dev/)
- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Domain-Driven Design](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)

## 许可证

MIT

## 作者

[maguowei](https://github.com/maguowei)

## 反馈

遇到问题或有建议？欢迎 [提交 Issue](https://github.com/maguowei/claude-plugins/issues)!
