# Smart Git Commit - 智能 Git 提交助手

自动分析代码变更并生成符合 Conventional Commits 规范的高质量 commit message。

## 功能特性

- 🤖 **智能分析** - 深度理解代码变更内容和影响
- 📝 **规范生成** - 符合 Conventional Commits 规范
- 🌏 **双语支持** - 支持中英文 commit message
- 🔍 **类型识别** - 自动识别变更类型（feat/fix/refactor等）
- 🎯 **范围推断** - 智能推断变更影响的模块范围
- ✅ **交互确认** - 生成后允许确认或修改
- 📚 **学习历史** - 参考项目历史commit保持一致性

## 安装

```bash
/plugin install smart-git-commit
```

## 使用方式

### 基本使用

1. 修改代码
2. 执行提交命令

```bash
/commit
```

3. Claude 会自动：
   - 分析 git status 和 git diff
   - 识别变更类型和范围
   - 生成规范的 commit message
   - 请求确认
   - 执行 git commit

### 修改最后一次提交

```bash
/commit --amend
```

## 工作流程

```
用户执行 /commit
    ↓
分析 git status 和 git diff
    ↓
识别变更类型和范围
    ↓
生成 Conventional Commits 格式的 message
    ↓
展示给用户确认
    ↓
用户确认或修改
    ↓
执行 git add 和 git commit
    ↓
完成！
```

## Commit Message 格式

遵循 Conventional Commits 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

- `feat` - 新功能
- `fix` - Bug 修复
- `refactor` - 代码重构
- `docs` - 文档更新
- `test` - 测试相关
- `build` - 构建系统
- `ci` - CI 配置
- `perf` - 性能优化
- `style` - 代码格式
- `chore` - 其他杂项

### 示例

#### 示例 1：新功能

```
feat(auth): 添加用户登录功能

实现了基于 JWT 的用户登录认证系统，包括：
- 用户密码加密存储
- JWT token 生成和验证
- 登录接口实现

Closes #123
```

#### 示例 2：Bug 修复

```
fix(api): 修复用户查询接口的空指针错误

在用户不存在时，查询接口会返回 null pointer 错误。
现在改为返回 404 状态码和友好的错误信息。
```

#### 示例 3：重构

```
refactor(db): 重构数据库连接池配置

将硬编码的配置改为从环境变量读取，提升配置的灵活性。
```

## 使用场景

### 场景 1：日常功能开发

```bash
# 开发新功能
vim backend/internal/domain/user/service.go

# 智能提交
/commit
```

**生成的 commit：**
```
feat(user): 添加用户信息更新功能

实现了用户信息更新接口，支持更新昵称、头像等信息。
```

### 场景 2：Bug 修复

```bash
# 修复 bug
vim backend/internal/infrastructure/db/connection.go

# 智能提交
/commit
```

**生成的 commit：**
```
fix(db): 修复数据库连接泄漏问题

添加 defer 确保数据库连接正确释放，防止连接池耗尽。
```

### 场景 3：文档更新

```bash
# 更新文档
vim README.md

# 智能提交
/commit
```

**生成的 commit：**
```
docs(readme): 更新安装说明

添加了 Docker 部署的详细步骤。
```

### 场景 4：多文件变更

```bash
# 修改多个相关文件
vim backend/internal/interfaces/handler/user.go
vim backend/internal/domain/user/service.go
vim backend/internal/domain/user/repository.go

# 智能提交（会分析所有变更）
/commit
```

**生成的 commit：**
```
feat(user): 实现用户完整的 CRUD 功能

实现了用户的增删改查功能，采用 DDD 分层架构：
- Handler 层：处理 HTTP 请求
- Service 层：业务逻辑
- Repository 层：数据访问

符合 RESTful API 规范。
```

## 智能识别示例

### 识别变更类型

| 文件变更 | 识别为 | 说明 |
|---------|--------|------|
| 新增 user_service.go | feat | 新功能 |
| 修复 null pointer | fix | Bug 修复 |
| 优化查询逻辑 | refactor | 重构 |
| 更新 README.md | docs | 文档 |
| 添加单元测试 | test | 测试 |
| 升级依赖版本 | build | 构建 |

### 识别范围（Scope）

