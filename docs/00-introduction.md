# Claude Code 扩展介绍

欢迎来到 Claude Code Plugins 市场！本文档将帮助你理解 Claude Code 的扩展机制，以及本市场提供的插件。

## Claude Code 是什么？

Claude Code 是 Anthropic 官方提供的命令行界面（CLI）工具，它允许你通过命令行与 Claude AI 进行交互，完成各种软件工程任务。

## 为什么需要插件？

虽然 Claude Code 本身已经非常强大，但通过插件系统，你可以：

- **自动化重复性任务** - 如生成规范的 Git commit message
- **提升代码质量** - 通过自动化代码审查
- **加速项目启动** - 使用项目模板快速初始化
- **定制工作流** - 根据团队需求创建专属工具
- **共享最佳实践** - 将团队经验封装成可复用的插件

## Claude Code 扩展类型

Claude Code 支持多种扩展方式，每种都有其适用场景：

### 1. Slash Commands（斜杠命令）

**特点：**
- 用户显式调用（输入 `/command`）
- 适合明确的、有意识的操作
- 可以接收参数

**使用场景：**
- Git 操作（如 `/commit`、`/pr`）
- 项目初始化（如 `/init-project`）
- 代码生成（如 `/generate-api`）

**调用方式：** 用户主动触发

### 2. Agents（代理）

**特点：**
- 专门化的 AI 助手
- 独立的上下文窗口
- 可以执行多步骤任务
- 可以自动触发或手动调用

**使用场景：**
- 代码审查（自动在代码修改后触发）
- 复杂的多步骤任务
- 需要深度分析的场景

**调用方式：** 自动或 Claude 根据描述调用

### 3. Skills（技能）

**特点：**
- 模块化的功能包
- Claude 自动发现和使用
- 包含详细指令和资源

**使用场景：**
- PDF 处理
- Excel 数据分析
- 复杂的领域知识封装

**调用方式：** Claude 自动识别并使用

### 4. Hooks（钩子）

**特点：**
- 在特定事件自动执行
- Shell 命令形式
- 提供确定性控制

**使用场景：**
- 代码格式化（PostToolUse）
- 文件保护（PreToolUse）
- 自动化测试

**调用方式：** 事件触发

### 5. MCP Servers（模型上下文协议）

**特点：**
- 连接外部工具和服务
- 标准化接口
- 提供额外的工具和数据源

**使用场景：**
- GitHub 集成
- 数据库查询
- Slack 通知

**调用方式：** 作为工具自动可用

### 6. Plugins（插件）

**特点：**
- 可打包分发
- 可以包含多种扩展类型
- 通过 marketplace 安装

**使用场景：**
- 打包团队工具集
- 分发公开的扩展
- 组合多种扩展类型

**调用方式：** 通过 `/plugin` 命令管理

## 本市场的插件

本市场提供 3 个核心插件，每个都采用最优的技术方案：

### 1. Smart Git Commit

**类型：** Plugin（包含 Command + Agent）

**技术方案：** Slash Command + Agent 组合

**为什么这样设计？**
- Command 提供清晰的触发点（`/commit`）
- Agent 提供智能分析能力，理解代码变更
- 分离关注点：Command 负责交互，Agent 负责智能处理

**工作流程：**
```
用户输入 /commit
  ↓
Command 调用 Agent
  ↓
Agent 分析 git diff 和 status
  ↓
Agent 生成 commit message
  ↓
用户确认
  ↓
执行 git commit
```

### 2. Code Reviewer

**类型：** Plugin（包含 Agent + Skill）

**技术方案：** Agent + Skill 组合

**为什么这样设计？**
- Agent 适合复杂的多步骤任务
- Skill 提供结构化的检查清单
- Agent 可以自动在代码修改后触发

**工作流程：**
```
代码修改完成
  ↓
Claude 识别应该调用 code-reviewer
  ↓
Agent 分析变更文件
  ↓
Agent 加载相应的 Skill checklist
  ↓
逐项审查
  ↓
生成报告
```

### 3. Full-Stack Project Initializer

**类型：** Plugin（包含 Command + Skill）

**技术方案：** Slash Command + Skill 组合

**为什么这样设计？**
- Command 提供清晰的触发点和参数接收
- Skill 包含大量模板和生成逻辑
- Skill 可以被复用和维护

**工作流程：**
```
用户输入 /init-project <name>
  ↓
Command 接收参数
  ↓
调用 go-react-ddd-init Skill
  ↓
Skill 询问配置选项
  ↓
生成项目结构
  ↓
创建所有文件
```

## 技术选择决策树

如何为你的需求选择合适的扩展类型？

```
需要用户显式触发？
├─ 是 → 使用 Slash Command
│   └─ 逻辑复杂？
│       ├─ 是 → Command + Agent 组合
│       └─ 否 → 纯 Command
│
└─ 否 → 需要自动触发？
    ├─ 是 → 需要确定性控制？
    │   ├─ 是 → 使用 Hook
    │   └─ 否 → 使用 Agent（通过描述引导）
    │
    └─ 否 → 提供能力让 Claude 使用？
        └─ 使用 Skill
```

## 扩展类型对比

| 扩展类型 | 触发方式 | 复杂度支持 | 独立上下文 | 适用场景 |
|---------|---------|-----------|-----------|---------|
| Slash Command | 显式调用 | 低-中 | ❌ | 简单操作、参数接收 |
| Agent | 自动/显式 | 高 | ✅ | 多步骤任务、深度分析 |
| Skill | 自动识别 | 中-高 | ❌ | 能力提供、模板处理 |
| Hook | 事件触发 | 低 | ❌ | 确定性自动化 |
| MCP Server | 工具可用 | 中 | ❌ | 外部集成 |
| Plugin | 安装后可用 | - | - | 打包分发 |

## 最佳实践

### 1. 单一职责原则

每个扩展应该专注于一个明确的任务。

**好的例子：**
- `/commit` - 只负责生成和提交 commit
- `code-reviewer` - 只负责代码审查

**不好的例子：**
- `/do-everything` - 试图处理所有任务

### 2. 选择合适的扩展类型

- **明确操作** → Slash Command
- **自动审查** → Agent
- **能力提供** → Skill
- **自动化操作** → Hook
- **外部集成** → MCP Server

### 3. 组合使用

复杂功能可以组合多种扩展类型：

- **Smart Git Commit** = Command（触发） + Agent（智能处理）
- **Code Reviewer** = Agent（主逻辑） + Skill（检查清单）
- **Project Initializer** = Command（接口） + Skill（模板）

### 4. 文档完整

每个扩展都应该有清晰的文档：
- 功能说明
- 使用示例
- 配置选项
- 常见问题

## 下一步

- [快速开始](01-quick-start.md) - 安装和使用插件
- [Smart Git Commit 文档](02-smart-git-commit.md)
- [Code Reviewer 文档](03-code-reviewer.md)
- [Full-Stack Initializer 文档](04-fullstack-init.md)
- [插件开发指南](05-plugin-development.md)
- [最佳实践](06-best-practices.md)

## 参考资源

- [Claude Code 官方文档](https://github.com/anthropics/claude-code)
- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [Go 标准布局](https://github.com/golang-standards/project-layout)
- [DDD 分层架构](https://learn.microsoft.com/zh-cn/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/ddd-oriented-microservice)

---

有问题或建议？欢迎 [提交 Issue](https://github.com/maguowei/claude-plugins/issues)!
