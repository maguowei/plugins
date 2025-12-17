# Full-Stack Project Initializer - 全栈项目初始化工具

快速创建 Go + React 全栈项目，采用 DDD 分层架构，包含完整的开发配置和文档。

## 概述

Full-Stack Project Initializer 是一个项目脚手架工具，它可以：

- 🚀 **一键初始化**：快速创建完整的全栈项目结构
- 🏗️ **DDD 架构**：领域驱动设计分层架构（Domain, Application, Infrastructure, Interfaces）
- 📐 **标准布局**：符合 Go 标准布局（[golang-standards/project-layout](https://github.com/golang-standards/project-layout)）
- 🎨 **现代前端**：React 18 + TypeScript + Tailwind CSS + shadcn/ui
- 🐳 **容器化**：Docker 和 docker-compose 配置
- 📝 **OpenAPI**：OpenAPI 3.0 规范
- 🔌 **WebSocket**：可选的 WebSocket 支持
- 🔐 **认证系统**：可选的 JWT 认证
- 📚 **完整文档**：架构说明、开发指南、部署文档

## 安装

```bash
/plugin install fullstack-init
```

## 技术方案

**架构：** Slash Command + Skill

```
/init-project <name> 命令
    ↓
调用 go-react-ddd-init Skill
    ↓
询问配置选项
    ↓
根据模板生成项目
    ↓
创建所有文件
    ↓
初始化 git 仓库
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
| 状态管理 | Zustand/Jotai | Latest |
| HTTP 客户端 | Axios | Latest |

### 开发工具

- **容器化**：Docker, docker-compose
- **版本控制**：Git
- **包管理**：Go modules, npm/pnpm

## 使用方式

### 基本使用

```bash
/init-project my-awesome-app
```

### 配置选项

在初始化过程中，会询问以下配置：

#### 1. 数据库选择

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

#### 2. WebSocket 支持

- **是**：添加 WebSocket 支持，适合实时应用
- **否**：仅 RESTful API

#### 3. 认证系统

- **是（JWT）**：添加 JWT 认证系统
- **否**：无认证（可后续添加）

#### 4. 状态管理

- **Zustand**（推荐）：轻量级，API 简洁
- **Jotai**：原子化状态
- **React Context**：仅使用内置 Context

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

**详细说明请参考生成项目中的** `docs/architecture.md`

### Domain 层（领域层）

**职责**：核心业务逻辑，系统的心脏

**包含**：
- **Entity**：具有唯一标识的对象
- **Repository Interface**：数据访问抽象
- **Domain Service**：跨实体的业务逻辑

**原则**：
- 纯净：不依赖外部框架
- 稳定：变化最少的层
- 独立：可以独立测试

### Application 层（应用层）

**职责**：协调领域对象完成用户用例

**包含**：
- **Use Case**：特定业务流程的实现
- **DTO**：数据传输对象

**原则**：
- 薄层：不包含业务逻辑
- 编排：协调领域对象和仓储
- 事务管理

### Infrastructure 层（基础设施层）

**职责**：提供技术实现

**包含**：
- **Persistence**：数据库实现（使用 Ent ORM）
- **HTTP Client**：外部 API 调用
- **WebSocket**：WebSocket 实现

**原则**：
- 实现 Domain 层定义的接口
- 处理技术细节
- 可替换

### Interfaces 层（接口层）

**职责**：处理外部通信

**包含**：
- **Handler**：HTTP 请求处理（使用 Gin）
- **Middleware**：跨切面关注点（CORS、日志、认证）
- **Router**：URL 路由配置

**原则**：
- 转换 HTTP 请求和 DTO
- 验证请求数据
- 处理响应格式

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

**生成的 README.md 会包含：**
- 项目介绍
- 技术栈列表
- 快速开始指南
- API 文档链接
- 部署说明

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
- 后端 WebSocket handler
- 前端 WebSocket client
- 适合实时聊天应用

**WebSocket 相关文件：**
- `backend/internal/infrastructure/websocket/hub.go`
- `backend/internal/interfaces/handler/websocket_handler.go`
- `frontend/src/services/websocket.ts`

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
- 无需外部数据库
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

这将启动：
- PostgreSQL（如果选择了 PostgreSQL）
- MySQL（如果选择了 MySQL）

### 3. 启动后端

```bash
cd backend
go mod download
make run
```

或者使用开发模式（热重载）：

```bash
make dev
```

### 4. 启动前端

```bash
cd frontend
npm install  # 或 pnpm install
npm run dev
```

### 5. 访问应用

- **前端**：http://localhost:5173
- **后端 API**：http://localhost:8080
- **API 文档**：http://localhost:8080/swagger

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
make docker-build    # 构建 Docker 镜像
make docker-run      # 运行 Docker 容器
make clean           # 清理构建文件
```

### npm 命令（前端）

```bash
npm run dev          # 开发模式
npm run build        # 构建生产版本
npm run lint         # 运行代码检查
npm run preview      # 预览生产构建
npm run type-check   # TypeScript 类型检查
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

## 核心功能实现

### 后端关键文件

#### main.go

```go
package main

import (
    "context"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "your-project/internal/infrastructure/persistence"
    "your-project/internal/interfaces/router"
    "your-project/pkg/logger"
)

func main() {
    // 初始化日志
    logger.Init()

    // 加载配置
    cfg := loadConfig()

    // 初始化数据库
    db, err := persistence.NewDatabase(cfg.Database)
    if err != nil {
        logger.Fatal("Failed to connect database", err)
    }
    defer db.Close()

    // 初始化路由
    r := router.NewRouter(db)

    // 启动服务器
    srv := &http.Server{
        Addr:    cfg.Port,
        Handler: r,
    }

    // 优雅关闭
    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            logger.Fatal("Failed to start server", err)
        }
    }()

    // 等待中断信号
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    logger.Info("Shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        logger.Fatal("Server forced to shutdown", err)
    }

    logger.Info("Server exited")
}
```

#### Ent Schema 示例

```go
// backend/internal/infrastructure/persistence/ent/schema/user.go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
)

