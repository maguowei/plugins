---
name: audit
description: 按 codego 基线只读审计现有 Go 项目，输出分级改进建议：AI Coding 友好度、目录结构与命名、技术栈选型。用户要检查、评估、体检现有 Go 项目，或询问它离基线差多少时使用。
---

# 审计 Go 项目

以 [基线摘要](references/baseline.md) 为尺子审计一个现有 Go 项目，输出一份有证据的分级报告。开始前通读基线摘要。

审计全程只读：不修改、不新建、不删除目标项目的任何文件，也不改它的 `go.mod`。报告给出建议，是否对齐、怎么对齐由用户决定。

## 1. 定界

- 找出目标目录下所有 `go.mod`。只有一个时以它所在目录为**审计对象**；有多个时（monorepo）用 AskUserQuestion 问审哪个。根目录编排、前端与其他语言的代码不在审计范围内。
- 判定**项目形态**：有 HTTP 入口（`net/http` server、路由库）的是 HTTP 服务；以 Cobra 或 `flag` 为入口的命令行程序是 CLI；其余（library、gRPC、worker-only 等）为「其他形态」。
- 读项目自己的事实源：`CLAUDE.md` / `AGENTS.md`、`.claude/`、README、Makefile、CI workflow、lint 配置。

完成标准：审计对象（module 根路径）与项目形态都已确定。

## 2. 收集证据

逐项对照基线摘要检查，每条发现都要落到文件路径、命令输出或规则 ID 上。

**AI 友好缺口**（任何形态都检查）：

- agent 入口：有没有 `CLAUDE.md` / `AGENTS.md`，是否写了常用命令、工作流、分层边界；其中提到的路径和 Make 目标是否真实存在。
- 按路径拆分的 rules：有没有 `.claude/rules/`，有没有 `paths` frontmatter，有没有路径规则索引。
- 统一命令入口：Makefile 是否有 `check`（快速迭代）与 `verify`（交付门禁）这一类分层入口，CI 与 hooks 是否复用 Make 目标。
- 质量门禁：golangci-lint（对照摘要的 linter 下限）、govulncheck、gitleaks、Lefthook；工具版本是否经 `go.mod` 的 tool directive 固定。
- 编辑反馈：`.claude/settings.json` 是否有权限白名单和编辑后的质量 hook。
- CI 供应链：Actions 是否固定到 commit SHA，是否有最小权限。

**结构与命名**（仅 HTTP 服务、CLI）：

- HTTP 服务运行 archcheck；`go run` 指定版本只读执行，不改动 `go.mod`：

  ```bash
  go run github.com/maguowei/codego/archrules/cmd/archcheck@v0.1.0 check -root <module 根> -format json
  ```

  项目自带 `archrules.json` 时会被自动加载。按规则 ID 聚合结果，每条规则只记违规数和最多 3 个样例路径，用 `explain <rule-id>` 补一句规则含义。无法下载或运行时，记录原因并改为对照摘要第 2、3 节人工检查目录与命名。
- CLI 对照摘要的 CLI 目录约定人工检查。
- 两种形态都人工检查 archrules 判定不了的规则（摘要第 3 节的 review 规则）与工程约定（摘要第 4 节）。

**技术栈差异**（仅 HTTP 服务、CLI）：从 `go.mod` 与代码中读出路由、契约、持久化、配置、日志、观测、测试替身的实际选型，列出与摘要第 1 节不一致的项。

其他形态的项目只检查 AI 友好缺口，并在报告里写明结构、命名与技术栈两档不适用。

完成标准：适用的每一档里，摘要的每个检查点都给出了「符合 / 不符合 / 不适用」及证据。

## 3. 报告

在对话中输出报告：

```markdown
# Go 项目审计：<module path>

形态：<HTTP 服务 / CLI / 其他> ｜ 基线：<摘要头部的 codego commit 与日期> ｜ archcheck：<已运行 / 未运行及原因>

## 必须修：AI 友好缺口
- <问题> — 证据：<路径或命令输出> — 对齐方式：<怎么做>

## 建议：结构与命名
- [<rule-id>] <违规数> 处，例如 <路径>… — 对齐方式：<怎么做> — 迁移成本：<低 / 中 / 高及原因>

## 提示：技术栈差异
- <关注点>：当前 <X>，基线 <Y> — 差异影响：<一句话>

## 已符合
- <简短列出与基线一致的方面>
```

- 「必须修」与技术栈无关，只看 agent 能否在项目里高效、安全地工作。
- 「建议」按迁移成本从低到高排序；存量违规多时，建议接入 archrules 后用 `go tool archcheck baseline -write` 登记豁免，再逐条收敛。
- 「提示」只说明差异及其影响。替换框架、ORM、配置库这类迁移，只在用户已有迁移计划时才展开；默认结论是沿用现有选型，在其上补齐门禁与 agent 资产。

报告末尾询问用户是否要保存报告文件，以及是否要按「必须修」一档开始改。

完成标准：报告中每条发现都有证据和对齐方式，报告已输出。
