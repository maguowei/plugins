---
name: init-react-app
description: 初始化一个新的 React + Tailwind CSS 项目，使用 Vite + SWC + TypeScript，集成 ESLint v9、Prettier、Husky 等最佳实践配置
argument-hint: "[--name <project-name>]"
allowed-tools:
  - Bash
  - AskUserQuestion
---

# 初始化 React + Tailwind CSS 项目

使用脚本驱动的方式创建一个完整的 React 前端项目，包含现代化工具链和最佳实践配置。

## 执行流程

### 第 1 步: 收集项目信息

使用 AskUserQuestion 工具收集以下信息:

1. **项目名称** (必需):
   - 提示: "项目名称 (如: my-react-app)"
   - 验证: 只包含小写字母、数字和连字符
   - 用于创建项目目录

2. **可选功能** (多选):
   - React Router (路由管理)
   - Zustand (状态管理)
   - Vitest + Testing Library (单元测试)
   - Storybook (组件文档)
   - 默认: 全部选中

### 第 2 步: 调用生成脚本

使用 Bash 工具执行以下命令:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate.sh \
  "<project_name>" \
  "<include_router>" \
  "<include_zustand>" \
  "<include_vitest>" \
  "<include_storybook>" \
  "${CLAUDE_PLUGIN_ROOT}"
```

**参数说明**:
- `project_name`: 项目名称
- `include_router`: yes/no - 是否包含 React Router
- `include_zustand`: yes/no - 是否包含 Zustand
- `include_vitest`: yes/no - 是否包含 Vitest
- `include_storybook`: yes/no - 是否包含 Storybook
- 最后一个参数: 插件根目录

**重要**:
- 确保替换所有 `<参数>` 为实际值
- 项目名称需要加引号以处理特殊字符
- `${CLAUDE_PLUGIN_ROOT}` 会自动展开为插件根目录

脚本将自动完成:
- 使用 pnpm create vite 创建项目
- 安装 Tailwind CSS v4
- 配置 ESLint v9 Flat Config
- 配置 Prettier
- 配置 Stylelint
- 设置 Husky + lint-staged + Commitlint
- 创建项目目录结构
- 安装所有依赖

### 第 3 步: 显示后续步骤

项目生成完成后，向用户显示以下信息:

```
✅ React + Tailwind CSS 项目创建成功!

项目位置: ./<project-name>/

后续步骤:

1. 进入项目目录:
   cd <project-name>

2. 启动开发服务器:
   pnpm dev

3. 打开浏览器:
   http://localhost:5173

4. 构建生产版本:
   pnpm build

5. 运行代码检查:
   pnpm lint
   pnpm format:check

6. 运行测试 (如果包含 Vitest):
   pnpm test

7. 启动 Storybook (如果包含):
   pnpm storybook

项目包含:
✅ Vite + React + SWC + TypeScript
✅ Tailwind CSS v4 (CSS-first 配置)
✅ ESLint v9 Flat Config
✅ Prettier 代码格式化
✅ Stylelint CSS 检查
✅ Husky + lint-staged Git Hooks
✅ Commitlint 提交规范
✅ 按类型组织的目录结构

开始开发吧! 🚀
```

## 使用示例

### 交互式使用

```
用户: /init-react-app

系统询问:
1. 项目名称: my-react-app
2. 可选功能: [全选]

[脚本自动生成项目]

系统显示: ✅ 项目创建成功! [后续步骤]
```

## 错误处理

如果发生错误，清晰地告知用户:

- **项目名称无效**: "项目名称只能包含小写字母、数字和连字符"
- **目录已存在**: "目录 '<name>' 已存在，请选择其他名称或删除现有目录"
- **Node.js 未安装**: "未检测到 Node.js，请先安装 Node.js 18+"
- **pnpm 未安装**: "未检测到 pnpm，请先安装: npm install -g pnpm"
- **依赖安装失败**: "依赖安装失败: <error>，请检查网络连接"

## 前置依赖

运行此命令前，请确保已安装:

1. **Node.js 18+**
   ```bash
   # macOS
   brew install node

   # 验证
   node --version
   ```

2. **pnpm**
   ```bash
   npm install -g pnpm

   # 验证
   pnpm --version
   ```

## 注意事项

- 确保在调用脚本前验证所有输入
- 项目生成过程需要几分钟 (下载依赖)
- 生成的项目目录在当前工作目录下
- 不要覆盖现有目录
- 脚本会自动验证环境并提供清晰的错误提示

## 相关技能

此命令生成的项目使用了以下最佳实践:
- Tailwind CSS v4 最佳实践 (参考 tailwind-css-v4 skill)
- ESLint + Prettier 配置 (参考 eslint-prettier-config skill)
- Git Hooks 工作流 (参考 git-hooks-workflow skill)
- Vite + React 项目结构 (参考 vite-react-structure skill)
