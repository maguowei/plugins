# Claude Plugins Marketplace

## 插件

| 插件 | 作用 | Skill |
| --- | --- | --- |
| [git](plugins/git/README.md) | git 工作流，可被其他 agent 和 workflow 调用 | `git:commit`、`git:push` |
| [agent-maintenance](plugins/agent-maintenance/README.md) | 把项目侧 agent 配置同步到 mattpocock/skills 上游模板 | `agent-maintenance:sync-matt-pocock-skills` |
| [go-project](plugins/go-project/README.md) | 不运行 codego 脚手架，按 codego 基线初始化和审计 Go 项目 | `go-project:init`、`go-project:audit` |

各 skill 的行为与约束见对应插件 README。

## 安装

### Claude Code 插件

```bash
/plugin marketplace add maguowei/plugins
/plugin install git@maguowei-plugins
/plugin install agent-maintenance@maguowei-plugins
/plugin install go-project@maguowei-plugins
```

### 作为 Skills 安装

非 Claude Code 工具可通过 skills CLI 将仓库中的 skill 安装到全局：

```bash
skills add -g maguowei/plugins
```

## 本地开发

在仓库根目录直接加载全部插件，无需安装：

```bash
claude plugin validate .         # 校验 marketplace、插件清单与 skill frontmatter
claude --plugin-dir ./plugins    # 本次会话加载 plugins/ 下所有插件
```

会话中修改文件后执行 `/reload-plugins` 生效。

## 参考

- [插件文档](https://code.claude.com/docs/zh-CN/plugins)
- [插件参考](https://code.claude.com/docs/zh-CN/plugins-reference)
- [插件市场文档](https://code.claude.com/docs/zh-CN/plugin-marketplaces)
