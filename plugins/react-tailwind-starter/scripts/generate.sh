#!/bin/bash

# React + Tailwind CSS 项目生成脚本
# 使用最新的工具链和最佳实践配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 参数验证
if [ "$#" -lt 6 ]; then
    log_error "Usage: $0 <project_name> <include_router> <include_zustand> <include_vitest> <include_storybook> <plugin_root>"
    exit 1
fi

PROJECT_NAME="$1"
INCLUDE_ROUTER="$2"
INCLUDE_ZUSTAND="$3"
INCLUDE_VITEST="$4"
INCLUDE_STORYBOOK="$5"
PLUGIN_ROOT="$6"

TEMPLATE_DIR="${PLUGIN_ROOT}/templates"

log_info "=========================================="
log_info "React + Tailwind CSS 项目生成器"
log_info "=========================================="
log_info "项目名称: ${PROJECT_NAME}"
log_info "React Router: ${INCLUDE_ROUTER}"
log_info "Zustand: ${INCLUDE_ZUSTAND}"
log_info "Vitest: ${INCLUDE_VITEST}"
log_info "Storybook: ${INCLUDE_STORYBOOK}"
log_info "=========================================="

# 验证项目名称
if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    log_error "项目名称无效: 只能包含小写字母、数字和连字符，且必须以字母开头"
    exit 1
fi

# 检查目录是否存在
if [ -d "$PROJECT_NAME" ]; then
    log_error "目录 '${PROJECT_NAME}' 已存在，请选择其他名称或删除现有目录"
    exit 1
fi

# 检查 Node.js
check_node() {
    if ! command -v node &> /dev/null; then
        log_error "未检测到 Node.js，请先安装 Node.js 18+"
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        log_error "Node.js 版本过低，需要 18+，当前版本: $(node -v)"
        exit 1
    fi
    log_success "Node.js $(node -v) ✓"
}

# 检查 pnpm
check_pnpm() {
    if ! command -v pnpm &> /dev/null; then
        log_warning "未检测到 pnpm，正在安装..."
        npm install -g pnpm
    fi
    log_success "pnpm $(pnpm -v) ✓"
}

# 环境检查
log_info "检查环境..."
check_node
check_pnpm

# 步骤 1: 创建 Vite 项目
log_info "步骤 1/8: 创建 Vite + React + SWC + TypeScript 项目..."
pnpm create vite@latest "$PROJECT_NAME" --template react-swc-ts

cd "$PROJECT_NAME"

# 步骤 2: 安装 Tailwind CSS v4
log_info "步骤 2/8: 安装 Tailwind CSS v4..."
pnpm add tailwindcss @tailwindcss/vite

# 步骤 3: 安装 ESLint v9 + Prettier
log_info "步骤 3/8: 安装 ESLint v9 + Prettier..."
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

# 步骤 4: 安装 Stylelint
log_info "步骤 4/8: 安装 Stylelint..."
pnpm add -D stylelint stylelint-config-standard

# 步骤 5: 安装 Husky + lint-staged + Commitlint
log_info "步骤 5/8: 安装 Git Hooks 工具..."
pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional

# 步骤 6: 安装可选依赖
log_info "步骤 6/8: 安装可选功能..."

if [ "$INCLUDE_ROUTER" = "yes" ]; then
    log_info "  - 安装 React Router..."
    pnpm add react-router-dom
fi

if [ "$INCLUDE_ZUSTAND" = "yes" ]; then
    log_info "  - 安装 Zustand..."
    pnpm add zustand
fi

if [ "$INCLUDE_VITEST" = "yes" ]; then
    log_info "  - 安装 Vitest + Testing Library..."
    pnpm add -D vitest @vitest/ui @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom @types/testing-library__jest-dom
fi

if [ "$INCLUDE_STORYBOOK" = "yes" ]; then
    log_info "  - 安装 Storybook..."
    pnpm dlx storybook@latest init --skip-install --yes
    # 安装 storybook 相关依赖，包括 eslint 插件
    pnpm add -D eslint-plugin-storybook
    pnpm install
fi

