# Smart Git Commit - 智能 Git 提交助手

智能分析代码变更，自动生成符合 [Conventional Commits](https://www.conventionalcommits.org/) 规范的 commit message。

## 概述

Smart Git Commit 是一个基于 AI 的 Git 提交助手，它可以：

- 🔍 **智能分析**：自动分析 `git status` 和 `git diff`
- 📝 **规范生成**：生成符合 Conventional Commits 规范的 commit message
- 🌏 **双语支持**：支持中英文 commit message
- 🎯 **类型识别**：自动识别变更类型（feat/fix/refactor/docs/test/chore 等）
- 📦 **范围推断**：智能推断变更范围（如 api, ui, db）
- ✅ **交互确认**：在提交前可以确认或修改 message

## 安装

```bash
/plugin install smart-git-commit
```

## 技术方案

**架构：** Slash Command + Agent

```
/commit 命令
    ↓
调用 commit-assistant Agent
    ↓
分析 git status 和 git diff
    ↓
生成 Conventional Commits 格式 message
    ↓
交互确认
    ↓
执行 git commit
```

## 使用方式

### 基本使用

```bash
# 普通提交
/commit

# 修改上一次提交
/commit --amend
```

### 工作流程

1. **执行命令**
   ```bash
   /commit
   ```

2. **自动分析**
   - Agent 执行 `git status` 查看文件状态
   - 执行 `git diff` 查看具体变更
   - 分析变更的文件路径、类型和内容

3. **智能生成**
   - 识别变更类型（feature/fix/refactor 等）
   - 推断变更范围（根据文件路径）
   - 生成简洁的 commit subject
   - 生成详细的 commit body（如果需要）
   - 添加相关的 footer（如 Breaking Changes）

4. **交互确认**
   - 展示生成的 commit message
   - 询问是否确认或需要修改

5. **执行提交**
   - 执行 `git add` 添加文件
   - 执行 `git commit` 创建提交

## Conventional Commits 规范

### 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型（Type）

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(api): add user authentication endpoint` |
| `fix` | Bug 修复 | `fix(ui): resolve button alignment issue` |
| `docs` | 文档更新 | `docs(readme): update installation guide` |
| `style` | 代码格式（不影响功能） | `style(lint): fix eslint warnings` |
| `refactor` | 重构（不是新功能也不是修复） | `refactor(db): optimize query performance` |
| `perf` | 性能优化 | `perf(api): reduce response time by caching` |
| `test` | 测试相关 | `test(auth): add unit tests for login` |
| `build` | 构建系统或外部依赖 | `build(deps): upgrade react to 18.2` |
| `ci` | CI 配置 | `ci(github): add automated testing workflow` |
| `chore` | 其他修改 | `chore(git): update .gitignore` |
| `revert` | 回退 | `revert: revert commit abc123` |

### 范围（Scope）

范围是可选的，表示变更影响的模块或组件：

- `api` - 后端 API
- `ui` - 用户界面
- `db` - 数据库
- `auth` - 认证系统
- `docs` - 文档
- `test` - 测试
- `config` - 配置
- `build` - 构建
- `deps` - 依赖

### 主题（Subject）

- 使用祈使句，现在时："add" 而不是 "added" 或 "adds"
- 首字母小写
- 结尾不加句号
- 简洁明了，不超过 50 个字符

### 正文（Body）

可选，详细说明：

- 变更的原因
- 与之前的对比
- 可能的副作用

### 页脚（Footer）

可选，用于：

- **Breaking Changes**：不兼容的变更
  ```
  BREAKING CHANGE: API endpoint /users changed to /v2/users
  ```

- **Issue 引用**：关联的 Issue
  ```
  Closes #123
  Fixes #456
  ```

## 使用示例

### 示例 1：新增功能

**场景：** 添加了用户登录功能

**变更文件：**
- `backend/internal/interfaces/handler/auth_handler.go`
- `backend/internal/application/usecase/auth/login.go`
- `frontend/src/pages/Login.tsx`

**生成的 commit message：**
```
feat(auth): add user login functionality

- Implement login handler with JWT authentication
- Add login use case with password validation
- Create login page with form validation

Related to #42
```

### 示例 2：Bug 修复

**场景：** 修复了按钮对齐问题

**变更文件：**
- `frontend/src/components/ui/Button.tsx`
- `frontend/src/styles/button.css`

**生成的 commit message：**
```
fix(ui): resolve button alignment issue in modal

The submit button was not properly aligned in the modal dialog.
Fixed by adjusting flexbox properties.

Fixes #89
```

### 示例 3：重构

**场景：** 优化数据库查询性能

**变更文件：**
- `backend/internal/infrastructure/persistence/repository/user_repository.go`

**生成的 commit message：**
```
refactor(db): optimize user query performance

- Add database indexes for frequently queried fields
- Implement eager loading to reduce N+1 queries
- Reduce query time from 500ms to 50ms
```

### 示例 4：文档更新

**场景：** 更新 README

**变更文件：**
- `README.md`

**生成的 commit message：**
```
docs(readme): update installation instructions

Add Docker installation steps and troubleshooting section.
```

### 示例 5：Breaking Change

**场景：** API 接口不兼容变更

**变更文件：**
- `backend/internal/interfaces/handler/user_handler.go`
- `backend/api/openapi.yaml`

**生成的 commit message：**
```
feat(api): redesign user API endpoints

- Rename /users to /v2/users
- Change response format to include metadata
- Add pagination support

BREAKING CHANGE: The /users endpoint has been moved to /v2/users.
The response format has changed from a flat array to an object with
data and metadata fields. Clients need to update their integrations.

Closes #156
```

## 配置选项

### 语言设置

Agent 会自动根据代码库和变更内容选择合适的语言（中文或英文）。

你也可以在 commit message 中混用中英文：

```
feat(auth): 添加用户登录功能

Implement JWT-based authentication with the following features:
- 用户名/密码验证
- Token 自动刷新
- Remember me 功能
```

### Amend 提交

如果你想修改上一次提交：

```bash
/commit --amend
```

这会：
1. 分析当前的暂存变更
2. 生成新的 commit message
3. 使用 `git commit --amend` 修改上一次提交

## 最佳实践

### 1. 提交前检查

在执行 `/commit` 之前：

- 确保 `git status` 显示的文件都是你想提交的
- 使用 `git diff` 检查变更内容
- 确保没有包含敏感信息（密码、密钥等）

### 2. 原子性提交

每次提交应该只包含一个逻辑变更：

- ✅ 好：一次提交只添加一个功能
- ❌ 差：一次提交包含多个不相关的变更

### 3. 有意义的提交

确保每个提交都是完整的、有意义的：

- ✅ 好：`feat(auth): add user login functionality`
- ❌ 差：`update code`、`fix bug`、`WIP`

### 4. 利用 Scope

使用 scope 可以让提交历史更清晰：

```bash
feat(api): add endpoint          # 后端 API
feat(ui): add button             # 前端 UI
feat(db): add migration          # 数据库
```

### 5. Breaking Changes

如果有不兼容的变更，一定要在 footer 中说明：

```
BREAKING CHANGE: description of what broke and how to migrate
```

## 高级用法

### 查看提交历史

Agent 会自动查看最近的提交历史，学习你的提交风格：

```bash
git log --oneline -10
```

### 多文件变更

当有多个文件变更时，Agent 会：

1. 按文件路径分组（如 backend/, frontend/）
2. 识别主要的变更类型
3. 选择最合适的 scope
4. 在 body 中列出详细变更

### 自动识别范围

Agent 会根据文件路径自动推断 scope：

| 文件路径 | 推断的 Scope |
|---------|-------------|
| `backend/internal/interfaces/handler/` | `api` |
| `frontend/src/components/` | `ui` |
| `backend/internal/infrastructure/persistence/` | `db` |
| `docs/` | `docs` |
| `.github/workflows/` | `ci` |
| `package.json`, `go.mod` | `deps` |

## 故障排除

### 问题 1：Agent 没有识别变更类型

**解决方案：**
- 确保变更的文件有明确的功能
- 在交互确认时手动选择正确的类型

### 问题 2：Commit message 太长

**解决方案：**
- Agent 生成的 message 可以在确认时修改
- 简化 subject，详细内容放到 body

### 问题 3：想要修改生成的 message

**解决方案：**
- 在确认步骤选择 "修改"
- 或使用 `git commit --amend` 后续修改

### 问题 4：不小心提交了错误的内容

**解决方案：**
```bash
# 回退到上一次提交（保留变更）
git reset --soft HEAD~1

# 重新提交
/commit
```

## 技术实现细节

### Slash Command

文件：`commands/commit.md`

```yaml
---
name: commit
description: 智能 Git 提交助手
---
```

### Commit Assistant Agent

文件：`agents/commit-assistant.md`

**核心功能：**
1. 执行 `git status` 获取文件状态
2. 执行 `git diff` 获取变更详情
3. 分析文件路径和变更内容
4. 根据 Conventional Commits 规范生成 message
5. 交互式确认
6. 执行 git commit

**使用的工具：**
- `Bash`: 执行 git 命令
- `Read`: 读取配置文件
- `Grep`: 搜索代码内容

### Commit Message 模板

文件：`templates/commit-message-template.md`

提供：
- Conventional Commits 完整规范
- 各种类型的示例
- 最佳实践建议

## 与其他工具集成

### Commitlint

Smart Git Commit 生成的 message 完全符合 commitlint 规范：

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

`.commitlintrc.json`:
```json
{
  "extends": ["@commitlint/config-conventional"]
}
```

### Husky

配合 husky 使用，自动验证 commit message：

```bash
npm install --save-dev husky

# .husky/commit-msg
#!/bin/sh
npx --no -- commitlint --edit $1
```

### Changelog 生成

基于 Conventional Commits 的提交可以自动生成 CHANGELOG：

```bash
npm install --save-dev conventional-changelog-cli

# 生成 CHANGELOG
npx conventional-changelog -p angular -i CHANGELOG.md -s
```

## 参考资源

- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [Angular Commit Message 规范](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- [Commitizen](https://github.com/commitizen/cz-cli)
- [Commitlint](https://commitlint.js.org/)

## 常见问题

### Q: 如何强制使用特定的类型？

A: 在交互确认时可以手动修改类型。

### Q: 支持哪些语言？

A: 主要支持中文和英文，可以混用。

### Q: 如何添加自定义的 scope？

A: 在交互确认时可以手动输入 scope。

### Q: 是否支持 emoji？

A: 目前不默认添加 emoji，但你可以在确认时手动添加。

### Q: 如何设置默认的提交模板？

A: 可以通过 git 配置：
```bash
git config commit.template ~/.gitmessage
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT
