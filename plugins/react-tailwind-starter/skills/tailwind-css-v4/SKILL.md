---
name: Tailwind CSS v4 Best Practices
description: This skill should be used when the user asks about "Tailwind CSS v4", "CSS-first configuration", "tailwind config", "@theme directive", "custom colors in Tailwind", "Tailwind utilities", or needs guidance on configuring and using Tailwind CSS v4 in React projects.
version: 0.1.0
---

# Tailwind CSS v4 最佳实践

## 概述

Tailwind CSS v4 引入了全新的 **CSS-first 配置方式**，大多数情况下不再需要 JavaScript 配置文件。这种方式更接近原生 CSS，利用 CSS 自定义属性和层叠层提供更好的性能和开发体验。

## 核心变化

### 从 v3 到 v4 的主要变化

| 特性 | v3 | v4 |
|------|----|----|
| 配置文件 | `tailwind.config.js` (必需) | CSS 文件中配置 (可选 JS) |
| 内容检测 | 手动配置 `content` 路径 | 自动检测 |
| 自定义主题 | JavaScript 对象 | `@theme` 指令 |
| 变体定义 | JavaScript 函数 | `@custom-variant` 指令 |
| 导入方式 | `@tailwind base/components/utilities` | `@import "tailwindcss"` |

## 安装和配置

### Vite 项目安装

```bash
# 安装 Tailwind CSS v4 和 Vite 插件
pnpm add tailwindcss @tailwindcss/vite
```

### Vite 配置

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

### CSS 入口文件

```css
/* src/index.css */
@import "tailwindcss";

/* 所有配置都在 CSS 中完成 */
```

## @theme 指令 - 自定义主题

`@theme` 指令是 v4 的核心，用于定义自定义设计令牌：

```css
@import "tailwindcss";

@theme {
  /* 颜色 */
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

  /* 字体大小 */
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;

  /* 间距 */
  --spacing-18: 4.5rem;
  --spacing-128: 32rem;

  /* 圆角 */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-2xl: 1rem;

  /* 阴影 */
  --shadow-soft: 0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04);

  /* 动画时长 */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;

  /* 断点 (可选，默认已有) */
  --breakpoint-xs: 475px;
}
```

### 使用自定义主题

```tsx
// 在 JSX 中使用
<div className="bg-primary text-white">Primary Background</div>
<button className="bg-primary-dark hover:bg-primary">Button</button>
<p className="font-sans text-lg">Custom font and size</p>
<div className="p-18 rounded-xl shadow-soft">Custom spacing and shadow</div>
```

## @custom-variant - 自定义变体

```css
@import "tailwindcss";

/* 暗色模式变体 */
@custom-variant dark (&:where(.dark, .dark *));

/* 打印模式变体 */
@custom-variant print (@media print);

/* RTL 变体 */
@custom-variant rtl (&:where([dir="rtl"], [dir="rtl"] *));

/* 悬停时子元素变体 */
@custom-variant group-hover (&:where(.group:hover *));
```

### 使用自定义变体

```tsx
<div className="bg-white dark:bg-gray-900">
  <p className="text-gray-900 dark:text-gray-100">Supports dark mode</p>
</div>

<div className="hidden print:block">Only visible when printing</div>
```

## @layer - 自定义工具类

```css
@import "tailwindcss";

@layer utilities {
  /* 文本平衡 */
  .text-balance {
    text-wrap: balance;
  }

  /* 隐藏滚动条 */
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }

  /* 渐变文字 */
  .text-gradient {
    background: linear-gradient(to right, var(--color-primary), var(--color-accent));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
}

@layer components {
  /* 卡片组件 */
  .card {
    @apply bg-white dark:bg-gray-800 rounded-xl shadow-soft p-6;
  }

  /* 按钮基础样式 */
  .btn {
    @apply inline-flex items-center justify-center px-4 py-2 rounded-lg font-medium transition-colors duration-fast;
  }

  .btn-primary {
    @apply btn bg-primary hover:bg-primary-dark text-white;
  }

  .btn-secondary {
    @apply btn bg-secondary hover:bg-gray-600 text-white;
  }

  .btn-outline {
    @apply btn border-2 border-primary text-primary hover:bg-primary hover:text-white;
  }
}
```

## 响应式设计

