# org-cloner

A command-line tool for managing GitHub organization repositories. List, clone, and sync all public repositories from any GitHub organization.

## Features

- **List**: View all public repositories in an organization
- **Clone**: Clone all public repositories from an organization
- **Sync**: Update existing repositories and clone new ones
- **Smart Directory Management**: Automatically detects if you're already in an organization directory

## Prerequisites

- [GitHub CLI (gh)](https://cli.github.com/) installed and authenticated
- Bash shell
- Git

## Installation

Run the installation script:

```bash
./install.sh
```

This will create a symlink to `/usr/local/bin/org-cloner`, making the command available system-wide.

### Uninstall

To remove the symlink:

```bash
./install.sh --uninstall
```

## Usage

```bash
org-cloner <command> <organization>
```

### Commands

- `list` - List all public repositories for the organization
- `clone` - Clone all public repositories for the organization
- `sync` - Pull updates for existing repos and clone new ones

### Examples

List all public repositories in the Anthropic organization:
```bash
org-cloner list anthropics
```

Clone all public repositories:
```bash
org-cloner clone anthropics
```

Sync repositories (update existing, clone new):
```bash
org-cloner sync anthropics
```

## How It Works

### Directory Management

The tool uses intelligent directory management:

1. If you're already inside a directory matching the organization name, it uses that location
2. Otherwise, it creates a new directory with the organization name in your current location

For example:
```bash
# Creates ./anthropics/ and clones there
cd ~/projects
org-cloner clone anthropics

# Or navigate to an existing directory
cd ~/projects/anthropics
org-cloner sync anthropics  # Updates repos in current directory
```

### Authentication

The tool requires GitHub CLI authentication. If not authenticated, run:

```bash
gh auth login
```

## Features in Detail

### List Repositories
Displays all public repositories with their URLs:
```
ℹ Fetching public repositories for organization: anthropics
  • repo-name - https://github.com/anthropics/repo-name
  • another-repo - https://github.com/anthropics/another-repo
```

### Clone Repositories
Clones all public repositories that don't already exist locally:
- Skips existing repositories
- Shows progress for each repository
- Provides summary of cloned and skipped repositories

### Sync Repositories
The most comprehensive command:
- Pulls latest changes for existing repositories
- Clones new repositories that don't exist locally
- Reports summary of new, updated, and failed repositories

## License

MIT
