# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 Claude Code 插件市场仓库，包含三个核心插件：
- **smart-git-commit**: 智能 Git 提交助手（Slash Command + Agent）
- **code-reviewer**: 专业代码审查工具（Agent + Skill）
- **fullstack-init**: 全栈项目初始化工具（Slash Command + Skill）

## 核心架构

### 市场配置
- `.claude-plugin/marketplace.json` 是市场的入口配置文件
- 定义了市场名称、元数据和所有可用插件列表
- 插件通过 `source` 字段指向各自的目录

### 插件结构
每个插件位于 `plugins/<plugin-name>/` 目录下，必须包含：
- `.claude-plugin/plugin.json`: 插件清单（必需）
- `README.md`: 使用文档（必需）
- 至少一种扩展类型目录：
  - `commands/`: Slash Commands（命令文件 `*.md`）
  - `agents/`: Agents（代理文件 `*.md`）
  - `skills/`: Skills（技能目录，包含 `SKILL.md`）

### 扩展类型组合

**Command + Agent 模式** (smart-git-commit):
```
commands/commit.md          # 定义命令入口和参数
agents/commit-assistant.md  # 执行具体的提交逻辑
templates/                  # 模板文件
```

**Agent + Skill 模式** (code-reviewer):
```
agents/code-reviewer.md           # 自动触发的审查代理
skills/review-checklist/          # 包含多个检查清单
  ├── SKILL.md                    # 技能定义
  ├── checklists/                 # 语言特定的检查清单
  └── templates/                  # 报告模板
```

**Command + Skill 模式** (fullstack-init):
```
commands/init-project.md          # 命令入口
skills/go-react-ddd-init/         # 项目生成逻辑
  ├── SKILL.md                    # 技能定义
  ├── templates/                  # 项目模板文件
  └── docs/                       # 架构文档
```

### Agent 自动触发机制
- Agent 的 `description` 字段定义了自动触发条件
- 例如 code-reviewer 的 description 说明"在完成代码编写或修改后自动使用"
- 这使得 Claude Code 在适当时机自动调用相应的 Agent

## 开发工具

### 创建新插件
```bash
./tools/create-plugin.sh <plugin-name>
```
交互式创建插件目录结构和基础文件。

### 验证插件
```bash
# 验证单个插件
./tools/validate-plugin.sh <plugin-name>

# 验证所有插件
./tools/validate-plugin.sh --all

# 生成验证报告
./tools/validate-plugin.sh <plugin-name> --report report.md
```

验证内容：
- plugin.json 格式和必需字段
- YAML frontmatter 格式
- 目录结构规范
- README.md 存在性

### 测试插件
```bash
# 测试单个插件
./tools/test-plugin.sh <plugin-name>

# 详细输出
./tools/test-plugin.sh <plugin-name> --verbose
```

## 关键文件规范

### plugin.json 必需字段
```json
{
  "name": "plugin-name",          // 必须与目录名一致
  "description": "...",            // 插件功能描述
  "version": "1.0.0",             // 语义化版本号
  "author": {
    "name": "...",                // 作者名称
    "email": "..."                // 作者邮箱
  }
}
```

### YAML Frontmatter 格式

**Commands:**
```yaml
---
description: 命令简短描述
allowed-tools: Bash(git*), Read, Write  # 可选
argument-hint: [参数提示]               # 可选
model: claude-3-5-haiku-20241022       # 可选
---
```

**Agents:**
```yaml
---
name: agent-name
description: Agent 触发条件和用途描述
tools: Read, Grep, Glob, Bash, Skill
model: sonnet
permissionMode: default
skills: skill-name  # 可选，关联的 skill
---
```

**Skills:**
```yaml
---
name: skill-name
description: 技能用途描述
allowed-tools: Read, Edit, Bash, Grep  # 可选
---
```

## 命名规范

**插件名称**（plugin.json 的 name 字段）：
- 小写字母、数字、连字符（kebab-case）
- 以字母开头
- 不超过 50 个字符
- ✅ `smart-git-commit`, `code-reviewer`
- ❌ `SmartGitCommit`, `code_reviewer`

**文件命名**：
- Commands: `command-name.md`
- Agents: `agent-name.md`
- Skills 目录: `skill-name/`

## 测试流程

### 本地测试
```bash
# 1. 添加本地市场
/plugin marketplace add /Users/maguowei/Work/AI/claude-code-plugin

# 2. 安装插件
/plugin install <plugin-name>

# 3. 测试功能
/commit                           # smart-git-commit
# code-reviewer 会在代码修改后自动触发
/init-project my-app              # fullstack-init
```

### 提交前检查清单
- [ ] 运行 `./tools/validate-plugin.sh <plugin-name>` 验证通过
- [ ] 本地安装测试功能正常
- [ ] README.md 包含完整使用说明
- [ ] plugin.json 版本号已更新
- [ ] Git commit message 遵循 Conventional Commits 规范

## Git Commit 规范

遵循 Conventional Commits 规范：
```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型**:
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例**:
```
feat(smart-git-commit): 添加对 monorepo 的支持

- 支持自动识别 monorepo 结构
- 在 commit message 中添加 scope

Closes #123
```

## 项目特定约定

### Markdown 文档
- 使用中文时遵循中文排版规范
- 代码块必须指定语言
- 内部链接使用相对路径

### 版本更新
1. 更新 `plugin.json` 的 `version` 字段
2. 更新 README.md 变更日志
3. 创建 git tag: `git tag v1.1.0`

### 目录组织
- `/plugins/*`: 插件代码
- `/docs/*`: 详细文档
- `/tools/*`: 开发工具脚本
- `/tools/lib/*`: 工具库函数

## 工具脚本架构

工具脚本位于 `tools/` 目录，使用模块化设计：
- `tools/lib/common.sh`: 通用函数（打印、路径等）
- `tools/lib/validators.sh`: 验证函数

主要脚本：
- `create-plugin.sh`: 创建插件脚手架
- `validate-plugin.sh`: 验证插件结构和规范
- `test-plugin.sh`: 测试插件功能

所有脚本都支持 `-h/--help` 查看用法。
