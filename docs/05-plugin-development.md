# Plugin Development Guide - 插件开发指南

完整的 Claude Code 插件开发指南，从创建到发布。

## 概述

本指南将教你如何开发一个 Claude Code 插件，包括：

- 🛠️ **创建插件**：使用工具快速创建插件结构
- 📝 **编写代码**：Slash Command、Agent、Skill 的开发
- ✅ **测试验证**：确保插件正常工作
- 📦 **发布分享**：与社区分享你的插件

## 前置知识

在开始之前，你应该了解：

1. **Claude Code 基础**
   - 如何使用 Claude Code CLI
   - 基本的命令和工作流程

2. **扩展类型**
   - Slash Commands
   - Agents
   - Skills
   - Hooks
   - MCP Servers

3. **Markdown 和 YAML**
   - 基础语法
   - YAML Frontmatter

如果你还不熟悉这些概念，请先阅读 [00-introduction.md](./00-introduction.md)。

## 快速开始

### 使用工具创建插件

我们提供了 `create-plugin.sh` 工具来快速创建插件结构：

```bash
cd /path/to/claude-plugins
./tools/create-plugin.sh my-plugin
```

工具会提示你：

1. **插件名称**：必须是 lowercase-with-hyphens 格式
2. **插件描述**：简短描述插件功能
3. **作者信息**：你的名字和邮箱
4. **扩展类型**：选择要包含的扩展类型（Command/Agent/Skill）

### 手动创建插件

如果你想手动创建插件，遵循以下结构：

```
plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json          # 必需：插件元数据
├── commands/                 # 可选：Slash Commands
│   └── my-command.md
├── agents/                   # 可选：Agents
│   └── my-agent.md
├── skills/                   # 可选：Skills
│   └── my-skill/
│       └── SKILL.md
├── hooks/                    # 可选：Hooks
│   └── my-hook.md
└── README.md                # 必需：使用文档
```

## Plugin Manifest (plugin.json)

每个插件必须包含 `plugin.json` 文件，定义插件的元数据。

### 基本结构

```json
{
  "name": "my-plugin",
  "description": "简短描述插件的功能",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "you@example.com",
    "url": "https://github.com/yourname"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/yourname/claude-plugins"
  },
  "keywords": ["keyword1", "keyword2", "keyword3"],
  "license": "MIT"
}
```

### 字段说明

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `name` | string | ✅ | 插件唯一标识，必须与目录名一致 |
| `description` | string | ✅ | 插件功能描述 |
| `version` | string | ✅ | 语义化版本号（semver） |
| `author` | object | ✅ | 作者信息 |
| `author.name` | string | ✅ | 作者名字 |
| `author.email` | string | ✅ | 作者邮箱 |
| `author.url` | string | ❌ | 作者主页 |
| `repository` | object | ❌ | 代码仓库信息 |
| `keywords` | array | ❌ | 关键词，便于搜索 |
| `license` | string | ❌ | 开源协议 |

### 命名规范

**插件名称（name）必须：**
- 使用小写字母
- 使用连字符分隔单词（kebab-case）
- 只包含字母、数字和连字符
- 以字母开头
- 不超过 50 个字符

**示例：**
- ✅ `git-helper`
- ✅ `code-formatter`
- ✅ `api-client-generator`
- ❌ `GitHelper`（不能用大写）
- ❌ `code_formatter`（不能用下划线）
- ❌ `123-plugin`（不能以数字开头）

## 开发 Slash Command

### 基本结构

文件：`commands/my-command.md`

```markdown
---
name: my-command
description: 命令的简短描述
---

# my-command 命令

详细的命令说明和使用方式。

## 功能

列出命令的主要功能。

## 使用示例

\`\`\`bash
/my-command argument1 argument2
\`\`\`

## 参数

- `argument1`: 第一个参数的说明
- `argument2`: 第二个参数的说明

## 工作流程

1. 步骤 1
2. 步骤 2
3. 步骤 3
```

### YAML Frontmatter

**必需字段：**
- `name`: 命令名称（不带 `/`）
- `description`: 简短描述

**可选字段：**
- `category`: 命令分类
- `aliases`: 命令别名

### 接收参数

在命令说明中描述参数：

