# Commit Message 模板和规范

本文档提供 Conventional Commits 规范的详细说明和示例。

## 基本格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| feat | 新功能 | feat(auth): 添加用户登录功能 |
| fix | Bug 修复 | fix(api): 修复空指针错误 |
| refactor | 代码重构 | refactor(db): 重构连接池逻辑 |
| docs | 文档更新 | docs(readme): 更新安装说明 |
| test | 测试相关 | test(user): 添加用户服务单元测试 |
| build | 构建系统 | build(deps): 升级 gin 到 v1.9.0 |
| ci | CI 配置 | ci(github): 添加 Go 测试工作流 |
| perf | 性能优化 | perf(query): 优化数据库查询性能 |
| style | 代码格式 | style(format): 格式化代码 |
| chore | 其他杂项 | chore(gitignore): 添加 .env 到忽略列表 |

## Scope 范围

从项目模块或文件路径提取，例如：

- `auth` - 认证相关
- `api` - API 相关
- `ui` - 用户界面
- `db` - 数据库
- `user` - 用户模块
- `payment` - 支付模块
- `core` - 核心逻辑

## Subject 主题

- 使用祈使句，现在时（如"添加"而不是"添加了"）
- 首字母小写
- 不超过 50 个字符
- 结尾不加句号
- 清晰具体，避免模糊

**好的示例：**
- `添加用户注册功能`
- `修复登录超时问题`
- `优化首页加载速度`

**不好的示例：**
- `更新` （太模糊）
- `修复了一个 bug` （未说明具体bug）
- `添加了很多新功能` （不具体）

## Body 正文

- 与 subject 之间空一行
- 详细说明变更的动机和内容
- 每行不超过 72 个字符
- 可以分多段
- 解释"为什么"和"怎么做"

**示例：**

```
为了提升用户体验，实现了自动保存功能。

具体改动：
- 添加定时器每 30 秒自动保存
- 实现本地存储备份
- 添加保存状态提示

解决了用户意外关闭浏览器导致数据丢失的问题。
```

## Footer 页脚

### 1. 破坏性变更

```
BREAKING CHANGE: API 接口路径变更

所有 API 端点从 /v1/ 迁移到 /v2/。
客户端需要更新请求路径。
```

### 2. 关联 Issue

```
Closes #123
Fixes #456
Relates to #789
```

### 3. 其他元信息

```
Reviewed-by: @reviewer
Co-authored-by: name <email>
```

## 完整示例

### 示例 1：新功能

```
feat(payment): 添加支付宝支付集成

实现了支付宝扫码支付功能，包括：
- 生成支付二维码
- 处理支付回调
- 更新订单状态
- 发送支付成功通知

支持沙箱和生产环境配置。

Closes #234
```

### 示例 2：Bug 修复

```
fix(auth): 修复 JWT token 过期时间错误

JWT token 过期时间设置错误，导致用户需要频繁重新登录。
将过期时间从 1 小时改为 24 小时。

Fixes #567
```

### 示例 3：重构

```
refactor(api): 重构 HTTP 路由配置

将所有路由配置集中到 routes.go 文件中，提升代码可维护性。

主要变更：
- 创建 routes.go 统一管理路由
- 按功能模块分组路由
- 添加路由注释说明

```

### 示例 4：性能优化

```
perf(db): 优化用户查询性能

通过添加索引和查询优化，将用户查询时间从 500ms 降低到 50ms。

优化内容：
- 在 email 字段添加索引
- 使用预编译语句
- 实现查询结果缓存
```

### 示例 5：破坏性变更

```
refactor(api)!: 重构 API 响应格式

统一所有 API 响应格式，提升一致性。

新格式：
{
  "code": 0,
  "message": "success",
  "data": {...}
}

BREAKING CHANGE: API 响应格式变更

所有 API 端点的响应格式已更改。
客户端需要更新响应解析逻辑。

迁移指南：https://docs.example.com/api-migration
```

## 提交频率建议

### 应该提交

- 完成一个功能单元
- 修复一个 bug
- 重构一个模块
- 更新相关文档

### 不应该提交

- 未完成的代码
- 破坏测试的代码
- 包含多个不相关变更
- 调试代码和临时文件

## 最佳实践

1. **小步提交** - 每次提交只做一件事
2. **完整提交** - 确保提交是可运行的
3. **清晰描述** - commit message 要让他人能理解
4. **遵循规范** - 保持团队一致性
5. **及时提交** - 不要积累太多变更

## 工具推荐

- **commitlint** - 检查 commit message 格式
- **husky** - Git hooks 管理
- **conventional-changelog** - 自动生成 CHANGELOG

## 参考资源

- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [Angular 提交规范](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- [Semantic Versioning](https://semver.org/)