# 步骤 7: 创建目录结构
log_info "步骤 7/8: 创建项目目录结构..."
mkdir -p src/{components,hooks,pages,services,stores,types,utils}

# 步骤 8: 生成配置文件
log_info "步骤 8/8: 生成配置文件..."

# ESLint 配置 (Flat Config)
cat > eslint.config.mjs << 'ESLINT_EOF'
import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import prettier from 'eslint-plugin-prettier';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  { ignores: ['dist', 'node_modules', '*.config.*'] },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended, prettierConfig],
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
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
      'react/react-in-jsx-scope': 'off',
      'react/prop-types': 'off',
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      'prettier/prettier': 'error',
    },
    settings: {
      react: { version: 'detect' },
    },
  }
);
ESLINT_EOF

# Prettier 配置
cat > prettier.config.mjs << 'PRETTIER_EOF'
/** @type {import("prettier").Config} */
export default {
  printWidth: 100,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: true,
  quoteProps: 'as-needed',
  jsxSingleQuote: false,
  trailingComma: 'es5',
  bracketSpacing: true,
  bracketSameLine: false,
  arrowParens: 'always',
  endOfLine: 'lf',
  plugins: [],
};
PRETTIER_EOF

# Stylelint 配置
cat > stylelint.config.mjs << 'STYLELINT_EOF'
/** @type {import('stylelint').Config} */
export default {
  extends: ['stylelint-config-standard'],
  rules: {
    'at-rule-no-unknown': [
      true,
      {
        ignoreAtRules: ['tailwind', 'apply', 'variants', 'responsive', 'screen', 'layer', 'theme', 'custom-variant'],
      },
    ],
    'selector-class-pattern': null,
    'no-descending-specificity': null,
    'function-no-unknown': [
      true,
      {
        ignoreFunctions: ['theme'],
      },
    ],
  },
};
STYLELINT_EOF

# Commitlint 配置
cat > commitlint.config.mjs << 'COMMITLINT_EOF'
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
        'refactor', // 重构 (既不是新功能也不是 bug 修复)
        'perf',     // 性能优化
        'test',     // 添加/修改测试
        'chore',    // 构建过程或辅助工具变动
        'revert',   // 回滚
        'ci',       // CI 配置变更
        'build',    // 构建系统变更
      ],
    ],
    'subject-case': [0],
  },
};
COMMITLINT_EOF

# 更新 Vite 配置
cat > vite.config.ts << 'VITE_EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import tailwindcss from '@tailwindcss/vite';

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': '/src',
    },
  },
  server: {
    port: 5173,
    open: true,
  },
  build: {
    target: 'esnext',
    sourcemap: true,
  },
});
VITE_EOF

# 更新 index.css (Tailwind v4 CSS-first)
cat > src/index.css << 'CSS_EOF'
@import "tailwindcss";

/* Tailwind CSS v4 - CSS-first 配置 */
@theme {
  /* 自定义颜色 */
  --color-primary: #3b82f6;
  --color-primary-dark: #2563eb;
  --color-secondary: #6b7280;

  /* 自定义字体 */
  --font-family-sans: 'Inter', system-ui, sans-serif;

  /* 自定义间距 */
  --spacing-18: 4.5rem;
}

/* 自定义工具类 */
@layer utilities {
  .text-balance {
    text-wrap: balance;
  }
}
CSS_EOF

# 更新 App.tsx
cat > src/App.tsx << 'APP_EOF'
import { useState } from 'react';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-5xl font-bold text-white mb-8">
          React + Tailwind CSS
        </h1>
        <p className="text-gray-400 mb-8 text-lg">
          Vite + SWC + TypeScript + Tailwind CSS v4
        </p>
        <div className="bg-gray-800 rounded-xl p-8 shadow-2xl">
          <button
            onClick={() => setCount((c) => c + 1)}
            className="bg-primary hover:bg-primary-dark text-white font-semibold py-3 px-8 rounded-lg transition-colors duration-200 text-lg"
          >
            Count: {count}
          </button>
        </div>
        <p className="text-gray-500 mt-8 text-sm">
          Edit <code className="text-primary">src/App.tsx</code> and save to test HMR
        </p>
      </div>
    </div>
  );
}

