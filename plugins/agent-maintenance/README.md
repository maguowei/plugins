# agent-maintenance

维护项目侧 agent 配置的 skill 集合，后续类似的同步、迁移、守护工具也放在这里。

| Skill | 作用 |
| --- | --- |
| `agent-maintenance:sync-matt-pocock-skills` | 把 `docs/agents/*.md` 与 `CLAUDE.md`/`AGENTS.md` 的 `## Agent skills` 章节同步到 mattpocock/skills 上游最新模板；处理 `CONTEXT.md` → `GLOSSARY.md` 等迁移；补齐「本节由 agent skills 配置流程维护」声明 |

## 安装

```bash
/plugin install agent-maintenance
```

## 背景

`setup-matt-pocock-skills` 目前没有升级步骤（[mattpocock/skills#1176](https://github.com/mattpocock/skills/issues/1176)），skill 升级后项目内的配置会停留在旧模板，例如 1.3.0 把 `CONTEXT.md` 改名 `GLOSSARY.md` 后旧项目仍引用旧名。`sync-matt-pocock-skills` 是临时替代方案：显式调用后比对上游、列出差异、经用户确认再写入。上游提供升级能力后即可退役。

## 设计约束

- 仅在用户显式调用时运行（`disable-model-invocation: true`）。
- 写入前必须给出差异清单并等待确认；`--check` 不修改项目文件或 Git index，仅在本次创建的临时目录中下载上游并清理。
- 保留项目事实与自定义：tracker 选型、triage 标签映射、PR 开关、多上下文布局。
- 不改写 `## Agent skills` 里项目自己写的一句话摘要，不做顺带格式化、精简或重排。
