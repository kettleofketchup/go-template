# Development recipes

# Bootstrap the development environment
dev:
    @echo "Setting up development environment..."
    uv sync
    @echo "Done! Development environment ready."
    @echo ""
    @echo "Available commands:"
    @echo "  just build        Build the Copier runner image"
    @echo "  just new REPO     Create a new project from template"
    @echo "  just test-template  Run end-to-end template test"
    @echo "  just docs-serve   Start docs dev server"