export default App;
APP_EOF

# 更新 main.tsx
cat > src/main.tsx << 'MAIN_EOF'
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import App from './App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
MAIN_EOF

# 创建示例文件
# 示例 Hook
cat > src/hooks/useCounter.ts << 'HOOK_EOF'
import { useState, useCallback } from 'react';

interface UseCounterOptions {
  initialValue?: number;
  min?: number;
  max?: number;
  step?: number;
}

export function useCounter(options: UseCounterOptions = {}) {
  const { initialValue = 0, min = -Infinity, max = Infinity, step = 1 } = options;

  const [count, setCount] = useState(initialValue);

  const increment = useCallback(() => {
    setCount((c) => Math.min(c + step, max));
  }, [step, max]);

  const decrement = useCallback(() => {
    setCount((c) => Math.max(c - step, min));
  }, [step, min]);

  const reset = useCallback(() => {
    setCount(initialValue);
  }, [initialValue]);

  const set = useCallback(
    (value: number) => {
      setCount(Math.min(Math.max(value, min), max));
    },
    [min, max]
  );

  return { count, increment, decrement, reset, set };
}
HOOK_EOF

# 示例组件
cat > src/components/Button.tsx << 'BUTTON_EOF'
import { ButtonHTMLAttributes, forwardRef } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

const variantStyles = {
  primary: 'bg-primary hover:bg-primary-dark text-white',
  secondary: 'bg-secondary hover:bg-gray-600 text-white',
  outline: 'border-2 border-primary text-primary hover:bg-primary hover:text-white',
};

const sizeStyles = {
  sm: 'py-1.5 px-3 text-sm',
  md: 'py-2 px-4 text-base',
  lg: 'py-3 px-6 text-lg',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', className = '', children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={`font-semibold rounded-lg transition-colors duration-200 ${variantStyles[variant]} ${sizeStyles[size]} ${className}`}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
BUTTON_EOF

# 示例类型
cat > src/types/index.ts << 'TYPES_EOF'
// 通用类型定义

export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  createdAt: Date;
  updatedAt: Date;
}

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
TYPES_EOF

# 示例工具函数
cat > src/utils/cn.ts << 'CN_EOF'
/**
 * 合并 className 的工具函数
 * 简化版的 clsx/classnames
 */
export function cn(...classes: (string | undefined | null | false)[]): string {
  return classes.filter(Boolean).join(' ');
}
CN_EOF

# Zustand store 示例 (如果启用)
if [ "$INCLUDE_ZUSTAND" = "yes" ]; then
cat > src/stores/counterStore.ts << 'STORE_EOF'
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

interface CounterState {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
  setCount: (value: number) => void;
}

export const useCounterStore = create<CounterState>()(
  devtools(
    persist(
      (set) => ({
        count: 0,
        increment: () => set((state) => ({ count: state.count + 1 })),
        decrement: () => set((state) => ({ count: state.count - 1 })),
        reset: () => set({ count: 0 }),
        setCount: (value) => set({ count: value }),
      }),
      { name: 'counter-storage' }
    ),
    { name: 'CounterStore' }
  )
);
STORE_EOF
fi

# Vitest 配置 (如果启用)
if [ "$INCLUDE_VITEST" = "yes" ]; then
cat > vitest.config.ts << 'VITEST_EOF'
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react-swc';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.{test,spec}.{js,jsx,ts,tsx}'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },
  },
  resolve: {
    alias: {
      '@': '/src',
    },
  },
});
VITEST_EOF

mkdir -p src/test
cat > src/test/setup.ts << 'SETUP_EOF'
import '@testing-library/jest-dom';
SETUP_EOF

cat > src/components/Button.test.tsx << 'TEST_EOF'
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { Button } from './Button';

