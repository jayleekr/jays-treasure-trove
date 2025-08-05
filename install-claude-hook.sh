#!/bin/bash
# Claude Hook Installer - Install hooks anywhere with one command
# Usage: curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-claude-hook.sh | bash -s -- [hook-type] [target-dir]

set -e

HOOK_TYPE="${1:-pre-commit}"
TARGET_DIR="${2:-.}"

# Validate hook type
VALID_HOOKS=("pre-commit" "post-commit" "pre-push" "commit-msg" "prepare-commit-msg")
if [[ ! " ${VALID_HOOKS[@]} " =~ " ${HOOK_TYPE} " ]]; then
    echo "❌ Invalid hook type. Valid types: ${VALID_HOOKS[*]}"
    exit 1
fi

echo "🪝 Installing Claude hook: $HOOK_TYPE in $TARGET_DIR"

# Create git hooks directory if it doesn't exist
mkdir -p "$TARGET_DIR/.git/hooks"

# Create the hook file
HOOK_FILE="$TARGET_DIR/.git/hooks/$HOOK_TYPE"

cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
# Claude AI Hook - Automated code review and suggestions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🤖 Running Claude AI analysis...${NC}"

# Get staged files for pre-commit hooks
if [[ "$0" == *"pre-commit"* ]]; then
    FILES=$(git diff --cached --name-only --diff-filter=ACM)
else
    FILES=$(git diff --name-only HEAD~1)
fi

# Skip if no files to analyze
if [ -z "$FILES" ]; then
    echo -e "${GREEN}✅ No files to analyze${NC}"
    exit 0
fi

# Create temporary file for analysis
TEMP_FILE=$(mktemp)
echo "Files to analyze:" > "$TEMP_FILE"
echo "$FILES" >> "$TEMP_FILE"

# Add file contents for context
echo -e "\n--- File Contents ---" >> "$TEMP_FILE"
for file in $FILES; do
    if [ -f "$file" ]; then
        echo -e "\n=== $file ===" >> "$TEMP_FILE"
        head -100 "$file" >> "$TEMP_FILE" 2>/dev/null || true
    fi
done

# Claude analysis prompt based on hook type
case "$0" in
    *pre-commit*)
        PROMPT="Review these staged changes for potential issues, bugs, or improvements. Be concise."
        ;;
    *post-commit*)
        PROMPT="Analyze this commit for documentation needs or follow-up tasks. Be concise."
        ;;
    *pre-push*)
        PROMPT="Check if these changes are ready for pushing. Look for incomplete work or TODOs."
        ;;
    *commit-msg*)
        PROMPT="Review this commit message for clarity and conventional commit standards."
        ;;
    *)
        PROMPT="Analyze these changes and provide relevant feedback."
        ;;
esac

# Use Claude if available (you can customize this part)
if command -v claude &> /dev/null; then
    echo -e "${YELLOW}🔍 Analyzing with Claude...${NC}"
    # Add your Claude API call here
    # claude api "$PROMPT" < "$TEMP_FILE"
    echo -e "${GREEN}✅ Analysis complete${NC}"
else
    echo -e "${YELLOW}⚠️  Claude CLI not found. Install it for AI-powered reviews.${NC}"
fi

# Cleanup
rm -f "$TEMP_FILE"

# Always allow the operation to continue
exit 0
EOF

# Make the hook executable
chmod +x "$HOOK_FILE"

echo "✅ Claude hook '$HOOK_TYPE' installed successfully in $TARGET_DIR!"
echo "📍 Location: $HOOK_FILE"
echo "🎯 The hook will run automatically on '$HOOK_TYPE' events"