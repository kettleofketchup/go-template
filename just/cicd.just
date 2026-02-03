# CI/CD recipes - platform-agnostic build commands
# Call as: just cicd::build, just cicd::test-template, etc.
# These recipes are called by GitLab CI / GitHub Actions

# Build the Copier runner Docker image
[group('cicd')]
build:
    @echo "Building Copier runner image..."
    docker build -t go-template:latest -f docker/Dockerfile .

# Test template generation produces working project
[group('cicd')]
test-template:
    just testing::test-template

# Build documentation to public/
[group('cicd')]
pages:
    @echo "Building documentation..."
    uv sync
    uv run mkdocs build
