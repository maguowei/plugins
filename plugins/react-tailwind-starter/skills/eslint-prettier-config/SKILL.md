---
name: ESLint + Prettier Configuration Guide
description: "ESLint v9 Flat Config 和 Prettier 的配置指南，专注于 React + TypeScript 项目。当用户提到 ESLint v9、Flat Config、eslint.config.mjs、Prettier 配置、代码格式化、ESLint 规则、TypeScript ESLint、从 .eslintrc 迁移到 Flat Config、ESLint 和 Prettier 冲突、Stylelint 配置，甚至只是问 '代码风格怎么统一'、'怎么自动格式化'、'ESLint 报错怎么处理' 这样的问题时，都应该使用这个 skill。"
version: 0.1.0
---

# ESLint v9 + Prettier 配置指南

ESLint v9 引入了 **Flat Config** 格式，使用 `eslint.config.mjs` 替代传统的 `.eslintrc` 文件，更简洁且类型支持更好。

## v8 → v9 核心变化

| 特性 | v8 | v9 |
|------|----|----|
| 配置文件 | `.eslintrc.js/.json/.yaml` | `eslint.config.mjs` |
| 忽略文件 | `.eslintignore` | 配置中的 `ignores` |
| 插件格式 | 字符串数组 | 对象形式 |
| 扩展方式 | `extends` 数组 | 直接展开配置数组 |

## 安装依赖

```bash
pnpm add -D eslint@^9 \
  @eslint/js \
  typescript-eslint \
  eslint-plugin-react \
  eslint-plugin-react-hooks \
  eslint-plugin-react-refresh \
  prettier \
  eslint-config-prettier \
  eslint-plugin-prettier \
  globals
```

## ESLint Flat Config

```javascript
// eslint.config.mjs
import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import prettier from 'eslint-plugin-prettier';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  // 忽略的文件和目录
  { ignores: ['dist', 'node_modules', '*.config.*', 'coverage'] },

  // 主要配置
  {
    extends: [
      js.configs.recommended,
      ...tseslint.configs.recommended,
      prettierConfig, // 必须在最后，禁用与 Prettier 冲突的规则
    ],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2024,
      globals: globals.browser,
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
    },
    plugins: {
      react,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
      prettier,
    },
    rules: {
      // React Hooks 规则
      ...reactHooks.configs.recommended.rules,

      // React Refresh（热更新）
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],

      // React 规则
      'react/react-in-jsx-scope': 'off',
      'react/prop-types': 'off',
      'react/jsx-no-target-blank': 'error',
      'react/jsx-curly-brace-presence': ['warn', { props: 'never', children: 'never' }],

      // TypeScript 规则
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/consistent-type-imports': ['warn', { prefer: 'type-imports' }],
      '@typescript-eslint/no-non-null-assertion': 'warn',

      // Prettier 集成
      'prettier/prettier': 'error',

      // 通用
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'prefer-const': 'error',
      'no-var': 'error',
    },
    settings: {
      react: { version: 'detect' },
    },
  },

  // 测试文件使用宽松规则
  {
    files: ['**/*.test.{ts,tsx}', '**/*.spec.{ts,tsx}'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      'no-console': 'off',
    },
  }
);
```

## Prettier 配置

```javascript
// prettier.config.mjs
/** @type {import("prettier").Config} */
export default {
  printWidth: 100,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: true,
  jsxSingleQuote: false,
  quoteProps: 'as-needed',
  trailingComma: 'es5',
  bracketSpacing: true,
  bracketSameLine: false,
  arrowParens: 'always',
  endOfLine: 'lf',
};
```

### .prettierignore

```
dist
node_modules
.husky
pnpm-lock.yaml
*.min.js
*.min.css
coverage
storybook-static
```

## VS Code 集成

```json
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "eslint.useFlatConfig": true,
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

## package.json Scripts

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  }
}
```

## 关键最佳实践

### 1. 配置继承顺序

`prettier-config` 必须放在最后，以禁用与 Prettier 冲突的 ESLint 规则：

```javascript
export default tseslint.config(
  js.configs.recommended,           // 1. ESLint 基础
  ...tseslint.configs.recommended,  // 2. TypeScript
  prettierConfig,                   // 最后: 禁用冲突规则
);
```

### 2. 使用 type-only imports

减少运行时包体积：

```typescript
// 推荐
import type { User } from './types';
import { useState } from 'react';

// 避免 (User 只用作类型)
import { User } from './types';
```

### 3. 从旧配置迁移

如果有遗留的 `.eslintrc` 配置，可以使用 `FlatCompat` 过渡：

```javascript
import { FlatCompat } from '@eslint/eslintrc';
const compat = new FlatCompat();

export default [
  ...compat.extends('some-legacy-config'),
  // 新的 flat config
];
```

## 常见问题

**Prettier 和 ESLint 冲突？** 确保 `eslint-config-prettier` 在配置数组的最后位置。

**如何禁用某行规则？**

```typescript
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const data: any = fetchData();
```
