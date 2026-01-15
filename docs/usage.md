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
| `gitlab_url` | GitLab instance URL | `gitlab.lan` |
| `gitlab_registry` | Docker registry path | `gitlab.lan:5050/myproject` |

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
└── .gitlab-ci.yml      # CI pipeline
```

See [Template Reference](template-reference.md) for full details.
