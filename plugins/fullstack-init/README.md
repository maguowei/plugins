# Full-Stack Project Initializer - 全栈项目初始化工具

快速创建 Go + React 全栈项目，采用 DDD 分层架构，包含完整的开发配置和文档。

## 功能特性

- 🚀 **一键初始化** - 快速创建完整的全栈项目结构
- 🏗️ **DDD 架构** - 领域驱动设计分层架构（Domain, Application, Infrastructure, Interfaces）
- 📐 **标准布局** - 符合 Go 标准布局（golang-standards/project-layout）
- 🎨 **现代前端** - React 18 + TypeScript + Tailwind CSS + shadcn/ui
- 🐳 **容器化** - Docker 和 docker-compose 配置
- 📝 **OpenAPI** - OpenAPI 3.0 规范
- 🔌 **WebSocket** - 可选的 WebSocket 支持
- 🔐 **认证系统** - 可选的 JWT 认证
- 📚 **完整文档** - 架构说明、开发指南、部署文档

## 安装

```bash
/plugin install fullstack-init
```

## 使用方式

### 基本使用

```bash
/init-project my-awesome-app
```

### 工作流程

```
执行命令
    ↓
回答配置问题
    ↓
生成项目结构
    ↓
创建所有文件
    ↓
初始化 git 仓库
    ↓
显示下一步操作
```

## 技术栈

### 后端（Go）

| 组件 | 技术 | 版本 |
|------|------|------|
| 语言 | Go | 1.21+ |
| Web 框架 | Gin | Latest |
| ORM | Ent | Latest |
| API 规范 | OpenAPI | 3.0 |
| 认证 | JWT | Latest |
| 日志 | Zap | Latest |

### 前端（React）

| 组件 | 技术 | 版本 |
|------|------|------|
| 框架 | React | 18+ |
| 语言 | TypeScript | 5+ |
| 构建工具 | Vite | 5+ |
| 样式 | Tailwind CSS | 3+ |
| 组件库 | shadcn/ui | Latest |
| 路由 | React Router | 6+ |
| 状态管理 | Zustand | Latest |
| HTTP 客户端 | Axios | Latest |

### 开发工具

- **容器化：** Docker, docker-compose
- **版本控制：** Git
- **包管理：** Go modules, npm/pnpm

## 配置选项

在初始化过程中，会询问以下配置：

### 1. 数据库选择

- **PostgreSQL**（推荐）
  - 功能强大
  - 支持复杂查询
  - 适合生产环境

- **MySQL**
  - 广泛使用
  - 良好性能
  - 社区支持丰富

- **SQLite**
  - 轻量级
  - 零配置
  - 适合开发环境

### 2. WebSocket 支持

- **是** - 添加 WebSocket 支持，适合实时应用
- **否** - 仅 RESTful API

### 3. 认证系统

- **是（JWT）** - 添加 JWT 认证系统
- **否** - 无认证（可后续添加）

### 4. 状态管理

- **Zustand**（推荐）- 轻量级，API 简洁
- **Jotai** - 原子化状态
- **React Context** - 仅使用内置 Context

## 生成的项目结构

```
my-awesome-app/
├── backend/                           # Go 后端
│   ├── cmd/
│   │   └── api/
│   │       └── main.go               # 主程序入口
│   ├── internal/
│   │   ├── domain/                   # 领域层
│   │   │   ├── entity/               # 实体
│   │   │   ├── repository/           # 仓储接口
│   │   │   └── service/              # 领域服务
│   │   ├── application/              # 应用层
│   │   │   ├── usecase/              # 用例
│   │   │   └── dto/                  # DTO
│   │   ├── infrastructure/           # 基础设施层
│   │   │   ├── persistence/          # 持久化
│   │   │   ├── http/                 # HTTP 客户端
│   │   │   └── websocket/            # WebSocket
│   │   └── interfaces/               # 接口层
│   │       ├── handler/              # HTTP 处理器
│   │       ├── middleware/           # 中间件
│   │       └── router/               # 路由
│   ├── pkg/                          # 可复用包
│   │   ├── logger/
│   │   ├── validator/
│   │   └── response/
│   ├── api/
│   │   └── openapi.yaml              # OpenAPI 规范
│   ├── go.mod
│   ├── Makefile
│   └── Dockerfile
├── frontend/                          # React 前端
│   ├── src/
│   │   ├── components/               # UI 组件
│   │   │   ├── ui/                   # shadcn/ui 组件
│   │   │   └── layout/               # 布局组件
│   │   ├── pages/                    # 页面组件
│   │   ├── hooks/                    # 自定义 Hooks
│   │   ├── services/                 # API 服务
│   │   ├── types/                    # TypeScript 类型
│   │   ├── lib/                      # 工具函数
│   │   └── store/                    # 状态管理
│   ├── package.json
│   ├── tsconfig.json
│   ├── tailwind.config.js
│   └── vite.config.ts
├── docs/                              # 文档
│   ├── architecture.md               # 架构说明
│   └── getting-started.md            # 快速开始
├── docker-compose.yml
├── .gitignore
├── .env.example
└── README.md
```

## DDD 分层架构

项目采用领域驱动设计（DDD）分层架构：