```markdown
## 使用方式

\`\`\`bash
# 单个参数
/commit

# 多个参数
/init-project <project-name>

# 可选参数
/commit [--amend]
\`\`\`
```

### 调用其他组件

命令可以调用 Agent 或 Skill：

```markdown
# 命令执行后会调用相应的 Agent

这个命令会调用 `my-agent` Agent 来处理逻辑。
```

### 示例：Git Commit 命令

```markdown
---
name: commit
description: 智能 Git 提交助手
---

# commit 命令

智能分析代码变更，生成符合 Conventional Commits 规范的 commit message。

## 使用方式

\`\`\`bash
# 普通提交
/commit

# 修改上一次提交
/commit --amend
\`\`\`

## 工作流程

1. 执行命令后，会调用 commit-assistant Agent
2. Agent 分析 git status 和 git diff
3. 生成 Conventional Commits 格式的 message
4. 用户确认后执行 commit

## 参数

- `--amend`: （可选）修改上一次提交
```

## 开发 Agent

### 基本结构

文件：`agents/my-agent.md`

```markdown
---
name: my-agent
description: Agent 的简短描述
---

# my-agent Agent

你是一个 Claude Code Agent，专门用于 [具体用途]。

## 职责

- 职责 1
- 职责 2
- 职责 3

## 工作流程

1. 步骤 1：描述具体操作
2. 步骤 2：描述具体操作
3. 步骤 3：描述具体操作

## 可用工具

你可以使用以下工具：

- \`Bash\`: 执行命令
- \`Read\`: 读取文件
- \`Write\`: 写入文件
- \`Edit\`: 编辑文件
- \`Grep\`: 搜索文件内容
- \`Glob\`: 查找文件

## 输出格式

描述 Agent 应该如何输出结果。

## 示例

提供具体的使用示例。
```

### YAML Frontmatter

**必需字段：**
- `name`: Agent 名称
- `description`: 简短描述

**可选字段：**
- `trigger`: 触发条件（用于自动触发）
- `model`: 使用的模型（sonnet/opus/haiku）

### System Prompt

Agent 的主体内容是 System Prompt，告诉 Claude 如何行动：

**关键要素：**

1. **身份定义**
   ```markdown
   你是一个 Claude Code Agent，专门用于代码审查。
   ```

2. **职责说明**
   ```markdown
   ## 职责

   - 检查代码质量
   - 发现安全问题
   - 提供改进建议
   ```

3. **工作流程**
   ```markdown
   ## 工作流程

   1. 使用 Read 工具读取变更的文件
   2. 分析代码，查找问题
   3. 生成详细的审查报告
   4. 提供具体的修复建议
   ```

4. **输出要求**
   ```markdown
   ## 输出格式

   以 Markdown 格式输出审查报告，包含：
   - 概述
   - 问题列表（按严重性排序）
   - 具体的改进建议和代码示例
   ```

### 自动触发 Agent

如果你希望 Agent 自动触发，在描述中说明触发条件：

```markdown
---
name: code-reviewer
description: 在代码修改后自动执行代码审查
---

# Code Reviewer Agent

**自动触发条件：** 当用户使用 Write 或 Edit 工具修改代码后。

你是一个代码审查 Agent...
```

### 调用其他组件

Agent 可以调用 Skill：

```markdown
## 工作流程

1. 识别代码语言
2. 调用相应的 review-checklist Skill
3. 逐项检查代码
4. 生成报告
```

### 示例：Commit Assistant Agent

```markdown
---
name: commit-assistant
description: 智能 Git 提交助手
---

# Commit Assistant Agent

你是一个智能 Git 提交助手，帮助用户生成符合 Conventional Commits 规范的 commit message。

## 职责

- 分析 git 变更
- 识别变更类型（feat/fix/refactor 等）
- 生成规范的 commit message
- 与用户交互确认

## 工作流程

1. **分析变更**
   - 执行 \`git status\` 查看文件状态
   - 执行 \`git diff\` 查看具体变更

2. **识别类型**
   - 根据文件路径和变更内容
   - 确定变更类型（feat/fix/refactor/docs/test/chore）

3. **生成 Message**
   - Format: \`<type>(<scope>): <subject>\`
   - 可选的 body 和 footer

4. **交互确认**
   - 展示生成的 message
   - 询问用户是否确认或修改

5. **执行提交**
   - \`git add\` 添加文件
   - \`git commit\` 创建提交

## 输出格式

生成的 commit message 格式：

\`\`\`
<type>(<scope>): <subject>

<body>

<footer>
\`\`\`
```

