---
name: sync-matt-pocock-skills
description: "把项目侧 mattpocock/skills 配置同步到上游最新模板：docs/agents/*.md、CLAUDE.md/AGENTS.md 的 ## Agent skills 章节与相关迁移（如 CONTEXT.md → GLOSSARY.md）。当 skill 升级后项目配置疑似过时、需要核对 setup-matt-pocock-skills 输出、或要补齐章节维护声明时使用。"
disable-model-invocation: true
---

# 同步 mattpocock/skills 项目配置

## 背景

`setup-matt-pocock-skills` 只在首次配置时写模板，上游没有版本升级步骤（mattpocock/skills#1176）。skill 升级后，旧项目里的 `docs/agents/*.md` 和 `## Agent skills` 章节会停留在旧模板，例如 1.3.0 把 `CONTEXT.md` 改名 `GLOSSARY.md` 后项目仍引用旧文件名。

本 skill 是该问题的临时替代方案，同步三类对象：

1. `docs/agents/issue-tracker.md`、`docs/agents/triage-labels.md`、`docs/agents/domain.md`
2. `CLAUDE.md`（或 `AGENTS.md`）的 `## Agent skills` 章节：结构与最新 `setup-matt-pocock-skills` 输出一致，并包含维护声明
3. 相关迁移留下的引用（如根目录 `CONTEXT.md`/`CONTEXT-MAP.md` → `GLOSSARY.md`/`GLOSSARY-MAP.md` 及其在仓库文档中的引用）

它不更新已安装的 skill 本体（那由 `npx skills update` / 插件更新完成）。上游提供升级能力后，本 skill 即可退役。

## 调用与硬性约束

用户显式调用本 skill（`disable-model-invocation: true`，模型不得自动触发）。可带参数：

- `--check`：只报告差异，不修改项目文件或 Git index；允许在本次创建的临时目录中下载上游并清理
- `--ref <branch|tag|commit>`：上游参照物，默认 `main`

规则：

1. 只有本 skill 被用户显式调用，才构成对 `## Agent skills` 章节的修改授权；项目里的其他任务一律不得改动该章节。
2. 项目写入前必须给出完整差异清单并等用户确认；`--check` 对项目全程只读。
3. 保留项目事实与自定义：tracker 选型、triage 标签映射右列、`PRs as a request surface` 取值、多上下文布局、自定义工作流。
4. `## Agent skills` 里项目自己写的一句话摘要不改写；仅当同步导致事实失真（文件改名、布局变化）时提出修改并单独确认。
5. 不碰无关文档，不做顺带格式化、精简或重排。
6. 不臆造上游内容；网络失败时如实报告，降级使用本机副本必须注明可能过时。

## 第 1 步：探明项目现状

```bash
git status --short
git diff --
git diff --cached --
ls CLAUDE.md AGENTS.md 2>/dev/null
rg -n '^## Agent skills' CLAUDE.md AGENTS.md 2>/dev/null
ls -1 docs/agents/ 2>/dev/null
ls -1 CONTEXT.md CONTEXT-MAP.md GLOSSARY.md GLOSSARY-MAP.md 2>/dev/null
test -f docs/agents/triage-labels.md && echo "triage-labels: present" || echo "triage-labels: absent"
ls -d ~/.agents/skills/triage ~/.pi/agent/skills/triage ~/.claude/skills/triage .claude/skills/triage 2>/dev/null
```

记录执行前的 staged、unstaged 和未跟踪文件状态，并读取拟修改的未跟踪文件。已有改动属于用户；若与拟同步内容重叠，先列明冲突供第 5 步确认，保留其内容与暂存状态，不自动 stash、reset 或覆盖。

**triage 安装状态**：优先检查会话可用 skills（含插件命名空间，如 `engineering:triage`），再检查启用插件的 skill 目录及上面的本机路径，记录证据。找到可用 skill 或有效 `triage/SKILL.md` 为「已安装」；只有核查完整安装与启用清单后才能判为「未安装」；仅固定目录未命中、清单不可用或插件状态不明时为「未知」。`triage-labels.md` 是否存在单独记录，不能代替安装状态。

