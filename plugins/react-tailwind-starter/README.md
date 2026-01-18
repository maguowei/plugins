# React Tailwind Starter

React + Tailwind CSS 脚手架生成器，基于最新的工具链和最佳实践。

## 特性

- **Vite + SWC + TypeScript** - 极速开发体验
- **Tailwind CSS v4** - CSS-first 配置，原生 CSS 变量
- **ESLint v9 Flat Config** - 最新的扁平配置格式
- **Prettier** - 代码格式化
- **Stylelint** - CSS/样式检查
- **Husky v9 + lint-staged** - Git hooks 自动化
- **Commitlint** - 提交信息规范化

## 可选功能

- **React Router** - 路由管理
- **Zustand** - 状态管理
- **Vitest + Testing Library** - 单元测试
- **Storybook** - 组件文档和开发

## 使用方法

```bash
# 在 Claude Code 中运行
/init-react-app
```

## 生成的项目结构

```
my-app/
├── src/
│   ├── components/      # 可复用组件
│   ├── hooks/           # 自定义 Hooks
│   ├── pages/           # 页面组件
│   ├── services/        # API 服务
│   ├── stores/          # Zustand 状态
│   ├── types/           # TypeScript 类型
│   ├── utils/           # 工具函数
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css        # Tailwind 入口
├── public/
├── .husky/              # Git hooks
├── eslint.config.mjs
├── prettier.config.mjs
├── stylelint.config.mjs
├── commitlint.config.mjs
├── vite.config.ts
├── tsconfig.json
└── package.json
```

## 技术栈版本

| 工具 | 版本 |
|------|------|
| React | ^19.0.0 |
| Vite | ^6.0.0 |
| Tailwind CSS | ^4.0.0 |
| ESLint | ^9.0.0 |
| Prettier | ^3.4.0 |
| Stylelint | ^16.0.0 |
| Husky | ^9.0.0 |
| TypeScript | ^5.7.0 |

## 相关 Skills

- `tailwind-css-v4` - Tailwind CSS v4 最佳实践
- `eslint-prettier-config` - ESLint + Prettier 配置指南
- `git-hooks-workflow` - Git Hooks 工作流
- `vite-react-structure` - Vite + React 项目结构

## License

MIT
