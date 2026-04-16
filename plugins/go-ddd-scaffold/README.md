# Go DDD Scaffold

Go Web 项目脚手架生成器，基于 DDD 四层架构（Gin + Ent + Viper + slog + Prometheus + Sentry）。

## 前置依赖

- Go 1.22+

## 使用方式

在 Claude Code 中运行：

```
/init-go-web
```

交互式收集项目信息后自动生成。

### 手动生成

```bash
bash scripts/generate.sh <项目名> <module路径> <mysql|sqlite> <yes|no> <插件根目录>
```

示例：

```bash
bash scripts/generate.sh my-service github.com/myorg/my-service mysql yes /path/to/plugin
```

## 生成的项目结构

```
my-service/
├── cmd/server/main.go          # 服务入口
├── cmd/migrate/main.go         # 数据库迁移
├── configs/config.yaml         # 配置文件
├── internal/
│   ├── app/
│   │   ├── domain/             # 领域层（Entity、VO、Event、Repo接口）
│   │   ├── application/        # 应用层（Service、DTO）
│   │   ├── infrastructure/     # 基础设施层（Ent实现、可观测性）
│   │   └── interface/http/     # 接口层（Handler、Middleware、Router）
│   └── ent/                    # Ent ORM 生成代码
├── docker/                     # Docker 配置
├── Makefile
└── README.md
```

## 生成后的操作

```bash
cd my-service
make docker-up    # 启动 MySQL（如适用）
make migrate      # 数据库迁移
make run          # 启动服务
make test         # 运行测试
```

## API 端点

- `POST /api/v1/users` — 创建用户
- `GET /api/v1/users` — 用户列表
- `GET /api/v1/users/:id` — 查询用户
- `PUT /api/v1/users/:id` — 更新用户
- `DELETE /api/v1/users/:id` — 删除用户
- `GET /health` — 健康检查
- `GET /metrics` — Prometheus 指标

## 技术栈

| 组件 | 技术 |
|------|------|
| Web 框架 | Gin |
| ORM | Ent |
| 配置 | Viper |
| 日志 | slog |
| 监控 | Prometheus |
| 错误追踪 | Sentry |
| 领域事件 | CloudEvents |