再从 `docs/agents/issue-tracker.md` 判定 tracker 类型：含 `gh ` 为 GitHub，含 `glab ` 为 GitLab，含 `.scratch/` 为 local markdown，其余按自定义处理。

记录：

- 章节所在文件：`CLAUDE.md` 优先，否则 `AGENTS.md`；若 `AGENTS.md` 是指向 `CLAUDE.md` 的符号链接，只编辑一处
- tracker 类型、triage 安装状态与现有配置、单/多上下文（读取 domain 配置及映射；`CONTEXT-MAP.md` 也作为迁移前多上下文的证据）
- 是否残留 legacy 文件名

**未配置项目**：既没有 `docs/agents/` 也没有 `## Agent skills` 章节时，不要初始化——提示用户先运行 `/setup-matt-pocock-skills`，然后结束。
**章节缺失但 `docs/agents/` 存在**：允许按第 4 步补建章节，摘要从现有文件和 `git remote -v` 提炼，写入前给用户确认。

## 第 2 步：取得上游最新版

```bash
SYNC_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mattpocock-skills-sync.XXXXXX") || exit 1
printf 'SYNC_DIR=%s\n' "$SYNC_DIR"
REF="${REF:-main}"
if ! git clone --depth 1 --branch "$REF" https://github.com/mattpocock/skills.git "$SYNC_DIR"; then
  rm -rf -- "$SYNC_DIR"
  exit 1
fi

UPSTREAM="$SYNC_DIR/skills/engineering/setup-matt-pocock-skills"
UPSTREAM_VERSION=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$SYNC_DIR/package.json")
UPSTREAM_COMMIT=$(git -C "$SYNC_DIR" rev-parse --short HEAD)
```

保留本次 `mktemp` 返回的目录路径；正常完成、`--check`、取消或失败退出时都按第 6 步清理。清理权限仅覆盖本次创建的目录，不复用或删除其他运行的目录。

`--ref` 是 commit sha 时 `--branch` 不适用，改为：clone 默认分支后 `git -C "$SYNC_DIR" fetch --depth 1 origin "$REF" && git -C "$SYNC_DIR" checkout --detach FETCH_HEAD`。

读取上游材料（以仓库实际内容为准，不依赖本文件的转述）：

- `$UPSTREAM/SKILL.md`：`## Agent skills` 区块的最新格式与 triage 小节的取舍规则
- `$UPSTREAM/domain.md`、`$UPSTREAM/triage-labels.md`、`$UPSTREAM/issue-tracker-{github,gitlab,local}.md`
- `$SYNC_DIR/CHANGELOG.md`：带迁移说明的条目

上游目录若搬迁，先用以下命令定位再继续：

```bash
gh api "repos/mattpocock/skills/git/trees/$REF?recursive=1" \
  --jq '.tree[].path | select(endswith("setup-matt-pocock-skills/domain.md"))'
```

网络不可用时，降级使用本机安装副本（`~/.agents/skills/setup-matt-pocock-skills`、`~/.pi/agent/skills/...`、`~/.claude/skills/...`），并明确告知用户：无法核验其新鲜度，建议先 `npx skills update` 再重跑本 skill。

## 第 3 步：逐文件比对并分类

| 项目文件 | 上游模板 | 必须保留 |
|---|---|---|
| `docs/agents/domain.md` | `$UPSTREAM/domain.md` | 项目文档路径、单/多上下文布局、自定义领域文档消费规则或段落 |
| `docs/agents/triage-labels.md` | `$UPSTREAM/triage-labels.md` | 右列「Label in our tracker」 |
| `docs/agents/issue-tracker.md` | 最接近的 `$UPSTREAM/issue-tracker-{github,gitlab,local}.md` | `PRs as a request surface` 取值、仓库事实、自定义命令或段落 |

```bash
git diff --no-index -- docs/agents/domain.md "$UPSTREAM/domain.md"   # 退出码 1 表示有差异，属正常
# issue-tracker 先找最接近的 stock 模板（差异最少的一个），再逐个 hunk 分类
for t in github gitlab local; do
  printf '%s: ' "$t"
  git diff --no-index --numstat -- docs/agents/issue-tracker.md "$UPSTREAM/issue-tracker-$t.md" 2>/dev/null \
    | awk '{print $1" added, "$2" removed"}'
done
```

