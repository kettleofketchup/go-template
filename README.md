# Go Template

A Copier-based project template for generating standardized Go CLI projects.

## Features

- **Cobra CLI** with Viper configuration
- **Modular justfile** with `just/*.just` files
- **MkDocs Material** documentation
- **CI/CD** choice of GitLab CI or GitHub Actions
- **Docker** multi-stage builds with Debian slim
- **Self-update command** for automatic binary updates from releases
- **Claude Code** configuration with agents and skills

## Quick Start

### Using uv (Recommended)

```sh
# Create a new project
uvx copier copy gh:kettleofketchup/go-template ./my-project

# With specific answers
uvx copier copy gh:kettleofketchup/go-template ./my-project \
    --data project_name=myproject \
    --data tool_name=myctl \
    --data ci_platform=github
```

### Using Docker

```sh
./dev                                           # Bootstrap environment
just build                                      # Build template runner
just new git@github.com:user/myproject.git     # Create new project
```

## Template Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project/repo name | (required) |
| `tool_name` | CLI binary name | `project_name` |
| `ci_platform` | CI/CD platform (`gitlab` or `github`) | `gitlab` |
| `gitlab_url` | GitLab instance URL | `gitlab.lan` |
| `gitlab_registry` | Docker registry (GitLab) | `gitlab_url:5050/project_name` |
| `github_registry` | Container registry (GitHub) | `ghcr.io/project_name` |
| `self_update` | Include self-update command | `true` |

## Generated Project Structure

```
myproject/
├── src/mytool/          # Go source code
│   ├── cmd/             # CLI commands (root, version, update)
│   ├── internal/        # Private packages
│   └── version/         # Version info
├── just/                # justfile modules
├── docs/                # MkDocs documentation
├── docker/              # Docker configuration
├── .claude/             # Claude Code config
├── .gitlab-ci.yml       # GitLab CI (if ci_platform=gitlab)
├── .github/workflows/   # GitHub Actions (if ci_platform=github)
├── justfile             # Build system
└── mkdocs.yml           # Docs config
```

## Adding Certificates

Place `.pem` files in `docker/certificates/` before building. They will be:
- Baked into the Copier runner image
- Copied to generated projects

## Documentation

Full documentation: [https://kettleofketchup.github.io/go-template](https://kettleofketchup.github.io/go-template)

## Development

```sh
just clean               # Clean output directory
just build               # Rebuild Docker image
just testing::test-template  # Test template generation
just docs::serve         # Serve docs locally
```
