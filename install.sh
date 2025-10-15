#!/bin/bash

# org-cloner installer
# Creates/removes symlink to /usr/local/bin/org-cloner

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/org-cloner.sh"
SYMLINK_PATH="/usr/local/bin/org-cloner"

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

check_source() {
    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        log_error "Source script not found: $SOURCE_SCRIPT"
        exit 1
    fi

    if [[ ! -x "$SOURCE_SCRIPT" ]]; then
        log_error "Source script is not executable: $SOURCE_SCRIPT"
        echo "Run: chmod +x $SOURCE_SCRIPT"
        exit 1
    fi
}

check_permissions() {
    if [[ ! -w "$(dirname "$SYMLINK_PATH")" ]]; then
        log_error "No write permission to $(dirname "$SYMLINK_PATH")"
        echo "You may need to run this script with sudo:"
        echo "  sudo $0 $*"
        exit 1
    fi
}

install() {
    log_info "Installing org-cloner..."

    check_source
    check_permissions

    # Check if symlink already exists
    if [[ -L "$SYMLINK_PATH" ]]; then
        local current_target=$(readlink "$SYMLINK_PATH")
        if [[ "$current_target" == "$SOURCE_SCRIPT" ]]; then
            log_warning "org-cloner is already installed and points to the correct location"
            log_info "Symlink: $SYMLINK_PATH → $SOURCE_SCRIPT"
            exit 0
        else
            log_warning "Existing symlink found pointing to: $current_target"
            read -p "Replace with new installation? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
            rm "$SYMLINK_PATH"
        fi
    elif [[ -e "$SYMLINK_PATH" ]]; then
        log_error "A file already exists at $SYMLINK_PATH (not a symlink)"
        log_info "Please remove it manually and try again"
        exit 1
    fi

    # Create symlink
    ln -s "$SOURCE_SCRIPT" "$SYMLINK_PATH"
    log_success "Symlink created: $SYMLINK_PATH → $SOURCE_SCRIPT"
    log_success "Installation complete!"
    echo ""
    log_info "You can now run: org-cloner <command> <organization>"
    log_info "Example: org-cloner list anthropics"
}

uninstall() {
    log_info "Uninstalling org-cloner..."

    check_permissions

    if [[ ! -L "$SYMLINK_PATH" ]]; then
        if [[ -e "$SYMLINK_PATH" ]]; then
            log_error "$SYMLINK_PATH exists but is not a symlink"
            log_info "Manual removal required"
            exit 1
        else
            log_warning "org-cloner is not installed (symlink not found)"
            exit 0
        fi
    fi

    # Check if symlink points to our script
    local current_target=$(readlink "$SYMLINK_PATH")
    if [[ "$current_target" != "$SOURCE_SCRIPT" ]]; then
        log_warning "Symlink points to: $current_target"
        log_warning "Expected: $SOURCE_SCRIPT"
        read -p "Remove anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Uninstallation cancelled"
            exit 0
        fi
    fi

    # Remove symlink
    rm "$SYMLINK_PATH"
    log_success "Symlink removed: $SYMLINK_PATH"
    log_success "Uninstallation complete!"
}

usage() {
    cat << EOF
Usage: $0 [--uninstall]

Install or uninstall the org-cloner command.

Options:
    (no args)      Install org-cloner by creating a symlink to /usr/local/bin
    --uninstall    Remove the org-cloner symlink

Examples:
    $0              # Install
    $0 --uninstall  # Uninstall

EOF
    exit 1
}

main() {
    case "${1:-}" in
        --uninstall)
            uninstall
            ;;
        "")
            install
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
}

main "$@"
