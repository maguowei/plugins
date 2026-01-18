---
name: Git Hooks Workflow
description: This skill should be used when the user asks about "Husky", "lint-staged", "Commitlint", "pre-commit hooks", "commit message format", "conventional commits", "Git hooks setup", or needs guidance on automating code quality checks with Git hooks.
version: 0.1.0
---

# Git Hooks 工作流指南

## 概述

Git Hooks 工作流通过在提交代码前自动运行检查来保证代码质量。本指南介绍如何使用 **Husky v9 + lint-staged + Commitlint** 构建完整的 Git 工作流。

## 核心工具

| 工具 | 作用 |
|------|------|
| **Husky** | Git hooks 管理器，简化 hooks 配置 |
| **lint-staged** | 只对暂存的文件运行 linters |
| **Commitlint** | 检查提交信息是否符合规范 |

## 安装

```bash
pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional
```

## Husky v9 配置

### 初始化

```bash
# 初始化 Husky
pnpm exec husky init
```

这会创建 `.husky/` 目录和 `pre-commit` 文件。

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

### 设置执行权限

```bash
chmod +x .husky/pre-commit
chmod +x .husky/commit-msg
```

## lint-staged 配置

### package.json 方式

```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,md,yml,yaml}": [
      "prettier --write"
    ],
    "*.css": [
      "stylelint --fix",
      "prettier --write"
    ]
  }
}
```

### 独立配置文件

```javascript
// lint-staged.config.mjs
export default {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
  '*.css': ['stylelint --fix', 'prettier --write'],
};
```

## Commitlint 配置

### 基础配置

```javascript
// commitlint.config.mjs
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // 提交类型
    'type-enum': [
      2,
      'always',
      [
        'feat',     // 新功能
        'fix',      // 修复 bug
        'docs',     // 文档变更
        'style',    // 代码格式 (不影响功能)
        'refactor', // 重构 (既不是新功能也不是 bug 修复)
        'perf',     // 性能优化
        'test',     // 添加/修改测试
        'chore',    // 构建过程或辅助工具变动
        'revert',   // 回滚
        'ci',       // CI 配置变更
        'build',    // 构建系统变更
      ],
    ],
    // 允许中文
    'subject-case': [0],
    // 主题最大长度
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
# 新功能
feat(auth): add login page

# 修复
fix(api): handle null response

# 文档
docs(readme): update installation guide

# 重构
refactor(utils): simplify date formatting

# 带 scope 和 body
feat(user): add avatar upload feature

Allow users to upload custom avatars.
Supports JPG, PNG, and GIF formats.

Closes #123
```

### 类型说明

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
| `ci` | CI/CD | `ci: add GitHub Actions` |
| `build` | 构建系统 | `build: upgrade vite to v5` |
| `revert` | 回滚 | `revert: undo last commit` |

## 完整配置示例

### package.json

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

### 目录结构

```
project/
├── .husky/
│   ├── _/
│   │   └── husky.sh
│   ├── pre-commit
│   └── commit-msg
├── commitlint.config.mjs
├── lint-staged.config.mjs (可选)
└── package.json
```

## 高级配置

### 跳过 Hooks (紧急情况)

```bash
# 跳过 pre-commit
git commit --no-verify -m "emergency fix"

# 或使用环境变量
HUSKY=0 git commit -m "skip hooks"
```

### 并行运行

```javascript
// lint-staged.config.mjs
export default {
  '*.{ts,tsx}': (files) => [
    `eslint --fix ${files.join(' ')}`,
    `prettier --write ${files.join(' ')}`,
  ],
};
```

### 条件运行

```javascript
// lint-staged.config.mjs
export default {
  '*.{ts,tsx}': (files) => {
    // 只在文件数小于 10 时运行类型检查
    if (files.length < 10) {
      return ['tsc --noEmit', `eslint --fix ${files.join(' ')}`];
    }
    return `eslint --fix ${files.join(' ')}`;
  },
};
```

## CI 集成

### GitHub Actions

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

### Q: hooks 没有执行？

1. 确保运行了 `pnpm prepare` (或 `npx husky init`)
2. 检查 `.husky/` 目录下的文件是否有执行权限
3. 确保 Git 版本 >= 2.9

### Q: Windows 上有问题？

使用 Git Bash 或 WSL，确保换行符为 LF：

```bash
git config core.autocrlf false
```

### Q: 如何调试 lint-staged？

```bash
# 查看将要运行的命令
pnpm exec lint-staged --debug
```

## 最佳实践

1. **提交粒度**: 每个提交只做一件事
2. **描述清晰**: 提交信息说明 "为什么" 而不是 "做了什么"
3. **及时提交**: 不要积累大量更改
4. **类型准确**: 正确选择 feat/fix/docs 等类型

## 参考资源

- [Husky 文档](https://typicode.github.io/husky/)
- [lint-staged 文档](https://github.com/okonet/lint-staged)
- [Commitlint 文档](https://commitlint.js.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)