## 开发 Skill

### 基本结构

文件：`skills/my-skill/SKILL.md`

```markdown
---
name: my-skill
description: Skill 的简短描述
---

# my-skill Skill

Skill 的详细说明。

## 功能

列出 Skill 提供的功能。

## 使用方式

说明如何使用这个 Skill。

## 输入

定义输入格式（如果有）。

## 输出

定义输出格式。

## 示例

提供使用示例。
```

### 目录结构

Skill 可以包含多个文件：

```
skills/my-skill/
├── SKILL.md              # 主定义文件
├── templates/            # 模板文件
│   └── template.md
├── checklists/           # 检查清单
│   ├── checklist1.md
│   └── checklist2.md
└── docs/                 # 文档
    └── guide.md
```

### 模块化设计

Skill 适合组织复杂的逻辑和资源：

```markdown
# Review Checklist Skill

这个 Skill 提供代码审查检查清单。

## 检查清单

根据代码类型加载相应的检查清单：

- Go: \`checklists/go-checklist.md\`
- TypeScript: \`checklists/typescript-checklist.md\`
- React: \`checklists/react-checklist.md\`
- Security: \`checklists/security-checklist.md\`

## 报告模板

使用 \`templates/review-report.md\` 生成审查报告。
```

### 示例：Project Init Skill

```markdown
---
name: go-react-ddd-init
description: 创建 Go + React 全栈项目的 Skill
---

# Go React DDD Init Skill

快速创建 Go + React 全栈项目，采用 DDD 分层架构。

## 配置选项

在创建项目时，会询问以下配置：

1. **数据库类型**：PostgreSQL / MySQL / SQLite
2. **WebSocket 支持**：是 / 否
3. **认证系统**：JWT / 否
4. **状态管理**：Zustand / Jotai / Context

## 模板文件

所有模板文件位于 \`templates/\` 目录：

- \`backend/\`: Go 后端模板
- \`frontend/\`: React 前端模板
- \`shared/\`: 共享配置模板

## 变量替换

模板中可以使用以下变量：

- \`{{PROJECT_NAME}}\`: 项目名称
- \`{{DATABASE}}\`: 数据库类型
- \`{{ENABLE_WEBSOCKET}}\`: WebSocket 支持
- \`{{ENABLE_AUTH}}\`: 认证支持
- \`{{STATE_MANAGER}}\`: 状态管理器

## 生成流程

1. 验证项目名称
2. 检查目录是否存在
3. 询问配置选项
4. 生成项目结构
5. 根据模板创建文件
6. 替换模板变量
7. 初始化 git 仓库
8. 生成 README
```

## 测试插件

### 使用验证工具

```bash
# 验证单个插件
./tools/validate-plugin.sh my-plugin

# 验证所有插件
./tools/validate-plugin.sh --all

# 生成验证报告
./tools/validate-plugin.sh my-plugin --report report.md
```

### 使用测试工具

```bash
# 测试插件
./tools/test-plugin.sh my-plugin

# 详细输出
./tools/test-plugin.sh my-plugin --verbose
```

### 本地安装测试

```bash
# 添加本地市场
/plugin marketplace add /path/to/claude-plugins

# 安装插件
/plugin install my-plugin

# 测试使用
/my-command  # 如果是 Command
```

## 调试技巧

### 1. 使用打印输出

在 Agent 或 Skill 中添加调试信息：

```markdown
## 调试

在执行过程中，输出关键信息：

1. "步骤 1: 读取配置..."
2. "步骤 2: 处理数据..."
3. "步骤 3: 生成结果..."
```

### 2. 分步执行

将复杂任务分解为多个小步骤，每步输出结果。

### 3. 查看日志

Claude Code 的日志可以帮助定位问题。

### 4. 使用简单示例

从最简单的功能开始，逐步增加复杂度。

## 版本管理

### 语义化版本

