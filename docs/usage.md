# Usage

## Creating a New Project

### Interactive Mode

Run the template with a target Git repository:

```bash
just new git@gitlab.lan:mygroup/myproject.git
```

Copier will prompt for:

| Prompt | Description | Example |
|--------|-------------|---------|
| `project_name` | Repository directory name | `myproject` |
| `tool_name` | CLI binary name | `myctl` |
| `ci_platform` | CI/CD platform choice | `gitlab` or `github` |
| `gitlab_url` | GitLab instance URL (if GitLab) | `gitlab.lan` |
| `gitlab_registry` | Docker registry path (if GitLab) | `gitlab.lan:5050/myproject` |
| `github_registry` | GitHub Container Registry (if GitHub) | `ghcr.io/myproject` |

### What Happens

1. Docker runs Copier with your answers
2. Project generates in `output/<project_name>/`
3. Git repository initializes
4. Remote origin set to your `REPO` URL
5. Initial commit created

### Post-Creation

Navigate to your new project and push:

```bash
cd output/myproject
git push -u origin main
```

## First Steps in Your New Project

### Quick Start

```bash
./dev
```

This bootstraps your environment (installs `just` if needed).

### Build the CLI

```bash
just build
./bin/myctl version
```

### Run Tests

```bash
just test
```

### Start Documentation Server

```bash
just docs::serve
```

Open http://localhost:8000 to view docs.

### Build Docker Image

```bash
just docker::build
```

## CI/CD Commands

The `cicd` module provides platform-agnostic CI/CD commands that work identically whether you're using GitLab CI or GitHub Actions:

| Recipe | Description |
|--------|-------------|
| `just cicd::lint` | Run golangci-lint |
| `just cicd::test` | Run tests with race detection |
| `just cicd::build` | Build the binary |
| `just cicd::docker <tag>` | Build Docker image |
| `just cicd::docker-push <tag>` | Build and push Docker image |
| `just cicd::pages` | Build MkDocs documentation |

These commands are called by the CI pipeline, but you can also run them locally.

## Self-Update Command

Your generated CLI includes a built-in update command that downloads the latest release:

```bash
# Check for and install updates
./bin/myctl update
```

**How it works:**

1. Detects the release source from your git remote URL (GitHub or GitLab)
2. Queries the releases API for the latest version
3. Compares against current version
4. Downloads the appropriate binary for your OS/architecture
5. Atomically replaces the running binary

**Supported platforms:**

- GitHub releases (`github.com`)
- GitLab releases (gitlab.com and self-hosted instances)
- Automatic binary naming: `<tool>_<os>_<arch>` (e.g., `myctl_linux_amd64`)
- Windows support with `.exe` extension

## Updating from Template

When the go-template is updated, you can pull in changes to your project:

```bash
# Interactive update (recommended)
just copier::update

# Show what would change without applying
just copier::diff

# Non-interactive update (for scripts/CI)
just copier::update-auto

# Re-copy entire template (for major changes)
just copier::recopy

# View current template answers
just copier::answers
```

## Project Structure

Your generated project includes:

```
myproject/
├── src/myctl/          # Go source code
│   ├── cmd/            # Cobra commands
│   ├── internal/       # Private packages
│   └── version/        # Version info
├── docs/               # MkDocs documentation
├── docker/             # Dockerfiles
├── just/               # justfile modules
│   └── cicd.just       # CI/CD recipes
├── .gitlab-ci.yml      # GitLab CI (if ci_platform=gitlab)
└── .github/workflows/  # GitHub Actions (if ci_platform=github)
```

See [Template Reference](template-reference.md) for full details.
