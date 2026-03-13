---
name: Vite + React Project Structure
description: "React + Vite + TypeScript 项目结构和组件组织指南。当用户提到 React 项目结构、Vite 配置、组件如何组织、目录怎么规划、React 最佳实践、TypeScript 项目搭建，或者在开发 React 项目时不确定文件该放哪里、组件该怎么拆分时，都应该使用这个 skill。即使用户只是问 '这个组件放哪个目录'、'项目文件太乱了' 这样的问题也要触发。"
version: 0.1.0
---

# Vite + React 项目结构指南

## 推荐目录结构

```
my-app/
├── public/                    # 静态资源 (直接复制到构建输出)
│   ├── favicon.ico
│   └── robots.txt
├── src/
│   ├── components/            # 可复用组件
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.test.tsx
│   │   │   └── index.ts
│   │   └── index.ts           # 统一导出
│   ├── hooks/                 # 自定义 Hooks
│   │   ├── useCounter.ts
│   │   └── index.ts
│   ├── pages/                 # 页面组件
│   │   ├── Home/
│   │   │   ├── Home.tsx
│   │   │   └── index.ts
│   │   └── NotFound/
│   ├── services/              # API 服务
│   │   ├── api.ts
│   │   └── index.ts
│   ├── stores/                # 状态管理 (Zustand)
│   │   ├── counterStore.ts
│   │   └── index.ts
│   ├── types/                 # TypeScript 类型
│   │   └── index.ts
│   ├── utils/                 # 工具函数
│   │   ├── cn.ts
│   │   └── index.ts
│   ├── constants/             # 常量定义
│   │   └── index.ts
│   ├── styles/                # 全局样式
│   │   └── index.css          # Tailwind 入口
│   ├── App.tsx                # 根组件
│   ├── main.tsx               # 入口文件
│   └── vite-env.d.ts          # Vite 类型声明
├── .husky/                    # Git hooks
├── .vscode/                   # VS Code 配置
├── eslint.config.mjs
├── prettier.config.mjs
├── stylelint.config.mjs
├── commitlint.config.mjs
├── vite.config.ts
├── tsconfig.json
└── package.json
```

## 组件组织

### 单组件目录结构

每个组件使用独立目录，包含实现、测试和导出：

```
components/
└── Button/
    ├── Button.tsx          # 组件实现
    ├── Button.test.tsx     # 单元测试
    ├── Button.stories.tsx  # Storybook (可选)
    └── index.ts            # 导出
```

### 组件编写模板

使用 `forwardRef` 支持 ref 转发，通过 `cn()` 工具函数合并 Tailwind 类名：

```typescript
// components/Button/Button.tsx
import { forwardRef, type ButtonHTMLAttributes } from 'react';
import { cn } from '@/utils';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', className, children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center rounded-lg font-medium transition-colors',
          variant === 'primary' && 'bg-primary hover:bg-primary-dark text-white',
          variant === 'secondary' && 'bg-secondary hover:bg-gray-600 text-white',
          variant === 'outline' && 'border-2 border-primary text-primary hover:bg-primary hover:text-white',
          size === 'sm' && 'px-3 py-1.5 text-sm',
          size === 'md' && 'px-4 py-2 text-base',
          size === 'lg' && 'px-6 py-3 text-lg',
          className
        )}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
```

### 统一导出 (桶文件)

每个模块目录都使用 `index.ts` 统一导出，简化导入路径：

```typescript
// components/index.ts
export * from './Button';
export * from './Input';

// 使用时
import { Button, Input } from '@/components';
```

## 核心约定

### 路径别名

通过 `@/` 别名避免深层相对路径（已在 vite.config.ts 和 tsconfig.json 中配置）：

```typescript
// 推荐
import { Button } from '@/components';
import { useDebounce } from '@/hooks';

// 避免
import { Button } from '../../../components/Button';
```

### 环境变量

Vite 只暴露 `VITE_` 前缀的环境变量给客户端代码：

```bash
# .env
VITE_API_URL=https://api.example.com
VITE_APP_TITLE=My App
```

```typescript
const apiUrl = import.meta.env.VITE_API_URL;
```

### 代码分割

使用 `lazy` + `Suspense` 实现路由级别懒加载：

```typescript
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('@/pages/Dashboard'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </Suspense>
  );
}
```

## 更多代码模板

`references/` 目录包含更详细的代码模板：
- `references/code-templates.md` — 自定义 Hooks、Zustand Store、API 服务、TypeScript 类型定义的完整模板
