# Claude Code Plugins 市场

Claude Code 插件集合，提供 Go Web 项目脚手架生成工具。

## 插件列表

### go-ddd-scaffold

Go Web 项目脚手架生成器，基于 DDD 架构、Go 标准布局、Gin+Ent 技术栈的一键项目初始化工具。

**特性：**
- 基于 DDD（领域驱动设计）分层架构
- 遵循 Go 标准项目布局（golang-standards/project-layout）
- Gin Web 框架 + Ent ORM
- 清晰的项目结构和代码组织
- 完整的技术栈集成指导

**使用方式：**
```bash
/init-go-web <project-name>
```

## 快速开始

### 1. 安装官方插件市场

首先安装 Claude Code 官方插件市场，其中包含强大的插件开发工具：

```bash
# 添加官方插件市场
/plugin marketplace add https://github.com/anthropics/claude-plugins-official

# 安装插件开发工具
/plugin install plugin-dev
```

### 2. 添加本插件市场

```bash
# 从 GitHub 添加
/plugin marketplace add https://github.com/maguowei/claude-code-plugin

# 或使用本地路径（开发模式）
/plugin marketplace add /path/to/claude-code-plugin
```

### 3. 安装插件

```bash
/plugin install go-ddd-scaffold
```

### 4. 使用插件

```bash
# 初始化新的 Go Web 项目
/init-go-web my-project
```

## 插件开发

本插件市场使用官方 `plugin-dev` 插件进行开发，享受强大的开发辅助功能。

### 官方插件开发工具

[claude-plugins-official](https://github.com/anthropics/claude-plugins-official) 提供了完整的插件开发工具集：

**plugin-dev 插件包含的技能（Skills）：**
- `plugin-structure`: 插件结构和组织指导
- `command-development`: Slash Command 开发
- `agent-development`: Agent 开发
- `skill-development`: Skill 开发
- `hook-development`: Hook 开发
- `plugin-settings`: 插件配置管理
- `mcp-integration`: MCP 服务器集成

**快速创建插件：**
```bash
# 使用 create-plugin skill 创建新插件
/plugin-dev:create-plugin
```

### 本地开发测试

```bash
# 以开发模式添加本地插件市场
/plugin marketplace add /path/to/claude-code-plugin

# 重新加载插件（修改后）
/plugin reload go-ddd-scaffold

# 测试插件功能
/init-go-web test-project
```

## 插件结构

```
claude-code-plugin/
├── .claude-plugin/
│   └── marketplace.json          # 插件市场配置
├── plugins/
│   └── go-ddd-scaffold/          # Go DDD 脚手架插件
│       ├── .claude-plugin/
│       │   └── plugin.json       # 插件清单
│       ├── README.md             # 插件文档
│       ├── TESTING.md            # 测试说明
│       ├── commands/             # Slash Commands
│       │   └── init-go-web.md
│       ├── agents/               # Agents
│       │   └── go-ddd-scaffold-generator.md
│       └── skills/               # Skills
│           ├── ddd-core-concepts/
│           ├── ddd-layered-architecture/
│           ├── go-project-structure/
│           ├── clean-architecture-principles/
│           ├── cloudevents-pattern/
│           └── go-tech-stack-integration/
└── README.md
```

## 参考资源

- [Claude Code 官方文档](https://github.com/anthropics/claude-code)
- [官方插件市场](https://github.com/anthropics/claude-plugins-official)
- [plugin-dev 插件文档](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/plugin-dev)
- [插件文档](https://code.claude.com/docs/zh-CN/plugins)
- [插件参考文档](https://code.claude.com/docs/zh-CN/plugins-reference)
- [插件市场文档](https://code.claude.com/docs/zh-CN/plugin-marketplaces)
