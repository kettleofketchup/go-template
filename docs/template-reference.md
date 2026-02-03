# Template Reference

## Template Variables

| Variable | Type | Default | Condition | Description |
|----------|------|---------|-----------|-------------|
| `project_name` | string | (required) | - | Project/repo directory name |
| `tool_name` | string | `{{ project_name }}` | - | CLI binary name |
| `ci_platform` | choice | `gitlab` | - | CI/CD platform (`gitlab` or `github`) |
| `gitlab_url` | string | `gitlab.lan` | `ci_platform == 'gitlab'` | GitLab instance URL |
| `gitlab_registry` | string | `{{ gitlab_url }}:5050/{{ project_name }}` | `ci_platform == 'gitlab'` | Docker registry path |
| `github_registry` | string | `ghcr.io/{{ project_name }}` | `ci_platform == 'github'` | GitHub Container Registry |

### Derived Values

These are computed from the template variables:

**For GitLab:**

- **Go module path**: `{{ gitlab_url }}/{{ project_name }}`
- **Docker image tag**: `{{ gitlab_registry }}/{{ tool_name }}:${CI_COMMIT_TAG}`

**For GitHub:**

- **Go module path**: `github.com/{{ github_registry | replace('ghcr.io/', '') }}`
- **Docker image tag**: `{{ github_registry }}/{{ tool_name }}:${GITHUB_REF_NAME}`

**Common:**

- **Binary output**: `bin/{{ tool_name }}`

## Generated Project Structure

```
{{ project_name }}/
├── .gitlab-ci.yml          # GitLab CI (if ci_platform=gitlab)
├── .github/                # GitHub Actions (if ci_platform=github)
│   └── workflows/
│       ├── ci.yml          # CI workflow (lint, test, build, docker)
│       └── pages.yml       # Documentation deployment
├── .gitignore
├── mkdocs.yml               # Documentation config
├── pyproject.toml           # Python deps for docs
├── README.md
├── CLAUDE.md                # AI assistant instructions
├── dev                      # Bootstrap script
├── justfile                 # Root justfile with modules
├── .claude/
│   ├── agents/              # Claude Code agents
│   └── skills/              # Claude Code skills
├── docker/
│   ├── Dockerfile.{{ tool_name }}
│   └── certificates/        # CA certificates
├── docs/
│   ├── index.md
│   └── includes/
│       └── abbreviations.md
├── just/
│   ├── dev.just             # Development recipes (imported)
│   ├── go.just              # Go build recipes (go::*)
│   ├── docs.just            # Documentation recipes (docs::*)
│   ├── docker.just          # Docker recipes (docker::*)
│   ├── release.just         # Cross-compilation (release::*)
│   ├── compose.just         # Docker Compose (compose::*)
│   ├── certs.just           # Certificate management (certs::*)
│   ├── testing.just         # Test recipes (testing::*)
│   ├── cicd.just            # CI/CD recipes (cicd::*)
│   └── copier.just          # Template updates (copier::*)
└── src/
    └── {{ tool_name }}/
        ├── main.go
        ├── go.mod
        ├── cmd/
        │   ├── root.go      # Root command + Viper
        │   ├── version.go   # Version subcommand
        │   └── update.go    # Self-update command
        ├── internal/        # Private packages
        └── version/
            └── version.go   # Build-time version
```

## Just Recipes

### Core Aliases (Top-Level)

| Recipe | Group | Description |
|--------|-------|-------------|
| `just build` | dev | Build the CLI binary |
| `just test` | dev, ci | Run Go tests |
| `just lint` | dev, ci | Run golangci-lint |
| `just run` | dev | Build and run |

### Go Module (`go::`)

| Recipe | Description |
|--------|-------------|
| `just go::build <tool>` | Build the Go binary |
| `just go::test <tool>` | Run tests |
| `just go::lint <tool>` | Run linter |
| `just go::format <tool>` | Format code |
| `just go::tidy <tool>` | Tidy modules |
| `just go::clean` | Remove build artifacts |

### Documentation Module (`docs::`)

| Recipe | Description |
|--------|-------------|
| `just docs::serve` | Start MkDocs dev server |
| `just docs::build` | Build static documentation |
| `just docs::clean` | Clean generated docs |

### Docker Module (`docker::`)

| Recipe | Description |
|--------|-------------|
| `just docker::build` | Build Docker image |
| `just docker::push` | Push to registry |
| `just docker::login` | Login to registry (GitLab or GitHub) |

### Release Module (`release::`)

| Recipe | Description |
|--------|-------------|
| `just release::all` | Build for all platforms |
| `just release::linux` | Build Linux binaries |
| `just release::darwin` | Build macOS binaries |
| `just release::windows` | Build Windows binaries |

### CI/CD Module (`cicd::`)

Platform-agnostic recipes called by GitLab CI / GitHub Actions:

| Recipe | Description |
|--------|-------------|
| `just cicd::lint` | Run golangci-lint with timeout |
| `just cicd::test` | Run tests with race detection and coverage |
| `just cicd::build` | Build the binary |
| `just cicd::docker <tag>` | Build Docker image with tag |
| `just cicd::docker-push <tag>` | Build and push Docker image |
| `just cicd::pages` | Build MkDocs documentation |

### Copier Module (`copier::`)

Template update management:

| Recipe | Description |
|--------|-------------|
| `just copier::update` | Update project from template (interactive) |
| `just copier::update-auto` | Update without prompts (for CI) |
| `just copier::diff` | Show diff against template |
| `just copier::recopy` | Re-copy entire template |
| `just copier::answers` | Show current template answers |

## CI Pipeline

### GitLab CI (ci_platform=gitlab)

**Stages:**

1. **test** - Lint and test on merge requests and tags
2. **build** - Compile binary, create artifacts
3. **docker** - Build and push image on tags
4. **pages** - Deploy docs on main branch

**Pipeline Rules:**

- **Merge requests**: lint, test, build
- **Tags (v*)**: lint, test, build, docker
- **Main branch**: pages deployment

### GitHub Actions (ci_platform=github)

**Workflows:**

1. **ci.yml** - Runs on PRs and version tags
   - `lint` job: golangci-lint
   - `test` job: go test with race detection
   - `build` job: compile binary, upload artifact
   - `docker` job: build and push to GHCR (tags only)

2. **pages.yml** - Runs on main/master branch
   - `build` job: build MkDocs documentation
   - `deploy` job: deploy to GitHub Pages

**Trigger Rules:**

- **Pull requests**: lint, test, build
- **Tags (v*)**: lint, test, build, docker
- **Main/master branch**: pages deployment
