# Template Reference

## Template Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | string | (required) | Project/repo directory name |
| `tool_name` | string | `{{ project_name }}` | CLI binary name |
| `gitlab_url` | string | `gitlab.lan` | GitLab instance URL |
| `gitlab_registry` | string | `{{ gitlab_url }}:5050/{{ project_name }}` | Docker registry path |

### Derived Values

These are computed from the template variables:

- **Go module path**: `{{ gitlab_url }}/{{ project_name }}`
- **Docker image tag**: `{{ gitlab_registry }}/{{ tool_name }}:${CI_COMMIT_TAG}`
- **Binary output**: `bin/{{ tool_name }}`

## Generated Project Structure

```
{{ project_name }}/
├── .gitlab-ci.yml          # CI pipeline configuration
├── .gitignore
├── mkdocs.yml               # Documentation config
├── pyproject.toml           # Python deps for docs
├── README.md
├── CLAUDE.md                # AI assistant instructions
├── dev                      # Bootstrap script
├── justfile                 # Root justfile (imports just/justfile)
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
│   ├── justfile             # Main justfile with modules
│   ├── dev.just             # Development recipes
│   ├── go.just              # Go build recipes (go::*)
│   ├── docs.just            # Documentation recipes (docs::*)
│   ├── docker.just          # Docker recipes (docker::*)
│   ├── release.just         # Cross-compilation (release::*)
│   ├── compose.just         # Docker Compose (compose::*)
│   ├── certs.just           # Certificate management (certs::*)
│   └── testing.just         # Test recipes (testing::*)
└── src/
    └── {{ tool_name }}/
        ├── main.go
        ├── go.mod
        ├── cmd/
        │   ├── root.go      # Root command + Viper
        │   └── version.go   # Version subcommand
        ├── internal/        # Private packages
        └── version/
            └── version.go   # Build-time version
```

## Just Recipes

### Core Aliases (Top-Level)

| Recipe | Description |
|--------|-------------|
| `just build` | Build the CLI binary |
| `just test` | Run Go tests |
| `just lint` | Run golangci-lint |
| `just run` | Build and run |

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
| `just docker::login` | Login to GitLab registry |

### Release Module (`release::`)

| Recipe | Description |
|--------|-------------|
| `just release::all` | Build for all platforms |
| `just release::linux` | Build Linux binaries |
| `just release::darwin` | Build macOS binaries |
| `just release::windows` | Build Windows binaries |

## GitLab CI Pipeline

### Stages

1. **test** - Lint and test on merge requests
2. **build** - Compile binary, create artifacts
3. **docker** - Build and push image on tags
4. **pages** - Deploy docs on main branch

### Pipeline Rules

- **Merge requests**: lint, test, build
- **Tags (v*)**: lint, test, build, docker
- **Main branch**: pages deployment
