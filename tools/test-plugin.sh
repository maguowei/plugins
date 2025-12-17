#!/bin/bash

# Test a Claude Code plugin

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Print usage
usage() {
    echo "Usage: $0 <plugin-name> [options]"
    echo ""
    echo "Test a Claude Code plugin."
    echo ""
    echo "Options:"
    echo "  -v, --verbose       Verbose output"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 my-plugin                     # Test plugin"
    echo "  $0 my-plugin --verbose           # Test with verbose output"
    exit 1
}

# Test plugin installation
test_installation() {
    local plugin_name="$1"

    print_step "Testing plugin installation..."

    # Check if plugin directory exists
    local plugins_dir="$(get_plugins_dir)"
    local plugin_dir="$plugins_dir/$plugin_name"

    if [ ! -d "$plugin_dir" ]; then
        print_error "Plugin directory not found"
        return 1
    fi

    print_success "Plugin directory exists"
    return 0
}

# Test plugin manifest
test_manifest() {
    local plugin_name="$1"

    print_step "Testing plugin manifest..."

    local plugins_dir="$(get_plugins_dir)"
    local plugin_dir="$plugins_dir/$plugin_name"
    local manifest="$plugin_dir/.claude-plugin/plugin.json"

    if [ ! -f "$manifest" ]; then
        print_error "plugin.json not found"
        return 1
    fi

    # Check required fields
    local required_fields=("name" "description" "version")
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$manifest"; then
            print_error "Missing required field: $field"
            return 1
        fi
    done

    print_success "Plugin manifest is valid"
    return 0
}

# Test plugin extensions
test_extensions() {
    local plugin_name="$1"
    local verbose="$2"

    print_step "Testing plugin extensions..."

    local plugins_dir="$(get_plugins_dir)"
    local plugin_dir="$plugins_dir/$plugin_name"

    local extension_count=0

    # Test commands
    if [ -d "$plugin_dir/commands" ]; then
        local cmd_count=$(find "$plugin_dir/commands" -name "*.md" | wc -l | tr -d ' ')
        if [ "$cmd_count" -gt 0 ]; then
            print_info "Found $cmd_count command(s)"
            ((extension_count++))

            if [ "$verbose" = "1" ]; then
                for cmd_file in "$plugin_dir/commands"/*.md; do
                    if [ -f "$cmd_file" ]; then
                        echo "  - $(basename "$cmd_file")"
                    fi
                done
            fi
        fi
    fi

    # Test agents
    if [ -d "$plugin_dir/agents" ]; then
        local agent_count=$(find "$plugin_dir/agents" -name "*.md" | wc -l | tr -d ' ')
        if [ "$agent_count" -gt 0 ]; then
            print_info "Found $agent_count agent(s)"
            ((extension_count++))

            if [ "$verbose" = "1" ]; then
                for agent_file in "$plugin_dir/agents"/*.md; do
                    if [ -f "$agent_file" ]; then
                        echo "  - $(basename "$agent_file")"
                    fi
                done
            fi
        fi
    fi

    # Test skills
    if [ -d "$plugin_dir/skills" ]; then
        local skill_count=$(find "$plugin_dir/skills" -type d -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
        if [ "$skill_count" -gt 0 ]; then
            print_info "Found $skill_count skill(s)"
            ((extension_count++))

            if [ "$verbose" = "1" ]; then
                for skill_dir in "$plugin_dir/skills"/*; do
                    if [ -d "$skill_dir" ]; then
                        echo "  - $(basename "$skill_dir")"
                    fi
                done
            fi
        fi
    fi

    # Test hooks
    if [ -d "$plugin_dir/hooks" ]; then
        local hook_count=$(find "$plugin_dir/hooks" -name "*.md" | wc -l | tr -d ' ')
        if [ "$hook_count" -gt 0 ]; then
            print_info "Found $hook_count hook(s)"
            ((extension_count++))

            if [ "$verbose" = "1" ]; then
                for hook_file in "$plugin_dir/hooks"/*.md; do
                    if [ -f "$hook_file" ]; then
                        echo "  - $(basename "$hook_file")"
                    fi
                done
            fi
        fi
    fi

    if [ $extension_count -eq 0 ]; then
        print_error "No extensions found"
        return 1
    fi

    print_success "Found $extension_count extension type(s)"
    return 0
}

# Test README
test_readme() {
    local plugin_name="$1"

    print_step "Testing README..."

    local plugins_dir="$(get_plugins_dir)"
    local plugin_dir="$plugins_dir/$plugin_name"

    if [ ! -f "$plugin_dir/README.md" ]; then
        print_error "README.md not found"
        return 1
    fi

    # Check if README has content
    local readme_lines=$(wc -l < "$plugin_dir/README.md" | tr -d ' ')
    if [ "$readme_lines" -lt 5 ]; then
        print_warning "README.md seems empty or incomplete"
    fi

    print_success "README.md exists"
    return 0
}

# Run all tests
run_tests() {
    local plugin_name="$1"
    local verbose="$2"

    local test_count=0
    local pass_count=0

    # Test installation
    ((test_count++))
    if test_installation "$plugin_name"; then
        ((pass_count++))
    fi

    # Test manifest
    ((test_count++))
    if test_manifest "$plugin_name"; then
        ((pass_count++))
    fi

    # Test extensions
    ((test_count++))
    if test_extensions "$plugin_name" "$verbose"; then
        ((pass_count++))
    fi

    # Test README
    ((test_count++))
    if test_readme "$plugin_name"; then
        ((pass_count++))
    fi

    # Print summary
    echo ""
    print_header "Test Summary"

    echo "Total tests: $test_count"
    echo "Passed: $pass_count"
    echo "Failed: $((test_count - pass_count))"

    if [ $pass_count -eq $test_count ]; then
        echo ""
        print_success "✅ All tests PASSED"
        return 0
    else
        echo ""
        print_error "❌ Some tests FAILED"
        return 1
    fi
}

# Main function
main() {
    local plugin_name=""
    local verbose=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=1
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                if [ -z "$plugin_name" ]; then
                    plugin_name="$1"
                else
                    print_error "Unknown option: $1"
                    usage
                fi
                shift
                ;;
        esac
    done

    # Check plugin name
    if [ -z "$plugin_name" ]; then
        print_error "Plugin name is required"
        usage
    fi

    # Check if plugin exists
    if ! plugin_exists "$plugin_name"; then
        print_error "Plugin '$plugin_name' not found"
        exit 1
    fi

    print_header "Testing Plugin: $plugin_name"

    # Run tests
    if run_tests "$plugin_name" "$verbose"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