每个差异 hunk 归为四类，按类处理：

- **模板漂移**：上游的措辞、结构、命令更新 → 应用上游
- **项目事实**：tracker 选型、标签右列、PR 开关、布局 → 保留
- **自定义内容**：项目自己加的命令或段落 → 保留；只有机械替换（如路径改名）在用户点名时改
- **疑似过时事实**：文档内自相矛盾（如摘要写 `CONTEXT.md`、正文写 `GLOSSARY.md`）→ 列入计划，单独确认

上述分类适用于全部三个配置文件。无法判断是模板漂移还是项目自定义时保留现状并报告未决项；只有逐 hunk 确认不存在项目定制，且用户已批准整文件替换时，才整体采用上游模板。

再从 `CHANGELOG.md` 提取迁移项，此步只形成计划，第 6 步才执行。例如 v1.3.0 的改名，先列出根目录与各上下文的实际文件，再扫描引用：

```bash
rg --files --hidden --glob '!.git' --glob 'CONTEXT.md' --glob 'CONTEXT-MAP.md' --glob 'GLOSSARY.md' --glob 'GLOSSARY-MAP.md' .
rg -n --hidden --glob '!.git' 'CONTEXT(-MAP)?\.md' .
```

逐项列出源文件、同目录目标文件、受影响引用与 Git 跟踪状态：

- 根目录 `CONTEXT.md` → `GLOSSARY.md`、`CONTEXT-MAP.md` → `GLOSSARY-MAP.md`；多上下文同时纳入映射所指目录中的 `CONTEXT.md`（如 `src/ordering/`、`packages/billing/`），逐个改为同目录 `GLOSSARY.md`。
- 仅迁移确认属于上游 domain-doc 约定的文件与有效路径引用；历史说明、示例或无关的同名文件保留并注明原因。
- 源与目标并存时先展示内容差异，等待用户选择合并或保留；目标冲突未解决前不改名、不改指向它的引用，不使用强制覆盖。
- 纳入映射内容、`docs/agents/domain.md`、章节摘要与其他实际引用；改名和引用更新作为同一批准项。干净的已跟踪文件用 `git mv`；有用户已有修改的迁移源文件先挂起，等待用户处理或单独批准暂存状态变更；未跟踪文件普通改名，不为了展示 diff 而暂存。

`docs/agents/issue-tracker.md` 若是完全自定义 tracker（三个 stock 模板都不接近），不要整体覆盖：把上游模板作为参照，只提出用户点名的对齐点。

## 第 4 步：核对 `## Agent skills` 章节

以 `$UPSTREAM/SKILL.md` 第 4 步为准。当前目标结构：

````markdown
## Agent skills

> <维护声明>

### Issue tracker

<一句话摘要>. See `docs/agents/issue-tracker.md`.

### Triage labels

<一句话摘要>. See `docs/agents/triage-labels.md`.

### Domain docs

<一句话摘要>. See `docs/agents/domain.md`.
````

规则：

- 小节顺序为 Issue tracker → Triage labels → Domain docs；按第 1 步的安装状态处理 `### Triage labels` 与 `docs/agents/triage-labels.md`：
  - 已安装且文件存在：保留并同步文件
  - 已安装但文件缺失：提案按上游模板创建文件（默认标签名）并补小节，等用户确认
  - 确认未安装但已有文件或小节：列入计划，询问删除还是保留；仅缺少本机路径不能作为删除依据
  - 确认未安装且文件、小节均缺失：不要新增
  - 安装状态未知：保留已有文件、小节和标签映射，安装状态相关的新增或删除挂起并说明缺失证据
