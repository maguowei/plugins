---
name: go-react-ddd-init
description: 初始化 Go + React 全栈项目，采用 DDD 分层架构。生成完整的项目结构、配置文件和文档。
allowed-tools: Write, Bash, Read, AskUserQuestion
---

# Go + React DDD 全栈项目初始化

本技能用于初始化一个完整的全栈项目，包含 Go 后端和 React 前端，采用领域驱动设计（DDD）分层架构。

## 项目技术栈

### 后端（Go）
- **语言：** Go 1.25
- **Web 框架：** Gin v1.11.0
- **ORM：** Ent v0.14.0
- **架构：** DDD 分层（Domain, Application, Infrastructure, Interfaces）
- **API 规范：** OpenAPI 3.0
- **通信：** RESTful API + WebSocket（可选）

### 前端（React）
- **框架：** React 19.1.4
- **语言：** TypeScript
- **构建工具：** Vite 7.3.0
- **样式：** Tailwind CSS 4.1.18
- **组件库：** shadcn/ui
- **路由：** React Router v6
- **状态管理：** Zustand
- **HTTP 客户端：** Axios

### 开发工具
- **容器化：** Docker, docker-compose
- **版本控制：** Git
- **包管理：** Go modules, npm/pnpm

## 初始化流程

### 步骤 1：接收项目名称

从用户输入或参数中获取项目名称。

**验证规则：**
- 仅包含小写字母、数字、连字符
- 长度 3-50 个字符
- 不以连字符开头或结尾

```
项目名称：my-awesome-app
```

### 步骤 2：询问配置选项

使用 AskUserQuestion 工具询问用户配置：

**问题 1：选择数据库**
- PostgreSQL（推荐）
- MySQL
- SQLite（开发环境）

**问题 2：是否需要 WebSocket 支持**
- 是
- 否

**问题 3：是否需要认证系统**
- 是（JWT）
- 否

**问题 4：前端状态管理**
- Zustand（推荐）
- Jotai
- 仅使用 React Context

### 步骤 3：创建项目目录结构

在当前目录下创建项目文件夹：

```
<project-name>/
├── backend/
├── frontend/
├── docker-compose.yml
├── .gitignore
├── .env.example
└── README.md
```

### 步骤 4：生成后端文件

#### 目录结构

```
backend/
├── cmd/
│   └── api/
│       └── main.go                    # 主程序入口
├── internal/
│   ├── domain/                        # 领域层
│   │   ├── entity/                    # 实体
│   │   │   └── user.go
│   │   ├── repository/                # 仓储接口
│   │   │   └── user.go
│   │   └── service/                   # 领域服务
│   │       └── user.go
│   ├── application/                   # 应用层
│   │   ├── usecase/                   # 用例
│   │   │   └── user/
│   │   │       ├── create_user.go
│   │   │       └── get_user.go
│   │   └── dto/                       # 数据传输对象
│   │       └── user.go
│   ├── infrastructure/                # 基础设施层
│   │   ├── persistence/               # 持久化
│   │   │   ├── ent/                   # Ent schema
│   │   │   │   └── schema/
│   │   │   │       └── user.go
│   │   │   └── repository/
│   │   │       └── user_repository.go
│   │   ├── http/                      # HTTP 客户端
│   │   └── websocket/                 # WebSocket（可选）
│   └── interfaces/                    # 接口层
│       ├── handler/                   # HTTP 处理器
│       │   └── user_handler.go
│       ├── middleware/                # 中间件
│       │   ├── cors.go
│       │   ├── logger.go
│       │   └── auth.go（可选）
│       └── router/                    # 路由
│           └── router.go
├── pkg/                               # 可复用的包
│   ├── logger/
│   │   └── logger.go
│   ├── validator/
│   │   └── validator.go
│   └── response/
│       └── response.go
├── api/
│   └── openapi.yaml                   # OpenAPI 3.0 规范
├── go.mod
├── go.sum
├── Makefile
├── Dockerfile
└── README.md
```

#### 关键文件模板

使用 `templates/backend/` 下的模板文件生成。

### 步骤 5：生成前端文件

#### 目录结构

