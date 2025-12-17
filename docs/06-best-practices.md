# Best Practices - 最佳实践指南

Claude Code 插件开发的最佳实践，基于实际项目经验总结。

## 概述

本指南总结了开发高质量 Claude Code 插件的最佳实践，包括：

- 🎯 **技术选型**：如何选择合适的扩展类型
- 📝 **文档编写**：如何编写清晰的文档
- 🏗️ **架构设计**：如何组织插件结构
- ✅ **质量保证**：如何确保插件质量
- 🚀 **用户体验**：如何提升用户体验

## 技术选型

### 选择合适的扩展类型

根据需求选择最合适的扩展类型组合：

#### Slash Command

**适用场景：**
- 需要显式触发的操作
- 接收用户参数
- 提供清晰的入口点

**示例：**
- `/commit` - Git 提交
- `/init-project` - 项目初始化
- `/deploy` - 部署应用

**最佳实践：**
```markdown
✅ 好：命令名称简短、直观
/commit
/review
/deploy

❌ 差：命令名称过长或不清晰
/create-a-git-commit-with-conventional-format
/do-review
```

#### Agent

**适用场景：**
- 复杂的多步骤任务
- 需要独立上下文
- 自动化任务

**示例：**
- Commit Assistant - 智能提交
- Code Reviewer - 代码审查
- Bug Fixer - 自动修复 Bug

**最佳实践：**
```markdown
✅ 好：清晰的职责和工作流程
## 职责
- 分析代码变更
- 生成 commit message

## 工作流程
1. 执行 git status
2. 分析变更
3. 生成 message

❌ 差：职责不清晰
帮助用户处理各种 git 相关的事情
```

#### Skill

**适用场景：**
- 可复用的能力
- 组织复杂资源
- 模块化逻辑

**示例：**
- Review Checklist - 审查清单
- Project Templates - 项目模板
- Code Generators - 代码生成器

**最佳实践：**
```markdown
✅ 好：模块化组织
skills/review-checklist/
├── SKILL.md
├── checklists/
│   ├── go-checklist.md
│   ├── typescript-checklist.md
│   └── security-checklist.md
└── templates/
    └── report-template.md

❌ 差：所有内容放在一个文件中
skills/review-checklist/
└── SKILL.md (5000 行)
```

### 组合使用

最强大的插件通常组合使用多种扩展类型：

| 组合 | 适用场景 | 示例 |
|------|---------|------|
| Command + Agent | 用户触发 + 智能处理 | Smart Git Commit |
| Agent + Skill | 自动触发 + 模块化资源 | Code Reviewer |
| Command + Skill | 用户触发 + 复杂逻辑 | Full-Stack Initializer |

## 文档编写

### README.md 结构

完整的 README.md 应该包含：

```markdown
# 插件名称

简短的描述（一句话）

## 概述

详细介绍插件的功能和特性（带 emoji）

## 安装

\`\`\`bash
/plugin install plugin-name
\`\`\`

## 使用方式

### 基本使用

简单的使用示例

### 高级用法

更复杂的使用场景

## 配置选项

列出所有配置选项

## 使用示例

提供实际的使用示例

## 故障排除

常见问题和解决方案

## 技术实现

（可选）技术细节

## 贡献

欢迎贡献

## 许可证

MIT
```

### 代码示例

**最佳实践：**

```markdown
✅ 好：提供完整、可运行的示例
\`\`\`bash
# 初始化项目
/init-project my-app

# 回答配置问题
数据库：PostgreSQL
WebSocket：是
认证：JWT
\`\`\`

❌ 差：不完整或不清楚的示例
\`\`\`
使用 /init-project 命令
\`\`\`
```

### 使用 Emoji

适当使用 emoji 可以提升可读性：