Tailwind v4 保持了相同的响应式语法：

```tsx
<div className="
  grid
  grid-cols-1
  sm:grid-cols-2
  md:grid-cols-3
  lg:grid-cols-4
  gap-4
">
  {/* Grid items */}
</div>

<p className="text-sm md:text-base lg:text-lg">
  Responsive text size
</p>
```

### 自定义断点

```css
@theme {
  --breakpoint-xs: 475px;
  --breakpoint-3xl: 1920px;
}
```

```tsx
<div className="hidden xs:block 3xl:text-xl">Custom breakpoints</div>
```

## 暗色模式

### 基于类的暗色模式

```css
@custom-variant dark (&:where(.dark, .dark *));
```

```tsx
// 切换暗色模式
function toggleDarkMode() {
  document.documentElement.classList.toggle('dark');
}

// 使用
<div className="bg-white dark:bg-gray-900">
  <h1 className="text-gray-900 dark:text-white">Title</h1>
</div>
```

### 基于系统偏好

```css
@custom-variant dark (@media (prefers-color-scheme: dark));
```

## 最佳实践

### 1. 组织 CSS 文件

```
src/
├── styles/
│   ├── index.css        # 主入口，@import 其他文件
│   ├── theme.css        # @theme 定义
│   ├── components.css   # @layer components
│   └── utilities.css    # @layer utilities
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
  /* ✅ 语义化命名 */
  --color-primary: #3b82f6;
  --color-surface: #ffffff;
  --color-on-surface: #1f2937;
  --color-error: #ef4444;

  /* ❌ 避免硬编码颜色名 */
  /* --color-blue-500: #3b82f6; */
}
```

### 3. 提取可复用组件

```css
@layer components {
  /* 输入框基础样式 */
  .input {
    @apply w-full px-4 py-2 border border-gray-300 rounded-lg
           focus:ring-2 focus:ring-primary focus:border-transparent
           dark:bg-gray-800 dark:border-gray-700;
  }

  /* 标签样式 */
  .label {
    @apply block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1;
  }
}
```

### 4. 使用 cn() 工具函数合并类名

```typescript
// src/utils/cn.ts
export function cn(...classes: (string | undefined | null | false)[]): string {
  return classes.filter(Boolean).join(' ');
}

// 使用
<button className={cn(
  'btn',
  variant === 'primary' && 'btn-primary',
  variant === 'secondary' && 'btn-secondary',
  disabled && 'opacity-50 cursor-not-allowed'
)}>
  Click me
</button>
```

## 从 v3 迁移

### 迁移步骤

1. **更新依赖**
   ```bash
   pnpm remove tailwindcss postcss autoprefixer
   pnpm add tailwindcss @tailwindcss/vite
   ```

2. **更新 Vite 配置**
   ```typescript
   // 移除 postcss 配置，添加 Tailwind 插件
   import tailwindcss from '@tailwindcss/vite';
   export default defineConfig({
     plugins: [react(), tailwindcss()],
   });
   ```

3. **转换 CSS 入口**
   ```css
   /* 旧版 */
   @tailwind base;
   @tailwind components;
   @tailwind utilities;

   /* 新版 */
   @import "tailwindcss";
   ```

4. **迁移 tailwind.config.js 到 CSS**
   ```css
   @theme {
     /* 将 JavaScript 配置转换为 CSS 变量 */
   }
   ```

5. **删除不需要的文件**
   - `tailwind.config.js`
   - `postcss.config.js`

## 常见问题

### Q: 还需要 PostCSS 吗？
A: 使用 `@tailwindcss/vite` 插件时不需要，它内置了所有必要的处理。

### Q: 如何使用第三方插件？
A: 某些 v3 插件可能需要更新才能兼容 v4。官方插件如 `@tailwindcss/typography` 已经支持。

### Q: 性能如何？
A: v4 性能显著提升，构建速度更快，生成的 CSS 文件更小。

## 参考资源

- [Tailwind CSS v4 官方文档](https://tailwindcss.com/docs)
- [Tailwind CSS v4 升级指南](https://tailwindcss.com/docs/upgrade-guide)
- [Tailwind CSS GitHub](https://github.com/tailwindlabs/tailwindcss)

详细配置示例参见 `references/` 目录。
