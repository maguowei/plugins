# {{ .ProjectName }}

{{ .ProjectDescription | default "基于 DDD 架构的 Go Web 服务" }}

## 项目概述

本项目采用领域驱动设计 (DDD) 和整洁架构 (Clean Architecture) 原则构建，使用 Go 语言实现。

### 技术栈

- **Web 框架**: Gin {{ .Go.Dependencies | findByName "github.com/gin-gonic/gin" | getVersion }}
- **ORM**: Ent {{ .Go.Dependencies | findByName "entgo.io/ent" | getVersion }}
- **数据库**: {{ .Database | upper }}
- **配置管理**: Viper
- **日志**: slog (Go 标准库)
- **监控**: Prometheus
- **错误追踪**: Sentry
- **事件**: CloudEvents

### 架构设计

本项目严格遵循 DDD 四层架构：

```
{{ .ProjectName }}/
├── cmd/                          # 应用程序入口
│   ├── server/                   # HTTP 服务器
│   └── migrate/                  # 数据库迁移工具
├── internal/                     # 私有代码
│   ├── app/                      # 应用程序核心
│   │   ├── domain/              # 领域层 (业务逻辑核心)
│   │   ├── application/         # 应用层 (用例编排)
│   │   ├── infrastructure/      # 基础设施层 (技术实现)
│   │   └── interface/           # 接口层 (HTTP API)
│   └── ent/                     # Ent ORM Schema
├── api/                         # API 规范
├── configs/                     # 配置文件
├── docs/                        # 文档
├── scripts/                     # 脚本
└── deployments/                 # 部署配置
```

详细架构说明请参见 [docs/architecture.md](docs/architecture.md)

## 快速开始

### 前置要求

- Go {{ .Go.Version }}+
{{- if eq .Database "mysql" }}
- MySQL 8.0+
{{- else if eq .Database "sqlite" }}
- SQLite 3+
{{- end }}
- Docker & Docker Compose (可选)

### 本地开发

1. **克隆项目**

```bash
git clone <repository-url>
cd {{ .ProjectName }}
```

2. **安装依赖**

```bash
go mod download
```

3. **配置环境变量**

```bash
cp configs/config.yaml configs/config.local.yaml
# 编辑 configs/config.local.yaml，设置数据库连接等配置
```

4. **启动数据库** (使用 Docker)

```bash
{{- if eq .Database "mysql" }}
docker-compose up -d db
{{- else }}
# SQLite 无需额外启动
{{- end }}
```

5. **运行数据库迁移**

```bash
go run ./cmd/migrate
```

6. **启动服务器**

```bash
go run ./cmd/server
```

服务器将在 `http://localhost:{{ .Server.Port }}` 启动。

### 使用 Docker Compose

```bash
docker-compose up
```

## 开发指南

### 项目结构

详细的项目结构说明请参见 [docs/development.md](docs/development.md)

### API 文档

- **OpenAPI 规范**: [api/openapi.yaml](api/openapi.yaml)
- **在线文档**: 启动服务器后访问 `http://localhost:{{ .Server.Port }}/swagger`

### 健康检查

```bash
curl http://localhost:{{ .Server.Port }}/health
```

### Prometheus 指标

```bash
curl http://localhost:{{ .Server.Port }}/metrics
```

## 测试

### 运行所有测试

```bash
go test ./...
```

### 运行单元测试

```bash
go test ./internal/app/domain/...
```

### 运行集成测试

```bash
go test ./test/integration/...
```

### 测试覆盖率

```bash
go test -cover ./...
```

## 构建

### 构建二进制文件

```bash
# 使用脚本
./scripts/build.sh

# 或手动构建
go build -o bin/server ./cmd/server
go build -o bin/migrate ./cmd/migrate
```

### 构建 Docker 镜像

```bash
docker build -t {{ .ProjectName }}:latest .
```

## 部署

详细的部署指南请参见 [docs/deployment.md](docs/deployment.md)

### 环境变量

| 变量名 | 描述 | 默认值 |
|-------|------|--------|
{{- if eq .Database "mysql" }}
| `DATABASE_HOST` | 数据库主机 | `localhost` |
| `DATABASE_PORT` | 数据库端口 | `3306` |
| `DATABASE_USER` | 数据库用户 | `root` |
| `DATABASE_PASSWORD` | 数据库密码 | - |
| `DATABASE_NAME` | 数据库名称 | `{{ .ProjectName }}` |
{{- else if eq .Database "sqlite" }}
| `DATABASE_FILE` | SQLite 数据库文件路径 | `./data/data.db` |
{{- end }}
| `SERVER_PORT` | 服务器端口 | `{{ .Server.Port }}` |
| `LOG_LEVEL` | 日志级别 | `{{ .Logging.Level }}` |
| `SENTRY_DSN` | Sentry DSN | - |

## 贡献

欢迎贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

## 许可证

[MIT License](LICENSE)

## 联系方式

{{- if .Author.Name }}
- 作者: {{ .Author.Name }}
{{- end }}
{{- if .Author.Email }}
- 邮箱: {{ .Author.Email }}
{{- end }}

---

🤖 本项目使用 [Claude Code](https://claude.com/claude-code) 的 go-ddd-scaffold 插件生成
