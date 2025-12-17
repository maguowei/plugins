# 贡献指南

感谢你对 Claude Code Plugins 市场的关注！我们欢迎所有形式的贡献。

## 如何贡献

### 1. 提交插件

如果你开发了一个有用的 Claude Code 插件，欢迎提交到本市场！

**步骤：**

1. Fork 本仓库
2. 在 `plugins/` 目录下创建你的插件目录
3. 确保插件符合规范（见下文）
4. 提交 Pull Request

### 2. 改进现有插件

发现 bug 或有改进建议？

1. 创建 Issue 描述问题或建议
2. Fork 仓库并进行修改
3. 提交 Pull Request

### 3. 完善文档

文档永远可以做得更好！

1. 修正错误或改进说明
2. 添加使用示例
3. 翻译文档

## 插件规范

### 目录结构

每个插件必须包含以下结构：

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # 必需：插件清单
├── README.md                # 必需：插件文档
└── [commands/|agents/|skills/]  # 至少一种扩展类型
```

### Plugin Manifest (plugin.json)

```json
{
  "name": "plugin-name",
  "description": "插件简短描述（100字以内）",
  "version": "1.0.0",
  "author": {
    "name": "作者名称",
    "email": "email@example.com",
    "url": "https://github.com/username"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/username/repo"
  },
  "keywords": ["keyword1", "keyword2"],
  "license": "MIT"
}
```

**必需字段：**
- `name`: 插件名称（小写字母、数字、连字符，与目录名一致）
- `description`: 简短描述
- `version`: 语义化版本号
- `author.name`: 作者名称

**推荐字段：**
- `author.email`: 联系邮箱
- `author.url`: 个人网站或 GitHub
- `repository`: 代码仓库
- `keywords`: 关键词（便于搜索）
- `license`: 开源许可证

### README.md

每个插件的 README.md 应包含：

```markdown
# 插件名称

简短描述

## 功能

- 功能点 1
- 功能点 2

## 安装

\`\`\`bash
/plugin install <plugin-name>
\`\`\`

## 使用方式

详细的使用说明和示例

## 配置（如果需要）

配置选项说明

## 许可证

MIT
```

### Slash Commands 规范

如果插件包含 Slash Commands（`commands/` 目录），每个命令文件应该：

**文件命名：** `command-name.md`

**YAML Frontmatter（可选但推荐）：**

```yaml
---
description: 命令简短描述
allowed-tools: Bash(git*), Read, Write
argument-hint: [参数提示]
model: claude-3-5-haiku-20241022
---
```

**命令内容：**
- 清晰的指令
- 使用示例
- 参数说明

### Agents 规范

Agent 文件应该：

**文件命名：** `agent-name.md`

**YAML Frontmatter：**

```yaml
---
name: agent-name
description: 何时使用此 Agent 的自然语言描述
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: default
---
```

**Agent 系统提示：**
- 清晰定义 Agent 的角色和职责
- 提供详细的工作流程
- 包含必要的约束和要求

### Skills 规范

Skill 应该包含：

**目录结构：**
```
skills/<skill-name>/
├── SKILL.md                # 必需
├── reference.md            # 可选：参考文档
├── examples.md             # 可选：示例
├── scripts/                # 可选：辅助脚本
└── templates/              # 可选：模板文件
```

**SKILL.md Frontmatter：**

```yaml
---
name: skill-name
description: 技能描述，说明何时使用
allowed-tools: Read, Edit, Bash, Grep
---
```

## 代码规范

### 命名规范

- **插件名称：** 小写字母、数字、连字符（如 `smart-git-commit`）
- **Command 文件：** 小写字母、连字符（如 `init-project.md`）
- **Agent 文件：** 小写字母、连字符（如 `code-reviewer.md`）
- **Skill 目录：** 小写字母、连字符（如 `go-react-ddd-init/`）

### Markdown 规范

- 使用中文时遵循中文排版规范
- 中英文之间不需要空格（已经是常见做法）
- 代码块必须指定语言
- 链接使用相对路径

### Git Commit 规范

遵循 Conventional Commits 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型（type）：**
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例：**
```
feat(smart-git-commit): 添加对 monorepo 的支持

- 支持自动识别 monorepo 结构
- 在 commit message 中添加 scope

Closes #123
```

## 提交 Pull Request

### PR 标题

使用清晰的标题，遵循 Conventional Commits 格式：

```
feat: 添加新插件 awesome-plugin
fix(code-reviewer): 修复 Go 检查清单中的错误
docs: 更新快速开始指南
```

### PR 描述

**模板：**

```markdown
## 变更类型
- [ ] 新插件
- [ ] Bug 修复
- [ ] 功能增强
- [ ] 文档更新
- [ ] 其他

## 描述
简要描述你的变更

## 相关 Issue
Closes #123

## 测试
- [ ] 本地测试通过
- [ ] 插件验证通过

## 截图（如适用）
```

### PR 检查清单

提交前确保：

- [ ] 代码符合规范
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] Commit message 符合规范
- [ ] 插件通过验证脚本

## 验证插件

在提交前，使用验证脚本检查插件：

```bash
./tools/validate-plugin.sh plugins/<plugin-name>
```

验证内容包括：
- plugin.json 格式正确
- 必需字段完整
- YAML frontmatter 格式正确
- 目录结构符合规范
- README.md 存在

## 测试

### 本地测试

```bash
# 添加本地市场
/plugin marketplace add /path/to/claude

# 安装你的插件
/plugin install <plugin-name>

# 测试功能
<根据插件类型测试>
```

### 使用测试脚本

```bash
./tools/test-plugin.sh plugins/<plugin-name>
```

## 发布流程

插件版本更新流程：

1. 更新 `plugin.json` 中的 `version`
2. 更新 `README.md` 中的变更日志
3. 创建 git tag
4. 提交 PR

## 获取帮助

如有疑问：

- 查看 [文档](docs/)
- 创建 [Issue](https://github.com/maguowei/claude-plugins/issues)
- 参考现有插件作为示例

## 行为准则

- 尊重他人
- 建设性反馈
- 包容不同观点
- 专注于项目改进

## 许可证

贡献的代码将遵循项目的 MIT 许可证。

---

再次感谢你的贡献！