```markdown
✅ 好：功能列表使用 emoji
- 🚀 **快速初始化**：一键创建项目
- 🔒 **安全检查**：基于 OWASP Top 10
- 📊 **详细报告**：结构化审查报告

❌ 差：过度使用 emoji
🎉🎉🎉 欢迎使用我的插件 🎉🎉🎉
这是一个 😎 超级酷 😎 的插件
```

## 架构设计

### 目录结构

保持清晰的目录结构：

```
✅ 好：清晰的组织
plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/           # 所有命令
│   ├── command1.md
│   └── command2.md
├── agents/             # 所有 Agent
│   ├── agent1.md
│   └── agent2.md
├── skills/             # 所有 Skill
│   └── skill1/
│       ├── SKILL.md
│       └── templates/
└── README.md

❌ 差：混乱的结构
plugins/my-plugin/
├── plugin.json
├── command.md
├── agent.md
├── skill.md
├── template1.md
├── template2.md
└── readme.txt
```

### 文件命名

使用一致的命名规范：

```
✅ 好：清晰、一致的命名
commit.md              # Slash Command
commit-assistant.md    # Agent
commit-message-template.md  # Template

❌ 差：不一致或不清晰的命名
cmd.md
agent_1.md
template.txt
```

### 模块化

将大的功能拆分为小的模块：

```markdown
✅ 好：每个 checklist 单独一个文件
skills/review-checklist/
└── checklists/
    ├── go-checklist.md        (200 行)
    ├── typescript-checklist.md (180 行)
    ├── react-checklist.md     (150 行)
    └── security-checklist.md  (300 行)

❌ 差：所有内容在一个文件
skills/review-checklist/
└── SKILL.md (2000 行，包含所有 checklist)
```

## Agent 设计

### System Prompt 编写

**清晰的身份定义：**

```markdown
✅ 好：
你是一个 Claude Code Agent，专门用于代码审查。
你的职责是检查代码质量、安全性和性能问题。

❌ 差：
你是一个帮助用户的助手。
```

**详细的工作流程：**

```markdown
✅ 好：
## 工作流程

1. **分析文件**
   - 使用 Read 工具读取变更的文件
   - 识别文件类型（Go/TypeScript/React）

2. **加载 Checklist**
   - 根据文件类型加载对应的 checklist
   - 同时加载安全 checklist

3. **逐项检查**
   - 代码质量
   - 安全性
   - 性能

4. **生成报告**
   - 按严重性排序问题
   - 提供具体的修复建议

❌ 差：
根据代码内容进行审查。
```

**明确的输出要求：**

```markdown
✅ 好：
## 输出格式

生成 Markdown 格式的审查报告：

\`\`\`markdown
# 代码审查报告

## 概述
- 变更文件：X 个
- 总体评分：⭐⭐⭐⭐

## 发现的问题

### 🔴 Critical
...

### 🟡 Medium
...
\`\`\`

❌ 差：
输出审查结果。
```

### 工具使用

**最佳实践：**

```markdown
✅ 好：明确说明可用工具和用途
## 可用工具

- \`Read\`: 读取文件内容
  - 用于读取变更的代码文件
- \`Grep\`: 搜索代码
  - 用于查找特定模式
- \`Bash\`: 执行命令
  - 用于执行 git status, git diff

❌ 差：
你可以使用各种工具。
```

### 错误处理

在 Agent 中考虑错误情况：

```markdown
✅ 好：
## 错误处理

1. **文件不存在**
   - 提示用户文件路径可能不正确
   - 建议使用 Glob 工具查找文件

2. **git 命令失败**
   - 检查是否在 git 仓库中
   - 提示用户初始化 git 仓库

3. **配置缺失**
   - 使用默认配置
   - 提示用户可以自定义配置

❌ 差：
（没有错误处理说明）
```

## Skill 设计

### 模板系统

**变量命名：**

```markdown
✅ 好：清晰、大写的变量名
{{PROJECT_NAME}}
{{DATABASE_TYPE}}
{{ENABLE_AUTH}}

❌ 差：不清晰或不一致的变量名
{{name}}
{{db}}
{{auth_enabled}}
```

