# go-project 插件只承载 codego 基线的文字摘要，codego 仍是唯一事实源

`go-project` 插件需要在不运行 codego 脚手架的情况下初始化和审计 Go 项目，所以 skill 里必须带上一些基线内容。codego ADR-0018 否决过「另立共享规范文档」，理由是文档无法被 golden 与 smoke 机械验证。我们仍然决定在 skill 中放一份**基线摘要**：只用文字记录大的原则与选型，不复制模板文件，标注提炼来源（codego commit 与日期），冲突时以 codego 为准，不在本仓库独立演化规则。

## Considered Options

- **skill 独立演化，成为第二事实源**：否决。两份规则必然漂移，且绕开了 codego 的 smoke 验证。
- **skill 只放链接，运行时读取 codego 仓库**：否决。使用者不一定能访问 codego，离线不可用。
- **逐字收录契约文件或渲染产物（离线脚手架）**：否决。`minimal` 一个 preset 就有 155 个文件，逐字内容的维护成本与 codego 本体相当，而且一旦漂移就会悄悄传到新项目里。

## Consequences

- 具体文件（Makefile、lint 配置、CI、agent 资产）由 agent 依据原则现场编写，正确性靠项目自身的 `make verify` 与 `archcheck` 兜底，不追求与 codego 产物逐字一致。
- 命名与分层规则不在摘要中复述，直接依赖版本化的 `github.com/maguowei/codego/archrules`。
- 摘要篇幅小，同步靠人工对照 codego ADR 与 `docs/codego/baseline.md` 的变更，不需要同步脚本。
