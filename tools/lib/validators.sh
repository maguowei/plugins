#!/bin/bash

# Validation functions for Claude Code plugins

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Validate plugin.json exists
validate_plugin_json_exists() {
    local plugin_dir="$1"
    local manifest="$plugin_dir/.claude-plugin/plugin.json"

    if [ ! -f "$manifest" ]; then
        print_error "Missing plugin.json at $manifest"
        return 1
    fi

    return 0
}

# Validate plugin.json is valid JSON
validate_plugin_json_format() {
    local plugin_dir="$1"
    local manifest="$plugin_dir/.claude-plugin/plugin.json"

    # Basic JSON validation (check for balanced braces)
    local open_braces=$(grep -o '{' "$manifest" | wc -l)
    local close_braces=$(grep -o '}' "$manifest" | wc -l)

    if [ "$open_braces" -ne "$close_braces" ]; then
        print_error "Invalid JSON format in plugin.json (unbalanced braces)"
        return 1
    fi

    # Check for required fields
    local required_fields=("name" "description" "version")
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$manifest"; then
            print_error "Missing required field '$field' in plugin.json"
            return 1
        fi
    done

    return 0
}

# Validate plugin name matches directory name
validate_plugin_name_matches_dir() {
    local plugin_dir="$1"
    local manifest="$plugin_dir/.claude-plugin/plugin.json"

    local plugin_name=$(get_plugin_name "$plugin_dir")
    local manifest_name=$(read_json_value "$manifest" "name")

    if [ "$plugin_name" != "$manifest_name" ]; then
        print_error "Plugin name mismatch: directory='$plugin_name' manifest='$manifest_name'"
        return 1
    fi

    return 0
}

# Validate plugin has at least one extension type
validate_has_extensions() {
    local plugin_dir="$1"
    local has_extension=0

    # Check for commands
    if [ -d "$plugin_dir/commands" ] && [ -n "$(ls -A "$plugin_dir/commands" 2>/dev/null)" ]; then
        has_extension=1
    fi

    # Check for agents
    if [ -d "$plugin_dir/agents" ] && [ -n "$(ls -A "$plugin_dir/agents" 2>/dev/null)" ]; then
        has_extension=1
    fi

    # Check for skills
    if [ -d "$plugin_dir/skills" ] && [ -n "$(ls -A "$plugin_dir/skills" 2>/dev/null)" ]; then
        has_extension=1
    fi

    # Check for hooks
    if [ -d "$plugin_dir/hooks" ] && [ -n "$(ls -A "$plugin_dir/hooks" 2>/dev/null)" ]; then
        has_extension=1
    fi

    if [ $has_extension -eq 0 ]; then
        print_error "Plugin must have at least one extension type (commands, agents, skills, or hooks)"
        return 1
    fi

    return 0
}

# Validate README exists
validate_readme_exists() {
    local plugin_dir="$1"

    if [ ! -f "$plugin_dir/README.md" ]; then
        print_error "Missing README.md"
        return 1
    fi

    return 0
}

# Validate Markdown YAML frontmatter
validate_markdown_frontmatter() {
    local md_file="$1"
    local file_type="$2" # command, agent, skill, hook

    # Check if file starts with ---
    if ! head -1 "$md_file" | grep -q '^---$'; then
        print_error "Missing YAML frontmatter in $md_file"
        return 1
    fi

    # Extract frontmatter (between first two --- lines)
    local frontmatter=$(sed -n '/^---$/,/^---$/p' "$md_file" | sed '1d;$d')

    # Check for required fields based on type
    case "$file_type" in
        command)
            if ! echo "$frontmatter" | grep -q '^name:'; then
                print_error "Missing 'name' field in command frontmatter: $md_file"
                return 1
            fi
            ;;
        agent)
            if ! echo "$frontmatter" | grep -q '^name:'; then
                print_error "Missing 'name' field in agent frontmatter: $md_file"
                return 1
            fi
            ;;
        skill)
            # Skills use SKILL.md, check in parent directory
            if [ "$(basename "$md_file")" = "SKILL.md" ]; then
                if ! echo "$frontmatter" | grep -q '^name:'; then
                    print_error "Missing 'name' field in skill frontmatter: $md_file"
                    return 1
                fi
            fi
            ;;
    esac

    return 0
}