```
┌─────────────────────────────────┐
│      Interfaces 层               │
│   (HTTP Handlers, Middleware)   │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│      Application 层              │
│     (Use Cases, DTOs)           │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│        Domain 层                 │
│  (Entities, Domain Services)    │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│    Infrastructure 层             │
│  (Database, External APIs)      │
└─────────────────────────────────┘
```

**详细说明：** 生成的项目中包含 `docs/architecture.md`

## 使用示例

### 示例 1：创建基础项目

```bash
/init-project blog-api
```

**配置选择：**
- 数据库：PostgreSQL
- WebSocket：否
- 认证：是（JWT）
- 状态管理：Zustand

**生成结果：**
- 完整的 Go + React 项目
- PostgreSQL 配置
- JWT 认证系统
- Zustand 状态管理

### 示例 2：创建实时应用

```bash
/init-project chat-app
```

**配置选择：**
- 数据库：PostgreSQL
- WebSocket：是
- 认证：是（JWT）
- 状态管理：Zustand

**生成结果：**
- 包含 WebSocket 支持
- 适合实时聊天应用

### 示例 3：创建开发原型

```bash
/init-project prototype
```

**配置选择：**
- 数据库：SQLite
- WebSocket：否
- 认证：否
- 状态管理：React Context

**生成结果：**
- 轻量级配置
- 快速开发和测试

## 初始化后的操作

### 1. 进入项目目录

```bash
cd my-awesome-app
```

### 2. 启动数据库

```bash
docker-compose up -d
```

### 3. 启动后端

```bash
cd backend
go mod download
make run
```

### 4. 启动前端

```bash
cd frontend
npm install
npm run dev
```

### 5. 访问应用

- **前端：** http://localhost:5173
- **后端：** http://localhost:8080
- **API 文档：** http://localhost:8080/swagger

## 开发工具

### Makefile 命令（后端）

```bash
make help            # 显示所有可用命令
make run             # 运行应用
make build           # 编译应用
make test            # 运行测试
make test-coverage   # 生成测试覆盖率报告
make ent-gen         # 生成 Ent 代码
make migrate         # 运行数据库迁移
make lint            # 运行代码检查
make fmt             # 格式化代码
make dev             # 开发模式（热重载）
```

### npm 命令（前端）

```bash
npm run dev          # 开发模式
npm run build        # 构建生产版本
npm run lint         # 运行代码检查
npm run preview      # 预览生产构建
```

## 项目特点

### 1. 标准化结构

- 符合 Go 标准布局
- 清晰的前端组件组织
- 统一的命名规范

### 2. 最佳实践

- DDD 分层架构
- 依赖注入
- 接口抽象
- 错误处理
- 日志记录

### 3. 开发效率

- 热重载（前后端）
- Makefile 快捷命令
- Docker 容器化
- API 文档自动生成

### 4. 代码质量

- TypeScript 类型检查
- ESLint 代码检查
- golangci-lint 代码检查
- 单元测试结构

## 部署

### Docker 部署

```bash
# 构建镜像
docker build -t my-app-backend ./backend
docker build -t my-app-frontend ./frontend

# 运行容器
docker-compose up -d
```

### 生产环境配置

1. 修改 `.env` 文件
2. 设置生产数据库
3. 配置 CORS
4. 启用 HTTPS
5. 设置日志级别

## 常见问题

### Q: 如何添加新的 API 端点？

A:
1. 在 `domain/entity/` 创建实体
2. 在 `domain/repository/` 定义仓储接口
3. 在 `application/usecase/` 创建用例
4. 在 `interfaces/handler/` 创建处理器
5. 在 `interfaces/router/` 注册路由

### Q: 如何使用 shadcn/ui 组件？

A:
```bash
cd frontend
npx shadcn-ui@latest add button
npx shadcn-ui@latest add input
```

### Q: 如何运行数据库迁移？

A:
```bash
cd backend
make ent-gen      # 生成 Ent 代码
make migrate      # 运行迁移
```

### Q: 如何更换数据库？

A:
1. 修改 `.env` 文件中的数据库配置
2. 更新 `docker-compose.yml`
3. 重新生成 Ent 代码

### Q: 项目已存在怎么办？

A: 选择：
1. 使用不同的项目名称
2. 删除现有目录
3. 取消操作

## 技术实现

### 架构

**Slash Command (`/init-project`)**
- 接收项目名称
- 触发初始化流程

**Skill (go-react-ddd-init)**
- 询问配置选项
- 生成项目结构
- 创建所有文件
- 初始化 git 仓库

### 模板系统

- 使用模板文件
- 变量替换
- 条件生成（根据配置）

## 参考资源

- [Go 标准布局](https://github.com/golang-standards/project-layout)
- [DDD 分层架构](https://learn.microsoft.com/zh-cn/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/ddd-oriented-microservice)
- [Gin 文档](https://gin-gonic.com/docs/)
- [Ent 文档](https://entgo.io/docs/getting-started)
- [React 文档](https://react.dev/)
- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Vite 文档](https://vitejs.dev/)

## 许可证

MIT

## 作者

[maguowei](https://github.com/maguowei)

## 反馈

遇到问题或有建议？欢迎 [提交 Issue](https://github.com/maguowei/claude-plugins/issues)!