**条件逻辑：**

```markdown
✅ 好：清晰的条件结构
{{#if ENABLE_AUTH}}
# JWT 配置
JWT_SECRET={{JWT_SECRET}}
JWT_EXPIRATION=24h
{{/if}}

❌ 差：复杂的嵌套条件
{{#if A}}
  {{#if B}}
    {{#if C}}
      ...
    {{/if}}
  {{/if}}
{{/if}}
```

### 文档组织

Skill 应该包含清晰的文档：

```markdown
✅ 好：
skills/project-init/
├── SKILL.md              # 主文档
├── templates/            # 模板文件
│   └── ...
└── docs/                 # 详细文档
    ├── architecture.md   # 架构说明
    └── getting-started.md # 快速开始

❌ 差：
skills/project-init/
└── SKILL.md (包含所有内容)
```

## 质量保证

### 验证检查

在发布前运行所有验证：

```bash
# 验证插件结构
./tools/validate-plugin.sh my-plugin

# 测试插件
./tools/test-plugin.sh my-plugin

# 生成报告
./tools/validate-plugin.sh my-plugin --report report.md
```

### 测试场景

测试多种使用场景：

**✅ 好：全面的测试**
- 正常使用场景
- 边界情况
- 错误情况
- 不同配置选项
- 与其他插件的兼容性

**❌ 差：仅测试正常情况**
- 只测试基本功能
- 不测试错误处理

### 代码审查

请他人审查你的插件：

- 文档是否清晰？
- 使用是否直观？
- 是否有遗漏的功能？
- 是否有安全问题？

## 用户体验

### 交互式确认

对重要操作提供确认：

```markdown
✅ 好：
生成的 commit message：

\`\`\`
feat(api): add user authentication endpoint

Implement JWT-based authentication with login and token refresh.
\`\`\`

是否确认提交？[y/N]

❌ 差：
直接执行 git commit（没有确认）
```

### 进度提示

对耗时操作显示进度：

```markdown
✅ 好：
→ 步骤 1/5: 创建项目结构...
→ 步骤 2/5: 生成后端代码...
→ 步骤 3/5: 生成前端代码...
→ 步骤 4/5: 安装依赖...
→ 步骤 5/5: 初始化 git 仓库...
✓ 项目创建成功！

❌ 差：
（长时间没有输出，用户不知道发生了什么）
```

### 错误消息

提供清晰的错误消息和解决方案：

```markdown
✅ 好：
❌ 错误：项目目录已存在

目录 '/path/to/my-app' 已存在。

解决方案：
1. 使用不同的项目名称
2. 删除现有目录：rm -rf /path/to/my-app
3. 或取消操作

❌ 差：
Error: directory exists
```

### 输出格式

使用一致的输出格式：

```markdown
✅ 好：使用 Unicode 符号
✓ 成功：文件已创建
→ 步骤 1: 处理中...
ℹ 提示：可以使用 --help 查看帮助
⚠ 警告：这个操作不可逆
❌ 错误：文件不存在

❌ 差：不一致的格式
Success: file created
[INFO] Step 1...
WARNING: cannot undo
ERROR: file not found
```

## 性能优化

### 减少工具调用

合并可以一起执行的操作：

```markdown
✅ 好：一次调用完成
Bash: git status && git diff --staged

❌ 差：多次调用
Bash: git status
Bash: git diff --staged
```

### 缓存结果

避免重复读取相同文件：

```markdown
✅ 好：
1. Read: file.go
2. 分析内容
3. 使用已读取的内容

❌ 差：
1. Read: file.go
2. 分析内容
3. Read: file.go（再次读取）
4. 处理内容
```

### 使用合适的模型

根据任务选择模型：

```yaml
---
name: simple-task
model: haiku  # 简单任务使用 haiku
---
```

## 安全性

### 输入验证

验证所有用户输入：

