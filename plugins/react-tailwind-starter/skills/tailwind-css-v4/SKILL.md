---
name: Tailwind CSS v4 Best Practices
description: "Tailwind CSS v4 的 CSS-first 配置方式和最佳实践指南。当用户提到 Tailwind CSS v4、CSS-first 配置、@theme 指令、@custom-variant、自定义颜色/主题、Tailwind 工具类、暗色模式实现、从 v3 迁移到 v4，甚至只是在 React 项目中写样式、讨论 CSS 架构、问 'Tailwind 怎么自定义主题' 或 '怎么配置暗色模式' 时，都应该使用这个 skill。"
version: 0.1.0
---

# Tailwind CSS v4 最佳实践

## 核心变化: CSS-first 配置

Tailwind CSS v4 最大的变化是从 JavaScript 配置文件转向 CSS-first 配置。大多数情况下不再需要 `tailwind.config.js`。

| 特性 | v3 | v4 |
|------|----|----|
| 配置文件 | `tailwind.config.js` (必需) | CSS 文件中配置 (可选 JS) |
| 内容检测 | 手动配置 `content` 路径 | 自动检测 |
| 自定义主题 | JavaScript 对象 | `@theme` 指令 |
| 变体定义 | JavaScript 函数 | `@custom-variant` 指令 |
| 导入方式 | `@tailwind base/components/utilities` | `@import "tailwindcss"` |

## 安装 (Vite 项目)

```bash
pnpm add tailwindcss @tailwindcss/vite
```

```typescript
// vite.config.ts
import tailwindcss from '@tailwindcss/vite';
export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

```css
/* src/index.css */
@import "tailwindcss";
```

## @theme 指令 - 自定义设计令牌

`@theme` 是 v4 的核心，通过 CSS 自定义属性定义设计令牌，自动生成对应的工具类：

```css
@import "tailwindcss";

@theme {
  /* 颜色 - 自动生成 bg-primary, text-primary 等工具类 */
  --color-primary: #3b82f6;
  --color-primary-dark: #2563eb;
  --color-primary-light: #60a5fa;
  --color-secondary: #6b7280;
  --color-accent: #f59e0b;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;

  /* 字体 */
  --font-family-sans: 'Inter', system-ui, sans-serif;
  --font-family-mono: 'JetBrains Mono', monospace;

  /* 间距 */
  --spacing-18: 4.5rem;
  --spacing-128: 32rem;

  /* 圆角 */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;

  /* 阴影 */
  --shadow-soft: 0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04);

  /* 动画时长 */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
}
```

使用：

```tsx
<div className="bg-primary text-white rounded-xl shadow-soft p-18">
  <button className="bg-primary-dark hover:bg-primary transition-colors duration-fast">
    Button
  </button>
</div>
```

## @custom-variant - 自定义变体

```css
/* 暗色模式 (基于 class) */
@custom-variant dark (&:where(.dark, .dark *));

/* 打印模式 */
@custom-variant print (@media print);
```

```tsx
<div className="bg-white dark:bg-gray-900">
  <p className="text-gray-900 dark:text-white">支持暗色模式</p>
</div>
<div className="hidden print:block">仅打印时可见</div>
```

## @layer - 自定义组件和工具类

```css
@layer utilities {
  .text-balance {
    text-wrap: balance;
  }
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
}

@layer components {
  .card {
    @apply bg-white dark:bg-gray-800 rounded-xl shadow-soft p-6;
  }
  .btn {
    @apply inline-flex items-center justify-center px-4 py-2 rounded-lg font-medium transition-colors duration-fast;
  }
  .btn-primary {
    @apply btn bg-primary hover:bg-primary-dark text-white;
  }
  .input {
    @apply w-full px-4 py-2 border border-gray-300 rounded-lg
           focus:ring-2 focus:ring-primary focus:border-transparent
           dark:bg-gray-800 dark:border-gray-700;
  }
}
```

## 最佳实践

### 1. CSS 文件组织

大型项目建议拆分 CSS 文件：

```
src/styles/
├── index.css        # 主入口
├── theme.css        # @theme 定义
├── components.css   # @layer components
└── utilities.css    # @layer utilities
```

```css
/* src/styles/index.css */
@import "tailwindcss";
@import "./theme.css";
@import "./components.css";
@import "./utilities.css";
```

### 2. 使用语义化颜色名

```css
@theme {
  /* 推荐: 语义化命名 */
  --color-primary: #3b82f6;
  --color-surface: #ffffff;
  --color-on-surface: #1f2937;
  --color-error: #ef4444;

  /* 避免: 硬编码颜色名 */
  /* --color-blue-500: #3b82f6; */
}
```

### 3. 使用 cn() 工具函数合并类名

```typescript
// src/utils/cn.ts
export function cn(...classes: (string | undefined | null | false)[]): string {
  return classes.filter(Boolean).join(' ');
}

// 使用
<button className={cn(
  'btn',
  variant === 'primary' && 'btn-primary',
  disabled && 'opacity-50 cursor-not-allowed'
)}>
  Click me
</button>
```

## 从 v3 迁移

1. **更新依赖**: `pnpm remove tailwindcss postcss autoprefixer && pnpm add tailwindcss @tailwindcss/vite`
2. **更新 Vite 配置**: 添加 `@tailwindcss/vite` 插件
3. **转换 CSS**: `@tailwind base/components/utilities` → `@import "tailwindcss"`
4. **迁移配置**: `tailwind.config.js` → `@theme { ... }` (CSS 自定义属性)
5. **删除旧文件**: `tailwind.config.js`、`postcss.config.js`

## 常见问题

**还需要 PostCSS 吗？** 使用 `@tailwindcss/vite` 插件时不需要。

**第三方插件兼容性？** 官方插件如 `@tailwindcss/typography` 已支持 v4，第三方插件可能需要更新。

**性能提升？** v4 构建速度更快，生成的 CSS 文件更小。
