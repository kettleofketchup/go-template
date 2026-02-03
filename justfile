# Go Template - Copier-based project generator
# Run `just --list` to see all available recipes

set quiet
set dotenv-load

# Modules - call as `just module::recipe`
mod cicd 'just/cicd.just'
mod copier 'just/copier.just'
mod testing 'just/testing.just'

# Import top-level recipes (merged into root namespace)
import 'just/dev.just'

# List all available recipes
default:
    just --list

# Variables
IMAGE_NAME := "go-template"
IMAGE_TAG := "latest"

# Build the Copier runner Docker image
[group('build')]
build:
    @echo "Building Copier runner image..."
    docker build -t {{ IMAGE_NAME }}:{{ IMAGE_TAG }} -f docker/Dockerfile .
    @echo ""
    @echo "Image built: {{ IMAGE_NAME }}:{{ IMAGE_TAG }}"

# Create a new project from template (usage: just new git@gitlab.example.com:group/project.git)
[group('dev')]
new REPO:
    @mkdir -p output
    @echo "Running Copier template..."
    docker run -it --rm \
        -v "$(pwd)/output:/workspace" \
        {{ IMAGE_NAME }}:{{ IMAGE_TAG }}
    @echo ""
    @echo "Project created in output/"
    @PROJECT_DIR=$(ls -d output/*/ 2>/dev/null | head -1) && \
    if [ -n "$$PROJECT_DIR" ]; then \
        echo "Initializing git repository..." && \
        cd "$$PROJECT_DIR" && \
        git init && \
        git remote add origin {{ REPO }} && \
        git add . && \
        git commit -m "Initial commit from go-template" && \
        echo "" && \
        echo "Done! Project ready at: $$PROJECT_DIR" && \
        echo "To push: cd $$PROJECT_DIR && git push -u origin main"; \
    else \
        echo "Error: No project directory found in output/"; \
        exit 1; \
    fi

# Remove output directory
[group('dev')]
clean:
    rm -rf output/
    @echo "Output directory cleaned"

# Start MkDocs development server
[group('docs')]
docs-serve:
    uv run mkdocs serve

# Build documentation
[group('docs')]
docs-build:
    uv run mkdocs build
