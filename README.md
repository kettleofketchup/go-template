# Go Template

A Copier-based project template for generating standardized Go CLI projects.

## Features

- **Cobra CLI** with Viper configuration
- **Modular justfile** with `just/*.just` files
- **MkDocs Material** documentation
- **GitLab CI** pipeline (test, build, docker, pages)
- **Docker** multi-stage builds with Debian slim
- **Claude Code** configuration with agents and skills

## Prerequisites

- Docker
- [just](https://github.com/casey/just) (auto-installed by `./dev`)

## Usage

### Quick Start

```sh
./dev
```

This bootstraps your environment (installs `just` if needed).

### Build the Template Runner

```sh
just build
```

### Create a New Project

```sh
just new git@gitlab.lan:mygroup/myproject.git
```

This will:
1. Run Copier interactively
2. Prompt for project variables
3. Generate project in `output/`
4. Initialize git and set remote

### Template Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project/repo name | (required) |
| `tool_name` | CLI binary name | `project_name` |
| `gitlab_url` | GitLab instance URL | `gitlab.lan` |
| `gitlab_registry` | Docker registry | `gitlab_url:5050/project_name` |

## Adding Certificates

Place `.pem` files in `docker/certificates/` before building. They will be:
- Baked into the Copier runner image
- Copied to generated projects

## Generated Project Structure

```
myproject/
├── src/mytool/          # Go source code
│   ├── cmd/             # CLI commands
│   ├── internal/        # Private packages
│   └── version/         # Version info
├── just/                # justfile modules
├── docs/                # MkDocs documentation
├── docker/              # Docker configuration
├── .claude/             # Claude Code config
├── .gitlab-ci.yml       # CI pipeline
├── just/justfile        # Build system
└── mkdocs.yml           # Docs config
```

## Development

### Clean Output

```sh
just clean
```

### Rebuild Image

```sh
just build
```
