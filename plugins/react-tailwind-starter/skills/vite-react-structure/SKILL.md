---
name: Vite + React Project Structure
description: This skill should be used when the user asks about "React project structure", "Vite configuration", "folder organization", "component organization", "React best practices", "TypeScript project setup", or needs guidance on organizing React + Vite + TypeScript projects.
version: 0.1.0
---

# Vite + React 项目结构指南

## 概述

良好的项目结构是可维护代码的基础。本指南介绍 Vite + React + TypeScript 项目的推荐目录结构和最佳实践。

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
│   │   ├── Input/
│   │   └── index.ts           # 统一导出
│   ├── hooks/                 # 自定义 Hooks
│   │   ├── useCounter.ts
│   │   ├── useDebounce.ts
│   │   └── index.ts
│   ├── pages/                 # 页面组件
│   │   ├── Home/
│   │   │   ├── Home.tsx
│   │   │   └── index.ts
│   │   ├── About/
│   │   └── NotFound/
│   ├── services/              # API 服务
│   │   ├── api.ts             # Axios/Fetch 实例
│   │   ├── userService.ts
│   │   └── index.ts
│   ├── stores/                # 状态管理 (Zustand)
│   │   ├── userStore.ts
│   │   ├── themeStore.ts
│   │   └── index.ts
│   ├── types/                 # TypeScript 类型
│   │   ├── user.ts
│   │   ├── api.ts
│   │   └── index.ts
│   ├── utils/                 # 工具函数
│   │   ├── cn.ts
│   │   ├── format.ts
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
├── tsconfig.node.json
└── package.json
```

## 组件组织

### 单组件结构

```
components/
└── Button/
    ├── Button.tsx          # 组件实现
    ├── Button.test.tsx     # 单元测试
    ├── Button.stories.tsx  # Storybook (可选)
    └── index.ts            # 导出
```

### 组件模板

```typescript
// components/Button/Button.tsx
import { forwardRef, type ButtonHTMLAttributes } from 'react';
import { cn } from '@/utils';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', isLoading, className, children, disabled, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center rounded-lg font-medium transition-colors',
          // Variant styles
          variant === 'primary' && 'bg-primary hover:bg-primary-dark text-white',
          variant === 'secondary' && 'bg-secondary hover:bg-gray-600 text-white',
          variant === 'outline' && 'border-2 border-primary text-primary hover:bg-primary hover:text-white',
          // Size styles
          size === 'sm' && 'px-3 py-1.5 text-sm',
          size === 'md' && 'px-4 py-2 text-base',
          size === 'lg' && 'px-6 py-3 text-lg',
          // States
          (disabled || isLoading) && 'opacity-50 cursor-not-allowed',
          className
        )}
        disabled={disabled || isLoading}
        {...props}
      >
        {isLoading ? <span className="animate-spin mr-2">⏳</span> : null}
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
```

```typescript
// components/Button/index.ts
export { Button } from './Button';
export type { ButtonProps } from './Button';
```

### 统一导出

```typescript
// components/index.ts
export * from './Button';
export * from './Input';
export * from './Card';
// ... 其他组件
```

## 自定义 Hooks

### Hook 模板

```typescript
// hooks/useDebounce.ts
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number = 300): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(timer);
    };
  }, [value, delay]);

  return debouncedValue;
}
```

```typescript
// hooks/useLocalStorage.ts
import { useState, useCallback } from 'react';

export function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = useCallback(
    (value: T | ((val: T) => T)) => {
      try {
        const valueToStore = value instanceof Function ? value(storedValue) : value;
        setStoredValue(valueToStore);
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      } catch (error) {
        console.error('Error saving to localStorage:', error);
      }
    },
    [key, storedValue]
  );

  const removeValue = useCallback(() => {
    try {
      window.localStorage.removeItem(key);
      setStoredValue(initialValue);
    } catch (error) {
      console.error('Error removing from localStorage:', error);
    }
  }, [key, initialValue]);

  return [storedValue, setValue, removeValue] as const;
}
```

## 状态管理 (Zustand)

### Store 模板

```typescript
// stores/userStore.ts
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import type { User } from '@/types';

interface UserState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;

  // Actions
  setUser: (user: User) => void;
  logout: () => void;
  setLoading: (loading: boolean) => void;
}

