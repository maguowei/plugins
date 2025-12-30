# Go DDD Scaffold

> Go Web 项目脚手架生成器 - 一键创建符合 DDD 架构和 Go 标准布局的企业级 Web 项目

## 概述

**go-ddd-scaffold** 是一个 Claude Code 插件，用于快速生成遵循领域驱动设计（DDD）和整洁架构（Clean Architecture）原则的 Go Web 项目。生成的项目开箱即用，包含完整的 CRUD 示例、测试、文档和容器化配置。

## 特性

### 架构模式
- ✅ **DDD 四层架构**: Domain、Application、Infrastructure、Interface 层清晰分离
- ✅ **整洁架构**: 遵循依赖倒置原则，核心业务逻辑独立于框架
- ✅ **SOLID 原则**: 单一职责、开闭原则、里氏替换、接口隔离、依赖倒置
- ✅ **Go 标准布局**: 符合 golang-standards/project-layout 规范

### 技术栈
- **Web 框架**: Gin
- **ORM**: Ent (Facebook 开源)
- **配置管理**: Viper
- **日志**: slog (Go 1.21+ 官方库)
- **数据库**: MySQL / SQLite
- **错误追踪**: Sentry
- **监控指标**: Prometheus
- **测试**: testing + testify + gomock
- **代码质量**: golangci-lint

### 开箱即用
- ✅ **完整 CRUD 示例**: User 实体的增删改查实现
- ✅ **DDD 核心概念**: Entity、Value Object、Domain Event、Repository、Domain Service
- ✅ **容器化**: Docker + docker-compose 配置
- ✅ **API 规范**: OpenAPI 3.1 文档
- ✅ **完整文档**: 架构说明、开发指南、部署文档
- ✅ **单元测试**: 领域层单元测试 + 应用层集成测试
- ✅ **自动初始化**: 自动安装依赖、生成代码

## 快速开始

### 前置要求
- Claude Code CLI 已安装
- Go 1.21+ 已安装
- Docker 已安装（可选，用于容器化运行）

### 安装插件

1. 克隆插件仓库或复制插件目录到 `.claude-plugin/`
2. 启动 Claude Code 时指定插件目录：
   ```bash
   cc --plugin-dir /path/to/plugins/go-ddd-scaffold
   ```

### 创建项目

在 Claude Code 中执行：

```
/init-go-web
```

插件将引导你输入以下信息：
- **项目名称**: 例如 `my-service`
- **Go module 路径**: 例如 `github.com/myorg/my-service`
- **数据库类型**: `mysql` 或 `sqlite`
- **是否包含完整示例**: 默认 `yes`，包含 User CRUD 完整实现

生成完成后，你将得到一个可立即运行的 Go Web 项目！

### 运行生成的项目

```bash
cd <项目名称>

# 启动依赖服务（MySQL）
docker-compose up -d db

# 运行数据库迁移
go run ./cmd/migrate

# 启动服务
go run ./cmd/server

# 访问 API
curl http://localhost:8080/api/v1/users
```

## 生成的项目结构

```
my-service/
├── cmd/                    # 应用程序入口
│   ├── server/            # HTTP 服务器
│   └── migrate/           # 数据库迁移工具
├── api/                   # OpenAPI 规范
├── configs/               # 配置文件
├── internal/              # 内部代码
│   ├── app/
│   │   ├── domain/        # 领域层（核心业务逻辑）
│   │   │   └── user/
│   │   │       ├── entity/        # 实体
│   │   │       ├── valueobject/   # 值对象
│   │   │       ├── event/         # 领域事件
│   │   │       ├── repository/    # 仓储接口
│   │   │       └── service/       # 领域服务
│   │   ├── application/   # 应用层（用例编排）
│   │   ├── infrastructure/# 基础设施层（技术实现）
│   │   │   ├── repository/       # 仓储实现
│   │   │   ├── config/           # 配置管理
│   │   │   └── observability/    # 可观测性
│   │   └── interface/     # 接口层（HTTP API）
│   │       ├── handler/          # HTTP 处理器
│   │       ├── dto/              # 数据传输对象
│   │       └── middleware/       # 中间件
│   └── ent/               # Ent ORM Schema（私有）
├── test/                  # 集成测试
├── docs/                  # 文档
├── scripts/               # 脚本
├── deployments/           # 部署配置
│   ├── docker/
│   └── k8s/
├── docker-compose.yml
├── Dockerfile
└── README.md
```

## DDD 核心概念示例

生成的项目包含完整的 DDD 概念实现：

### Entity（实体）
```go
// internal/app/domain/user/entity/user.go
type User struct {
    ID        uuid.UUID
    Email     valueobject.Email  // 值对象
    Name      string
    CreatedAt time.Time
}
```

### Value Object（值对象）
```go
// internal/app/domain/user/valueobject/email.go
type Email struct {
    value string
}

func NewEmail(email string) (Email, error) {
    if !isValidEmail(email) {
        return Email{}, errors.New("invalid email")
    }
    return Email{value: email}, nil
}
```

### Domain Event（领域事件）
```go
// internal/app/domain/user/event/user_created.go
type UserCreated struct {
    UserID    uuid.UUID
    Email     string
    OccurredAt time.Time
}
```

### Repository（仓储）
```go
// 接口定义在 domain 层
type UserRepository interface {
    Save(ctx context.Context, user *entity.User) error
    FindByID(ctx context.Context, id uuid.UUID) (*entity.User, error)
}

// 实现在 infrastructure 层
type EntUserRepository struct { ... }
```

## 插件组件

### Commands（命令）
- `/init-go-web` - 交互式项目初始化命令

### Agents（代理）
- `go-ddd-scaffold-generator` - 自主生成完整项目结构和代码

### Skills（技能）
插件包含 6 个详细的技能文档，提供 DDD 和 Go 开发的完整知识：

1. **ddd-core-concepts** - DDD 核心概念详解
2. **ddd-layered-architecture** - DDD 四层架构设计模式
3. **go-project-structure** - Go 标准项目布局规范
4. **go-tech-stack-integration** - Gin+Ent 等技术栈集成
5. **clean-architecture-principles** - SOLID 和整洁架构原则
6. **cloudevents-pattern** - CloudEvents 领域事件模式

## 开发指南

### 添加新的实体

1. 在 `internal/app/domain/<实体名>/` 创建目录结构
2. 定义 Entity、Value Object、Repository 接口
3. 在 `infrastructure/repository/` 实现仓储
4. 在 `application/service/` 创建应用服务
5. 在 `interface/handler/` 添加 HTTP 处理器
6. 在 `internal/ent/schema/` 添加 Ent Schema

### 运行测试

```bash
# 单元测试
go test ./internal/app/domain/...

# 集成测试
go test ./test/...

# 测试覆盖率
go test -cover ./...
```

### 代码检查

```bash
golangci-lint run
```

## 技术支持

### 文档
- [DDD 概念详解](./skills/ddd-core-concepts/SKILL.md)
- [架构设计原则](./skills/clean-architecture-principles/SKILL.md)
- [项目结构说明](./skills/go-project-structure/SKILL.md)

### 问题反馈
如有问题或建议，请在项目仓库提交 Issue。

## 许可证

MIT License

---

**生成高质量、可维护、遵循最佳实践的 Go Web 项目！** 🚀
