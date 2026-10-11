# Claude Plugins Marketplace

## 插件

- **git**：git 工作流 skill 集合，可被其他 agent 和 workflow 调用。
  - `git:commit`：按 Conventional Commits 规范提交（type 英文、描述中文，scope 可选），支持首次提交
  - `git:push`：检查远端、工作区与同步状态后安全推送，新分支自动设置 upstream
- **agent-maintenance**：维护项目侧 agent 配置的 skill 集合，后续类似工具也放在这里。
  - `agent-maintenance:sync-matt-pocock-skills`：把 `docs/agents/*.md` 与 `CLAUDE.md`/`AGENTS.md` 的 `## Agent skills` 章节同步到 mattpocock/skills 上游最新模板，处理 `CONTEXT.md` → `GLOSSARY.md` 等迁移，并补齐「本节由 agent skills 配置流程维护」声明

## 安装

### Claude Code 插件

```bash
/plugin marketplace add maguowei/plugins
/plugin install git
/plugin install agent-maintenance
```

### 作为 Skills 安装

非 Claude Code 工具可通过 skills CLI 将仓库中的 skill 安装到全局：

```bash
skills add -g maguowei/plugins
```

### 本地开发

本地开发时把 URL 换成仓库本地路径，修改后执行 `/plugin reload git`。插件开发推荐使用官方 [plugin-dev](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/plugin-dev) 插件。

## 参考

- [插件文档](https://code.claude.com/docs/zh-CN/plugins)
- [插件参考](https://code.claude.com/docs/zh-CN/plugins-reference)
- [插件市场文档](https://code.claude.com/docs/zh-CN/plugin-marketplaces)
