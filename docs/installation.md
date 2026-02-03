# Installation

## Prerequisites

### Required

- **Git** - For version control and SSH access to GitLab/GitHub
- **just** - For running build recipes (auto-installed by `./dev`)

### Optional (choose one)

- **uv** - Python package manager for running Copier directly
- **Docker** - For running the Copier template generator in a container

## Option 1: Using uv (Recommended)

The simplest way to use the template is with [uv](https://docs.astral.sh/uv/):

```bash
# Create a new project from the template
uvx copier copy gh:kettleofketchup/go-template ./my-project

# Or with specific answers
uvx copier copy gh:kettleofketchup/go-template ./my-project \
    --data project_name=myproject \
    --data tool_name=myctl \
    --data ci_platform=github
```

## Option 2: Using Docker

The template can also run inside a Docker container that includes:

- Python 3.12 with Copier
- GitLab CLI (glab)
- Custom CA certificates for self-signed GitLab instances

Build the image:

```bash
just build
```

This creates the `go-template:latest` Docker image.

## Self-Signed Certificates

If your GitLab instance uses self-signed certificates:

1. Export your CA certificate as a `.pem` file
2. Place it in `docker/certificates/`
3. Rebuild the image: `just build`

The certificates are automatically added to the container's trust store.

## Verifying the Installation

After building, verify the image exists:

```bash
docker images | grep go-template
```

Expected output:

```
go-template   latest   abc123def456   1 minute ago   250MB
```
