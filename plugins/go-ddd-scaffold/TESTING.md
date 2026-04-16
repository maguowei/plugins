# 测试指南

## 验证生成的项目

### 1. MySQL 项目

```bash
bash scripts/generate.sh mysql-test github.com/test/mysql-test mysql yes "$(pwd)"
cd mysql-test
go build ./...       # 编译通过
go test ./... -v     # 14 个测试通过
cd .. && rm -rf mysql-test
```

### 2. SQLite 项目

```bash
bash scripts/generate.sh sqlite-test github.com/test/sqlite-test sqlite yes "$(pwd)"
cd sqlite-test
go build ./...
go test ./... -v
cd .. && rm -rf sqlite-test
```

### 3. 无示例骨架

```bash
bash scripts/generate.sh skeleton github.com/test/skeleton mysql no "$(pwd)"
cd skeleton
go build ./...
cd .. && rm -rf skeleton
```

## 验收标准

- [ ] MySQL 项目：编译通过，测试通过
- [ ] SQLite 项目：编译通过，测试通过
- [ ] 无示例项目：编译通过（空骨架）
- [ ] `go build ./...` 无报错
- [ ] `go test ./...` 全部 PASS
- [ ] 健康检查端点 `/health` 返回 200
- [ ] API 端点 `/api/v1/users` 存在

## Scaffold CLI 测试

```bash
cd tools/scaffold
go test -v
```

预期：3 个测试通过（模板渲染、User 文件跳过、非模板文件复制）。

## 测试覆盖

生成项目包含以下测试：

| 包 | 测试数 | 内容 |
|---|--------|------|
| domain/valueobject | 5 | Email 值对象验证 |
| domain/entity | 5 | User 实体创建和修改 |
| domain/service | 2 | 邮箱唯一性检查 |
| application/service | 2 | 创建用户和重复邮箱 |
| **合计** | **14** | |
