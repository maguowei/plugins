#!/bin/bash

# Common utility functions for Claude Code plugin tools

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_step() {
    echo -e "${CYAN}→${NC} $1"
}

print_header() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════${NC}"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required commands
check_required_commands() {
    local commands=("$@")
    local missing=()

    for cmd in "${commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing[*]}"
        return 1
    fi

    return 0
}

# Get project root directory
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "$script_dir/../.." && pwd)"
}

# Get plugins directory
get_plugins_dir() {
    echo "$(get_project_root)/plugins"
}

# Check if directory is a valid plugin
is_valid_plugin_dir() {
    local plugin_dir="$1"

    if [ ! -d "$plugin_dir" ]; then
        return 1
    fi

    if [ ! -f "$plugin_dir/.claude-plugin/plugin.json" ]; then
        return 1
    fi

    return 0
}

# Get plugin name from directory
get_plugin_name() {
    local plugin_dir="$1"
    basename "$plugin_dir"
}

# List all plugins
list_plugins() {
    local plugins_dir="$(get_plugins_dir)"

    if [ ! -d "$plugins_dir" ]; then
        return 0
    fi

    for dir in "$plugins_dir"/*; do
        if is_valid_plugin_dir "$dir"; then
            get_plugin_name "$dir"
        fi
    done
}

# Count plugins
count_plugins() {
    list_plugins | wc -l | tr -d ' '
}

# Read JSON value using grep and sed (no jq dependency)
read_json_value() {
    local json_file="$1"
    local key="$2"

    if [ ! -f "$json_file" ]; then
        return 1
    fi

    # Simple JSON extraction (works for simple key-value pairs)
    grep "\"$key\"" "$json_file" | head -1 | sed -E 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/'
}

# Create directory if not exists
ensure_dir() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "Created directory: $dir"
    fi
}

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"

    local prompt
    if [ "$default" = "y" ]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        read -p "$question $prompt " yn
        yn=${yn:-$default}

        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Ask for input with default value
ask_input() {
    local question="$1"
    local default="$2"
    local var_name="$3"

    if [ -n "$default" ]; then
        read -p "$question [$default]: " value
        value=${value:-$default}
    else
        read -p "$question: " value
    fi

    eval "$var_name='$value'"
}

# Validate plugin name
validate_plugin_name() {
    local name="$1"

    # Must start with letter, contain only lowercase letters, numbers, and hyphens
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        print_error "Invalid plugin name. Must start with lowercase letter and contain only lowercase letters, numbers, and hyphens."
        return 1
    fi

    # Must not be empty
    if [ -z "$name" ]; then
        print_error "Plugin name cannot be empty."
        return 1
    fi

    # Must not be too long
    if [ ${#name} -gt 50 ]; then
        print_error "Plugin name too long (max 50 characters)."
        return 1
    fi

    return 0
}

# Check if plugin exists
plugin_exists() {
    local plugin_name="$1"
    local plugins_dir="$(get_plugins_dir)"

    is_valid_plugin_dir "$plugins_dir/$plugin_name"
}

# Get file extension
get_file_extension() {
    local filename="$1"
    echo "${filename##*.}"
}

# Get file name without extension
get_file_basename() {
    local filename="$1"
    local basename="${filename##*/}"
    echo "${basename%.*}"
}

# Trim whitespace
trim() {
    local var="$1"
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# Convert string to lowercase
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
to_uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Generate timestamp
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Get current date
get_date() {
    date +"%Y-%m-%d"
}

# Exit with error message
exit_with_error() {
    print_error "$1"
    exit 1
}

# Exit with success message
exit_with_success() {
    print_success "$1"
    exit 0
}
