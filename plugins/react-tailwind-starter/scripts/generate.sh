#!/bin/bash

# React + Tailwind CSS 项目生成脚本
# 使用模板驱动的方式生成项目

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
log_info "模板目录: ${TEMPLATE_DIR}"
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

# 复制模板文件的函数
copy_template() {
    local src="$1"
    local dest="$2"
    if [ -f "$src" ]; then
        cp "$src" "$dest"
        log_info "  ✓ $(basename "$dest")"
    else
        log_warning "  模板不存在: $src"
    fi
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
    pnpm add -D eslint-plugin-storybook
    pnpm install
fi

# 步骤 7: 创建目录结构并复制模板
log_info "步骤 7/8: 创建项目目录结构..."
mkdir -p src/{components,hooks,pages,services,stores,types,utils}
mkdir -p .vscode

log_info "步骤 8/8: 从模板复制配置文件..."

# 复制配置文件
log_info "复制配置文件..."
copy_template "${TEMPLATE_DIR}/configs/eslint.config.mjs" "eslint.config.mjs"
copy_template "${TEMPLATE_DIR}/configs/prettier.config.mjs" "prettier.config.mjs"
copy_template "${TEMPLATE_DIR}/configs/stylelint.config.mjs" "stylelint.config.mjs"
copy_template "${TEMPLATE_DIR}/configs/commitlint.config.mjs" "commitlint.config.mjs"
copy_template "${TEMPLATE_DIR}/configs/vite.config.ts" "vite.config.ts"
copy_template "${TEMPLATE_DIR}/configs/.prettierignore" ".prettierignore"

# 复制源代码模板
log_info "复制源代码模板..."
copy_template "${TEMPLATE_DIR}/src/index.css" "src/index.css"
copy_template "${TEMPLATE_DIR}/src/App.tsx" "src/App.tsx"
copy_template "${TEMPLATE_DIR}/src/main.tsx" "src/main.tsx"
copy_template "${TEMPLATE_DIR}/src/hooks/useCounter.ts" "src/hooks/useCounter.ts"
copy_template "${TEMPLATE_DIR}/src/components/Button.tsx" "src/components/Button.tsx"
copy_template "${TEMPLATE_DIR}/src/types/index.ts" "src/types/index.ts"
copy_template "${TEMPLATE_DIR}/src/utils/cn.ts" "src/utils/cn.ts"

# 复制 VS Code 配置
log_info "复制 VS Code 配置..."
copy_template "${TEMPLATE_DIR}/vscode/settings.json" ".vscode/settings.json"
copy_template "${TEMPLATE_DIR}/vscode/extensions.json" ".vscode/extensions.json"

# 条件复制: Zustand store
if [ "$INCLUDE_ZUSTAND" = "yes" ]; then
    log_info "复制 Zustand store 模板..."
    copy_template "${TEMPLATE_DIR}/src/stores/counterStore.ts" "src/stores/counterStore.ts"
fi

# 条件复制: Vitest 配置
if [ "$INCLUDE_VITEST" = "yes" ]; then
    log_info "复制 Vitest 配置..."
    mkdir -p src/test
    copy_template "${TEMPLATE_DIR}/configs/vitest.config.ts" "vitest.config.ts"
    copy_template "${TEMPLATE_DIR}/src/test/setup.ts" "src/test/setup.ts"
    copy_template "${TEMPLATE_DIR}/src/components/Button.test.tsx" "src/components/Button.test.tsx"
fi

# 追加 .gitignore 内容
log_info "更新 .gitignore..."
cat "${TEMPLATE_DIR}/configs/.gitignore.append" >> .gitignore

# 更新 package.json scripts
log_info "更新 package.json scripts..."
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

# 复制 Husky hooks
log_info "配置 Git Hooks..."
copy_template "${TEMPLATE_DIR}/husky/pre-commit" ".husky/pre-commit"
copy_template "${TEMPLATE_DIR}/husky/commit-msg" ".husky/commit-msg"

# 设置执行权限
chmod +x .husky/pre-commit
chmod +x .husky/commit-msg

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