| 文件路径 | 识别 Scope |
|---------|-----------|
| backend/internal/domain/user/ | user |
| frontend/src/components/Header/ | header 或 ui |
| api/openapi.yaml | api |
| backend/internal/infrastructure/db/ | db |
| docs/README.md | 省略或 docs |

## 高级功能

### 1. 破坏性变更

如果检测到破坏性变更（API 变更、接口调整等），会自动添加 BREAKING CHANGE：

```
refactor(api)!: 重构 API 响应格式

统一所有 API 响应格式。

BREAKING CHANGE: API 响应格式变更

所有 API 端点的响应格式已更改。
客户端需要更新响应解析逻辑。
```

### 2. 关联 Issue

如果 commit 相关 Issue，会询问并添加到 footer：

```
feat(payment): 添加支付宝支付集成

Closes #234
```

### 3. 多次提交建议

如果检测到多个不相关的变更，会建议分别提交：

```
检测到以下变更：
1. 用户登录功能（feat）
2. README 文档更新（docs）

建议分别提交以保持提交历史清晰。
```

## 配置选项

可以在 `.claude/settings.json` 中配置：

```json
{
  "plugins": {
    "smart-git-commit": {
      "language": "zh-CN",
      "conventional-commits": true,
      "auto-add-files": false,
      "max-subject-length": 50,
      "require-scope": false
    }
  }
}
```

**选项说明：**

- `language` - commit message 语言（zh-CN/en-US）
- `conventional-commits` - 是否强制 Conventional Commits 规范
- `auto-add-files` - 是否自动 add 所有变更
- `max-subject-length` - subject 最大长度
- `require-scope` - 是否强制要求 scope

## 最佳实践

### 1. 小步提交

每次只提交一个功能单元或 bug 修复：

```bash
# 好的做法
/commit  # 仅提交用户登录功能

# 不好的做法
# 同时修改了登录、注册、支付三个功能后一起提交
```

### 2. 保持一致性

Claude 会学习项目的历史 commit，保持风格一致：

```bash
# 项目历史使用中文
feat(auth): 添加用户登录

# Claude 也会生成中文
feat(user): 添加用户注册
```

### 3. 详细的 Body

对于复杂变更，提供详细的 body：

```
feat(payment): 添加支付宝支付集成

实现了支付宝扫码支付功能，包括：
- 生成支付二维码
- 处理支付回调
- 更新订单状态
- 发送支付成功通知

支持沙箱和生产环境配置。
```

## 故障排除

### 问题 1：没有检测到变更

**症状：**
```
当前没有检测到任何代码变更。
```

**解决方案：**
1. 确认已修改文件
2. 运行 `git status` 检查
3. 如果文件未 staged，会提示是否 add

### 问题 2：无法生成合适的 commit message

**症状：**
生成的 commit message 不准确

**解决方案：**
1. 选择"修改 message"选项
2. 提供更多上下文信息
3. Claude 会重新生成

### 问题 3：Git 错误

**症状：**
```
Git 操作失败：not a git repository
```

**解决方案：**
1. 确认在 Git 仓库中
2. 运行 `git init` 初始化仓库
3. 配置 git 用户信息

## 技术实现

### 架构

**Slash Command (`/commit`)**
- 提供用户触发点
- 接收参数（如 `--amend`）
- 调用 smart-git-commit:commit-assistant Agent

**Agent (smart-git-commit:commit-assistant)**
- 执行 git 命令分析仓库
- 使用 AI 理解代码变更
- 生成规范的 commit message
- 与用户交互确认
- 执行最终的 git commit

### 工具使用

- `Bash` - 执行 git 命令
- `Read` - 读取文件内容（如需要）
- `Grep` - 搜索代码模式（如需要）
- `AskUserQuestion` - 与用户交互

### 模型

使用 Sonnet 模型，平衡性能和成本。

## 参考资源

- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [Angular 提交规范](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- [Semantic Versioning](https://semver.org/)
- [Commit Message 模板](templates/commit-message-template.md)

## 许可证

MIT

## 作者

[maguowei](https://github.com/maguowei)

## 反馈

遇到问题或有建议？欢迎 [提交 Issue](https://github.com/maguowei/claude-plugins/issues)!
