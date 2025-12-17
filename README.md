# Claude Code Plugins 市场

专业级 Claude Code 插件集合，提升开发效率和代码质量。

## 核心插件

### 1. Smart Git Commit - 智能 Git 提交助手

自动分析代码变更并生成符合 Conventional Commits 规范的 commit message。

**特性：**
- 智能分析 git diff 和 git status
- 自动识别变更类型（feat/fix/refactor/docs/test/chore）
- 支持中英文 commit message
- 符合 Conventional Commits 规范
- 交互式确认流程

**技术方案：** Slash Command + Agent

**使用方式：**
```bash
/commit
```

---

### 2. Code Reviewer - 专业代码审查工具

自动化代码审查，检查代码质量、安全性和性能问题。

**特性：**
- 多维度审查（代码质量、安全性、性能、最佳实践）
- 技术栈特定检查（Go、TypeScript、React）
- 自动触发，无需手动调用
- 生成详细的审查报告和改进建议

**技术方案：** Agent + Skill

**审查维度：**
- 代码质量：命名规范、代码结构、可读性
- 安全性：SQL 注入、XSS、CSRF、敏感信息泄露
- 性能：算法复杂度、数据库优化、缓存使用
- 最佳实践：DDD 原则、SOLID 原则、设计模式
- 测试覆盖：单元测试、集成测试建议

---

### 3. Full-Stack Project Initializer - 全栈项目初始化工具

快速创建 Go + React 全栈项目，采用 DDD 分层架构。

**特性：**
- 后端：Go + Gin + Ent + DDD 架构
- 前端：React + TypeScript + Tailwind CSS + shadcn/ui
- 符合 Go 标准布局（golang-standards/project-layout）
- RESTful API + OpenAPI 3.0 + WebSocket
- Docker 和 docker-compose 配置
- 完整的开发文档

**技术方案：** Slash Command + Skill

**使用方式：**
```bash
/init-project <project-name>
```

**生成的项目结构：**
```
<project-name>/
├── backend/          # Go 后端（DDD 分层）
│   ├── cmd/         # 入口
│   ├── internal/    # 内部代码
│   │   ├── domain/          # 领域层
│   │   ├── application/     # 应用层
│   │   ├── infrastructure/  # 基础设施层
│   │   └── interfaces/      # 接口层
│   ├── pkg/         # 可复用包
│   └── api/         # OpenAPI 规范
├── frontend/        # React 前端
│   └── src/
│       ├── components/
│       ├── pages/
│       ├── hooks/
│       └── services/
├── docker-compose.yml
└── README.md
```

## 项目结构

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json      # 插件市场配置文件
├── plugins/
│   ├── smart-git-commit/     # 智能 Git 提交助手
│   ├── code-reviewer/        # 代码审查工具
│   └── fullstack-init/       # 全栈项目初始化工具
├── docs/                     # 详细文档
├── tools/                    # 开发工具脚本
├── CONTRIBUTING.md           # 贡献指南
└── README.md
```

### 市场配置文件

`.claude-plugin/marketplace.json` 是插件市场的核心配置文件，定义了：
- 市场名称和所有者信息
- 市场元数据（描述、版本、仓库地址）
- 可用插件列表及其配置

这使得 Claude Code 能够识别和加载市场中的所有插件。

## 快速开始

### 1. 添加市场到 Claude Code

```bash
# 添加本地市场
/plugin marketplace add /path/to/marketplace

# 或添加远程 Git 仓库
/plugin marketplace add https://github.com/maguowei/claude-plugins
```

### 2. 浏览可用插件

```bash
/plugin
```

### 3. 安装插件

```bash
# 安装智能提交助手
/plugin install smart-git-commit

# 安装代码审查工具
/plugin install code-reviewer

# 安装项目初始化工具
/plugin install fullstack-init
```

### 4. 使用插件

```bash
# 智能提交
/commit

# 代码审查会在代码修改后自动触发

# 初始化新项目
/init-project my-awesome-app
```

## 插件列表

| 插件 | 类型 | Claude Code 扩展 | 描述 |
|------|------|-----------------|------|
| smart-git-commit | Git 工具 | Slash Command + Agent | 智能生成符合规范的 commit message |
| code-reviewer | 代码质量 | Agent + Skill | 多维度自动代码审查 |
| fullstack-init | 项目模板 | Slash Command + Skill | Go + React DDD 全栈项目生成器 |

## 文档

- [介绍](docs/00-introduction.md) - Claude Code 扩展介绍
- [快速开始](docs/01-quick-start.md) - 详细的快速开始指南
- [Smart Git Commit](docs/02-smart-git-commit.md) - 智能提交插件文档
- [Code Reviewer](docs/03-code-reviewer.md) - 代码审查插件文档
- [Full-Stack Initializer](docs/04-fullstack-init.md) - 项目初始化插件文档
- [插件开发](docs/05-plugin-development.md) - 如何开发自己的插件
- [最佳实践](docs/06-best-practices.md) - Claude Code 插件开发最佳实践

## 技术栈

### Smart Git Commit
- Git
- Conventional Commits 规范
- Claude Agent 智能分析

### Code Reviewer
- 静态代码分析
- Go、TypeScript、React 最佳实践
- 安全性检查（OWASP Top 10）
- 性能优化建议

### Full-Stack Initializer
- **后端：** Go 1.21+, Gin, Ent ORM
- **前端：** React 18+, TypeScript, Vite, Tailwind CSS, shadcn/ui
- **架构：** DDD 分层架构
- **API：** RESTful, OpenAPI 3.0, WebSocket
- **容器化：** Docker, docker-compose

## 贡献

欢迎贡献新的插件或改进现有插件！请阅读 [贡献指南](CONTRIBUTING.md)。

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 作者

[maguowei](https://github.com/maguowei)

## 致谢

感谢 Claude Code 团队提供强大的扩展能力。
