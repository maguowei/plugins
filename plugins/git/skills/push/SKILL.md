---
name: push
description: 检查分支与远端状态后安全推送当前分支，新分支自动设置 upstream
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git remote:*), Bash(git rev-parse:*), Bash(git fetch:*), Bash(git push:*)
---

# Git Push Skill

把当前分支推送到远端。

## Context

- 当前 git 状态: !`git status --short --branch`
- 当前分支: !`git branch --show-current`
- 远端: !`git remote -v`
- upstream: !`git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "（未设置 upstream）"`
- 待推送提交: !`git log --oneline @{u}..HEAD 2>/dev/null || git log --oneline -10`

## Task

按顺序检查，每一项通过后进入下一项；任一项未通过时停止推送，向用户说明原因和建议操作。

1. **有远端**：没有 remote 时停止，提示先 `git remote add`。
2. **工作区干净**：有未提交改动时停止，提示先调用 `git:commit` 提交。
3. **分支安全**：当前分支是 `main` 或 `master` 时，先向用户确认再推送。
4. **与远端同步**：已有 upstream 时先 `git fetch`；远端有本地没有的提交（落后或分叉）时停止，提示先 `git pull --rebase` 或 merge。
5. **有可推送内容**：已有 upstream 且没有待推送提交时，告知已是最新并结束。

检查全部通过后推送：

- 已有 upstream：`git push`
- 未设置 upstream：`git push -u origin <当前分支>`（remote 不叫 `origin` 时用实际名称）

推送只用普通 fast-forward 推送并保留 hooks；用户明确要求 force push 时，改用 `git push --force-with-lease` 并先确认。

## 完成标准

推送成功，`git status --short --branch` 显示本地与 upstream 一致；最后用一句话报告推送的分支、远端和提交数。
