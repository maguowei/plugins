# mysql-test

基于 DDD 架构的 Go Web 服务。

## 快速开始

1. 启动数据库: `make docker-up`
2. 运行迁移: `make migrate`
3. 启动服务: `make run`
4. 测试: `curl http://localhost:8080/health`

## API

- `POST /api/v1/users` — 创建用户
- `GET /api/v1/users` — 用户列表
- `GET /api/v1/users/:id` — 查询用户
- `PUT /api/v1/users/:id` — 更新用户
- `DELETE /api/v1/users/:id` — 删除用户
