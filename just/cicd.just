# CI/CD recipes - platform-agnostic build commands
# Call as: just cicd::build, just cicd::test-template, etc.

# Build the Copier runner Docker image
build:
    @echo "Building Copier runner image..."
    docker build -t go-template:latest -f docker/Dockerfile .

# Test template generation produces working project
test-template:
    just test-template

# Build documentation to public/
pages:
    @echo "Building documentation..."
    uv sync
    uv run mkdocs build
