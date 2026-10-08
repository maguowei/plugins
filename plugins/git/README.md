# git

git 工作流 skill 集合，可被其他 agent 和 workflow 调用。

| Skill | 作用 |
| --- | --- |
| `git:commit` | 按 Conventional Commits 规范提交：`type(scope): description`，type 用英文、描述用中文、scope 可选；支持首次提交 |
| `git:push` | 检查远端、工作区、分支和同步状态后推送；新分支自动设置 upstream，推送 `main`/`master` 前确认 |

## 安装

```bash
/plugin install git
```

## 提交示例

- `feat(auth): 新增登录接口`
- `fix: 修复模板渲染路径校验`
- `chore: 初始化项目`（首次提交）
