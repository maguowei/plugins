---
name: commit
description: 按 Conventional Commits 规范创建 git 提交（type 英文、描述中文），支持首次提交
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*)
---

# Git Commit Skill

按 Conventional Commits 规范创建 git 提交。

## Context

- 当前 git 状态: !`git status`
- 当前改动（暂存与未暂存）: !`git diff HEAD 2>/dev/null || echo "（尚无提交，这是项目首次提交）"`
- 当前分支: !`git branch --show-current`
- 最近提交: !`git log --oneline -10 2>/dev/null || echo "（无历史提交）"`

## Task

基于以上改动，创建一个 git 提交。

### 提交信息格式

`type(scope): description`

- `type` 用英文：`feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`、`revert`
- `scope` 可选，标识影响范围（模块、文件、组件），参考最近提交的写法
- `description` 用中文，简洁说明改动内容，结尾不加句号

### 特殊情况

- 首次提交（无历史提交）时，暂存全部文件，使用 `chore: 初始化项目`，或按内容补充，如 `feat: 初始化命令行工具骨架`
- 密钥、`.env`、本地配置等敏感文件保持未暂存，并在提交后提示用户

### 执行要求

在一次响应中完成暂存和提交，除工具调用外不输出其他文本。
