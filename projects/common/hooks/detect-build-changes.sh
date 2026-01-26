#!/bin/bash
# detect-build-changes.sh
# Detect build.py changes and prompt skill document update

HASH_FILE="/tmp/claude-build-py-hash-${USER}"
BUILD_PY=""
ENV_TYPE=""

# Detect environment based on project structure
if [ -f "$CLAUDE_PROJECT_DIR/mobis/build.py" ]; then
    BUILD_PY="$CLAUDE_PROJECT_DIR/mobis/build.py"
    ENV_TYPE="yocto"
elif [ -f "$CLAUDE_PROJECT_DIR/build.py" ]; then
    BUILD_PY="$CLAUDE_PROJECT_DIR/build.py"
    ENV_TYPE="host"
fi

# Exit if no build.py found
if [ -z "$BUILD_PY" ]; then
    exit 0
fi

# Calculate current hash
CURRENT_HASH=$(md5sum "$BUILD_PY" 2>/dev/null | cut -d' ' -f1)

if [ -z "$CURRENT_HASH" ]; then
    exit 0
fi

# Compare with stored hash
if [ -f "$HASH_FILE" ]; then
    STORED_HASH=$(cat "$HASH_FILE")
    if [ "$CURRENT_HASH" != "$STORED_HASH" ]; then
        # Build.py changed - update hash and notify
        echo "$CURRENT_HASH" > "$HASH_FILE"

        # Extract option names for reference
        OPTIONS=$(grep -oE '"\-\-[a-z0-9-]+"' "$BUILD_PY" 2>/dev/null | \
            tr -d '"' | sort -u | tr '\n' ' ' | head -c 500)

        # Output JSON for Claude systemMessage
        cat << EOF
{
  "continue": true,
  "systemMessage": "[BUILD_SCRIPT_CHANGED] build.py has been modified since last session.\nEnvironment: ${ENV_TYPE}\nDetected options: ${OPTIONS}\n\nConsider updating /snt-ccu2-${ENV_TYPE}:build skill documentation if CLI options changed."
}
EOF
    fi
else
    # First run - store hash silently
    echo "$CURRENT_HASH" > "$HASH_FILE"
fi