```
frontend/
├── src/
│   ├── components/                    # UI 组件
│   │   ├── ui/                        # shadcn/ui 组件
│   │   │   ├── button.tsx
│   │   │   ├── input.tsx
│   │   │   └── card.tsx
│   │   └── layout/
│   │       ├── Header.tsx
│   │       └── Footer.tsx
│   ├── pages/                         # 页面组件
│   │   ├── Home.tsx
│   │   └── NotFound.tsx
│   ├── hooks/                         # 自定义 Hooks
│   │   └── useApi.ts
│   ├── services/                      # API 服务
│   │   ├── api.ts                     # Axios 配置
│   │   └── userService.ts             # 用户服务
│   ├── types/                         # TypeScript 类型
│   │   └── user.ts
│   ├── lib/                           # 工具函数
│   │   └── utils.ts
│   ├── store/                         # 状态管理
│   │   └── userStore.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── public/
│   └── vite.svg
├── index.html
├── package.json
├── tsconfig.json
├── tsconfig.node.json
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
├── components.json                     # shadcn/ui 配置
└── README.md
```

#### 关键文件模板

使用 `templates/frontend/` 下的模板文件生成。

### 步骤 6：生成共享配置文件

#### docker-compose.yml

根据用户选择的数据库生成相应的配置：

- PostgreSQL: postgres:15-alpine
- MySQL: mysql:8
- SQLite: 不需要容器

包含：
- 数据库服务
- 后端服务
- 前端服务（开发模式）

#### .gitignore

包含：
- Go 编译产物
- Node.js 依赖
- 环境变量文件
- IDE 配置
- 操作系统文件

#### .env.example

包含：
- 数据库配置
- 服务器配置
- JWT 密钥（如果启用）
- 其他环境变量

#### README.md

包含：
- 项目简介
- 技术栈说明
- 快速开始
- 开发指南
- 部署说明
- 许可证

### 步骤 7：初始化 Git 仓库

```bash
cd <project-name>
git init
git add .
git commit -m "chore: 初始化项目

- 创建 Go + React 全栈项目
- 采用 DDD 分层架构
- 配置 Docker 开发环境"
```

### 步骤 8：显示完成信息

```
✅ 项目初始化完成！

项目名称：my-awesome-app
项目路径：/path/to/my-awesome-app

技术栈：
  后端：Go 1.25 + Gin v1.11.0 + Ent v0.14.0 + DDD
  前端：React 19.1.4 + TypeScript + Tailwind CSS 4.1.18 + Vite 7.3.0 + shadcn/ui
  数据库：PostgreSQL
  其他：Docker, WebSocket

下一步操作：

1. 进入项目目录
   cd my-awesome-app

2. 启动开发环境
   docker-compose up -d

3. 安装前端依赖并启动
   cd frontend
   npm install
   npm run dev

4. 安装后端依赖并启动
   cd backend
   go mod download
   make run

5. 访问应用
   前端：http://localhost:5173
   后端：http://localhost:8080
   API 文档：http://localhost:8080/swagger

详细文档请查看：
  - README.md
  - backend/README.md
  - frontend/README.md
  - docs/architecture.md
  - docs/getting-started.md
```

## 模板变量替换

在生成文件时，替换以下变量：

- `{{PROJECT_NAME}}` - 项目名称
- `{{PROJECT_NAME_UPPER}}` - 项目名称（大写）
- `{{PROJECT_NAME_CAMEL}}` - 项目名称（驼峰）
- `{{DATABASE}}` - 数据库类型
- `{{ENABLE_WEBSOCKET}}` - 是否启用 WebSocket
- `{{ENABLE_AUTH}}` - 是否启用认证
- `{{STATE_MANAGER}}` - 状态管理库
- `{{CURRENT_YEAR}}` - 当前年份

## 文件生成顺序

1. 创建根目录
2. 创建后端目录结构
3. 生成后端核心文件
4. 创建前端目录结构
5. 生成前端核心文件
6. 生成共享配置
7. 生成文档
8. 初始化 Git

## 错误处理

### 项目已存在

如果目标目录已存在：

```
错误：项目目录已存在

目录 'my-awesome-app' 已经存在。
请选择：
1. 使用不同的项目名称
2. 删除现有目录
3. 取消操作
```

### 权限错误

如果没有写入权限：

```
错误：没有写入权限

当前目录没有写入权限。
请检查目录权限或切换到其他目录。
```

## 参考资源

- [Go 标准布局](https://github.com/golang-standards/project-layout)
- [DDD 分层架构](https://learn.microsoft.com/zh-cn/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/ddd-oriented-microservice)
- [Gin 文档](https://gin-gonic.com/docs/)
- [Ent 文档](https://entgo.io/docs/getting-started)
- [React 文档](https://react.dev/)
- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)
