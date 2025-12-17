#!/bin/bash

# Create a new Claude Code plugin with interactive prompts

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Print usage
usage() {
    echo "Usage: $0 [plugin-name]"
    echo ""
    echo "Create a new Claude Code plugin with interactive prompts."
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive mode"
    echo "  $0 my-plugin          # Create plugin with name 'my-plugin'"
    exit 1
}

# Create plugin.json
create_plugin_json() {
    local plugin_dir="$1"
    local plugin_name="$2"
    local description="$3"
    local author_name="$4"
    local author_email="$5"

    local manifest="$plugin_dir/.claude-plugin/plugin.json"

    ensure_dir "$(dirname "$manifest")"

    cat > "$manifest" <<EOF
{
  "name": "$plugin_name",
  "description": "$description",
  "version": "1.0.0",
  "author": {
    "name": "$author_name",
    "email": "$author_email"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/$author_name/claude-plugins"
  },
  "keywords": [],
  "license": "MIT"
}
EOF

    print_success "Created plugin.json"
}

# Create README.md
create_readme() {
    local plugin_dir="$1"
    local plugin_name="$2"
    local description="$3"

    local readme="$plugin_dir/README.md"

    cat > "$readme" <<EOF
# ${plugin_name}

${description}

## 安装

\`\`\`bash
/plugin install ${plugin_name}
\`\`\`

## 使用方式

TODO: 添加使用说明

## 功能特性

- TODO: 列出主要功能

## 配置选项

TODO: 添加配置说明（如果有）

## 示例

TODO: 添加使用示例

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT
EOF

    print_success "Created README.md"
}

# Create slash command
create_command() {
    local plugin_dir="$1"
    local command_name="$2"

    local commands_dir="$plugin_dir/commands"
    ensure_dir "$commands_dir"

    local command_file="$commands_dir/${command_name}.md"

    cat > "$command_file" <<EOF
---
name: $command_name
description: TODO: 添加命令描述
---

# $command_name 命令

TODO: 添加命令的详细说明和使用方式

## 使用示例

\`\`\`bash
/$command_name
\`\`\`

## 参数

TODO: 如果有参数，在这里说明

## 工作流程

1. TODO: 步骤 1
2. TODO: 步骤 2
3. TODO: 步骤 3
EOF

    print_success "Created command: $command_name"
}

# Create agent
create_agent() {
    local plugin_dir="$1"
    local agent_name="$2"

    local agents_dir="$plugin_dir/agents"
    ensure_dir "$agents_dir"

    local agent_file="$agents_dir/${agent_name}.md"

    cat > "$agent_file" <<EOF
---
name: $agent_name
description: TODO: 添加 Agent 描述
---

# $agent_name Agent

你是一个 Claude Code Agent，专门用于 TODO: 添加 Agent 的用途说明。

## 职责

TODO: 列出 Agent 的主要职责

## 工作流程

TODO: 描述 Agent 的工作流程

## 可用工具

你可以使用以下工具：

- \`Bash\`: 执行命令
- \`Read\`: 读取文件
- \`Write\`: 写入文件
- \`Edit\`: 编辑文件
- \`Grep\`: 搜索文件内容
- \`Glob\`: 查找文件

## 输出格式

TODO: 定义 Agent 的输出格式

## 示例

TODO: 添加使用示例
EOF

    print_success "Created agent: $agent_name"
}

# Create skill
create_skill() {
    local plugin_dir="$1"
    local skill_name="$2"

    local skill_dir="$plugin_dir/skills/$skill_name"
    ensure_dir "$skill_dir"

    local skill_file="$skill_dir/SKILL.md"

    cat > "$skill_file" <<EOF
---
name: $skill_name
description: TODO: 添加 Skill 描述
---

# $skill_name Skill

TODO: 添加 Skill 的详细说明

## 功能

TODO: 列出 Skill 提供的功能

## 使用方式

TODO: 说明如何使用这个 Skill

## 输入

TODO: 定义输入格式（如果有）

## 输出

TODO: 定义输出格式

## 示例

TODO: 添加使用示例
EOF

    print_success "Created skill: $skill_name"
}

# Main function
main() {
    print_header "Claude Code Plugin Creator"

    # Get plugin name
    local plugin_name="$1"

    if [ -z "$plugin_name" ]; then
        while true; do
            ask_input "Plugin name (lowercase-with-hyphens)" "" plugin_name

            if validate_plugin_name "$plugin_name"; then
                break
            fi
        done
    else
        if ! validate_plugin_name "$plugin_name"; then
            exit 1
        fi
    fi

    # Check if plugin already exists
    if plugin_exists "$plugin_name"; then
        print_error "Plugin '$plugin_name' already exists"
        exit 1
    fi

    # Get plugin details
    local description
    ask_input "Plugin description" "A Claude Code plugin" description

    local author_name
    ask_input "Author name" "$(git config user.name 2>/dev/null || echo 'Your Name')" author_name

    local author_email
    ask_input "Author email" "$(git config user.email 2>/dev/null || echo 'you@example.com')" author_email

    # Ask for extension types
    echo ""
    print_info "Select extension types to include:"

    local include_command=0
    if ask_yes_no "Include Slash Command?" "n"; then
        include_command=1
    fi

    local include_agent=0
    if ask_yes_no "Include Agent?" "n"; then
        include_agent=1
    fi

    local include_skill=0
    if ask_yes_no "Include Skill?" "n"; then
        include_skill=1
    fi

    # Validate at least one extension type
    if [ $include_command -eq 0 ] && [ $include_agent -eq 0 ] && [ $include_skill -eq 0 ]; then
        print_error "You must include at least one extension type"
        exit 1
    fi

    # Create plugin directory
    local plugins_dir="$(get_plugins_dir)"
    local plugin_dir="$plugins_dir/$plugin_name"

    print_step "Creating plugin directory: $plugin_dir"
    ensure_dir "$plugin_dir"

    # Create plugin.json
    create_plugin_json "$plugin_dir" "$plugin_name" "$description" "$author_name" "$author_email"

    # Create README
    create_readme "$plugin_dir" "$plugin_name" "$description"

    # Create extension files
    if [ $include_command -eq 1 ]; then
        local command_name
        ask_input "Command name" "$plugin_name" command_name
        create_command "$plugin_dir" "$command_name"
    fi

    if [ $include_agent -eq 1 ]; then
        local agent_name
        ask_input "Agent name" "${plugin_name}-agent" agent_name
        create_agent "$plugin_dir" "$agent_name"
    fi

    if [ $include_skill -eq 1 ]; then
        local skill_name
        ask_input "Skill name" "${plugin_name}-skill" skill_name
        create_skill "$plugin_dir" "$skill_name"
    fi

    # Success message
    echo ""
    print_header "Plugin Created Successfully!"

    echo "Plugin: $plugin_name"
    echo "Location: $plugin_dir"
    echo ""

    print_info "Next steps:"
    echo "  1. cd $plugin_dir"
    echo "  2. Edit the files to implement your plugin"
    echo "  3. Run: ../tools/validate-plugin.sh $plugin_name"
    echo "  4. Install: /plugin install $plugin_name"
    echo ""

    print_success "Happy coding!"
}

# Run main function
main "$@"