# Validate all commands
validate_commands() {
    local plugin_dir="$1"
    local commands_dir="$plugin_dir/commands"

    if [ ! -d "$commands_dir" ]; then
        return 0 # No commands directory is okay
    fi

    local error_count=0

    for cmd_file in "$commands_dir"/*.md; do
        if [ -f "$cmd_file" ]; then
            print_step "Validating command: $(basename "$cmd_file")"

            if ! validate_markdown_frontmatter "$cmd_file" "command"; then
                ((error_count++))
            fi
        fi
    done

    if [ $error_count -gt 0 ]; then
        print_error "Found $error_count error(s) in commands"
        return 1
    fi

    return 0
}

# Validate all agents
validate_agents() {
    local plugin_dir="$1"
    local agents_dir="$plugin_dir/agents"

    if [ ! -d "$agents_dir" ]; then
        return 0 # No agents directory is okay
    fi

    local error_count=0

    for agent_file in "$agents_dir"/*.md; do
        if [ -f "$agent_file" ]; then
            print_step "Validating agent: $(basename "$agent_file")"

            if ! validate_markdown_frontmatter "$agent_file" "agent"; then
                ((error_count++))
            fi
        fi
    done

    if [ $error_count -gt 0 ]; then
        print_error "Found $error_count error(s) in agents"
        return 1
    fi

    return 0
}

# Validate all skills
validate_skills() {
    local plugin_dir="$1"
    local skills_dir="$plugin_dir/skills"

    if [ ! -d "$skills_dir" ]; then
        return 0 # No skills directory is okay
    fi

    local error_count=0

    for skill_dir in "$skills_dir"/*; do
        if [ -d "$skill_dir" ]; then
            local skill_file="$skill_dir/SKILL.md"

            if [ ! -f "$skill_file" ]; then
                print_error "Missing SKILL.md in $(basename "$skill_dir")"
                ((error_count++))
                continue
            fi

            print_step "Validating skill: $(basename "$skill_dir")"

            if ! validate_markdown_frontmatter "$skill_file" "skill"; then
                ((error_count++))
            fi
        fi
    done

    if [ $error_count -gt 0 ]; then
        print_error "Found $error_count error(s) in skills"
        return 1
    fi

    return 0
}

# Validate plugin structure
validate_plugin_structure() {
    local plugin_dir="$1"

    print_step "Validating plugin structure..."

    local error_count=0

    # Check .claude-plugin directory
    if [ ! -d "$plugin_dir/.claude-plugin" ]; then
        print_error "Missing .claude-plugin directory"
        ((error_count++))
    fi

    # Validate plugin.json
    if ! validate_plugin_json_exists "$plugin_dir"; then
        ((error_count++))
    elif ! validate_plugin_json_format "$plugin_dir"; then
        ((error_count++))
    elif ! validate_plugin_name_matches_dir "$plugin_dir"; then
        ((error_count++))
    fi

    # Validate has extensions
    if ! validate_has_extensions "$plugin_dir"; then
        ((error_count++))
    fi

    # Validate README
    if ! validate_readme_exists "$plugin_dir"; then
        ((error_count++))
    fi

    # Validate commands
    if ! validate_commands "$plugin_dir"; then
        ((error_count++))
    fi

    # Validate agents
    if ! validate_agents "$plugin_dir"; then
        ((error_count++))
    fi

    # Validate skills
    if ! validate_skills "$plugin_dir"; then
        ((error_count++))
    fi

    if [ $error_count -gt 0 ]; then
        print_error "Plugin validation failed with $error_count error(s)"
        return 1
    fi

    print_success "Plugin structure validation passed"
    return 0
}

# Validate all plugins in marketplace
validate_all_plugins() {
    local plugins_dir="$(get_plugins_dir)"

    if [ ! -d "$plugins_dir" ]; then
        print_error "Plugins directory not found: $plugins_dir"
        return 1
    fi

    print_header "Validating All Plugins"

    local plugin_count=0
    local error_count=0

    for plugin_dir in "$plugins_dir"/*; do
        if [ -d "$plugin_dir" ]; then
            local plugin_name=$(get_plugin_name "$plugin_dir")

            echo ""
            print_info "Validating plugin: $plugin_name"
            echo ""

            if validate_plugin_structure "$plugin_dir"; then
                print_success "$plugin_name: PASSED"
            else
                print_error "$plugin_name: FAILED"
                ((error_count++))
            fi

            ((plugin_count++))
        fi
    done

    echo ""
    print_header "Validation Summary"

    echo "Total plugins: $plugin_count"
    echo "Passed: $((plugin_count - error_count))"
    echo "Failed: $error_count"

    if [ $error_count -gt 0 ]; then
        return 1
    fi

    return 0
}

# Generate validation report
generate_validation_report() {
    local plugin_dir="$1"
    local output_file="$2"

    {
        echo "# Plugin Validation Report"
        echo ""
        echo "Plugin: $(get_plugin_name "$plugin_dir")"
        echo "Date: $(get_timestamp)"
        echo ""
        echo "## Validation Results"
        echo ""

        if validate_plugin_structure "$plugin_dir" >/dev/null 2>&1; then
            echo "**Status:** ✅ PASSED"
        else
            echo "**Status:** ❌ FAILED"
        fi

        echo ""
        echo "## Details"
        echo ""

        # Run validation and capture output
        validate_plugin_structure "$plugin_dir" 2>&1

    } > "$output_file"

    print_success "Validation report generated: $output_file"
}
