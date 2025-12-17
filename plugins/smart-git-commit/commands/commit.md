---
name: commit
description: 智能分析代码变更并生成符合规范的 Git commit message
allowed-tools: Task
argument-hint: [--amend]
model: claude-sonnet-4-5-20250929
---

# 智能 Git 提交

请调用 `smart-git-commit:commit-assistant` Agent 来处理这次提交。

Agent 会：
1. 分析 git status 和 git diff
2. 理解代码变更的内容和影响
3. 生成符合 Conventional Commits 规范的 commit message
4. 提供交互式确认
5. 执行 git commit

## 参数说明

- `--amend`: 修改最后一次提交（可选）

## 使用方式

```bash
# 普通提交
/commit

# 修改最后一次提交
/commit --amend
```
