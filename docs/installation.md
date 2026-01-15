# Installation

## Prerequisites

### Required

- **Docker** - For running the Copier template generator
- **Git** - For version control and SSH access to GitLab
- **just** - For running build recipes (auto-installed by `./dev`)

### Optional

- **uv** - For local documentation development (`uv run mkdocs serve`)

## Building the Template Runner

The template runs inside a Docker container that includes:

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