// User holds the schema definition for the User entity.
type User struct {
    ent.Schema
}

// Fields of the User.
func (User) Fields() []ent.Field {
    return []ent.Field{
        field.String("id").
            Unique(),
        field.String("email").
            Unique(),
        field.String("name"),
        field.Time("created_at"),
        field.Time("updated_at"),
    }
}
```

### 前端关键文件

#### 主入口 main.tsx

```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>,
)
```

#### API 客户端

```typescript
// frontend/src/services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8080',
  timeout: 10000,
});

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 响应拦截器
api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // 处理未授权
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

#### Zustand Store 示例

```typescript
// frontend/src/store/useAuthStore.ts
import { create } from 'zustand';

interface AuthState {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: localStorage.getItem('token'),
  login: async (email, password) => {
    const response = await api.post('/auth/login', { email, password });
    const { user, token } = response.data;
    localStorage.setItem('token', token);
    set({ user, token });
  },
  logout: () => {
    localStorage.removeItem('token');
    set({ user: null, token: null });
  },
}));
```

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

#### 1. 修改 .env 文件

```env
# 生产环境配置
ENVIRONMENT=production
PORT=8080

# 数据库
DB_HOST=production-db-host
DB_PORT=5432
DB_USER=prod_user
DB_PASSWORD=secure_password
DB_NAME=my_app_prod

# JWT
JWT_SECRET=your-super-secret-key-change-this
JWT_EXPIRATION=24h

# CORS
CORS_ORIGINS=https://yourdomain.com

# 日志
LOG_LEVEL=warn
LOG_FORMAT=json
```

#### 2. 设置 HTTPS

使用 Nginx 作为反向代理：

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # 前端
    location / {
        proxy_pass http://localhost:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # 后端 API
    location /api {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

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
npx shadcn-ui@latest add dialog
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
4. 运行迁移

### Q: 项目已存在怎么办？

A: Skill 会检测到已存在的目录，并提供选项：
1. 使用不同的项目名称
2. 删除现有目录（需要确认）
3. 取消操作

### Q: 如何添加新的 Ent 实体？

A:
```bash
cd backend
go run -mod=mod entgo.io/ent/cmd/ent init User
# 编辑 internal/infrastructure/persistence/ent/schema/user.go
make ent-gen
```

### Q: 如何配置 WebSocket？

A: 如果初始化时选择了 WebSocket 支持，相关代码会自动生成。
你可以在以下文件中找到实现：
- 后端：`internal/infrastructure/websocket/hub.go`
- 前端：`src/services/websocket.ts`

## 技术实现细节

### Slash Command

文件：`commands/init-project.md`

```yaml
---
name: init-project
description: 创建全栈项目
---
```

接收参数：项目名称

### Go React DDD Init Skill

文件：`skills/go-react-ddd-init/SKILL.md`

**工作流程：**
1. 验证项目名称
2. 检查目录是否存在
3. 询问配置选项
4. 生成项目结构
5. 根据模板创建文件
6. 替换模板变量
7. 初始化 git 仓库
8. 生成 README

**模板系统：**
- 使用 Handlebars 风格的模板语法
- 条件生成（`{{#if}}...{{/if}}`）
- 变量替换（`{{PROJECT_NAME}}`）

### 模板文件

所有模板文件位于：`skills/go-react-ddd-init/templates/`

**模板变量：**
- `{{PROJECT_NAME}}`：项目名称
- `{{DATABASE}}`：数据库类型（postgres/mysql/sqlite）
- `{{ENABLE_WEBSOCKET}}`：是否启用 WebSocket
- `{{ENABLE_AUTH}}`：是否启用认证
- `{{STATE_MANAGER}}`：状态管理器（zustand/jotai/context）

## 扩展和定制

### 添加新的技术栈选项

你可以扩展 Skill 来支持更多选项：

1. 修改 `SKILL.md` 添加新的配置问题
2. 创建相应的模板文件
3. 更新模板变量

### 自定义模板

你可以修改 `templates/` 目录下的模板文件来定制生成的代码。

### 添加新的 Makefile 目标

编辑 `templates/backend/Makefile.template`：

```makefile
.PHONY: my-custom-target
my-custom-target:
    @echo "Running custom target"
    # 你的命令
```

## 参考资源

- [Go 标准布局](https://github.com/golang-standards/project-layout)
- [DDD 分层架构](https://learn.microsoft.com/zh-cn/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/ddd-oriented-microservice)
- [Gin 文档](https://gin-gonic.com/docs/)
- [Ent 文档](https://entgo.io/docs/getting-started)
- [React 文档](https://react.dev/)
- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Vite 文档](https://vitejs.dev/)

## 贡献

欢迎提交 Issue 和 Pull Request，特别是：
- 新的技术栈选项
- 模板改进
- 文档完善

## 许可证

MIT