- 每个小节末行必须是指向对应文件的 `See` 链接；语言可本地化，但要保留文件路径。
- 维护声明紧跟标题、用引用块；缺失或语义被削弱时补齐。已存在且语义完整则原样保留：
  - 中文文档：`> 本章节由 agent skills 配置流程维护。除非用户明确指示修改此章节，否则不要改动、重排或删减其中内容（包括 CLAUDE.md 精简、文档同步等顺带修改）。`
  - 英文文档：`> This section is maintained by the agent skills setup flow. Unless the user explicitly asks to change this section, do not modify, reorder, or remove its content (including incidental edits such as CLAUDE.md trimming and doc syncing).`
  - 其他语言：按相同语义翻译。
- 章节不得移动位置，不重排其他章节。
- 摘要有事实错误（文件改名等）时给出一行修正建议，不改变其风格和信息量。

## 第 5 步：出示差异并确认

先报告上游与本地状态，再给计划表：

```markdown
上游：mattpocock/skills <version>（<commit>，参照 <ref>）
配置：<CLAUDE.md|AGENTS.md>；docs/agents/{issue-tracker,triage-labels,domain}.md

| 文件 | 状态 | 拟改动 | 保留 |
| --- | --- | --- | --- |
| docs/agents/domain.md | 模板漂移 3 处 | 应用上游 | — |
| docs/agents/issue-tracker.md | 模板漂移 1 处 | 应用上游 | PR 开关=no |
| CLAUDE.md | 缺维护声明 | 补齐声明 | 三处摘要不动 |
```

等用户确认（可逐文件选择）后再进入第 6 步；`--check` 输出同样格式的报告，只清理本次临时目录后结束。写入前复核第 1 步记录的文件内容与暂存状态；出现新改动或新的冲突时更新计划，不沿用旧确认覆盖它们。

## 第 6 步：写入、验证、清理

仅执行批准的配置修改和迁移项。写入后验证完整状态，不只查看指定文档目录：

```bash
git status --short
git diff --stat
git diff --cached --stat
git diff --
git diff --cached --
git diff --check
git diff --cached --check
rg -n '^## Agent skills' -A 20 CLAUDE.md AGENTS.md 2>/dev/null
rg -n --hidden --glob '!.git' 'CONTEXT(-MAP)?\.md' .
```

将结果与执行前基线逐项比较，区分用户原有修改、本次修改和 `git mv` 产生的暂存改名。对新建未跟踪文件读取完整内容，用 `git diff --no-index -- /dev/null <新文件>` 展示差异（退出码 1 表示有差异），另用 `git diff --no-index --check -- /dev/null <新文件>` 检查格式：退出码 0 或 1 且无格式或命令错误输出才算通过，`--no-index` 的 1 不代表格式错误。只有确认无自定义的配置文件才要求与上游零差异；其余逐项核对保留内容和批准的 hunk。

逐个检查迁移清单中目标文件及映射、文档和章节的路径引用实际存在；剩余旧名命中逐项说明保留原因。批准项完成、用户已有改动保留、所有差异有归属且引用校验通过后，才能报告完成；未决冲突或安装状态仍未知时明确报告部分完成及剩余项。

所有退出路径（包括 `--check`、取消和失败）最后清理临时目录；仅当确认 `SYNC_DIR` 是本次 `mktemp` 创建的路径时执行：

```bash
rm -rf -- "$SYNC_DIR"
```

汇报：上游 version/commit、改动文件、保留的自定义、仍存在的偏差及原因。收尾用一句话提示可用 `docs(agents): 同步 mattpocock/skills 配置至 <version>` 提交；用户未要求时不要自行提交。

## 边界情况

- **未配置项目**：建议先跑 `/setup-matt-pocock-skills`，不要越权初始化。
- **章节缺失但 docs/agents 存在**：按第 4 步补建，摘要需确认。
- **自定义 tracker**：只做点名修改，给模板参照。
- **`AGENTS.md` 是 `CLAUDE.md` 的符号链接**：只编辑一处，不重复写。
- **多上下文仓库**：保留映射及其实际指向的上下文布局，按第 3 步迁移旧文件与引用，不按单上下文改写。
- **上游目录搬迁**：先定位，再比对；找不到就停下报告。
- **网络不可用**：降级本机副本并标注可能过时；无法确认的内容不写入。
