# Template testing recipes

# Test variables
TEST_OUTPUT_DIR := "output/test"
TEST_PROJECT_NAME := "testproject"
TEST_TOOL_NAME := "testtool"
TEST_GITLAB_URL := "gitlab.example.com"
TEST_GITLAB_REGISTRY := TEST_GITLAB_URL + ":5050/" + TEST_PROJECT_NAME

# Run end-to-end template test
test-template: build
    @echo "=== Testing template generation ==="
    @rm -rf {{ TEST_OUTPUT_DIR }}
    @mkdir -p {{ TEST_OUTPUT_DIR }}
    @docker run --rm \
        -v "$(pwd)/{{ TEST_OUTPUT_DIR }}:/workspace" \
        --user $(id -u):$(id -g) \
        {{ IMAGE_NAME }}:{{ IMAGE_TAG }} \
        --defaults \
        -d project_name={{ TEST_PROJECT_NAME }} \
        -d tool_name={{ TEST_TOOL_NAME }} \
        -d gitlab_url={{ TEST_GITLAB_URL }} \
        -d gitlab_registry={{ TEST_GITLAB_REGISTRY }} \
        /workspace
    @echo "=== Running generated project pipeline ==="
    cd {{ TEST_OUTPUT_DIR }}/{{ TEST_PROJECT_NAME }} && just build
    cd {{ TEST_OUTPUT_DIR }}/{{ TEST_PROJECT_NAME }} && just test
    cd {{ TEST_OUTPUT_DIR }}/{{ TEST_PROJECT_NAME }} && just lint
    cd {{ TEST_OUTPUT_DIR }}/{{ TEST_PROJECT_NAME }} && just docker::build
    @echo "=== Template test passed ==="
    @rm -rf {{ TEST_OUTPUT_DIR }}
    @echo "Cleaned up test artifacts"

# Clean up test artifacts
clean-test:
    @rm -rf {{ TEST_OUTPUT_DIR }}
    @echo "Cleaned up test artifacts"