遵循 [Semantic Versioning](https://semver.org/)：

- **MAJOR.MINOR.PATCH**（如 1.0.0）

版本号递增规则：

- **MAJOR**：不兼容的 API 变更
- **MINOR**：向后兼容的功能新增
- **PATCH**：向后兼容的问题修复

### 更新插件

1. 修改代码
2. 更新 `plugin.json` 中的 `version`
3. 更新 README 中的变更日志
4. 提交代码
5. 创建 git tag

```bash
# 更新版本
# 编辑 plugin.json: "version": "1.1.0"

# 提交
git add .
git commit -m "feat: add new feature"

# 创建 tag
git tag v1.1.0
git push origin v1.1.0
```

## 发布插件

### 准备发布

1. **完善文档**
   - README.md 包含完整的使用说明
   - 添加使用示例
   - 列出所有功能

2. **验证插件**
   ```bash
   ./tools/validate-plugin.sh my-plugin
   ```

3. **测试功能**
   - 在多个场景下测试
   - 确保所有功能正常

4. **更新版本号**
   - plugin.json
   - README.md

### 提交到市场

1. **Fork 仓库**
   ```bash
   git clone https://github.com/maguowei/claude-plugins
   cd claude-plugins
   git checkout -b add-my-plugin
   ```

2. **添加插件**
   ```bash
   cp -r /path/to/my-plugin plugins/
   ```

3. **验证**
   ```bash
   ./tools/validate-plugin.sh my-plugin
   ```

4. **提交 PR**
   ```bash
   git add plugins/my-plugin
   git commit -m "feat: add my-plugin"
   git push origin add-my-plugin
   ```

5. **创建 Pull Request**
   - 在 GitHub 上创建 PR
   - 描述插件功能
   - 提供使用示例

## 最佳实践

### 1. 清晰的文档

- README 应该包含完整的使用说明
- 提供实际的使用示例
- 说明所有配置选项

### 2. 有意义的命名

- 插件名称应该清楚地表达功能
- 命令名称应该简洁易记
- Agent 和 Skill 名称应该描述性强

### 3. 错误处理

- 在 Agent 中处理可能的错误情况
- 提供清晰的错误消息
- 建议解决方案

### 4. 用户友好

- 提供交互式确认
- 展示进度信息
- 给出清晰的输出

### 5. 模块化设计

- 将复杂逻辑拆分为多个文件
- 使用 Skill 组织资源
- 保持代码清晰

### 6. 测试覆盖

- 测试各种使用场景
- 测试边界情况
- 测试错误处理

## 示例项目

参考本市场中的 3 个核心插件：

1. **Smart Git Commit**
   - 命令 + Agent 组合
   - 交互式流程
   - 参考：`plugins/smart-git-commit/`

2. **Code Reviewer**
   - Agent + Skill 组合
   - 自动触发
   - 模块化检查清单
   - 参考：`plugins/code-reviewer/`

3. **Full-Stack Initializer**
   - 命令 + Skill 组合
   - 复杂的模板系统
   - 多种配置选项
   - 参考：`plugins/fullstack-init/`

## 常见问题

### Q: 如何选择合适的扩展类型？

A: 参考 [00-introduction.md](./00-introduction.md) 中的决策树。

### Q: 插件可以包含多种扩展类型吗？

A: 可以！一个插件可以包含 Command、Agent、Skill 等多种类型。

### Q: 如何处理插件依赖？

A: 目前不支持插件间依赖，每个插件应该是独立的。

### Q: 可以使用外部库吗？

A: Claude Code 插件主要基于 Markdown 和 Claude 的能力，不需要外部库。
   如果需要执行外部程序，可以使用 Bash 工具。

### Q: 如何更新已发布的插件？

A: 更新代码，修改版本号，提交新的 PR。

## 资源

- [Claude Code 官方文档](https://docs.anthropic.com/claude/docs)
- [示例插件](../plugins/)
- [最佳实践](./06-best-practices.md)
- [贡献指南](../CONTRIBUTING.md)

## 获取帮助

- 查看现有插件的实现
- 提交 Issue
- 加入社区讨论

## 贡献

欢迎贡献你的插件！请遵循 [CONTRIBUTING.md](../CONTRIBUTING.md) 中的指南。

## 许可证

MIT