export const useUserStore = create<UserState>()(
  devtools(
    persist(
      (set) => ({
        user: null,
        isAuthenticated: false,
        isLoading: false,

        setUser: (user) =>
          set({ user, isAuthenticated: true }, false, 'setUser'),

        logout: () =>
          set({ user: null, isAuthenticated: false }, false, 'logout'),

        setLoading: (isLoading) =>
          set({ isLoading }, false, 'setLoading'),
      }),
      { name: 'user-storage' }
    ),
    { name: 'UserStore' }
  )
);
```

### 使用 Store

```typescript
// 在组件中使用
import { useUserStore } from '@/stores';

function UserProfile() {
  const { user, isAuthenticated, logout } = useUserStore();

  if (!isAuthenticated) {
    return <LoginButton />;
  }

  return (
    <div>
      <p>Welcome, {user?.name}</p>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

## API 服务

### API 实例

```typescript
// services/api.ts
const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

interface RequestOptions extends RequestInit {
  params?: Record<string, string>;
}

async function request<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
  const { params, ...fetchOptions } = options;

  let url = `${API_BASE_URL}${endpoint}`;
  if (params) {
    url += '?' + new URLSearchParams(params).toString();
  }

  const response = await fetch(url, {
    ...fetchOptions,
    headers: {
      'Content-Type': 'application/json',
      ...fetchOptions.headers,
    },
  });

  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`);
  }

  return response.json();
}

export const api = {
  get: <T>(endpoint: string, params?: Record<string, string>) =>
    request<T>(endpoint, { method: 'GET', params }),

  post: <T>(endpoint: string, data?: unknown) =>
    request<T>(endpoint, { method: 'POST', body: JSON.stringify(data) }),

  put: <T>(endpoint: string, data?: unknown) =>
    request<T>(endpoint, { method: 'PUT', body: JSON.stringify(data) }),

  delete: <T>(endpoint: string) =>
    request<T>(endpoint, { method: 'DELETE' }),
};
```

### 服务模块

```typescript
// services/userService.ts
import { api } from './api';
import type { User, ApiResponse } from '@/types';

export const userService = {
  getProfile: () => api.get<ApiResponse<User>>('/users/me'),

  updateProfile: (data: Partial<User>) =>
    api.put<ApiResponse<User>>('/users/me', data),

  getUsers: (params?: { page?: number; limit?: number }) =>
    api.get<ApiResponse<User[]>>('/users', params as Record<string, string>),
};
```

## 类型定义

```typescript
// types/user.ts
export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: 'admin' | 'user';
  createdAt: string;
  updatedAt: string;
}

// types/api.ts
export interface ApiResponse<T> {
  data: T;
  message: string;
  success: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface ApiError {
  message: string;
  code: string;
  details?: Record<string, string[]>;
}

// types/index.ts
export * from './user';
export * from './api';
```

## Vite 配置

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import tailwindcss from '@tailwindcss/vite';
import path from 'path';

export default defineConfig({
  plugins: [react(), tailwindcss()],

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },

  server: {
    port: 5173,
    open: true,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },

  build: {
    target: 'esnext',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom'],
        },
      },
    },
  },

  envPrefix: 'VITE_',
});
```

## TypeScript 配置

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,

    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

## 最佳实践

### 1. 路径别名

使用 `@/` 代替相对路径：

```typescript
// ✅ 推荐
import { Button } from '@/components';
import { useDebounce } from '@/hooks';

// ❌ 避免深层相对路径
import { Button } from '../../../components/Button';
```

### 2. 桶文件导出

```typescript
// components/index.ts
export * from './Button';
export * from './Input';

// 使用时
import { Button, Input } from '@/components';
```

### 3. 环境变量

```bash
# .env
VITE_API_URL=https://api.example.com
VITE_APP_TITLE=My App
```

```typescript
// 使用
const apiUrl = import.meta.env.VITE_API_URL;
```

### 4. 代码分割

```typescript
// 路由级别懒加载
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('@/pages/Dashboard'));
const Settings = lazy(() => import('@/pages/Settings'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

## 参考资源

- [Vite 官方文档](https://vitejs.dev/)
- [React 官方文档](https://react.dev/)
- [TypeScript 官方文档](https://www.typescriptlang.org/)