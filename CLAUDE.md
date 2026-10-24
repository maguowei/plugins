# maguowei/plugins

Claude Code 插件市场：`.claude-plugin/marketplace.json` 登记 `plugins/<plugin>/`，每个插件是一组 skill，正文用中文。

## 改动插件

同一事实分布在多个文件，改一处就同步其余处：

- 插件 `version`：`plugins/<plugin>/.claude-plugin/plugin.json` 与 `marketplace.json` 对应条目保持一致（`claude plugin tag` 会校验）。
- 新增、改名或删除 plugin / skill：同步 `marketplace.json`、插件 README 的 skill 表、根 README 的插件表与安装命令。

写 skill 时：

- frontmatter `description` 先写做什么，再写「用户要……时使用」的触发场景。
- 有外部副作用的 skill（推送、改写他人项目配置）设 `disable-model-invocation: true`，如 `git:push`、`agent-maintenance:sync-matt-pocock-skills`。
- 多个 skill 共用的 reference 只存一份，其余用相对软链指向（如 `go-project/skills/audit/references`）。

提交 scope 用插件名，如 `feat(go-project): …`。

## 验证

`claude plugin validate .` 校验 marketplace 与全部插件的清单和 skill frontmatter；文档改动另跑 `git diff --check`。

## Agent skills

### Issue tracker

Issue 记在 GitHub Issues（maguowei/plugins），通过 `gh` CLI 操作。See `docs/agents/issue-tracker.md`.

### Triage labels

使用默认的五个 triage label：`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`。See `docs/agents/triage-labels.md`.

### Domain docs

single-context：根目录一个 `GLOSSARY.md` 加 `docs/adr/`。See `docs/agents/domain.md`.
