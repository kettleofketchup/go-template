#!/bin/bash
# Claude Code Hook: Check documentation freshness before commit
# Triggered on PreToolUse for git commit
# Analyzes staged changes and flags if docs/ may need updates

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$PROJECT_DIR"

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

# Categories of files that typically require doc updates
CODE_PATTERNS="\.go$|\.mk$|Makefile|docker-compose|Dockerfile"
CONFIG_PATTERNS="\.yaml$|\.yml$|\.json$|\.toml$"
AGENT_PATTERNS="\.claude/agents/|\.claude/skills/"

# Check what types of files are being committed
HAS_CODE_CHANGES=false
HAS_CONFIG_CHANGES=false
HAS_AGENT_CHANGES=false
HAS_DOC_CHANGES=false

CHANGED_CODE_FILES=""
CHANGED_CONFIG_FILES=""
CHANGED_AGENT_FILES=""

while IFS= read -r file; do
    if [[ "$file" =~ ^docs/ ]]; then
        HAS_DOC_CHANGES=true
    elif [[ "$file" =~ $CODE_PATTERNS ]]; then
        HAS_CODE_CHANGES=true
        CHANGED_CODE_FILES="$CHANGED_CODE_FILES $file"
    elif [[ "$file" =~ $CONFIG_PATTERNS ]]; then
        HAS_CONFIG_CHANGES=true
        CHANGED_CONFIG_FILES="$CHANGED_CONFIG_FILES $file"
    elif [[ "$file" =~ $AGENT_PATTERNS ]]; then
        HAS_AGENT_CHANGES=true
        CHANGED_AGENT_FILES="$CHANGED_AGENT_FILES $file"
    fi
done <<< "$STAGED_FILES"

# If only docs are being changed, or nothing significant, skip check
if [ "$HAS_CODE_CHANGES" = false ] && [ "$HAS_CONFIG_CHANGES" = false ] && [ "$HAS_AGENT_CHANGES" = false ]; then
    exit 0
fi

# Build context for Claude
CONTEXT=""

if [ "$HAS_CODE_CHANGES" = true ]; then
    CONTEXT="$CONTEXT\n- Code files changed:$CHANGED_CODE_FILES"
fi

if [ "$HAS_CONFIG_CHANGES" = true ]; then
    CONTEXT="$CONTEXT\n- Config files changed:$CHANGED_CONFIG_FILES"
fi

if [ "$HAS_AGENT_CHANGES" = true ]; then
    CONTEXT="$CONTEXT\n- Agent/skill files changed:$CHANGED_AGENT_FILES"
fi

if [ "$HAS_DOC_CHANGES" = true ]; then
    CONTEXT="$CONTEXT\n- Documentation is being updated in this commit"
fi

# Output reminder for Claude
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "DOCUMENTATION CHECK REQUIRED before commit.\n\nStaged changes include:$CONTEXT\n\nBefore proceeding with the commit, please verify:\n1. Are the docs/ MkDocs pages up to date with these changes?\n2. Are any .claude/agents/ files affected and documented?\n3. Check docs/dev/ for developer documentation that may need updates.\n4. Check docs/design/ for design docs that may be outdated.\n\nKey documentation areas:\n- docs/dev/test/ - Testing documentation\n- docs/dev/quickstart.md - Getting started guide\n- docs/design/cache/ - Cache implementation docs\n- .claude/agents/ - Agent documentation\n\nIf docs need updating, use the mkdocs-documentation-writer agent to update them before committing."
  }
}
EOF
