---
name: Git Hooks Workflow
description: "Husky v9 + lint-staged + Commitlint 的 Git Hooks 自动化工作流指南。当用户提到 Husky、lint-staged、Commitlint、pre-commit hooks、commit-msg hook、提交信息规范、Conventional Commits、Git hooks 配置、代码提交前自动检查，甚至只是问 '怎么规范提交信息'、'提交前自动跑 lint'、'commitlint 配置' 这样的问题时，都应该使用这个 skill。"
version: 0.1.0
---

# Git Hooks 工作流指南

通过 **Husky v9 + lint-staged + Commitlint** 在提交代码前自动运行检查，保证代码质量和提交规范。

## 核心工具

| 工具 | 作用 |
|------|------|
| **Husky** | Git hooks 管理器，简化 hooks 配置 |
| **lint-staged** | 只对暂存的文件运行 linters，速度快 |
| **Commitlint** | 检查提交信息是否符合 Conventional Commits 规范 |

## 安装和配置

```bash
pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional
```

### Husky v9 初始化

```bash
pnpm exec husky init
```

### pre-commit Hook

```bash
# .husky/pre-commit
pnpm exec lint-staged
```

### commit-msg Hook

```bash
# .husky/commit-msg
pnpm exec commitlint --edit $1
```

```bash
# 确保有执行权限
chmod +x .husky/pre-commit .husky/commit-msg
```

## lint-staged 配置

在 package.json 中添加：

```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yml,yaml}": ["prettier --write"],
    "*.css": ["stylelint --fix", "prettier --write"]
  }
}
```

## Commitlint 配置

```javascript
// commitlint.config.mjs
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // 新功能
        'fix',      // 修复 bug
        'docs',     // 文档变更
        'style',    // 代码格式 (不影响功能)
        'refactor', // 重构
        'perf',     // 性能优化
        'test',     // 测试相关
        'chore',    // 构建/辅助工具
        'revert',   // 回滚
        'ci',       // CI 配置
        'build',    // 构建系统
      ],
    ],
    'subject-case': [0],        // 允许中文
    'subject-max-length': [2, 'always', 100],
  },
};
```

## Conventional Commits 规范

### 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 示例

```bash
feat(auth): add login page
fix(api): handle null response
docs(readme): update installation guide
refactor(utils): simplify date formatting

# 带 body
feat(user): add avatar upload feature

Allow users to upload custom avatars.
Supports JPG, PNG, and GIF formats.

Closes #123
```

### 类型速查

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: add dark mode` |
| `fix` | Bug 修复 | `fix: correct button alignment` |
| `docs` | 文档更新 | `docs: update API docs` |
| `style` | 代码格式 | `style: format with prettier` |
| `refactor` | 重构代码 | `refactor: extract helper function` |
| `perf` | 性能优化 | `perf: lazy load images` |
| `test` | 测试相关 | `test: add unit tests for utils` |
| `chore` | 杂项任务 | `chore: update dependencies` |

## 完整 package.json 配置

```json
{
  "scripts": {
    "prepare": "husky",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  },
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yml,yaml}": ["prettier --write"],
    "*.css": ["stylelint --fix", "prettier --write"]
  }
}
```

## 高级用法

### 跳过 Hooks (紧急情况)

```bash
git commit --no-verify -m "emergency fix"
# 或
HUSKY=0 git commit -m "skip hooks"
```

### lint-staged 高级配置

```javascript
// lint-staged.config.mjs
export default {
  '*.{ts,tsx}': (files) => {
    // 文件数少于 10 时额外运行类型检查
    if (files.length < 10) {
      return ['tsc --noEmit', `eslint --fix ${files.join(' ')}`];
    }
    return `eslint --fix ${files.join(' ')}`;
  },
};
```

## CI 集成

```yaml
# .github/workflows/lint.yml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm format:check
```

## 常见问题

**Hooks 没有执行？**
1. 确保运行了 `pnpm prepare` (或 `pnpm exec husky init`)
2. 检查 `.husky/` 下文件的执行权限 (`chmod +x`)
3. 确保 Git 版本 >= 2.9

**如何调试 lint-staged？** 运行 `pnpm exec lint-staged --debug` 查看将要执行的命令。
