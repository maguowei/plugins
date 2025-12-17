---
name: init-project
description: 初始化 Go + React 全栈项目，采用 DDD 分层架构
allowed-tools: Skill, Write, Bash, AskUserQuestion
argument-hint: <project-name>
model: claude-sonnet-4-5-20250929
---

# 全栈项目初始化

请使用 `go-react-ddd-init` Skill 来初始化一个全栈项目。

## 参数

- `project-name`: 项目名称（必需）

## 项目特性

**后端（Go）：**
- Go 1.25
- Gin v1.11.0
- Ent v0.14.0
- DDD 分层架构（Domain, Application, Infrastructure, Interfaces）
- 符合 Go 标准布局（golang-standards/project-layout）
- OpenAPI 3.0 规范
- WebSocket 支持（可选）

**前端（React）：**
- React 19.1.4
- TypeScript
- Vite 7.3.0
- Tailwind CSS 4.1.18
- shadcn/ui 组件库
- React Router
- 状态管理（Zustand）

**其他：**
- Docker 和 docker-compose 配置
- 完整的开发文档
- 环境配置示例
- Git 配置

## 使用方式

```bash
# 基本使用
/init-project my-awesome-app

# 项目将创建在当前目录下的 my-awesome-app/ 文件夹中
```

## 初始化流程

1. 接收项目名称
2. 询问配置选项（数据库类型、是否需要 WebSocket 等）
3. 生成项目结构
4. 创建所有必要的文件
5. 初始化 git 仓库
6. 生成 README 和文档
7. 显示下一步操作指引

## 生成的项目结构

```
<project-name>/
├── backend/                 # Go 后端
│   ├── cmd/api/            # 主程序入口
│   ├── internal/           # 内部代码
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
│   │   ├── pages/          # 页面组件
│   │   ├── hooks/          # 自定义 Hooks
│   │   ├── services/       # API 服务
│   │   └── types/          # TypeScript 类型
│   ├── package.json
│   ├── tsconfig.json
│   ├── tailwind.config.js
│   └── vite.config.ts
├── docker-compose.yml
├── .gitignore
├── .env.example
└── README.md
```

## 注意事项

- 确保当前目录下没有同名项目
- 项目名称建议使用小写字母和连字符
- 初始化完成后，按照生成的 README.md 进行后续操作
