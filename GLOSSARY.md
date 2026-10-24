# maguowei/plugins

Claude Code 插件市场的单一上下文：每个插件是一组 skill，供 agent 在用户项目中执行工作流。

## Language

### Go 项目基线

**codego 基线**:
codego 当前模板对 Go 项目技术栈、目录布局、分层、命名、质量门禁与 agent 资产的约定；是所有派生内容的唯一事实源。
_Avoid_: 共享规范、标准模板、最佳实践

**基线摘要**:
本仓库 skill 中以文字提炼的 codego 基线原则与选型，不逐字复制模板文件；标注提炼来源（codego commit 与日期），与 codego 冲突时以 codego 为准。
_Avoid_: 基线快照、规范文档、第二基线

**项目形态**:
基线摘要覆盖的 Go 项目类型，只有 **HTTP 服务** 与 **CLI** 两种；认证、异步事件、部署编排等能力不在摘要的落地范围内。
_Avoid_: preset、模板类型

**初始化**:
在不运行 codego 脚手架的前提下，由 agent 按基线摘要为新项目写出骨架与 agent 资产。
_Avoid_: 脚手架生成、scaffold

**审计**:
对现有 Go 项目按基线摘要只读检查并输出分级建议报告，不修改任何文件。
_Avoid_: 检查修复、迁移、升级
