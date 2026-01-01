# {{ .Project.Name }} 开发指南

## 目录

- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [开发流程](#开发流程)
- [测试](#测试)
- [调试](#调试)
- [常见问题](#常见问题)

## 环境要求

### 必需

- **Go**: {{ .Go.Version }}+
- **Make**: 任意版本
{{- if eq .Database.Driver "mysql" }}
- **MySQL**: 8.0+
{{- else if eq .Database.Driver "sqlite3" }}
- **SQLite**: 3.0+
{{- end }}

### 可选

- **Docker**: 20.10+（用于容器化开发）
- **Docker Compose**: 1.29+（用于本地环境）

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd {{ .Project.Name }}
```

### 2. 安装依赖

```bash
# 下载 Go 依赖
go mod download

# 验证依赖
go mod verify
```

### 3. 配置环境

复制配置文件并根据需要修改：

```bash
cp configs/config.yaml configs/config.local.yaml
```

编辑 `configs/config.local.yaml`：

```yaml
server:
  port: "8080"
  mode: "debug"  # debug, release, test

database:
{{- if eq .Database.Driver "mysql" }}
  driver: "mysql"
  dsn: "root:password@tcp(localhost:3306)/{{ .Project.Name }}?parseTime=true"
{{- else if eq .Database.Driver "sqlite3" }}
  driver: "sqlite3"
  dsn: "file:{{ .Project.Name }}.db?cache=shared&mode=rwc"
{{- end }}

logging:
  level: "debug"
  format: "text"  # text, json
```

### 4. 运行数据库迁移

{{- if eq .Database.Driver "mysql" }}
```bash
# 启动 MySQL（如果使用 Docker）
docker run --name {{ .Project.Name }}-mysql \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE={{ .Project.Name }} \
  -p 3306:3306 \
  -d mysql:8.0

# 等待 MySQL 启动完成
sleep 10
```
{{- end }}

```bash
# 运行迁移
go run cmd/migrate/main.go

# 或使用 Make
make migrate
```

### 5. 启动服务器

```bash
# 直接运行
go run cmd/server/main.go

# 或使用 Make
make run

# 或使用热重载（需要安装 air）
air
```

服务器将在 `http://localhost:{{ .Server.Port }}` 启动

### 6. 验证服务

```bash
# 健康检查
curl http://localhost:{{ .Server.Port }}/health

# Prometheus metrics
curl http://localhost:{{ .Server.Port }}/metrics

{{- if .IncludeExamples }}
# 创建用户
curl -X POST http://localhost:{{ .Server.Port }}/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test User"}'

# 获取用户列表
curl http://localhost:{{ .Server.Port }}/api/v1/users
{{- end }}
```

## 开发流程

### 添加新的聚合

假设要添加 `Product` 聚合：

#### 1. 创建 Ent Schema

创建 `{{ .Paths.EntSchema }}/product.go`：

```go
package schema

import (
    "entgo.io/ent"
    "entgo.io/ent/schema/field"
)

type Product struct {
    ent.Schema
}

func (Product) Fields() []ent.Field {
    return []ent.Field{
        field.UUID("id", uuid.UUID{}).Default(uuid.New),
        field.String("name"),
        field.Float("price"),
        field.Time("created_at").Default(time.Now),
        field.Time("updated_at").Default(time.Now).UpdateDefault(time.Now),
    }
}
```

#### 2. 生成 Ent 代码

```bash
# 生成 Ent 代码
go generate ./internal/ent

# 或使用 Make
make generate
```

#### 3. 创建领域层

创建以下文件：
- `{{ .Paths.Domain }}/product/entity/product.go` - 实体
- `{{ .Paths.Domain }}/product/repository/repository.go` - 仓储接口
- `{{ .Paths.Domain }}/product/event/product_created.go` - 领域事件

#### 4. 创建应用层

创建以下文件：
- `{{ .Paths.Application }}/product/service/application_service.go` - 应用服务
- `{{ .Paths.Application }}/product/dto/dto.go` - DTO

#### 5. 创建基础设施层

创建：
- `{{ .Paths.Infrastructure }}/repository/product_repository.go` - 仓储实现

#### 6. 创建接口层

创建以下文件：
- `{{ .Paths.Interface }}/http/handler/product_handler.go` - HTTP 处理器
- `{{ .Paths.Interface }}/http/dto/product_request.go` - 请求 DTO
- `{{ .Paths.Interface }}/http/dto/product_response.go` - 响应 DTO

#### 7. 注册路由

在 `{{ .Paths.Interface }}/http/router.go` 中添加：

```go
productHandler := handler.NewProductHandler(productService)
productGroup := v1.Group("/products")
{
    productGroup.POST("/", productHandler.CreateProduct)
    productGroup.GET("/:id", productHandler.GetProduct)
    // ...
}
```

### Makefile 命令

```bash
# 构建
make build         # 构建所有二进制文件
make build-server  # 只构建服务器
make build-migrate # 只构建迁移工具

# 运行
make run           # 运行服务器
make migrate       # 运行数据库迁移

# 测试
make test          # 运行所有测试
make test-unit     # 只运行单元测试
make test-integration # 只运行集成测试
make coverage      # 生成测试覆盖率报告

# 代码质量
make lint          # 运行 linter
make fmt           # 格式化代码
make vet           # 运行 go vet

# 清理
make clean         # 清理构建产物

# Docker
make docker-build  # 构建 Docker 镜像
make docker-up     # 启动 Docker Compose
make docker-down   # 停止 Docker Compose

# Ent
make generate      # 生成 Ent 代码
```

## 测试

### 单元测试

```bash
# 运行所有单元测试
go test ./... -short

# 运行特定包的测试
go test ./{{ .Paths.Domain }}/user/entity/...

# 带覆盖率
go test ./... -short -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### 集成测试

```bash
# 运行集成测试（需要数据库）
go test ./... -run Integration

# 使用 Docker 运行测试
make test-integration
```

### 编写测试

**单元测试示例**（`entity_test.go`）：

```go
func TestUser_ChangeName(t *testing.T) {
    user, _ := entity.NewUser(
        valueobject.NewEmail("test@example.com"),
        "Old Name",
    )

    err := user.ChangeName("New Name")
    assert.NoError(t, err)
    assert.Equal(t, "New Name", user.Name())
}
```

**集成测试示例**（`repository_test.go`）：

```go
func TestUserRepository_Save(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }

    // 设置测试数据库
    client := setupTestDB(t)
    defer client.Close()

    repo := repository.NewUserRepository(client)
    user, _ := entity.NewUser(...)

    err := repo.Save(context.Background(), user)
    assert.NoError(t, err)
}
```

## 调试

### VSCode 配置

创建 `.vscode/launch.json`：

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch Server",
            "type": "go",
            "request": "launch",
            "mode": "debug",
            "program": "${workspaceFolder}/cmd/server",
            "env": {
                "APP_SERVER_MODE": "debug",
                "APP_LOGGING_LEVEL": "debug"
            }
        }
    ]
}
```

### 使用 Delve

```bash
# 安装 Delve
go install github.com/go-delve/delve/cmd/dlv@latest

# 调试服务器
dlv debug ./cmd/server/main.go

# 在代码中设置断点
(dlv) break main.main
(dlv) continue
```

### 日志调试

在代码中添加日志：

```go
logger.Debug("Debug message",
    slog.String("key", "value"),
    slog.Any("object", obj),
)
```

## 常见问题

### 1. 数据库连接失败

**问题**: `Failed to connect to database`

**解决**:
{{- if eq .Database.Driver "mysql" }}
- 检查 MySQL 是否启动：`docker ps` 或 `systemctl status mysql`
- 检查 DSN 配置是否正确
- 检查端口 3306 是否被占用
{{- else if eq .Database.Driver "sqlite3" }}
- 检查 SQLite 数据库文件路径
- 确保目录有写入权限
{{- end }}

### 2. 端口已被占用

**问题**: `address already in use`

**解决**:
```bash
# 查找占用端口的进程
lsof -i :{{ .Server.Port }}

# 杀死进程
kill -9 <PID>

# 或更换端口
export APP_SERVER_PORT=8081
```

### 3. Go 依赖下载失败

**问题**: `go: downloading ... connection timeout`

**解决**:
```bash
# 设置 Go 代理
export GOPROXY=https://goproxy.cn,direct

# 或
export GOPROXY=https://goproxy.io,direct
```

### 4. Ent 代码生成失败

**问题**: `entgo.io/ent/cmd/ent: command not found`

**解决**:
```bash
# 安装 Ent 工具
go install entgo.io/ent/cmd/ent@latest

# 确保 $GOPATH/bin 在 PATH 中
export PATH=$PATH:$(go env GOPATH)/bin
```

## 开发技巧

### 1. 使用热重载

安装 Air：

```bash
go install github.com/cosmtrek/air@latest
```

创建 `.air.toml`：

```toml
[build]
cmd = "go build -o ./tmp/main ./cmd/server"
bin = "tmp/main"
include_ext = ["go", "yaml"]
exclude_dir = ["tmp", "vendor"]
```

运行：

```bash
air
```

### 2. 使用 golangci-lint

```bash
# 安装
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# 运行
golangci-lint run
```

### 3. 生成 Mock

使用 mockery 生成 Mock：

```bash
# 安装
go install github.com/vektra/mockery/v2@latest

# 生成 Mock
mockery --name=UserRepository --dir={{ .Paths.Domain }}/user/repository
```
