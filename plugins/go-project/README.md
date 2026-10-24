# go-project

不运行 [codego](https://github.com/maguowei/codego) 脚手架，按 codego 基线初始化和审计 Go 项目。

| Skill | 作用 |
| --- | --- |
| `go-project:init` | 在空目录初始化 HTTP 服务（可选 PostgreSQL）或 CLI 项目：选型、目录布局、质量门禁与 agent 资产，收尾跑通项目自身的 `make verify`；仅在用户显式调用时运行（`disable-model-invocation: true`） |
| `go-project:audit` | 只读审计现有 Go 项目，按「必须修：AI 友好缺口 / 建议：结构与命名 / 提示：技术栈差异」三档输出带证据的报告 |

## 安装

```bash
/plugin install go-project
```

## 基线摘要

两个 skill 共用 `skills/init/references/baseline.md`（`audit/references` 是指向它的软链）。摘要只用文字写原则与选型，不复制模板文件；取舍见 [ADR-0001](../../docs/adr/0001-go-baseline-as-text-summary.md)。

摘要头部记录提炼来源（codego commit 与日期）。codego 基线变更后，对照该 commit 之后的 codego ADR 与 `docs/codego/baseline.md` 更新摘要，并刷新头部的 commit 与日期。
