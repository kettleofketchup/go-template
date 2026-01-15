# Go Template

A Copier-based project template that generates standardized Go CLI projects.

## Features

- **Cobra CLI** - Command-line interface with subcommands, flags, and Viper configuration
- **GitLab CI** - Pre-configured pipeline with lint, test, build, and Docker stages
- **Docker builds** - Multi-stage Dockerfile with certificate support
- **MkDocs Material** - Documentation site deployed to GitLab Pages
- **Modular justfile** - Organized build system with `just/*.just` modules

## Quick Start

### 1. Build the template runner

```bash
./dev
just build
```

### 2. Create a new project

```bash
just new git@gitlab.lan:mygroup/myproject.git
```

### 3. Answer the prompts

- `project_name` - Repository/directory name (e.g., `myproject`)
- `tool_name` - CLI binary name (e.g., `myctl`)
- `gitlab_url` - GitLab instance (default: `gitlab.lan`)
- `gitlab_registry` - Docker registry path

### 4. Push to GitLab

```bash
cd output/myproject
git push -u origin main
```

## Next Steps

- [Installation](installation.md) - Prerequisites and setup
- [Usage](usage.md) - Creating and configuring projects
- [Template Reference](template-reference.md) - Variables and generated structure
- [Development](development.md) - Contributing to the template
