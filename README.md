# Claude Plugins Marketplace

## 插件

- **git**：git 工作流 skill 集合，可被其他 agent 和 workflow 调用。
  - `git:commit`：按 Conventional Commits 规范提交（type 英文、描述中文，scope 可选），支持首次提交
  - `git:push`：检查远端、工作区与同步状态后安全推送，新分支自动设置 upstream

## 安装

```bash
/plugin marketplace add https://github.com/maguowei/plugins
/plugin install git
```

本地开发时把 URL 换成仓库本地路径，修改后执行 `/plugin reload git`。插件开发推荐使用官方 [plugin-dev](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/plugin-dev) 插件。

## 参考

- [插件文档](https://code.claude.com/docs/zh-CN/plugins)
- [插件参考](https://code.claude.com/docs/zh-CN/plugins-reference)
- [插件市场文档](https://code.claude.com/docs/zh-CN/plugin-marketplaces)
