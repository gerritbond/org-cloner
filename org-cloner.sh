#!/bin/bash

# org-cloner - GitHub Organization Repository Manager
# Manages listing, cloning, and syncing repositories for a GitHub organization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
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

# Function to check if gh CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        echo "Please install it from: https://cli.github.com/"
        exit 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub CLI"
        echo "Please run: gh auth login"
        exit 1
    fi
}

# Function to list all public repositories for an organization
list_repos() {
    local org="$1"

    log_info "Fetching public repositories for organization: $org"

    # Get all public repos using gh CLI
    gh repo list "$org" --limit 1000 --json name,url,isPrivate --jq '.[] | select(.isPrivate == false) | "\(.name)\t\(.url)"' | while IFS=$'\t' read -r name url; do
        echo "  • $name - $url"
    done
}

# Function to find the org directory in the current path
find_org_in_path() {
    local org="$1"
    local current_dir="$PWD"

    # Check each component of the current path
    while [[ "$current_dir" != "/" ]]; do
        if [[ "$(basename "$current_dir")" == "$org" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    return 1
}

# Function to clone all repositories
clone_repos() {
    local org="$1"
    local target_dir

    # Check if org name is already in the path
    if target_dir=$(find_org_in_path "$org"); then
        log_info "Found '$org' in path: $target_dir"
        cd "$target_dir"
    else
        # Create org directory in current location
        target_dir="$PWD/$org"
        log_info "Creating directory: $target_dir"
        mkdir -p "$target_dir"
        cd "$target_dir"
    fi

    log_info "Cloning repositories to: $PWD"

    # Get all public repos
    local repos=$(gh repo list "$org" --limit 1000 --json name,isPrivate --jq '.[] | select(.isPrivate == false) | .name')

    if [[ -z "$repos" ]]; then
        log_warning "No public repositories found for organization: $org"
        return
    fi

    local count=0
    local skipped=0

    while IFS= read -r repo; do
        if [[ -d "$repo" ]]; then
            log_warning "Repository already exists, skipping: $repo"
            ((skipped++))
        else
            log_info "Cloning: $repo"
            if gh repo clone "$org/$repo"; then
                log_success "Cloned: $repo"
                ((count++))
            else
                log_error "Failed to clone: $repo"
            fi
        fi
    done <<< "$repos"

    echo ""
    log_success "Cloning complete: $count new, $skipped skipped"
}

# Function to sync repositories (pull existing, clone new)
sync_repos() {
    local org="$1"
    local target_dir

    # Check if org name is already in the path
    if target_dir=$(find_org_in_path "$org"); then
        log_info "Found '$org' in path: $target_dir"
        cd "$target_dir"
    else
        # Create org directory in current location
        target_dir="$PWD/$org"
        log_info "Creating directory: $target_dir"
        mkdir -p "$target_dir"
        cd "$target_dir"
    fi

    log_info "Syncing repositories in: $PWD"

    # Get all public repos
    local repos=$(gh repo list "$org" --limit 1000 --json name,isPrivate --jq '.[] | select(.isPrivate == false) | .name')

    if [[ -z "$repos" ]]; then
        log_warning "No public repositories found for organization: $org"
        return
    fi

    local cloned=0
    local pulled=0
    local errors=0

    while IFS= read -r repo; do
        if [[ -d "$repo" ]]; then
            # Repository exists, pull changes
            log_info "Pulling updates: $repo"
            if (cd "$repo" && git pull); then
                log_success "Updated: $repo"
                ((pulled++))
            else
                log_error "Failed to pull: $repo"
                ((errors++))
            fi
        else
            # Repository doesn't exist, clone it
            log_info "Cloning new repository: $repo"
            if gh repo clone "$org/$repo"; then
                log_success "Cloned: $repo"
                ((cloned++))
            else
                log_error "Failed to clone: $repo"
                ((errors++))
            fi
        fi
    done <<< "$repos"

    echo ""
    log_success "Sync complete: $cloned new, $pulled updated, $errors errors"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 <command> <organization>

Commands:
    list    List all public repositories for the organization
    clone   Clone all public repositories for the organization
    sync    Pull updates for existing repos and clone new ones

Examples:
    $0 list anthropics
    $0 clone anthropics
    $0 sync anthropics

EOF
    exit 1
}

# Main script
main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local command="$1"
    local org="$2"

    # Check prerequisites
    check_gh_cli

    case "$command" in
        list)
            list_repos "$org"
            ;;
        clone)
            clone_repos "$org"
            ;;
        sync)
            sync_repos "$org"
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            ;;
    esac
}

main "$@"
