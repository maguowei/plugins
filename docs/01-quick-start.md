# 快速开始

本指南将帮助你在 5 分钟内开始使用 Claude Code Plugins 市场。

## 前置要求

1. **安装 Claude Code**

   请参考 [Claude Code 官方文档](https://github.com/anthropics/claude-code)安装 Claude Code CLI。

2. **确认安装成功**

   ```bash
   claude --version
   ```

## 步骤 1：添加插件市场

### 方式 A：本地路径（推荐用于开发）

如果你 clone 了本仓库：

```bash
# 在 Claude Code 中执行
/plugin marketplace add /path/to/marketplace
```

### 方式 B：Git 仓库（推荐用于使用）

```bash
# 从 GitHub 添加
/plugin marketplace add https://github.com/maguowei/claude-plugins
```

### 验证市场已添加

```bash
/plugin marketplace list
```

你应该看到市场已成功添加。

## 步骤 2：浏览可用插件

```bash
/plugin
```

这将显示所有可用的插件：

```
可用插件：
1. smart-git-commit - 智能 Git 提交助手
2. code-reviewer - 专业代码审查工具
3. fullstack-init - 全栈项目初始化工具
```

## 步骤 3：安装插件

### 安装单个插件

```bash
# 安装智能提交助手
/plugin install smart-git-commit
```

### 安装所有插件

```bash
/plugin install smart-git-commit
/plugin install code-reviewer
/plugin install fullstack-init
```

### 验证安装

```bash
/plugin list
```

你应该看到已安装的插件列表。

## 步骤 4：使用插件

### Smart Git Commit - 智能提交

1. **修改一些代码**

   ```bash
   # 在你的项目中修改一些文件
   echo "# Test" >> test.md
   ```

2. **使用智能提交**

   ```bash
   /commit
   ```

3. **Claude 会：**
   - 分析你的代码变更
   - 生成符合 Conventional Commits 规范的 message
   - 询问你是否确认
   - 执行 git commit

**示例输出：**

```
我已经分析了你的代码变更：

变更摘要：
- 添加了 test.md 文件

建议的 commit message：

docs: 添加测试文档

添加 test.md 用于测试智能提交功能。

是否确认提交？(y/n)
```

### Code Reviewer - 代码审查

Code Reviewer 会**自动触发**，无需手动调用！

1. **编写或修改代码**

   ```go
   // example.go
   func GetUser(id string) (*User, error) {
       query := "SELECT * FROM users WHERE id = " + id  // 潜在的 SQL 注入风险
       // ...
   }
   ```

2. **完成代码后，Claude 会自动调用 Code Reviewer**

3. **收到审查报告**

**示例报告：**

```
代码审查报告

文件：example.go

安全性问题：
❌ SQL 注入风险
   位置：第 3 行
   问题：直接拼接 SQL 查询字符串
   建议：使用参数化查询

   修复示例：
   query := "SELECT * FROM users WHERE id = ?"
   row := db.QueryRow(query, id)

代码质量：
⚠️  错误处理
   建议添加对数据库查询错误的处理

性能：
✅ 无明显性能问题

总体评分：3/5
```

### Full-Stack Project Initializer - 项目初始化

1. **初始化新项目**

   ```bash
   /init-project my-awesome-app
   ```

2. **回答配置问题**

   Claude 会询问：
   - 数据库类型（PostgreSQL / MySQL / SQLite）
   - 是否需要 WebSocket 支持
   - 是否需要 Docker 配置

3. **自动生成完整项目**

   ```
   生成的项目结构：

   my-awesome-app/
   ├── backend/                 # Go 后端
   │   ├── cmd/api/            # 主程序入口
   │   ├── internal/           # DDD 分层架构
   │   │   ├── domain/         # 领域层
   │   │   ├── application/    # 应用层
   │   │   ├── infrastructure/ # 基础设施层
   │   │   └── interfaces/     # 接口层
   │   ├── pkg/                # 可复用包
   │   ├── api/                # OpenAPI 规范
   │   ├── go.mod
   │   ├── Makefile
   │   └── Dockerfile
   ├── frontend/               # React 前端
   │   ├── src/
   │   │   ├── components/     # UI 组件
   │   │   ├── pages/          # 页面
   │   │   ├── hooks/          # Hooks
   │   │   └── services/       # API 服务
   │   ├── package.json
   │   ├── tsconfig.json
   │   ├── tailwind.config.js
   │   └── vite.config.ts
   ├── docker-compose.yml
   ├── .gitignore
   ├── .env.example
   └── README.md

   项目已创建！运行以下命令开始开发：

   cd my-awesome-app
   docker-compose up -d     # 启动数据库等服务
   cd backend && make run   # 启动后端
   cd frontend && npm run dev  # 启动前端
   ```

## 常见场景

### 场景 1：日常开发流程

```bash
# 1. 编写代码
# 2. 代码审查自动触发（Code Reviewer）
# 3. 修复审查发现的问题
# 4. 智能提交
/commit
```

### 场景 2：启动新项目

```bash
# 1. 初始化项目
/init-project my-new-project

# 2. 进入项目目录
cd my-new-project

# 3. 开始开发
# 4. 使用 /commit 提交代码
```

### 场景 3：团队协作

```bash
# 1. 团队成员 clone 仓库
git clone <repo-url>

# 2. 添加插件市场
/plugin marketplace add <marketplace-url>

# 3. 安装团队使用的插件
/plugin install smart-git-commit
/plugin install code-reviewer

# 4. 保持一致的开发体验
```

## 配置选项

### 插件安装作用域

插件可以安装到不同的作用域：

#### 用户作用域（默认）

所有项目都可以使用：

```bash
/plugin install smart-git-commit
```

配置保存在：`~/.claude/settings.json`

#### 项目作用域

仅当前项目可用（团队共享）：

```bash
/plugin install smart-git-commit --scope project
```

配置保存在：`.claude/settings.json`（提交到 git）

#### 本地作用域

仅当前项目可用（个人使用）：

```bash
/plugin install smart-git-commit --scope local
```

配置保存在：`.claude/settings.local.json`（gitignored）

### 自定义配置

某些插件支持自定义配置。编辑相应的 settings.json：

```json
{
  "plugins": {
    "smart-git-commit": {
      "language": "zh-CN",
      "conventional-commits": true
    }
  }
}
```

## 管理插件

### 查看已安装插件

```bash
/plugin list
```

### 更新插件

```bash
/plugin update smart-git-commit
```

### 卸载插件

```bash
/plugin uninstall smart-git-commit
```

### 查看插件详情

```bash
/plugin info smart-git-commit
```

## 故障排除

### 问题 1：插件未找到

**症状：**
```
错误：插件 'smart-git-commit' 未找到
```

**解决方案：**
1. 确认市场已添加：`/plugin marketplace list`
2. 刷新市场：`/plugin marketplace refresh`
3. 重新安装：`/plugin install smart-git-commit`

### 问题 2：命令不可用

**症状：**
```
错误：未知命令 '/commit'
```

**解决方案：**
1. 确认插件已安装：`/plugin list`
2. 重启 Claude Code
3. 检查插件配置

### 问题 3：Agent 未自动触发

**症状：**
Code Reviewer 没有自动运行

**解决方案：**
1. 检查 Agent 描述是否清晰
2. 确认 Agent 配置正确
3. 手动触发（如果支持）

### 问题 4：权限错误

**症状：**
```
错误：权限被拒绝
```

**解决方案：**
1. 检查文件权限
2. 确认 Claude Code 有必要的权限
3. 检查 hooks 配置

## 性能优化

### 选择合适的模型

不同任务可以使用不同的模型：

- **简单任务**：Haiku（快速、低成本）
- **复杂任务**：Sonnet（平衡）
- **最高质量**：Opus（最强能力）

在 Command 或 Agent 的 frontmatter 中指定：

```yaml
---
model: claude-3-5-haiku-20241022
---
```

### 限制 Agent 工具访问

减少 Agent 可用工具，提升性能和安全性：

```yaml
---
tools: Read, Grep, Glob
---
```

## 下一步

- [Smart Git Commit 详细文档](02-smart-git-commit.md)
- [Code Reviewer 详细文档](03-code-reviewer.md)
- [Full-Stack Initializer 详细文档](04-fullstack-init.md)
- [开发自己的插件](05-plugin-development.md)
- [最佳实践](06-best-practices.md)

## 获取帮助

- 查看 [常见问题](../README.md#faq)
- 提交 [Issue](https://github.com/maguowei/claude-plugins/issues)
- 参考 [贡献指南](../CONTRIBUTING.md)

---

开始享受 Claude Code Plugins 带来的效率提升吧！
