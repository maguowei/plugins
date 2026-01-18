---
name: ESLint + Prettier Configuration Guide
description: This skill should be used when the user asks about "ESLint v9", "Flat Config", "eslint.config.mjs", "Prettier configuration", "code formatting", "ESLint rules", "TypeScript ESLint", or needs guidance on setting up ESLint and Prettier for React TypeScript projects.
version: 0.1.0
---

# ESLint v9 + Prettier 配置指南

## 概述

ESLint v9 引入了全新的 **Flat Config** 格式，使用 `eslint.config.mjs` 替代传统的 `.eslintrc` 文件。这种新格式更简洁、更灵活，并且提供更好的类型支持。

## 核心变化 (v8 → v9)

| 特性 | v8 | v9 |
|------|----|----|
| 配置文件 | `.eslintrc.js/.json/.yaml` | `eslint.config.mjs` |
| 忽略文件 | `.eslintignore` | 配置中的 `ignores` |
| `root: true` | 需要 | 不需要 |
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

## ESLint Flat Config 配置

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

      // React Refresh (HMR)
      'react-refresh/only-export-components': [
        'warn',
        { allowConstantExport: true },
      ],

      // React 规则
      'react/react-in-jsx-scope': 'off', // React 17+ 不需要导入 React
      'react/prop-types': 'off', // 使用 TypeScript 代替
      'react/jsx-no-target-blank': 'error',
      'react/jsx-curly-brace-presence': ['warn', { props: 'never', children: 'never' }],

      // TypeScript 规则
      '@typescript-eslint/no-unused-vars': [
        'warn',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/consistent-type-imports': [
        'warn',
        { prefer: 'type-imports' },
      ],
      '@typescript-eslint/no-non-null-assertion': 'warn',

      // Prettier 集成
      'prettier/prettier': 'error',

      // 通用规则
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'prefer-const': 'error',
      'no-var': 'error',
    },
    settings: {
      react: { version: 'detect' },
    },
  },

  // 测试文件的特殊规则
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
  // 行宽
  printWidth: 100,

  // 缩进
  tabWidth: 2,
  useTabs: false,

  // 分号
  semi: true,

  // 引号
  singleQuote: true,
  jsxSingleQuote: false,
  quoteProps: 'as-needed',

  // 尾随逗号
  trailingComma: 'es5',

  // 括号
  bracketSpacing: true,
  bracketSameLine: false,

  // 箭头函数
  arrowParens: 'always',

  // 换行符
  endOfLine: 'lf',

  // 插件
  plugins: [],
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

### settings.json

```json
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

### 推荐扩展

```json
// .vscode/extensions.json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode"
  ]
}
```

## 常用 ESLint 规则

### React 相关

```javascript
rules: {
  // 必须使用 key
  'react/jsx-key': 'error',

  // 禁止在 JSX 中使用危险属性
  'react/no-danger': 'warn',

  // 组件命名使用 PascalCase
  'react/jsx-pascal-case': 'error',

  // 布尔属性简写
  'react/jsx-boolean-value': ['warn', 'never'],

  // 自闭合标签
  'react/self-closing-comp': 'warn',
}
```

### TypeScript 相关

```javascript
rules: {
  // 显式返回类型 (函数)
  '@typescript-eslint/explicit-function-return-type': 'off',

  // 显式模块边界类型
  '@typescript-eslint/explicit-module-boundary-types': 'off',

  // 禁止空函数
  '@typescript-eslint/no-empty-function': 'warn',

  // 命名规范
  '@typescript-eslint/naming-convention': [
    'warn',
    { selector: 'interface', format: ['PascalCase'] },
    { selector: 'typeAlias', format: ['PascalCase'] },
  ],
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

## 最佳实践

### 1. 配置继承顺序

```javascript
// prettier-config 必须在最后
export default tseslint.config(
  js.configs.recommended,           // 1. ESLint 基础规则
  ...tseslint.configs.recommended,  // 2. TypeScript 规则
  // ... 其他插件规则
  prettierConfig,                   // 最后: 禁用冲突规则
);
```

### 2. 分离测试配置

```javascript
// 测试文件使用宽松规则
{
  files: ['**/*.test.{ts,tsx}', '**/__tests__/**'],
  rules: {
    '@typescript-eslint/no-explicit-any': 'off',
  },
}
```

### 3. 类型导入

```javascript
// 推荐使用 type-only imports
'@typescript-eslint/consistent-type-imports': ['warn', { prefer: 'type-imports' }],
```

```typescript
// ✅ 正确
import type { User } from './types';
import { useState } from 'react';

// ❌ 避免
import { User } from './types'; // User 只用作类型
```

## 常见问题

### Q: 如何迁移旧配置？

使用 `@eslint/eslintrc` 的 `FlatCompat`:

```javascript
import { FlatCompat } from '@eslint/eslintrc';

const compat = new FlatCompat();

export default [
  ...compat.extends('some-legacy-config'),
  // 新的 flat config
];
```

### Q: 如何禁用某行规则？

```typescript
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const data: any = fetchData();

/* eslint-disable no-console */
console.log('debug');
/* eslint-enable no-console */
```

### Q: Prettier 和 ESLint 冲突？

确保 `eslint-config-prettier` 在配置数组的最后位置。

## 参考资源

- [ESLint Flat Config 文档](https://eslint.org/docs/latest/use/configure/configuration-files-new)
- [typescript-eslint](https://typescript-eslint.io/)
- [Prettier 文档](https://prettier.io/docs/en/)