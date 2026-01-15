#!/bin/bash
# Claude Code Hook: Run integration tests after Go source code changes
# Triggered on PostToolUse for Edit/Write operations on src/**/*.go files

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$PROJECT_DIR"

# Check if the tool input contains a Go file in src/
# CLAUDE_TOOL_INPUT contains the file path for Edit/Write operations
if [[ -n "$CLAUDE_TOOL_INPUT" ]]; then
    # Extract file path from JSON input (handles both Edit and Write tools)
    FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' || true)

    # Only run tests for Go files in src/
    if [[ ! "$FILE_PATH" =~ src/.*\.go$ ]]; then
        exit 0
    fi
fi

# Check if hookshot image exists
if ! docker images hookshot:latest --format "{{.Repository}}" | grep -q hookshot; then
    echo '{"decision": "block", "reason": "hookshot:latest image not found. Build with: make docker.hookshot.build"}' >&2
    exit 0
fi

echo "Go source file changed: $FILE_PATH" >&2
echo "Running integration tests..." >&2

# Run testcontainers integration tests (self-contained)
cd "$PROJECT_DIR/tests/integration"
if go test -v -timeout 5m ./... 2>&1; then
    TEST_RESULT="PASS"
else
    TEST_RESULT="FAIL"
fi

# Output result for Claude
if [ "$TEST_RESULT" = "PASS" ]; then
    echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Integration tests passed"}}'
else
    echo '{"decision": "block", "reason": "Integration tests failed. Please review the test output and fix any issues."}'
fi
