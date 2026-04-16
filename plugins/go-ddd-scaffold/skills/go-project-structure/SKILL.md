---
name: Go Project Structure
description: 用户问"Go 项目怎么组织"、"目录该怎么命名"、"cmd 目录放什么"、"internal 和 pkg 有什么区别"、"Go 标准项目布局是什么"时触发。涵盖 golang-standards/project-layout 规范和 DDD 目录组织。
version: 0.3.0
---

# Go 标准项目布局

## 核心目录

| 目录 | 用途 | 要点 |
|------|------|------|
| `/cmd` | 应用入口 | 每个应用一个子目录，main.go 保持精简 |
| `/internal` | 私有代码 | Go 编译器强制私有，按 DDD 分层组织 |
| `/internal/ent` | Ent 生成代码 | 和 `/internal/app` 平级 |
| `/pkg` | 公共库 | 确定对外暴露才放这里 |
| `/api` | API 定义 | OpenAPI, Proto |
| `/configs` | 配置文件 | 不含敏感信息，用环境变量 |
| `/test` | 集成测试 | 单元测试放在对应包的 `_test.go` |

## DDD 分层目录

```
internal/app/
  domain/{聚合}/entity/, valueobject/, event/, repository/, service/
  application/service/, dto/
  infrastructure/repository/, config/, observability/
  interface/http/handler/, dto/, middleware/, router.go
```

## 文件命名

Go 文件: `user_service.go` (小写 + 下划线)
目录: `user` (小写单数)
测试: `user_service_test.go`

## 类型命名速查

| 类别 | 规则 | 示例 |
|------|------|------|
| Entity | 名词 | `User`, `Order` |
| Value Object | 概念名词 | `Email`, `Money` |
| Repo 接口 | +Repository | `UserRepository` |
| Repo 实现 | +Impl 或存储前缀 | `EntUserRepository` |
| Service | +DomainService / +ApplicationService | `TransferDomainService` |
| DTO | +Request / +Response | `CreateUserRequest` |
| Event | 过去式 | `UserCreated` |
| Getter | 字段名 (无 Get) | `func (u *User) ID()` |
| Setter | 业务语义 | `func (u *User) ChangeName()` |
| Error | Err 前缀 | `ErrUserNotFound` |

## 不应有的目录

| 错误 | 正确 |
|------|------|
| `/src` | Go 不需要 src |
| `/models` | `/internal/app/domain` |
| `/controllers` | `/internal/app/interface/http/handler` |

## 最佳实践

1. 保持 `cmd/` 精简 -- main.go 只做初始化
2. 使用 `internal/` -- 私有代码不暴露
3. 按领域组织 -- internal/ 下按 DDD 聚合组织
4. 测试就近 -- 单元测试与代码同目录
5. 避免过深嵌套 -- 目录层级不超过 4-5 层

## 参考文档

- `references/go-project-layout.md` -- 完整目录结构、DDD 分层目录、命名规范详解
