#!/bin/bash

# Validate a Claude Code plugin

set -e

# Source common functions and validators
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/validators.sh"

# Print usage
usage() {
    echo "Usage: $0 [plugin-name] [options]"
    echo ""
    echo "Validate a Claude Code plugin."
    echo ""
    echo "Options:"
    echo "  -a, --all           Validate all plugins"
    echo "  -r, --report FILE   Generate validation report"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 my-plugin                     # Validate single plugin"
    echo "  $0 my-plugin -r report.md        # Validate and generate report"
    echo "  $0 --all                         # Validate all plugins"
    exit 1
}

# Main function
main() {
    local plugin_name=""
    local validate_all=0
    local report_file=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                validate_all=1
                shift
                ;;
            -r|--report)
                report_file="$2"
                shift 2
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

    # Validate all plugins
    if [ $validate_all -eq 1 ]; then
        validate_all_plugins
        exit $?
    fi

    # Validate single plugin
    if [ -z "$plugin_name" ]; then
        print_error "Plugin name is required"
        usage
    fi

    # Check if plugin exists
    if ! plugin_exists "$plugin_name"; then
        print_error "Plugin '$plugin_name' not found"
        exit 1
    fi

    local plugins_dir="$(get_plugins_dir)"
    local plugin_dir="$plugins_dir/$plugin_name"

    print_header "Validating Plugin: $plugin_name"

    # Run validation
    if validate_plugin_structure "$plugin_dir"; then
        echo ""
        print_success "✅ Plugin validation PASSED"

        # Generate report if requested
        if [ -n "$report_file" ]; then
            generate_validation_report "$plugin_dir" "$report_file"
        fi

        exit 0
    else
        echo ""
        print_error "❌ Plugin validation FAILED"

        # Generate report if requested
        if [ -n "$report_file" ]; then
            generate_validation_report "$plugin_dir" "$report_file"
        fi

        exit 1
    fi
}

# Run main function
main "$@"