describe('Button', () => {
  it('renders children correctly', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    fireEvent.click(screen.getByText('Click me'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('applies variant styles correctly', () => {
    render(<Button variant="secondary">Secondary</Button>);
    const button = screen.getByText('Secondary');
    expect(button.className).toContain('bg-secondary');
  });
});
TEST_EOF
fi

# 更新 package.json scripts
node << NODEJS_EOF
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

const includeVitest = '${INCLUDE_VITEST}' === 'yes';
const includeStorybook = '${INCLUDE_STORYBOOK}' === 'yes';

pkg.scripts = {
  'dev': 'vite',
  'build': 'tsc -b && vite build',
  'preview': 'vite preview',
  'lint': 'eslint .',
  'lint:fix': 'eslint . --fix',
  'format': 'prettier --write .',
  'format:check': 'prettier --check .',
  'stylelint': 'stylelint "src/**/*.css"',
  'stylelint:fix': 'stylelint "src/**/*.css" --fix',
  'prepare': 'husky',
  'typecheck': 'tsc --noEmit'
};

if (includeVitest) {
  pkg.scripts['test'] = 'vitest';
  pkg.scripts['test:ui'] = 'vitest --ui';
  pkg.scripts['test:coverage'] = 'vitest --coverage';
}

if (includeStorybook) {
  pkg.scripts['storybook'] = 'storybook dev -p 6006';
  pkg.scripts['build-storybook'] = 'storybook build';
}

pkg['lint-staged'] = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
  '*.css': ['stylelint --fix', 'prettier --write']
};

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
NODEJS_EOF

# 初始化 Husky
log_info "初始化 Husky..."
git init
pnpm exec husky init

# 创建 pre-commit hook
cat > .husky/pre-commit << 'PRECOMMIT_EOF'
pnpm exec lint-staged
PRECOMMIT_EOF

# 创建 commit-msg hook
cat > .husky/commit-msg << 'COMMITMSG_EOF'
pnpm exec commitlint --edit $1
COMMITMSG_EOF

# 设置执行权限
chmod +x .husky/pre-commit
chmod +x .husky/commit-msg

# 创建 .prettierignore
cat > .prettierignore << 'IGNORE_EOF'
dist
node_modules
.husky
pnpm-lock.yaml
*.min.js
*.min.css
IGNORE_EOF

# 创建 .gitignore 补充
cat >> .gitignore << 'GITIGNORE_EOF'

# IDE
.idea
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json

# Testing
coverage

# Storybook
storybook-static
GITIGNORE_EOF

# 创建 VS Code 配置
mkdir -p .vscode
cat > .vscode/settings.json << 'VSCODE_EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit",
    "source.fixAll.stylelint": "explicit"
  },
  "eslint.useFlatConfig": true,
  "typescript.tsdk": "node_modules/typescript/lib",
  "css.validate": false,
  "stylelint.validate": ["css"]
}
VSCODE_EOF

cat > .vscode/extensions.json << 'EXT_EOF'
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "stylelint.vscode-stylelint",
    "bradlc.vscode-tailwindcss",
    "dsznajder.es7-react-js-snippets"
  ]
}
EXT_EOF

log_success "=========================================="
log_success "项目 '${PROJECT_NAME}' 创建成功!"
log_success "=========================================="
log_info ""
log_info "后续步骤:"
log_info "  1. cd ${PROJECT_NAME}"
log_info "  2. pnpm dev"
log_info ""
log_info "项目已包含:"
log_success "  ✓ Vite + React + SWC + TypeScript"
log_success "  ✓ Tailwind CSS v4 (CSS-first)"
log_success "  ✓ ESLint v9 Flat Config"
log_success "  ✓ Prettier"
log_success "  ✓ Stylelint"
log_success "  ✓ Husky + lint-staged + Commitlint"
[ "$INCLUDE_ROUTER" = "yes" ] && log_success "  ✓ React Router"
[ "$INCLUDE_ZUSTAND" = "yes" ] && log_success "  ✓ Zustand"
[ "$INCLUDE_VITEST" = "yes" ] && log_success "  ✓ Vitest + Testing Library"
[ "$INCLUDE_STORYBOOK" = "yes" ] && log_success "  ✓ Storybook"
log_info ""
log_success "开始开发吧! 🚀"