```markdown
✅ 好：
## 输入验证

1. 项目名称
   - 只允许字母、数字、连字符
   - 长度：1-50 字符
   - 不允许特殊字符

2. 路径
   - 检查路径是否存在
   - 确保不在系统目录

❌ 差：
（直接使用用户输入，不验证）
```

### 敏感信息

不要在代码中包含敏感信息：

```markdown
✅ 好：
# .env.example
JWT_SECRET=your-secret-key-change-this
DB_PASSWORD=your-password

❌ 差：
# config.yaml
jwt_secret: "actual-secret-key-123456"
db_password: "production-password"
```

### 权限检查

对危险操作进行权限检查：

```markdown
✅ 好：
在删除文件前：
1. 确认用户真的想删除
2. 显示将要删除的文件列表
3. 要求二次确认

❌ 差：
直接执行 rm -rf（没有确认）
```

## 版本控制

### Git Commit 规范

使用 Conventional Commits：

```bash
✅ 好：
feat(auth): add JWT authentication
fix(ui): resolve button alignment issue
docs(readme): update installation guide

❌ 差：
update code
fix bug
changes
```

### 语义化版本

正确使用语义化版本：

```json
✅ 好：
{
  "version": "1.0.0"    // 初始发布
}
{
  "version": "1.1.0"    // 添加新功能（向后兼容）
}
{
  "version": "1.1.1"    // Bug 修复
}
{
  "version": "2.0.0"    // 不兼容的变更
}

❌ 差：
{
  "version": "1"        // 不完整
}
{
  "version": "v1.0.0"   // 不要加 'v' 前缀
}
```

### Changelog

维护清晰的变更日志：

```markdown
✅ 好：
# Changelog

## [1.1.0] - 2024-01-15

### Added
- 新增 WebSocket 支持
- 添加配置文件验证

### Fixed
- 修复模板变量替换问题

### Changed
- 更新依赖版本

❌ 差：
# Changes

v1.1.0: added some features and fixed bugs
```

## 社区参与

### 响应 Issue

及时响应用户的问题：

- 24-48 小时内回复
- 提供清晰的解答
- 如果是 bug，说明修复计划

### 接受贡献

欢迎社区贡献：

- 提供贡献指南
- Code review 要建设性
- 感谢贡献者

### 文档更新

保持文档最新：

- 新功能要更新文档
- 修复文档中的错误
- 添加更多示例

## 检查清单

发布前的最终检查：

### 代码质量
- [ ] 所有功能正常工作
- [ ] 没有已知 bug
- [ ] 代码结构清晰
- [ ] 错误处理完善

### 文档
- [ ] README.md 完整
- [ ] 使用示例清晰
- [ ] API 文档准确
- [ ] 故障排除部分完善

### 测试
- [ ] 通过验证工具检查
- [ ] 测试所有功能
- [ ] 测试边界情况
- [ ] 测试错误处理

### 元数据
- [ ] plugin.json 正确
- [ ] 版本号正确
- [ ] 许可证信息正确
- [ ] 作者信息完整

### 用户体验
- [ ] 命令名称直观
- [ ] 输出格式一致
- [ ] 错误消息清晰
- [ ] 提供交互确认

## 参考资源

### 官方文档
- [Claude Code 文档](https://docs.anthropic.com/claude/docs)
- [Claude API 文档](https://docs.anthropic.com/claude/reference)

### 规范
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)

### 示例插件
- [Smart Git Commit](../plugins/smart-git-commit/)
- [Code Reviewer](../plugins/code-reviewer/)
- [Full-Stack Initializer](../plugins/fullstack-init/)

## 总结

遵循这些最佳实践可以帮助你：

- ✅ 开发高质量的插件
- ✅ 提供良好的用户体验
- ✅ 易于维护和扩展
- ✅ 获得社区认可

记住：**简单、清晰、有用**是好插件的核心。

## 贡献

欢迎补充更多最佳实践！请提交 PR。

## 许可证

MIT
