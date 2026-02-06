#!/bin/bash
# Remote Claude Code Executor
# Usage: ./remote-claude.sh <host> <workdir> "<prompt>" [max_turns] [--stream]

set -euo pipefail

HOST=${1:-}
WORKDIR=${2:-}
PROMPT=${3:-}
MAX_TURNS=${4:-15}
STREAM=${5:-}

if [[ -z "$HOST" || -z "$WORKDIR" || -z "$PROMPT" ]]; then
    echo "Usage: $0 <host> <workdir> '<prompt>' [max_turns] [--stream]"
    echo ""
    echo "Examples:"
    echo "  $0 ccu2-builder /workspace/ccu-2.0 'Build container-manager'"
    echo "  $0 yocto-builder /workspace/manifest 'Build linux-s32' 20"
    echo "  $0 test-runner /workspace/tests 'Run all tests' 10 --stream"
    exit 1
fi

# Output format based on streaming option
if [[ "$STREAM" == "--stream" ]]; then
    OUTPUT_FORMAT="stream-json"
    EXTRA_FLAGS="--verbose --include-partial-messages"
else
    OUTPUT_FORMAT="json"
    EXTRA_FLAGS=""
fi

echo "🔌 Connecting to $HOST..."
echo "📁 Working directory: $WORKDIR"
echo "🤖 Max turns: $MAX_TURNS"
echo "📝 Prompt: $PROMPT"
echo "---"

# Execute remote Claude Code
ssh -o ConnectTimeout=30 -o ServerAliveInterval=60 "$HOST" << EOF
cd "$WORKDIR" || exit 1
echo "✅ Connected to \$(hostname)"
echo "📂 PWD: \$(pwd)"
echo "🔧 Claude Code version: \$(claude --version 2>/dev/null || echo 'unknown')"
echo "---"

claude -p "$PROMPT" \
    --allowedTools "Bash,Read,Edit,Grep,Glob,Write" \
    --output-format $OUTPUT_FORMAT \
    --max-turns $MAX_TURNS \
    $EXTRA_FLAGS \
    --dangerously-skip-permissions

echo "---"
echo "✅ Remote execution complete"
EOF
